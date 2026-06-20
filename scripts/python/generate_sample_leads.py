import csv
import random
import argparse
from pathlib import Path
from datetime import datetime, timedelta


OUTPUT_PATH = Path("data/raw/sample_leads.csv")


FIRST_NAMES = [
    "Miguel", "Sofia", "Daniel", "Isabella", "Gabriel",
    "Andrea", "Joshua", "Bianca", "Carlos", "Mikaela",
    "Nathan", "Jasmine", "Paolo", "Camille", "Rafael",
    "Alyssa", "Marcus", "Nicole", "John", "Patricia"
]

LAST_NAMES = [
    "Reyes", "Santos", "Cruz", "Garcia", "Lim",
    "Tan", "Mendoza", "Ramos", "Torres", "Flores",
    "Castillo", "Rivera", "Aquino", "Navarro", "Villanueva"
]

COMPANY_PREFIXES = [
    "Northstar", "BluePeak", "Silverline", "BrightPath", "CloudAxis",
    "PrimeCore", "NextWave", "UrbanEdge", "Summit", "Vertex"
]

COMPANY_SUFFIXES = [
    "Solutions", "Consulting", "Holdings", "Technologies", "Enterprises",
    "Group", "Services", "Systems", "Partners", "Industries"
]

SERVICE_CATEGORIES = [
    "CRM Implementation",
    "Workflow Automation",
    "Business Intelligence",
    "Data Migration",
    "Sales Operations",
    "Marketing Automation",
    "Customer Support Automation"
]

BUDGET_RANGES = [
    "Below 50k",
    "50k-100k",
    "100k-250k",
    "250k-500k",
    "500k+"
]

URGENCY_LEVELS = [
    "Low",
    "Medium",
    "High",
    "Critical"
]

SOURCE_CHANNELS = [
    "LinkedIn",
    "Google Search",
    "Referral",
    "Facebook",
    "Email",
    "Website"
]

LEAD_STATUSES = [
    "New",
    "Contacted",
    "Qualified",
    "Unqualified",
    "Converted",
    "Lost"
]

LOCATIONS = [
    "Metro Manila",
    "Cebu",
    "Davao",
    "Laguna",
    "Cavite",
    "Pampanga",
    "Remote"
]

SALES_REPS = [
    "alyssa.reyes@smartcrm.test",
    "marco.santos@smartcrm.test",
    "janelle.cruz@smartcrm.test",
    "rafael.lim@smartcrm.test",
    "bianca.tan@smartcrm.test"
]


def random_date_within_last_days(days: int = 180) -> str:
    today = datetime.today()
    random_days = random.randint(0, days)
    random_date = today - timedelta(days=random_days)
    return random_date.strftime("%Y-%m-%d %H:%M:%S")


def generate_phone_number() -> str:
    return f"+63 9{random.randint(10, 99)} {random.randint(100, 999)} {random.randint(1000, 9999)}"


def generate_company_name() -> str:
    return f"{random.choice(COMPANY_PREFIXES)} {random.choice(COMPANY_SUFFIXES)}"


def generate_email(first_name: str, last_name: str, index: int) -> str:
    return f"{first_name.lower()}.{last_name.lower()}{index}@example.com"


def generate_inquiry(service_category: str, urgency_level: str) -> str:
    templates = [
        f"We are looking for help with {service_category.lower()} and would like to understand available options.",
        f"Our team needs support for {service_category.lower()} with a {urgency_level.lower()} priority timeline.",
        f"We want to improve our current process using {service_category.lower()} services.",
        f"Please provide more information about your {service_category.lower()} offering.",
        f"We are comparing vendors for {service_category.lower()} and would like a consultation."
    ]

    return random.choice(templates)


def generate_lead(index: int) -> dict:
    first_name = random.choice(FIRST_NAMES)
    last_name = random.choice(LAST_NAMES)
    service_category = random.choice(SERVICE_CATEGORIES)
    urgency_level = random.choice(URGENCY_LEVELS)
    source_channel = random.choice(SOURCE_CHANNELS)

    return {
        "first_name": first_name,
        "last_name": last_name,
        "company": generate_company_name(),
        "email": generate_email(first_name, last_name, index),
        "phone": generate_phone_number(),
        "service_category": service_category,
        "budget_range": random.choice(BUDGET_RANGES),
        "urgency_level": urgency_level,
        "source_channel": source_channel,
        "location": random.choice(LOCATIONS),
        "inquiry_details": generate_inquiry(service_category, urgency_level),
        "lead_status": random.choice(LEAD_STATUSES),
        "assigned_sales_rep_email": random.choice(SALES_REPS),
        "created_at": random_date_within_last_days()
    }


def generate_sample_leads(row_count: int) -> None:
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    fieldnames = [
        "first_name",
        "last_name",
        "company",
        "email",
        "phone",
        "service_category",
        "budget_range",
        "urgency_level",
        "source_channel",
        "location",
        "inquiry_details",
        "lead_status",
        "assigned_sales_rep_email",
        "created_at"
    ]

    with OUTPUT_PATH.open(mode="w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writeheader()

        for index in range(1, row_count + 1):
            writer.writerow(generate_lead(index))

    print(f"Generated {row_count} sample leads.")
    print(f"Output file: {OUTPUT_PATH}")


def main():
    parser = argparse.ArgumentParser(description="Generate sample CRM lead data.")
    parser.add_argument(
        "--rows",
        type=int,
        default=500,
        help="Number of sample lead records to generate."
    )

    args = parser.parse_args()
    generate_sample_leads(args.rows)


if __name__ == "__main__":
    main()