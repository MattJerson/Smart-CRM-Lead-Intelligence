import os
from datetime import date, datetime
from decimal import Decimal
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


def make_json_serializable(value):
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


def fetch_high_priority_leads() -> list[dict]:
    query = """
        SELECT
            first_name,
            last_name,
            company,
            email,
            phone,
            service_category,
            budget_range,
            urgency_level,
            source_channel,
            assigned_sales_rep,
            total_score,
            lead_quality,
            routing_priority,
            response_status,
            routing_reason,
            routed_at
        FROM vw_pending_immediate_leads
        ORDER BY total_score DESC, routed_at ASC
        LIMIT 10;
    """

    with psycopg2.connect(**DB_CONFIG) as connection:
        with connection.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(query)
            return [dict(row) for row in cursor.fetchall()]


def build_alert_payload(high_priority_leads: list[dict]) -> dict:
    return {
        "event": "high_priority_lead_alert",
        "project": "Smart CRM Lead Intelligence",
        "generated_at": datetime.now(ZoneInfo("Asia/Manila")).isoformat(),
        "alert_type": "Immediate Lead Routing",
        "total_high_priority_leads": len(high_priority_leads),
        "message": (
            "High-priority leads require immediate follow-up."
            if high_priority_leads
            else "No high-priority leads currently require immediate follow-up."
        ),
        "high_priority_leads": high_priority_leads,
    }


def send_to_n8n(payload: dict) -> None:
    if not N8N_WEBHOOK_URL:
        raise ValueError(
            "N8N_WEBHOOK_URL is not set. Add it to your .env file."
        )

    response = requests.post(
        N8N_WEBHOOK_URL,
        json=payload,
        timeout=30
    )

    try:
        response.raise_for_status()
    except requests.exceptions.HTTPError as error:
        print("n8n request failed.")
        print(f"Status code: {response.status_code}")
        print(f"Response body: {response.text}")
        print(f"Webhook URL used: {N8N_WEBHOOK_URL}")
        raise error

    print("High-priority lead alert sent to n8n successfully.")
    print(f"n8n response status: {response.status_code}")


def main() -> None:
    high_priority_leads = fetch_high_priority_leads()
    payload = build_alert_payload(high_priority_leads)
    payload = make_json_serializable(payload)
    send_to_n8n(payload)


if __name__ == "__main__":
    main()