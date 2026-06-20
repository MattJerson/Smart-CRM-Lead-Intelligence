# Smart CRM Lead Intelligence & Revenue Automation Platform

A CRM-driven revenue operations platform that simulates lead intake, lead scoring, routing recommendations, follow-up task generation, and business intelligence reporting using PostgreSQL, SQL, Java, Python, Docker, and Metabase.

This project demonstrates how sales, marketing, and operations teams can use CRM data, automation logic, backend business rules, and dashboards to improve lead prioritization, follow-up execution, and revenue visibility.

---

## Project Overview

This platform simulates a real-world CRM and revenue operations workflow.

The system generates sample CRM lead data, stores it in PostgreSQL, scores each lead using a Java-based scoring engine, creates routing recommendations, generates follow-up tasks, and exposes reporting views for dashboarding in Metabase.

The goal of this project is to demonstrate practical skills in:

* CRM data modeling
* SQL analytics
* PostgreSQL database design
* Java business logic
* Python data generation and loading
* Lead scoring
* Lead routing
* Follow-up task tracking
* BI dashboard reporting
* Docker-based local development

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
```

---

## Tech Stack

| Layer            | Technology | Purpose                                                                        |
| ---------------- | ---------- | ------------------------------------------------------------------------------ |
| Database         | PostgreSQL | Stores leads, campaigns, sales reps, scores, routing logs, and follow-up tasks |
| Data Scripting   | Python     | Generates sample CRM lead data and loads CSV data into PostgreSQL              |
| Business Logic   | Java       | Calculates lead scores, routing priority, and follow-up recommendations        |
| Querying         | SQL        | Creates analytics queries and reporting views                                  |
| Dashboarding     | Metabase   | Visualizes lead quality, routing performance, and follow-up operations         |
| Containerization | Docker     | Runs PostgreSQL and Metabase locally                                           |

---

## Core Features

### Lead Intake

The project generates realistic CRM lead data with fields such as:

* Name
* Company
* Email
* Phone
* Service category
* Budget range
* Urgency level
* Source channel
* Lead status
* Assigned sales representative
* Inquiry details

---

### Java Lead Scoring Engine

The Java scoring engine calculates lead quality using weighted business rules.

Scoring factors include:

* Budget range
* Urgency level
* Source channel
* Inquiry completeness
* Lead status / engagement

Leads are classified as:

* Hot
* Warm
* Cold

The score results are written into the `lead_scores` table.

---

### Java Lead Routing Engine

The Java routing engine reads scored leads and creates routing recommendations.

Routing priorities include:

* Immediate
* Standard
* Nurture

Routing results are written into the `routing_logs` table.

---

### Follow-Up Task Generator

The follow-up task generator creates CRM-style tasks based on routing priority.

Examples:

* Immediate leads receive same-day call tasks.
* Standard leads receive sales follow-up tasks.
* Nurture leads receive lower-priority email follow-up tasks.

Follow-up results are written into the `follow_ups` table.

---

### SQL Reporting Views

The project includes reusable PostgreSQL views for reporting and dashboarding.

Examples:

* `vw_lead_scoring_base`
* `vw_lead_quality_summary`
* `vw_source_channel_performance`
* `vw_service_category_performance`
* `vw_funnel_summary`
* `vw_monthly_lead_trends`
* `vw_sales_rep_performance`
* `vw_routing_priority_summary`
* `vw_routing_workload_by_sales_rep`
* `vw_pending_immediate_leads`
* `vw_follow_up_summary`
* `vw_pending_follow_up_queue`

---

### Metabase Dashboards

Metabase is used as the local BI dashboarding layer.

Example dashboard sections:

* Lead Quality Overview
* Source Channel Performance
* Service Category Performance
* Monthly Lead Trends
* High-Priority Leads
* Routing Priority Summary
* Follow-Up Task Summary
* Sales Rep Workload

---

## Repository Structure

```txt
smart-crm-lead-intelligence/
├── README.md
├── docker-compose.yml
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
│       └── load_to_postgres.py
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
└── metabase/
```

---

## How to Run the Project

### 1. Start Docker services

```bash
docker compose up -d
```

This starts:

* PostgreSQL
* Metabase

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

---

### 3. Verify the pipeline output

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

### 4. Open Metabase

Visit:

```txt
http://localhost:3000
```

Connect Metabase to PostgreSQL using:

```txt
Host: postgres
Port: 5432
Database: smart_crm
Username: crm_user
Password: crm_password
```

---

## Example Business Questions Answered

This project can answer questions such as:

* Which lead sources generate the highest-quality leads?
* Which leads should be prioritized first?
* Which service categories receive the most demand?
* Which sales reps have the most assigned leads?
* Which leads require immediate follow-up?
* How many follow-up tasks are pending or overdue?
* Which channels generate the most converted leads?
* What is the distribution of hot, warm, and cold leads?

---

## Current Project Status

Completed:

* PostgreSQL schema
* Seed data
* Python sample lead generator
* Python PostgreSQL loader
* SQL analytics queries
* Java lead scoring engine
* Java lead routing engine
* Java follow-up task generator
* Reporting views
* Metabase dashboard foundation
* One-command pipeline script

Planned next steps:

* Add screenshots of Metabase dashboards
* Add Salesforce object documentation
* Add n8n workflow documentation
* Add dbt models after SQL logic is stable
* Improve dashboard design and project presentation

---

## Author

Matt Jerson Figueroa
