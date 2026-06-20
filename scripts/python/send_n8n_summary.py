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


def fetch_one(cursor, query: str) -> dict:
    cursor.execute(query)
    result = cursor.fetchone()
    return dict(result) if result else {}


def fetch_all(cursor, query: str) -> list[dict]:
    cursor.execute(query)
    return [dict(row) for row in cursor.fetchall()]


def build_summary_payload() -> dict:
    with psycopg2.connect(**DB_CONFIG) as connection:
        with connection.cursor(cursor_factory=RealDictCursor) as cursor:
            lead_summary = fetch_one(
                cursor,
                """
                SELECT
                    COUNT(*) AS total_leads,
                    COUNT(*) FILTER (WHERE estimated_lead_quality = 'Hot') AS hot_leads,
                    COUNT(*) FILTER (WHERE estimated_lead_quality = 'Warm') AS warm_leads,
                    COUNT(*) FILTER (WHERE estimated_lead_quality = 'Cold') AS cold_leads,
                    ROUND(AVG(estimated_lead_score), 2) AS average_lead_score
                FROM vw_lead_scoring_base;
                """
            )

            follow_up_summary = fetch_one(
                cursor,
                """
                SELECT
                    total_tasks,
                    pending_tasks,
                    completed_tasks,
                    overdue_tasks,
                    due_today_tasks,
                    upcoming_tasks
                FROM vw_follow_up_summary;
                """
            )

            routing_summary = fetch_all(
                cursor,
                """
                SELECT
                    routing_priority,
                    total_leads,
                    pending_leads,
                    responded_leads,
                    average_lead_score,
                    average_conversion_likelihood
                FROM vw_routing_priority_summary
                ORDER BY
                    CASE routing_priority
                        WHEN 'Immediate' THEN 1
                        WHEN 'Standard' THEN 2
                        WHEN 'Nurture' THEN 3
                        ELSE 4
                    END;
                """
            )

            source_performance = fetch_all(
                cursor,
                """
                SELECT
                    source_channel,
                    total_leads,
                    hot_leads,
                    converted_leads,
                    average_lead_score,
                    conversion_rate_percentage
                FROM vw_source_channel_performance
                ORDER BY average_lead_score DESC;
                """
            )

            top_immediate_leads = fetch_all(
                cursor,
                """
                SELECT
                    first_name,
                    last_name,
                    company,
                    email,
                    service_category,
                    budget_range,
                    urgency_level,
                    source_channel,
                    assigned_sales_rep,
                    total_score,
                    lead_quality,
                    routing_priority,
                    response_status
                FROM vw_pending_immediate_leads
                LIMIT 10;
                """
            )

            pending_follow_ups = fetch_all(
                cursor,
                """
                SELECT
                    first_name,
                    last_name,
                    company,
                    email,
                    sales_rep,
                    follow_up_type,
                    due_date,
                    task_timing_status,
                    days_overdue,
                    total_score,
                    lead_quality
                FROM vw_pending_follow_up_queue
                LIMIT 10;
                """
            )

    return {
        "event": "crm_lead_operations_summary",
        "project": "Smart CRM Lead Intelligence",
        "generated_at": datetime.now(ZoneInfo("Asia/Manila")).isoformat(),
        "lead_summary": lead_summary,
        "follow_up_summary": follow_up_summary,
        "routing_summary": routing_summary,
        "source_performance": source_performance,
        "top_immediate_leads": top_immediate_leads,
        "pending_follow_ups": pending_follow_ups,
    }


def send_to_n8n(payload: dict) -> None:
    if not N8N_WEBHOOK_URL:
        raise ValueError(
            "N8N_WEBHOOK_URL is not set. "
            "Run: export N8N_WEBHOOK_URL='your_webhook_url'"
        )

    response = requests.post(
        N8N_WEBHOOK_URL,
        json=payload,
        timeout=30
    )

    response.raise_for_status()

    print("CRM operations summary sent to n8n successfully.")
    print(f"n8n response status: {response.status_code}")


def main() -> None:
    payload = build_summary_payload()
    payload = make_json_serializable(payload)
    send_to_n8n(payload)


if __name__ == "__main__":
    main()