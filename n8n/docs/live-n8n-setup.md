# Live n8n Automation Setup

This project uses an existing self-hosted n8n instance as the automation layer.

n8n URL:

https://n8n.icentras.com/home/workflows

## Purpose

n8n is used to simulate CRM and revenue operations automation workflows such as:

- Lead operations summary notifications
- High-priority lead alerts
- Follow-up reminders
- Routing workflow documentation
- CRM automation simulation

## Integration Strategy

The local development environment runs PostgreSQL, Java, Python, and Metabase.

The live n8n instance runs externally on a VPS.

Because the VPS n8n instance cannot directly access the local Docker PostgreSQL database on the MacBook, integration is handled through n8n webhooks.

The local project generates CRM summaries from PostgreSQL and sends them to an n8n webhook endpoint.

## Planned Workflows

### 1. Daily Lead Operations Summary

Local script sends:

- Total leads
- Hot leads
- Warm leads
- Cold leads
- Pending follow-ups
- Overdue follow-ups
- Immediate routing tasks

n8n receives the payload and sends a formatted notification.

### 2. High-Priority Lead Alert

Local script sends hot/immediate leads to n8n.

n8n can send an email, Slack message, Discord message, or internal notification.

### 3. Follow-Up Reminder Workflow

Local script sends pending and overdue follow-up tasks.

n8n sends reminder notifications to the simulated sales operations team.