-- ============================================================
-- Lead Quality Metrics
-- Purpose:
-- Analyze CRM leads by quality indicators such as budget,
-- urgency, source channel, service category, and lead status.
-- ============================================================


-- 1. Total leads by status
SELECT
    lead_status,
    COUNT(*) AS total_leads
FROM leads
GROUP BY lead_status
ORDER BY total_leads DESC;


-- 2. Leads by source channel
SELECT
    source_channel,
    COUNT(*) AS total_leads
FROM leads
GROUP BY source_channel
ORDER BY total_leads DESC;


-- 3. Leads by service category
SELECT
    service_category,
    COUNT(*) AS total_leads
FROM leads
GROUP BY service_category
ORDER BY total_leads DESC;


-- 4. Leads by urgency level
SELECT
    urgency_level,
    COUNT(*) AS total_leads
FROM leads
GROUP BY urgency_level
ORDER BY
    CASE urgency_level
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Medium' THEN 3
        WHEN 'Low' THEN 4
        ELSE 5
    END;


-- 5. Leads by budget range
SELECT
    budget_range,
    COUNT(*) AS total_leads
FROM leads
GROUP BY budget_range
ORDER BY
    CASE budget_range
        WHEN '500k+' THEN 1
        WHEN '250k-500k' THEN 2
        WHEN '100k-250k' THEN 3
        WHEN '50k-100k' THEN 4
        WHEN 'Below 50k' THEN 5
        ELSE 6
    END;


-- 6. High-intent leads
-- These are leads with strong urgency and stronger budget.
SELECT
    first_name,
    last_name,
    company,
    email,
    service_category,
    budget_range,
    urgency_level,
    source_channel,
    lead_status,
    created_at
FROM leads
WHERE urgency_level IN ('High', 'Critical')
  AND budget_range IN ('250k-500k', '500k+')
ORDER BY created_at DESC
LIMIT 25;


-- 7. Lead quality estimate using SQL-only scoring
-- This is a temporary SQL scoring model before Java scoring is added.
SELECT
    lead_id,
    first_name,
    last_name,
    company,
    email,
    service_category,
    budget_range,
    urgency_level,
    source_channel,
    lead_status,

    (
        CASE budget_range
            WHEN '500k+' THEN 25
            WHEN '250k-500k' THEN 20
            WHEN '100k-250k' THEN 15
            WHEN '50k-100k' THEN 10
            WHEN 'Below 50k' THEN 5
            ELSE 0
        END
        +
        CASE urgency_level
            WHEN 'Critical' THEN 25
            WHEN 'High' THEN 20
            WHEN 'Medium' THEN 10
            WHEN 'Low' THEN 5
            ELSE 0
        END
        +
        CASE source_channel
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
            WHEN inquiry_details IS NOT NULL AND LENGTH(inquiry_details) >= 80 THEN 15
            WHEN inquiry_details IS NOT NULL AND LENGTH(inquiry_details) >= 40 THEN 10
            ELSE 5
        END
        +
        CASE lead_status
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
            CASE budget_range
                WHEN '500k+' THEN 25
                WHEN '250k-500k' THEN 20
                WHEN '100k-250k' THEN 15
                WHEN '50k-100k' THEN 10
                WHEN 'Below 50k' THEN 5
                ELSE 0
            END
            +
            CASE urgency_level
                WHEN 'Critical' THEN 25
                WHEN 'High' THEN 20
                WHEN 'Medium' THEN 10
                WHEN 'Low' THEN 5
                ELSE 0
            END
            +
            CASE source_channel
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
                WHEN inquiry_details IS NOT NULL AND LENGTH(inquiry_details) >= 80 THEN 15
                WHEN inquiry_details IS NOT NULL AND LENGTH(inquiry_details) >= 40 THEN 10
                ELSE 5
            END
            +
            CASE lead_status
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
            CASE budget_range
                WHEN '500k+' THEN 25
                WHEN '250k-500k' THEN 20
                WHEN '100k-250k' THEN 15
                WHEN '50k-100k' THEN 10
                WHEN 'Below 50k' THEN 5
                ELSE 0
            END
            +
            CASE urgency_level
                WHEN 'Critical' THEN 25
                WHEN 'High' THEN 20
                WHEN 'Medium' THEN 10
                WHEN 'Low' THEN 5
                ELSE 0
            END
            +
            CASE source_channel
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
                WHEN inquiry_details IS NOT NULL AND LENGTH(inquiry_details) >= 80 THEN 15
                WHEN inquiry_details IS NOT NULL AND LENGTH(inquiry_details) >= 40 THEN 10
                ELSE 5
            END
            +
            CASE lead_status
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

FROM leads
ORDER BY estimated_lead_score DESC
LIMIT 50;


-- 8. Lead quality distribution
WITH scored_leads AS (
    SELECT
        lead_id,
        (
            CASE budget_range
                WHEN '500k+' THEN 25
                WHEN '250k-500k' THEN 20
                WHEN '100k-250k' THEN 15
                WHEN '50k-100k' THEN 10
                WHEN 'Below 50k' THEN 5
                ELSE 0
            END
            +
            CASE urgency_level
                WHEN 'Critical' THEN 25
                WHEN 'High' THEN 20
                WHEN 'Medium' THEN 10
                WHEN 'Low' THEN 5
                ELSE 0
            END
            +
            CASE source_channel
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
                WHEN inquiry_details IS NOT NULL AND LENGTH(inquiry_details) >= 80 THEN 15
                WHEN inquiry_details IS NOT NULL AND LENGTH(inquiry_details) >= 40 THEN 10
                ELSE 5
            END
            +
            CASE lead_status
                WHEN 'Converted' THEN 15
                WHEN 'Qualified' THEN 12
                WHEN 'Contacted' THEN 8
                WHEN 'New' THEN 5
                WHEN 'Unqualified' THEN 2
                WHEN 'Lost' THEN 0
                ELSE 0
            END
        ) AS estimated_lead_score
    FROM leads
)

SELECT
    CASE
        WHEN estimated_lead_score >= 70 THEN 'Hot'
        WHEN estimated_lead_score >= 40 THEN 'Warm'
        ELSE 'Cold'
    END AS estimated_lead_quality,
    COUNT(*) AS total_leads,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_total
FROM scored_leads
GROUP BY estimated_lead_quality
ORDER BY
    CASE estimated_lead_quality
        WHEN 'Hot' THEN 1
        WHEN 'Warm' THEN 2
        WHEN 'Cold' THEN 3
    END;


-- 9. Average estimated lead score by source channel
WITH scored_leads AS (
    SELECT
        source_channel,
        (
            CASE budget_range
                WHEN '500k+' THEN 25
                WHEN '250k-500k' THEN 20
                WHEN '100k-250k' THEN 15
                WHEN '50k-100k' THEN 10
                WHEN 'Below 50k' THEN 5
                ELSE 0
            END
            +
            CASE urgency_level
                WHEN 'Critical' THEN 25
                WHEN 'High' THEN 20
                WHEN 'Medium' THEN 10
                WHEN 'Low' THEN 5
                ELSE 0
            END
            +
            CASE source_channel
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
                WHEN inquiry_details IS NOT NULL AND LENGTH(inquiry_details) >= 80 THEN 15
                WHEN inquiry_details IS NOT NULL AND LENGTH(inquiry_details) >= 40 THEN 10
                ELSE 5
            END
            +
            CASE lead_status
                WHEN 'Converted' THEN 15
                WHEN 'Qualified' THEN 12
                WHEN 'Contacted' THEN 8
                WHEN 'New' THEN 5
                WHEN 'Unqualified' THEN 2
                WHEN 'Lost' THEN 0
                ELSE 0
            END
        ) AS estimated_lead_score
    FROM leads
)

SELECT
    source_channel,
    COUNT(*) AS total_leads,
    ROUND(AVG(estimated_lead_score), 2) AS average_estimated_lead_score
FROM scored_leads
GROUP BY source_channel
ORDER BY average_estimated_lead_score DESC;