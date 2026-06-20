# n8n Workflow Overview

This project uses a live self-hosted n8n instance as the automation layer for CRM and revenue operations notifications.

The local CRM system generates lead data, scores leads, creates routing recommendations, generates follow-up tasks, and sends structured webhook payloads to n8n.

n8n receives those webhook events, routes them based on event type, formats the message, and sends email notifications.

---

## Live n8n Instance

The project uses an existing self-hosted n8n instance hosted on a VPS.

n8n is used for:

* CRM operations summary notifications
* High-priority lead alerts
* Follow-up reminders
* Lead routing notifications
* Workflow automation simulation

---

## Current Workflow

```txt
Webhook Trigger
        ↓
Switch Node
        ↓
Event-based routing
        ↓
Format Operations Summary / Format High Priority Alert
        ↓
Send Email
```

---

## Event Types

The workflow currently handles two event types.

### 1. CRM Lead Operations Summary

Event name:

```txt
crm_lead_operations_summary
```

Sent by:

```txt
scripts/python/send_n8n_summary.py
```

Purpose:

* Sends a full CRM operations summary
* Shows total leads
* Shows hot, warm, and cold lead distribution
* Shows follow-up task status
* Shows routing priority summary
* Shows source channel performance

---

### 2. High-Priority Lead Alert

Event name:

```txt
high_priority_lead_alert
```

Sent by:

```txt
scripts/python/send_high_priority_alert.py
```

Purpose:

* Sends urgent alert for immediate-priority leads
* Shows the number of high-priority leads
* Includes top pending immediate leads
* Supports simulated sales team escalation

---

## Switch Node Logic

The n8n Switch node checks the incoming event type.

Expression checked:

```txt
{{ $json.body.event }}
```

Routing rules:

```txt
{{ $json.body.event }} is equal to crm_lead_operations_summary
{{ $json.body.event }} is equal to high_priority_lead_alert
```

The first branch formats the operations summary.

The second branch formats the high-priority lead alert.

---

## Format Operations Summary Node

This branch creates an email-friendly summary message containing:

* Total leads
* Hot leads
* Warm leads
* Cold leads
* Average lead score
* Pending follow-ups
* Overdue follow-ups
* Due today tasks
* Generated timestamp

Output fields:

```txt
subject
message
```

Example subject:

```txt
CRM Lead Operations Summary
```

---

## Format High Priority Alert Node

This branch creates an email-friendly urgent lead alert containing:

* Total immediate leads
* Alert message
* Generated timestamp

Output fields:

```txt
subject
message
```

Example subject:

```txt
High-Priority Lead Alert
```

---

## Send Email Node

Both formatted branches connect to one Send Email node.

The email node uses:

```txt
Subject: {{$json.subject}}
Text: {{$json.message}}
```

This allows both event types to reuse the same email-sending step.

---

## Local Scripts Connected to n8n

The local project sends webhook payloads using these scripts:

```txt
scripts/python/send_n8n_summary.py
scripts/python/send_high_priority_alert.py
```

These scripts read from PostgreSQL reporting views and send JSON payloads to the live n8n webhook.

---

## Pipeline Integration

The full pipeline sends both n8n events after rebuilding the CRM data and refreshing reporting views.

Relevant pipeline steps:

```txt
12. Send CRM operations summary to live n8n webhook
13. Send high-priority lead alert to live n8n webhook
```

This makes the automation flow repeatable from one command:

```bash
./scripts/run_pipeline.sh
```

---

## Current Automation Flow

```txt
Python-generated leads
        ↓
PostgreSQL
        ↓
Java lead scoring
        ↓
Java lead routing
        ↓
Java follow-up generation
        ↓
SQL reporting views
        ↓
Python webhook sender
        ↓
n8n webhook
        ↓
Switch node
        ↓
Formatted message
        ↓
Email notification
```

---

## Future Improvements

Potential future improvements:

* Add separate workflow for overdue follow-up reminders
* Add email formatting with HTML
* Add Slack or Discord notification support
* Add webhook authentication
* Export n8n workflow JSON into the repository
* Add screenshots of workflow executions
