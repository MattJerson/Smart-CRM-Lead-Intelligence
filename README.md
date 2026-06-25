# Smart CRM Lead Intelligence & Revenue Automation Platform

A CRM-driven revenue operations platform that simulates lead intake, lead scoring, routing recommendations, follow-up task generation, business intelligence reporting, Salesforce CRM synchronization, and workflow automation.

This project uses PostgreSQL, SQL, Java, Python, Docker, Metabase, Salesforce, and a live self-hosted n8n instance to demonstrate how CRM data can be scored, routed, monitored, synced to Salesforce, and automated in a realistic revenue operations workflow.

---

## Project Overview

This project simulates a real-world CRM and revenue operations system used by sales, marketing, and operations teams.

The system generates sample CRM lead data, stores it in PostgreSQL, scores each lead using Java business logic, creates routing recommendations, generates follow-up tasks, prepares reporting views with SQL, visualizes insights in Metabase, syncs selected high-priority leads into Salesforce, creates Salesforce follow-up Tasks, and sends automated notifications through n8n.

The project is designed to demonstrate practical skills in:

- CRM data modeling
- Lead scoring
- Lead routing
- Follow-up task automation
- Salesforce Lead and Task synchronization
- SQL analytics
- PostgreSQL database design
- Java backend business rules
- Python data generation, loading, and integration scripting
- Metabase dashboarding
- n8n workflow automation
- Docker-based local development

---

## System Architecture

```txt
Sample CRM Lead Data
        ↓
Python Data Generator
        ↓
PostgreSQL Database
        ↓
Java Lead Scoring Engine
        ↓
Lead Scores Table
        ↓
Java Lead Routing Engine
        ↓
Routing Logs Table
        ↓
Java Follow-Up Task Generator
        ↓
Follow-Up Tasks Table
        ↓
SQL Reporting Views
        ↓
Metabase Dashboards

High-Priority Leads
        ↓
Python Salesforce Sync Script
        ↓
Live n8n Automation Workflow
        ↓
Salesforce Lead Upsert
        ↓
Salesforce Follow-Up Task
        ↓
PostgreSQL Salesforce Sync Log

CRM Summary + Alerts
        ↓
Python Webhook Senders
        ↓
Live n8n Automation Workflow
        ↓
Email Notifications
```

---

## Current Architecture

This project uses a hybrid local and cloud automation setup.

```txt
Local Docker Services
├── PostgreSQL
└── Metabase

Local Runtime
├── Python data generation/loading scripts
├── Java lead scoring engine
├── Java lead routing engine
├── Java follow-up task generator
├── Salesforce sync script
└── Pipeline validation script

Live Automation
└── n8n webhook workflow hosted externally

External CRM
└── Salesforce Lead and Task records
```

---

## Tech Stack

| Layer            | Technology | Purpose                                                                                              |
| ---------------- | ---------- | ---------------------------------------------------------------------------------------------------- |
| CRM              | Salesforce | Stores synced Lead records and follow-up Tasks                                                       |
| Database         | PostgreSQL | Stores leads, campaigns, sales reps, scores, routing logs, follow-up tasks, and Salesforce sync logs |
| Querying         | SQL        | Creates analytics queries and reusable reporting views                                               |
| Business Logic   | Java       | Scores leads, creates routing recommendations, and generates follow-up tasks                         |
| Data Scripting   | Python     | Generates sample data, loads PostgreSQL, sends webhook payloads, and syncs Salesforce records        |
| Dashboarding     | Metabase   | Visualizes CRM, lead quality, routing, follow-up, and Salesforce sync metrics                        |
| Automation       | n8n        | Receives webhook events, syncs with Salesforce, and sends email notifications                        |
| Containerization | Docker     | Runs PostgreSQL and Metabase locally                                                                 |

---

## Screenshots

### Pipeline Validation

<img width="816" height="203" alt="Screenshot 2026-06-26 at 12 13 43 AM" src="https://github.com/user-attachments/assets/3891bda5-1a85-422c-bd16-48a28edd4dbb" />

### Metabase Salesforce Sync Status

[Lead Quality Overview · Dashboard · Metabase.pdf](https://github.com/user-attachments/files/29348045/Lead.Quality.Overview.Dashboard.Metabase.pdf)

### n8n Workflow Overview

<img width="1638" height="697" alt="Screenshot 2026-06-26 at 12 06 28 AM" src="https://github.com/user-attachments/assets/c1a0aa33-1063-47c6-90cf-e9fcfc85d258" />

### Salesforce Lead Record

<img width="1920" height="963" alt="Screenshot 2026-06-26 at 12 09 06 AM" src="https://github.com/user-attachments/assets/8cfa9ca6-0bed-4c57-adbc-92ca6792c7d1" />

### Salesforce Follow-Up Task

<img width="1920" height="877" alt="Screenshot 2026-06-26 at 12 11 29 AM" src="https://github.com/user-attachments/assets/baf1a17d-d76b-4f74-8c67-17969852a2d9" />

---

## Core Features

### Lead Intake

The project generates realistic CRM lead records containing:

- Lead name
- Company
- Email
- Phone
- Service category
- Budget range
- Urgency level
- Source channel
- Lead status
- Assigned sales representative
- Inquiry details

The generated lead data is loaded into PostgreSQL for scoring, routing, reporting, dashboarding, and Salesforce synchronization.

---

### Java Lead Scoring Engine

The Java scoring engine calculates a weighted lead score using CRM and buyer-intent signals.

Scoring factors include:

- Budget range
- Urgency level
- Source channel
- Inquiry completeness
- Lead status

Leads are classified as:

- Hot
- Warm
- Cold

The calculated results are stored in the `lead_scores` table.

---

### Java Lead Routing Engine

The Java routing engine reads scored leads and creates routing recommendations.

Routing priorities include:

- Immediate
- Standard
- Nurture

Routing results are stored in the `routing_logs` table.

---

### Java Follow-Up Task Generator

The follow-up generator creates CRM-style follow-up tasks based on routing priority.

Examples:

- Hot / Immediate leads receive same-day call tasks.
- Warm / Standard leads receive sales follow-up tasks.
- Cold / Nurture leads receive lower-priority nurture email tasks.

Follow-up results are stored in the `follow_ups` table.

---

### Salesforce Integration

The project syncs selected high-priority leads into Salesforce through a live n8n workflow.

For each synced lead, the system:

1. Sends the lead payload from Python to n8n.
2. Uses an n8n HTTP Request node to upsert a Salesforce Lead.
3. Uses a Salesforce External ID field to prevent lead overwrite issues.
4. Finds the created or updated Salesforce Lead.
5. Checks whether a matching follow-up Task already exists.
6. Creates a Salesforce Task only when needed.
7. Returns the Salesforce Lead ID and Task ID.
8. Stores the Salesforce IDs back in PostgreSQL.

Salesforce objects used:

- Lead
- Task

Custom Salesforce Lead fields used:

- `Service_Category__c`
- `Budget_Range__c`
- `Urgency_Level__c`
- `Inquiry_Details__c`
- `Lead_Score__c`
- `Lead_Quality__c`
- `Routing_Priority__c`
- `External_Lead_ID__c`

Salesforce sync results are stored locally in:

```txt
salesforce_sync_logs
```

---

### SQL Reporting Views

The project uses reusable PostgreSQL views to prepare clean reporting tables for Metabase.

Example views include:

- `vw_lead_scoring_base`
- `vw_lead_quality_summary`
- `vw_source_channel_performance`
- `vw_service_category_performance`
- `vw_funnel_summary`
- `vw_monthly_lead_trends`
- `vw_sales_rep_performance`
- `vw_routing_priority_summary`
- `vw_routing_workload_by_sales_rep`
- `vw_pending_immediate_leads`
- `vw_follow_up_summary`
- `vw_pending_follow_up_queue`
- `vw_salesforce_sync_status`
- `vw_salesforce_sync_summary`
- `vw_salesforce_successful_syncs`
- `vw_salesforce_failed_syncs`

---

### Metabase Dashboards

Metabase is used as the business intelligence dashboarding layer.

Dashboard areas include:

- Lead Quality Overview
- Source Channel Performance
- Service Category Performance
- Monthly Lead Trends
- High-Priority Leads
- Routing Priority Summary
- Follow-Up Task Summary
- Sales Rep Workload
- Salesforce Sync Status

---

### n8n Automation

The project uses a live self-hosted n8n instance as the automation layer.

Local Python scripts send structured webhook payloads to n8n.

Current event types:

- `crm_lead_operations_summary`
- `high_priority_lead_alert`
- `salesforce_lead_sync`

The n8n workflow handles:

- CRM operations summary email
- High-priority lead alert email
- Salesforce Lead synchronization
- Salesforce Task creation
- Duplicate Task prevention
- Salesforce sync response back to Python

The n8n workflow structure:

```txt
Webhook Trigger
        ↓
Switch Node
        ├── CRM Summary Email Branch
        ├── High-Priority Alert Email Branch
        └── Salesforce Lead Sync Branch
                ↓
            Upsert Salesforce Lead
                ↓
            Find Salesforce Lead
                ↓
            Find Existing Salesforce Task
                ↓
            IF Task Exists?
                ├── Create Task
                └── Return Existing Task
```

---

## Repository Structure

```txt
smart-crm-lead-intelligence/
├── README.md
├── docker-compose.yml
├── requirements.txt
├── .env.example
├── database/
│   ├── schema.sql
│   ├── seed.sql
│   ├── queries.sql
│   ├── views.sql
│   ├── use_java_scores.sql
│   ├── routing_views.sql
│   ├── follow_up_views.sql
│   ├── salesforce_sync.sql
│   └── salesforce_reporting_views.sql
├── data/
│   ├── raw/
│   │   └── .gitkeep
│   └── processed/
│       └── .gitkeep
├── scripts/
│   ├── run_pipeline.sh
│   └── python/
│       ├── generate_sample_leads.py
│       ├── load_to_postgres.py
│       ├── send_n8n_summary.py
│       ├── send_high_priority_alert.py
│       ├── send_salesforce_leads.py
│       └── validate_pipeline.py
├── sql/
│   ├── lead_quality_metrics.sql
│   ├── funnel_metrics.sql
│   └── sales_rep_performance.sql
├── java-lead-scoring/
│   ├── pom.xml
│   └── src/main/java/com/crm/intelligence/
│       ├── LeadScoringApp.java
│       ├── LeadRoutingApp.java
│       └── FollowUpTaskApp.java
├── metabase/
├── n8n/
│   ├── docs/
│   │   └── workflow-overview.md
│   └── workflows/
└── salesforce/
    ├── objects.md
    ├── fields.md
    └── automation-notes.md
```

---

## Environment Variables

Create a `.env` file based on `.env.example`.

```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=smart_crm
POSTGRES_USER=crm_user
POSTGRES_PASSWORD=crm_password

N8N_WEBHOOK_URL=https://your-n8n-domain.com/webhook/your-webhook-path
```

The `.env` file is ignored by Git and should not be committed.

---

## How to Run the Project

### 1. Start Docker services

```bash
docker compose up -d
```

This starts:

- PostgreSQL
- Metabase

The project uses a live external n8n instance, so n8n is not run locally through Docker.

---

### 2. Run the full pipeline

```bash
./scripts/run_pipeline.sh
```

The pipeline will:

1. Start Docker services.
2. Seed sales reps and campaigns.
3. Generate sample CRM lead data.
4. Load leads into PostgreSQL.
5. Run the Java lead scoring engine.
6. Run the Java lead routing engine.
7. Generate follow-up tasks.
8. Refresh base reporting views.
9. Switch reporting views to Java-generated scores.
10. Refresh routing reporting views.
11. Refresh follow-up reporting views.
12. Ensure the Salesforce sync table exists.
13. Refresh Salesforce sync reporting views.
14. Sync high-priority leads to Salesforce through n8n.
15. Send CRM operations summary to n8n.
16. Send high-priority lead alert to n8n.
17. Validate the full pipeline output.

---

### 3. Validate pipeline output

```bash
python3 scripts/python/validate_pipeline.py
```

Expected validation output:

```txt
Smart CRM Pipeline Validation
-----------------------------
PASS: Leads loaded (500)
PASS: Lead scores created (500)
PASS: Routing logs created (500)
PASS: Follow-up tasks created (500)
PASS: Salesforce successful syncs (5)
PASS: Salesforce failed syncs (0)
PASS: Salesforce Lead IDs stored (5)
PASS: Salesforce Task IDs stored (5)

Pipeline validation passed.
```

---

### 4. Verify database counts

```bash
docker compose exec postgres psql -U crm_user -d smart_crm -c "
SELECT 'leads' AS table_name, COUNT(*) FROM leads
UNION ALL
SELECT 'lead_scores', COUNT(*) FROM lead_scores
UNION ALL
SELECT 'routing_logs', COUNT(*) FROM routing_logs
UNION ALL
SELECT 'follow_ups', COUNT(*) FROM follow_ups
UNION ALL
SELECT 'salesforce_successful_syncs', COUNT(*) FROM salesforce_sync_logs WHERE sync_status = 'Success'
UNION ALL
SELECT 'salesforce_failed_syncs', COUNT(*) FROM salesforce_sync_logs WHERE sync_status = 'Failed';
"
```

Expected result:

```txt
leads                       | 500
lead_scores                 | 500
routing_logs                | 500
follow_ups                  | 500
salesforce_successful_syncs | 5
salesforce_failed_syncs     | 0
```

---

## Salesforce Sync Script

Preview the next high-priority leads without sending them to n8n:

```bash
python3 scripts/python/send_salesforce_leads.py --dry-run
```

Sync a limited batch of high-priority leads:

```bash
python3 scripts/python/send_salesforce_leads.py --limit 5
```

---

## Metabase Setup

Open Metabase:

```txt
http://localhost:3000
```

Connect to PostgreSQL using:

```txt
Host: postgres
Port: 5432
Database: smart_crm
Username: crm_user
Password: crm_password
```

Use the reporting views as dashboard data sources.

---

## Example Business Questions Answered

This project can answer questions such as:

- Which lead sources generate the highest-quality leads?
- Which leads should sales prioritize first?
- Which service categories receive the most demand?
- Which sales reps have the most assigned leads?
- Which leads require immediate follow-up?
- How many follow-up tasks are pending, overdue, or due today?
- Which channels generate the most converted leads?
- What is the distribution of hot, warm, and cold leads?
- Which routed leads require urgent attention?
- How many leads were synced to Salesforce?
- Which Salesforce Lead and Task IDs were created?
- Which Salesforce syncs failed or remain pending?

---

## Current Project Status

Completed:

- PostgreSQL schema
- Seed data
- Python sample lead generator
- Python PostgreSQL loader
- SQL analytics queries
- Java lead scoring engine
- Java lead routing engine
- Java follow-up task generator
- Reporting views
- Metabase dashboard foundation
- Salesforce sync reporting views
- Live n8n webhook integration
- n8n email notification workflow
- Salesforce Lead sync through n8n
- Salesforce Task creation through n8n
- Salesforce duplicate Task prevention
- Salesforce sync logging back to PostgreSQL
- Pipeline validation script
- One-command pipeline script
- Docker cleanup with local PostgreSQL and Metabase only

Optional future improvements:

- Export sanitized n8n workflow JSON
- Add dashboard screenshots
- Improve Metabase dashboard layout
- Add dbt models after SQL logic is stable
- Add more Salesforce reporting cards
- Add retry logic for failed Salesforce syncs

---

## Author

Matt Jerson Figueroa
