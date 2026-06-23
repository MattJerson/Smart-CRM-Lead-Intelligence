import os
import sys

import psycopg2
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


def fetch_count(cursor, table_name: str) -> int:
    cursor.execute(f"SELECT COUNT(*) AS total FROM {table_name};")
    return cursor.fetchone()["total"]


def fetch_one(cursor, query: str) -> dict:
    cursor.execute(query)
    return dict(cursor.fetchone())


def validate_pipeline() -> bool:
    checks = []

    with psycopg2.connect(**DB_CONFIG) as connection:
        with connection.cursor(cursor_factory=RealDictCursor) as cursor:
            leads_count = fetch_count(cursor, "leads")
            lead_scores_count = fetch_count(cursor, "lead_scores")
            routing_logs_count = fetch_count(cursor, "routing_logs")
            follow_ups_count = fetch_count(cursor, "follow_ups")

            salesforce_summary = fetch_one(
                cursor,
                """
                SELECT
                    COUNT(*) FILTER (WHERE sync_status = 'Success') AS successful_syncs,
                    COUNT(*) FILTER (WHERE sync_status = 'Failed') AS failed_syncs,
                    COUNT(*) FILTER (WHERE salesforce_record_id IS NOT NULL) AS leads_with_salesforce_id,
                    COUNT(*) FILTER (WHERE salesforce_task_id IS NOT NULL) AS tasks_with_salesforce_id
                FROM salesforce_sync_logs;
                """
            )

            checks.append(("Leads loaded", leads_count == 500, leads_count))
            checks.append(("Lead scores created", lead_scores_count == 500, lead_scores_count))
            checks.append(("Routing logs created", routing_logs_count == 500, routing_logs_count))
            checks.append(("Follow-up tasks created", follow_ups_count == 500, follow_ups_count))
            checks.append(("Salesforce successful syncs", salesforce_summary["successful_syncs"] >= 1, salesforce_summary["successful_syncs"]))
            checks.append(("Salesforce failed syncs", salesforce_summary["failed_syncs"] == 0, salesforce_summary["failed_syncs"]))
            checks.append(("Salesforce Lead IDs stored", salesforce_summary["leads_with_salesforce_id"] >= 1, salesforce_summary["leads_with_salesforce_id"]))
            checks.append(("Salesforce Task IDs stored", salesforce_summary["tasks_with_salesforce_id"] >= 1, salesforce_summary["tasks_with_salesforce_id"]))

    print("\nSmart CRM Pipeline Validation")
    print("-----------------------------")

    all_passed = True

    for check_name, passed, value in checks:
        status = "PASS" if passed else "FAIL"
        print(f"{status}: {check_name} ({value})")

        if not passed:
            all_passed = False

    if all_passed:
        print("\nPipeline validation passed.")
    else:
        print("\nPipeline validation failed.")

    return all_passed


def main() -> None:
    passed = validate_pipeline()

    if not passed:
        sys.exit(1)


if __name__ == "__main__":
    main()

