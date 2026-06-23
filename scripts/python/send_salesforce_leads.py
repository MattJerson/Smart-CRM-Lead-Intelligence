import argparse
import os
from datetime import date, datetime
from decimal import Decimal
from typing import Any, Optional
from uuid import UUID
from zoneinfo import ZoneInfo

import psycopg2
import requests
from dotenv import load_dotenv
from psycopg2.extras import RealDictCursor


load_dotenv()

DB_CONFIG = {
    "host": os.getenv("POSTGRES_HOST", "localhost"),
    "port": os.getenv("POSTGRES_PORT", "5432"),
    "dbname": os.getenv("POSTGRES_DB", "smart_crm"),
    "user": os.getenv("POSTGRES_USER", "crm_user"),
    "password": os.getenv("POSTGRES_PASSWORD", "crm_password"),
}

N8N_WEBHOOK_URL = os.getenv("N8N_WEBHOOK_URL")


def make_json_serializable(value: Any) -> Any:
    if isinstance(value, Decimal):
        return float(value)

    if isinstance(value, (datetime, date)):
        return value.isoformat()

    if isinstance(value, UUID):
        return str(value)

    if isinstance(value, list):
        return [make_json_serializable(item) for item in value]

    if isinstance(value, dict):
        return {
            key: make_json_serializable(item)
            for key, item in value.items()
        }

    return value


def fetch_salesforce_ready_leads(limit: int = 5) -> list[dict]:
    query = """
        SELECT
            l.lead_id,
            l.first_name,
            l.last_name,
            l.company,
            l.email,
            l.phone,
            l.service_category,
            l.budget_range,
            l.urgency_level,
            l.source_channel,
            l.inquiry_details,
            ls.total_score,
            ls.lead_quality,
            rl.routing_priority,
            rl.routing_reason
        FROM leads l
        JOIN lead_scores ls ON l.lead_id = ls.lead_id
        JOIN routing_logs rl ON l.lead_id = rl.lead_id
        LEFT JOIN salesforce_sync_logs ssl
            ON l.lead_id = ssl.lead_id
            AND ssl.salesforce_object_type = 'Lead'
            AND ssl.sync_status = 'Success'
        WHERE ls.lead_quality = 'Hot'
          AND rl.routing_priority = 'Immediate'
          AND ssl.sync_id IS NULL
        ORDER BY ls.total_score DESC
        LIMIT %s;
    """

    with psycopg2.connect(**DB_CONFIG) as connection:
        with connection.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(query, (limit,))
            return [dict(row) for row in cursor.fetchall()]


def mark_sync_pending(lead_id: str) -> None:
    query = """
        INSERT INTO salesforce_sync_logs (
            lead_id,
            salesforce_object_type,
            sync_status,
            sync_message
        )
        VALUES (%s, 'Lead', 'Pending', 'Sent to n8n for Salesforce Lead sync')
        ON CONFLICT (lead_id, salesforce_object_type)
        DO UPDATE SET
            sync_status = 'Pending',
            sync_message = 'Resent to n8n for Salesforce Lead sync',
            synced_at = CURRENT_TIMESTAMP;
    """

    with psycopg2.connect(**DB_CONFIG) as connection:
        with connection.cursor() as cursor:
            cursor.execute(query, (lead_id,))
            connection.commit()


def mark_sync_success(
    lead_id: str,
    salesforce_record_id: Optional[str] = None,
    salesforce_task_id: Optional[str] = None,
    sync_message: str = "Payload successfully synced to Salesforce"
) -> None:
    query = """
        UPDATE salesforce_sync_logs
        SET
            sync_status = 'Success',
            salesforce_record_id = %s,
            salesforce_task_id = %s,
            sync_message = %s,
            synced_at = CURRENT_TIMESTAMP
        WHERE lead_id = %s
          AND salesforce_object_type = 'Lead';
    """

    with psycopg2.connect(**DB_CONFIG) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                query,
                (
                    salesforce_record_id,
                    salesforce_task_id,
                    sync_message,
                    lead_id,
                )
            )
            connection.commit()


def mark_sync_failed(lead_id: str, error_message: str) -> None:
    query = """
        UPDATE salesforce_sync_logs
        SET
            sync_status = 'Failed',
            sync_message = %s,
            synced_at = CURRENT_TIMESTAMP
        WHERE lead_id = %s
          AND salesforce_object_type = 'Lead';
    """

    with psycopg2.connect(**DB_CONFIG) as connection:
        with connection.cursor() as cursor:
            cursor.execute(query, (error_message, lead_id))
            connection.commit()


def extract_n8n_result(response: requests.Response) -> dict:
    try:
        data = response.json()
    except ValueError:
        return {}

    if isinstance(data, list) and data:
        first_item = data[0]

        if isinstance(first_item, dict):
            if "json" in first_item and isinstance(first_item["json"], dict):
                return first_item["json"]

            return first_item

    if isinstance(data, dict):
        if "json" in data and isinstance(data["json"], dict):
            return data["json"]

        return data

    return {}


def send_lead_to_n8n(lead: dict) -> bool:
    if not N8N_WEBHOOK_URL:
        raise ValueError("N8N_WEBHOOK_URL is not set in .env.")

    lead_id = str(lead["lead_id"])

    payload = {
        "event": "salesforce_lead_sync",
        "project": "Smart CRM Lead Intelligence",
        "generated_at": datetime.now(ZoneInfo("Asia/Manila")).isoformat(),
        "lead": lead,
    }

    payload = make_json_serializable(payload)

    mark_sync_pending(lead_id)

    try:
        response = requests.post(
            N8N_WEBHOOK_URL,
            json=payload,
            timeout=30
        )

        response.raise_for_status()

        result = extract_n8n_result(response)

        salesforce_lead_id = result.get("salesforce_lead_id")
        salesforce_task_id = result.get("salesforce_task_id")
        task_created = result.get("task_created")
        n8n_message = result.get("message", "Synced through n8n.")

        sync_message = (
            f"{n8n_message} "
            f"Lead ID: {salesforce_lead_id}. "
            f"Task ID: {salesforce_task_id}. "
            f"Task created: {task_created}."
        )

        mark_sync_success(
            lead_id=lead_id,
            salesforce_record_id=salesforce_lead_id,
            salesforce_task_id=salesforce_task_id,
            sync_message=sync_message
        )

        print(
            f"Synced lead to Salesforce through n8n: "
            f"{lead['first_name']} {lead['last_name']}"
        )
        print(f"Salesforce Lead ID: {salesforce_lead_id}")
        print(f"Salesforce Task ID: {salesforce_task_id}")
        print(f"Task Created: {task_created}")

        return True

    except requests.exceptions.HTTPError as error:
        error_message = (
            f"HTTP error from n8n. "
            f"Status code: {response.status_code}. "
            f"Response body: {response.text}"
        )

        mark_sync_failed(lead_id, error_message)

        print("n8n Salesforce lead sync failed.")
        print(f"Lead ID: {lead_id}")
        print(error_message)

        return False

    except requests.exceptions.RequestException as error:
        mark_sync_failed(lead_id, str(error))

        print("n8n Salesforce lead sync failed.")
        print(f"Lead ID: {lead_id}")
        print(f"Error: {error}")

        return False


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sync high-priority CRM leads to Salesforce through n8n."
    )

    parser.add_argument(
        "--limit",
        type=int,
        default=5,
        help="Maximum number of high-priority leads to sync."
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview leads that would be synced without sending them to n8n."
    )

    return parser.parse_args()


def main() -> None:
    args = parse_args()

    if args.limit <= 0:
        raise ValueError("--limit must be greater than 0.")

    leads = fetch_salesforce_ready_leads(limit=args.limit)

    if not leads:
        print("No high-priority leads found for Salesforce sync.")
        return

    if args.dry_run:
        print("Dry run mode. No leads will be sent to n8n.")
        print(f"Leads ready for Salesforce sync: {len(leads)}")

        for lead in leads:
            print(
                f"- {lead['first_name']} {lead['last_name']} | "
                f"{lead['email']} | "
                f"Score: {lead['total_score']} | "
                f"Quality: {lead['lead_quality']} | "
                f"Priority: {lead['routing_priority']}"
            )

        return

    successful_syncs = 0
    failed_syncs = 0

    for lead in leads:
        was_successful = send_lead_to_n8n(lead)

        if was_successful:
            successful_syncs += 1
        else:
            failed_syncs += 1

    print("Salesforce sync completed.")
    print(f"Total attempted: {len(leads)}")
    print(f"Successful syncs: {successful_syncs}")
    print(f"Failed syncs: {failed_syncs}")


if __name__ == "__main__":
    main()
