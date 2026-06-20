
```md
# Salesforce Field Mapping

This document maps the local CRM project fields to the Salesforce objects they would correspond to in a production CRM setup.

---

## Lead Fields

| Local Field | Salesforce Field | Type | Notes |
|---|---|---|---|
| first_name | FirstName | Standard | Lead first name |
| last_name | LastName | Standard | Lead last name |
| company | Company | Standard | Required on Salesforce Lead |
| email | Email | Standard | Buyer email |
| phone | Phone | Standard | Buyer phone number |
| service_category | Service_Category__c | Custom Picklist | Service requested |
| budget_range | Budget_Range__c | Custom Picklist | Estimated budget |
| urgency_level | Urgency_Level__c | Custom Picklist | Lead urgency |
| source_channel | LeadSource | Standard / Picklist | Acquisition source |
| location | Location__c | Custom Text | Buyer location |
| inquiry_details | Inquiry_Details__c | Custom Long Text | Buyer message |
| lead_status | Status | Standard Picklist | Lead stage |
| assigned_sales_rep_id | OwnerId | Standard Lookup | Assigned Salesforce user |

---

## Lead_Score__c Fields

| Field | Type | Notes |
|---|---|---|
| Lead__c | Lookup(Lead) | Related lead |
| Budget_Score__c | Number | Score from budget range |
| Urgency_Score__c | Number | Score from urgency level |
| Source_Score__c | Number | Score from source channel |
| Completeness_Score__c | Number | Score from inquiry quality |
| Engagement_Score__c | Number | Score from lead status |
| Total_Score__c | Number | Final Java-generated score |
| Lead_Quality__c | Picklist | Hot, Warm, Cold |
| Conversion_Likelihood__c | Percent | Estimated conversion likelihood |
| Scoring_Notes__c | Long Text | Scoring explanation |

---

## Routing_Log__c Fields

| Field | Type | Notes |
|---|---|---|
| Lead__c | Lookup(Lead) | Related lead |
| Assigned_Sales_Rep__c | Lookup(User) | Assigned rep |
| Routing_Priority__c | Picklist | Immediate, Standard, Nurture |
| Routing_Reason__c | Long Text | Explanation from routing engine |
| Response_Status__c | Picklist | Pending, Accepted, Rejected, Completed |
| Routed_At__c | Date/Time | Routing timestamp |
| Responded_At__c | Date/Time | Sales rep response timestamp |

---

## Follow_Up__c Fields

| Field | Type | Notes |
|---|---|---|
| Lead__c | Lookup(Lead) | Related lead |
| Sales_Rep__c | Lookup(User) | Owner of follow-up |
| Follow_Up_Type__c | Picklist | Same-Day Call, Sales Follow-Up, Nurture Email |
| Due_Date__c | Date | Task due date |
| Completed_At__c | Date/Time | Completion timestamp |
| Status__c | Picklist | Pending, Completed, Overdue |
| Notes__c | Long Text | Follow-up details |

---

## Campaign Fields

| Local Field | Salesforce Field | Type | Notes |
|---|---|---|---|
| campaign_name | Name | Standard | Campaign name |
| source_channel | Source_Channel__c | Custom Picklist | Lead source |
| campaign_budget | BudgetedCost | Standard | Campaign budget |
| start_date | StartDate | Standard | Campaign start |
| end_date | EndDate | Standard | Campaign end |