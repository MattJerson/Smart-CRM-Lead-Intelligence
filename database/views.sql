-- ============================================================
-- Reporting Views
-- Purpose:
-- Create reusable PostgreSQL views for Power BI reporting.
-- These views turn raw CRM lead data into clean analytics tables.
-- ============================================================


-- ============================================================
-- 1. Lead scoring base view
-- Temporary SQL scoring model until the Java scoring engine
-- becomes the official scoring source.
-- ============================================================

CREATE OR REPLACE VIEW vw_lead_scoring_base AS
SELECT
    l.lead_id,
    l.first_name,
    l.last_name,
    l.company,
    l.email,
    l.phone,
    l.service_category,
    l.budget_range,
    l.urgency_level,
    l.source_channel,
    l.location,
    l.inquiry_details,
    l.lead_status,
    l.created_at,
    l.updated_at,
    sr.full_name AS assigned_sales_rep,
    sr.region AS sales_rep_region,
    sr.specialization AS sales_rep_specialization,
    c.campaign_name,

    CASE l.budget_range
        WHEN '500k+' THEN 25
        WHEN '250k-500k' THEN 20
        WHEN '100k-250k' THEN 15
        WHEN '50k-100k' THEN 10
        WHEN 'Below 50k' THEN 5
        ELSE 0
    END AS budget_score,

    CASE l.urgency_level
        WHEN 'Critical' THEN 25
        WHEN 'High' THEN 20
        WHEN 'Medium' THEN 10
        WHEN 'Low' THEN 5
        ELSE 0
    END AS urgency_score,

    CASE l.source_channel
        WHEN 'Referral' THEN 20
        WHEN 'Google Search' THEN 18
        WHEN 'LinkedIn' THEN 15
        WHEN 'Website' THEN 12
        WHEN 'Email' THEN 10
        WHEN 'Facebook' THEN 8
        ELSE 0
    END AS source_score,

    CASE
        WHEN l.inquiry_details IS NOT NULL AND LENGTH(l.inquiry_details) >= 80 THEN 15
        WHEN l.inquiry_details IS NOT NULL AND LENGTH(l.inquiry_details) >= 40 THEN 10
        ELSE 5
    END AS completeness_score,

    CASE l.lead_status
        WHEN 'Converted' THEN 15
        WHEN 'Qualified' THEN 12
        WHEN 'Contacted' THEN 8
        WHEN 'New' THEN 5
        WHEN 'Unqualified' THEN 2
        WHEN 'Lost' THEN 0
        ELSE 0
    END AS status_score,

    (
        CASE l.budget_range
            WHEN '500k+' THEN 25
            WHEN '250k-500k' THEN 20
            WHEN '100k-250k' THEN 15
            WHEN '50k-100k' THEN 10
            WHEN 'Below 50k' THEN 5
            ELSE 0
        END
        +
        CASE l.urgency_level
            WHEN 'Critical' THEN 25
            WHEN 'High' THEN 20
            WHEN 'Medium' THEN 10
            WHEN 'Low' THEN 5
            ELSE 0
        END
        +
        CASE l.source_channel
            WHEN 'Referral' THEN 20
            WHEN 'Google Search' THEN 18
            WHEN 'LinkedIn' THEN 15
            WHEN 'Website' THEN 12
            WHEN 'Email' THEN 10
            WHEN 'Facebook' THEN 8
            ELSE 0
        END
        +
        CASE
            WHEN l.inquiry_details IS NOT NULL AND LENGTH(l.inquiry_details) >= 80 THEN 15
            WHEN l.inquiry_details IS NOT NULL AND LENGTH(l.inquiry_details) >= 40 THEN 10
            ELSE 5
        END
        +
        CASE l.lead_status
            WHEN 'Converted' THEN 15
            WHEN 'Qualified' THEN 12
            WHEN 'Contacted' THEN 8
            WHEN 'New' THEN 5
            WHEN 'Unqualified' THEN 2
            WHEN 'Lost' THEN 0
            ELSE 0
        END
    ) AS estimated_lead_score,

    CASE
        WHEN (
            CASE l.budget_range
                WHEN '500k+' THEN 25
                WHEN '250k-500k' THEN 20
                WHEN '100k-250k' THEN 15
                WHEN '50k-100k' THEN 10
                WHEN 'Below 50k' THEN 5
                ELSE 0
            END
            +
            CASE l.urgency_level
                WHEN 'Critical' THEN 25
                WHEN 'High' THEN 20
                WHEN 'Medium' THEN 10
                WHEN 'Low' THEN 5
                ELSE 0
            END
            +
            CASE l.source_channel
                WHEN 'Referral' THEN 20
                WHEN 'Google Search' THEN 18
                WHEN 'LinkedIn' THEN 15
                WHEN 'Website' THEN 12
                WHEN 'Email' THEN 10
                WHEN 'Facebook' THEN 8
                ELSE 0
            END
            +
            CASE
                WHEN l.inquiry_details IS NOT NULL AND LENGTH(l.inquiry_details) >= 80 THEN 15
                WHEN l.inquiry_details IS NOT NULL AND LENGTH(l.inquiry_details) >= 40 THEN 10
                ELSE 5
            END
            +
            CASE l.lead_status
                WHEN 'Converted' THEN 15
                WHEN 'Qualified' THEN 12
                WHEN 'Contacted' THEN 8
                WHEN 'New' THEN 5
                WHEN 'Unqualified' THEN 2
                WHEN 'Lost' THEN 0
                ELSE 0
            END
        ) >= 70 THEN 'Hot'
        WHEN (
            CASE l.budget_range
                WHEN '500k+' THEN 25
                WHEN '250k-500k' THEN 20
                WHEN '100k-250k' THEN 15
                WHEN '50k-100k' THEN 10
                WHEN 'Below 50k' THEN 5
                ELSE 0
            END
            +
            CASE l.urgency_level
                WHEN 'Critical' THEN 25
                WHEN 'High' THEN 20
                WHEN 'Medium' THEN 10
                WHEN 'Low' THEN 5
                ELSE 0
            END
            +
            CASE l.source_channel
                WHEN 'Referral' THEN 20
                WHEN 'Google Search' THEN 18
                WHEN 'LinkedIn' THEN 15
                WHEN 'Website' THEN 12
                WHEN 'Email' THEN 10
                WHEN 'Facebook' THEN 8
                ELSE 0
            END
            +
            CASE
                WHEN l.inquiry_details IS NOT NULL AND LENGTH(l.inquiry_details) >= 80 THEN 15
                WHEN l.inquiry_details IS NOT NULL AND LENGTH(l.inquiry_details) >= 40 THEN 10
                ELSE 5
            END
            +
            CASE l.lead_status
                WHEN 'Converted' THEN 15
                WHEN 'Qualified' THEN 12
                WHEN 'Contacted' THEN 8
                WHEN 'New' THEN 5
                WHEN 'Unqualified' THEN 2
                WHEN 'Lost' THEN 0
                ELSE 0
            END
        ) >= 40 THEN 'Warm'
        ELSE 'Cold'
    END AS estimated_lead_quality

FROM leads l
LEFT JOIN sales_reps sr
    ON l.assigned_sales_rep_id = sr.sales_rep_id
LEFT JOIN campaigns c
    ON l.campaign_id = c.campaign_id;


-- ============================================================
-- 2. Lead quality summary
-- ============================================================

CREATE OR REPLACE VIEW vw_lead_quality_summary AS
SELECT
    estimated_lead_quality,
    COUNT(*) AS total_leads,
    ROUND(AVG(estimated_lead_score), 2) AS average_lead_score,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_total
FROM vw_lead_scoring_base
GROUP BY estimated_lead_quality;


-- ============================================================
-- 3. Source channel performance
-- ============================================================

CREATE OR REPLACE VIEW vw_source_channel_performance AS
SELECT
    source_channel,
    COUNT(*) AS total_leads,
    COUNT(*) FILTER (WHERE estimated_lead_quality = 'Hot') AS hot_leads,
    COUNT(*) FILTER (WHERE estimated_lead_quality = 'Warm') AS warm_leads,
    COUNT(*) FILTER (WHERE estimated_lead_quality = 'Cold') AS cold_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Converted') AS converted_leads,
    ROUND(AVG(estimated_lead_score), 2) AS average_lead_score,
    ROUND(
        COUNT(*) FILTER (WHERE lead_status = 'Converted') * 100.0 / COUNT(*),
        2
    ) AS conversion_rate_percentage
FROM vw_lead_scoring_base
GROUP BY source_channel;


-- ============================================================
-- 4. Service category performance
-- ============================================================

CREATE OR REPLACE VIEW vw_service_category_performance AS
SELECT
    service_category,
    COUNT(*) AS total_leads,
    COUNT(*) FILTER (WHERE estimated_lead_quality = 'Hot') AS hot_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Converted') AS converted_leads,
    ROUND(AVG(estimated_lead_score), 2) AS average_lead_score,
    ROUND(
        COUNT(*) FILTER (WHERE lead_status = 'Converted') * 100.0 / COUNT(*),
        2
    ) AS conversion_rate_percentage
FROM vw_lead_scoring_base
GROUP BY service_category;


-- ============================================================
-- 5. Funnel summary
-- ============================================================

CREATE OR REPLACE VIEW vw_funnel_summary AS
SELECT
    lead_status,
    COUNT(*) AS total_leads,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_total
FROM leads
GROUP BY lead_status;


-- ============================================================
-- 6. Monthly lead trends
-- ============================================================

CREATE OR REPLACE VIEW vw_monthly_lead_trends AS
SELECT
    DATE_TRUNC('month', created_at)::DATE AS month,
    COUNT(*) AS total_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Qualified') AS qualified_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Converted') AS converted_leads,
    COUNT(*) FILTER (WHERE estimated_lead_quality = 'Hot') AS hot_leads,
    ROUND(AVG(estimated_lead_score), 2) AS average_lead_score
FROM vw_lead_scoring_base
GROUP BY DATE_TRUNC('month', created_at)::DATE;


-- ============================================================
-- 7. Sales rep performance
-- ============================================================

CREATE OR REPLACE VIEW vw_sales_rep_performance AS
SELECT
    assigned_sales_rep,
    sales_rep_region,
    sales_rep_specialization,
    COUNT(*) AS total_assigned_leads,
    COUNT(*) FILTER (WHERE lead_status = 'New') AS new_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Contacted') AS contacted_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Qualified') AS qualified_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Converted') AS converted_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Lost') AS lost_leads,
    COUNT(*) FILTER (WHERE estimated_lead_quality = 'Hot') AS hot_leads,
    ROUND(AVG(estimated_lead_score), 2) AS average_lead_score,
    ROUND(
        COUNT(*) FILTER (WHERE lead_status = 'Converted') * 100.0 / COUNT(*),
        2
    ) AS conversion_rate_percentage
FROM vw_lead_scoring_base
GROUP BY
    assigned_sales_rep,
    sales_rep_region,
    sales_rep_specialization;


-- ============================================================
-- 8. High priority leads
-- ============================================================

CREATE OR REPLACE VIEW vw_high_priority_leads AS
SELECT
    lead_id,
    first_name,
    last_name,
    company,
    email,
    phone,
    service_category,
    budget_range,
    urgency_level,
    source_channel,
    lead_status,
    assigned_sales_rep,
    estimated_lead_score,
    estimated_lead_quality,
    created_at
FROM vw_lead_scoring_base
WHERE estimated_lead_quality = 'Hot'
ORDER BY estimated_lead_score DESC, created_at DESC;