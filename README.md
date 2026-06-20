# Smart CRM Lead Intelligence & Revenue Automation Platform

A CRM-driven revenue operations platform that simulates lead intake, lead scoring, routing recommendations, follow-up task generation, business intelligence reporting, and workflow automation.

This project uses PostgreSQL, SQL, Java, Python, Docker, Metabase, and a live self-hosted n8n instance to demonstrate how CRM data can be scored, routed, monitored, and automated in a realistic revenue operations workflow.

---

## Project Overview

This project simulates a real-world CRM and revenue operations system used by sales, marketing, and operations teams.

The system generates sample CRM lead data, stores it in PostgreSQL, scores each lead using Java business logic, creates routing recommendations, generates follow-up tasks, prepares reporting views with SQL, visualizes insights in Metabase, and sends automated notifications through n8n.

The project is designed to demonstrate practical skills in:

- CRM data modeling
- Lead scoring
- Lead routing
- Follow-up task automation
- SQL analytics
- PostgreSQL database design
- Java backend business rules
- Python data generation and loading
- Metabase dashboarding
- n8n workflow automation
- Salesforce CRM mapping
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
        ↓
Python Webhook Sender
        ↓
Live n8n Automation Workflow
        ↓
Email Notifications
```

---

## Tech Stack

| Layer            | Technology | Purpose                                                                        |
| ---------------- | ---------- | ------------------------------------------------------------------------------ |
| CRM Mapping      | Salesforce | Documents the CRM object model and field mappings                              |
| Database         | PostgreSQL | Stores leads, campaigns, sales reps, scores, routing logs, and follow-up tasks |
| Querying         | SQL        | Creates analytics queries and reusable reporting views                         |
| Business Logic   | Java       | Scores leads, creates routing recommendations, and generates follow-up tasks   |
| Data Scripting   | Python     | Generates sample data, loads PostgreSQL, and sends webhook payloads            |
| Dashboarding     | Metabase   | Visualizes CRM, lead quality, routing, and follow-up metrics                   |
| Automation       | n8n        | Receives webhook events and sends email notifications                          |
| Containerization | Docker     | Runs PostgreSQL and Metabase locally                                           |

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

The generated lead data is loaded into PostgreSQL for scoring, routing, reporting, and dashboarding.

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

---

### n8n Automation

The project uses a live self-hosted n8n instance as the automation layer.

Local Python scripts send structured webhook payloads to n8n.

Current event types:

- `crm_lead_operations_summary`
- `high_priority_lead_alert`

The n8n workflow:

```txt
Webhook Trigger
        ↓
Switch Node
        ↓
Format Message
        ↓
Send Email
```

This simulates CRM operations notifications and urgent lead alerts.

---

### Salesforce CRM Mapping

The project includes Salesforce documentation for how the local system would map to a real CRM implementation.

Documented Salesforce areas include:

- Standard objects
- Custom objects
- Field mappings
- Lead scoring records
- Routing logs
- Follow-up automation
- Production automation flow

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
│   └── follow_up_views.sql
├── data/
│   ├── raw/
│   └── processed/
├── scripts/
│   ├── run_pipeline.sh
│   └── python/
│       ├── generate_sample_leads.py
│       ├── load_to_postgres.py
│       ├── send_n8n_summary.py
│       └── send_high_priority_alert.py
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

---

### 2. Run the full pipeline

```bash
./scripts/run_pipeline.sh
```

The pipeline will:

1. Start Docker services
2. Seed sales reps and campaigns
3. Generate sample CRM lead data
4. Load leads into PostgreSQL
5. Run the Java lead scoring engine
6. Run the Java lead routing engine
7. Generate follow-up tasks
8. Refresh reporting views
9. Send CRM operations summary to n8n
10. Send high-priority lead alert to n8n

---

### 3. Verify pipeline output

```bash
docker compose exec postgres psql -U crm_user -d smart_crm -c "
SELECT 'leads' AS table_name, COUNT(*) FROM leads
UNION ALL
SELECT 'lead_scores', COUNT(*) FROM lead_scores
UNION ALL
SELECT 'routing_logs', COUNT(*) FROM routing_logs
UNION ALL
SELECT 'follow_ups', COUNT(*) FROM follow_ups;
"
```

Expected result:

```txt
leads         | 500
lead_scores   | 500
routing_logs  | 500
follow_ups    | 500
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
- Live n8n webhook integration
- n8n email notification workflow
- Salesforce object and field documentation
- One-command pipeline script

Planned next steps:

- Export n8n workflow JSON
- Add dashboard screenshots
- Improve Metabase dashboard layout
- Add dbt models after SQL logic is stable
- Prepare final GitHub presentation
- Create final resume bullets

---

## Author

Matt Jerson Figueroa
