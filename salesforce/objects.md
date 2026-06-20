# Salesforce Object Model

This project uses Salesforce as the CRM layer for managing lead intake, qualification, opportunity tracking, routing, and follow-up activity.

The local PostgreSQL database simulates CRM data storage and analytics, while Salesforce represents the operational CRM system that sales and revenue teams would use in production.

---

## Standard Objects

### Lead

Stores incoming buyer or customer inquiries before they are qualified.

Example use cases:

- Capture new inquiries
- Track lead status
- Store source channel
- Store budget and urgency
- Assign leads to sales representatives

Related local PostgreSQL table:

- `leads`

---

### Account

Represents a company or organization after a lead is qualified.

Example use cases:

- Store company information
- Track customer relationship
- Link related contacts and opportunities

---

### Contact

Represents an individual person associated with an account.

Example use cases:

- Store buyer contact information
- Track communication history
- Associate decision-makers with accounts

---

### Opportunity

Represents a potential revenue deal created from a qualified lead.

Example use cases:

- Track deal stage
- Estimate pipeline value
- Monitor probability of closing
- Analyze revenue performance

Related local PostgreSQL table:

- `opportunities`

---

### Task

Represents follow-up activities for sales representatives.

Example use cases:

- Same-day call
- Sales follow-up
- Nurture email
- Reminder task

Related local PostgreSQL table:

- `follow_ups`

---

### Campaign

Represents marketing campaigns and acquisition sources.

Example use cases:

- Track lead source performance
- Compare campaign quality
- Analyze conversion rate by source

Related local PostgreSQL table:

- `campaigns`

---

## Custom Objects

### Lead_Score__c

Stores calculated lead scoring results.

Purpose:

- Store total score
- Store hot, warm, or cold classification
- Store score breakdown
- Store conversion likelihood

Related local PostgreSQL table:

- `lead_scores`

---

### Routing_Log__c

Tracks lead routing decisions and assignment history.

Purpose:

- Store routing priority
- Store routing reason
- Track assigned sales representative
- Track response status

Related local PostgreSQL table:

- `routing_logs`

---

### Follow_Up__c

Tracks CRM follow-up recommendations and task activity.

Purpose:

- Store follow-up type
- Store due date
- Track pending/completed status
- Track overdue follow-ups

Related local PostgreSQL table:

- `follow_ups`

---

## Object Flow

```txt
Lead
 ↓
Lead_Score__c
 ↓
Routing_Log__c
 ↓
Task / Follow_Up__c
 ↓
Opportunity
 ↓
Account + Contact