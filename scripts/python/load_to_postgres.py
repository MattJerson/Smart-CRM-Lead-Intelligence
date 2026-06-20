import csv
import os
from pathlib import Path

import psycopg2
from psycopg2.extras import execute_batch


CSV_PATH = Path("data/raw/sample_leads.csv")

DB_CONFIG = {
    "host": os.getenv("POSTGRES_HOST", "localhost"),
    "port": os.getenv("POSTGRES_PORT", "5432"),
    "dbname": os.getenv("POSTGRES_DB", "smart_crm"),
    "user": os.getenv("POSTGRES_USER", "crm_user"),
    "password": os.getenv("POSTGRES_PASSWORD", "crm_password"),
}


def read_leads_from_csv(csv_path: Path) -> list[dict]:
    if not csv_path.exists():
        raise FileNotFoundError(
            f"CSV file not found: {csv_path}. "
            "Run generate_sample_leads.py first."
        )

    with csv_path.open(mode="r", encoding="utf-8") as csv_file:
        reader = csv.DictReader(csv_file)
        return list(reader)


def load_leads_to_postgres(leads: list[dict]) -> None:
    insert_query = """
        INSERT INTO leads (
            first_name,
            last_name,
            company,
            email,
            phone,
            service_category,
            budget_range,
            urgency_level,
            source_channel,
            location,
            inquiry_details,
            lead_status,
            campaign_id,
            assigned_sales_rep_id,
            created_at,
            updated_at
        )
        VALUES (
            %(first_name)s,
            %(last_name)s,
            %(company)s,
            %(email)s,
            %(phone)s,
            %(service_category)s,
            %(budget_range)s,
            %(urgency_level)s,
            %(source_channel)s,
            %(location)s,
            %(inquiry_details)s,
            %(lead_status)s,
            (
                SELECT campaign_id
                FROM campaigns
                WHERE source_channel = %(source_channel)s
                LIMIT 1
            ),
            (
                SELECT sales_rep_id
                FROM sales_reps
                WHERE email = %(assigned_sales_rep_email)s
                LIMIT 1
            ),
            %(created_at)s,
            CURRENT_TIMESTAMP
        )
        ON CONFLICT (email)
        DO UPDATE SET
            first_name = EXCLUDED.first_name,
            last_name = EXCLUDED.last_name,
            company = EXCLUDED.company,
            phone = EXCLUDED.phone,
            service_category = EXCLUDED.service_category,
            budget_range = EXCLUDED.budget_range,
            urgency_level = EXCLUDED.urgency_level,
            source_channel = EXCLUDED.source_channel,
            location = EXCLUDED.location,
            inquiry_details = EXCLUDED.inquiry_details,
            lead_status = EXCLUDED.lead_status,
            campaign_id = EXCLUDED.campaign_id,
            assigned_sales_rep_id = EXCLUDED.assigned_sales_rep_id,
            updated_at = CURRENT_TIMESTAMP;
    """

    with psycopg2.connect(**DB_CONFIG) as connection:
        with connection.cursor() as cursor:
            execute_batch(cursor, insert_query, leads, page_size=100)

        connection.commit()


def print_load_summary() -> None:
    summary_query = """
        SELECT
            COUNT(*) AS total_leads,
            COUNT(DISTINCT source_channel) AS source_channels,
            COUNT(DISTINCT service_category) AS service_categories
        FROM leads;
    """

    with psycopg2.connect(**DB_CONFIG) as connection:
        with connection.cursor() as cursor:
            cursor.execute(summary_query)
            total_leads, source_channels, service_categories = cursor.fetchone()

    print("Load summary:")
    print(f"Total leads: {total_leads}")
    print(f"Source channels: {source_channels}")
    print(f"Service categories: {service_categories}")


def main() -> None:
    leads = read_leads_from_csv(CSV_PATH)

    if not leads:
        print("No leads found in CSV.")
        return

    load_leads_to_postgres(leads)

    print(f"Loaded {len(leads)} leads into PostgreSQL.")
    print_load_summary()


if __name__ == "__main__":
    main()