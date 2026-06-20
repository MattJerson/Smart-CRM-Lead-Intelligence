# Salesforce Automation Notes

This document explains how the local CRM automation flow would map to Salesforce and n8n in a production setup.

---

## Current Local Flow

```txt
Python generates sample leads
        ↓
PostgreSQL stores CRM data
        ↓
Java scores leads
        ↓
Java creates routing recommendations
        ↓
Java creates follow-up tasks
        ↓
SQL views prepare reporting data
        ↓
Metabase dashboards visualize results
        ↓
n8n sends email notifications