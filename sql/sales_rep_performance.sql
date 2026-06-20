-- ============================================================
-- Sales Rep Performance Metrics
-- Purpose:
-- Analyze sales rep workload, lead ownership, conversion rate,
-- lead quality indicators, and response/follow-up readiness.
-- ============================================================


-- 1. Total assigned leads per sales rep
SELECT
    sr.full_name AS sales_rep,
    sr.region,
    sr.specialization,
    COUNT(l.lead_id) AS assigned_leads
FROM sales_reps sr
LEFT JOIN leads l
    ON sr.sales_rep_id = l.assigned_sales_rep_id
GROUP BY
    sr.full_name,
    sr.region,
    sr.specialization
ORDER BY assigned_leads DESC;


-- 2. Sales rep performance by lead status
SELECT
    sr.full_name AS sales_rep,
    COUNT(l.lead_id) AS total_leads,
    COUNT(*) FILTER (WHERE l.lead_status = 'New') AS new_leads,
    COUNT(*) FILTER (WHERE l.lead_status = 'Contacted') AS contacted_leads,
    COUNT(*) FILTER (WHERE l.lead_status = 'Qualified') AS qualified_leads,
    COUNT(*) FILTER (WHERE l.lead_status = 'Converted') AS converted_leads,
    COUNT(*) FILTER (WHERE l.lead_status = 'Lost') AS lost_leads,
    COUNT(*) FILTER (WHERE l.lead_status = 'Unqualified') AS unqualified_leads
FROM sales_reps sr
LEFT JOIN leads l
    ON sr.sales_rep_id = l.assigned_sales_rep_id
GROUP BY sr.full_name
ORDER BY converted_leads DESC, qualified_leads DESC;


-- 3. Conversion rate by sales rep
SELECT
    sr.full_name AS sales_rep,
    COUNT(l.lead_id) AS total_leads,
    COUNT(*) FILTER (WHERE l.lead_status = 'Converted') AS converted_leads,
    ROUND(
        COUNT(*) FILTER (WHERE l.lead_status = 'Converted') * 100.0
        / NULLIF(COUNT(l.lead_id), 0),
        2
    ) AS conversion_rate_percentage
FROM sales_reps sr
LEFT JOIN leads l
    ON sr.sales_rep_id = l.assigned_sales_rep_id
GROUP BY sr.full_name
ORDER BY conversion_rate_percentage DESC NULLS LAST;


-- 4. Qualification rate by sales rep
SELECT
    sr.full_name AS sales_rep,
    COUNT(l.lead_id) AS total_leads,
    COUNT(*) FILTER (
        WHERE l.lead_status IN ('Qualified', 'Converted')
    ) AS qualified_or_converted_leads,
    ROUND(
        COUNT(*) FILTER (
            WHERE l.lead_status IN ('Qualified', 'Converted')
        ) * 100.0 / NULLIF(COUNT(l.lead_id), 0),
        2
    ) AS qualification_rate_percentage
FROM sales_reps sr
LEFT JOIN leads l
    ON sr.sales_rep_id = l.assigned_sales_rep_id
GROUP BY sr.full_name
ORDER BY qualification_rate_percentage DESC NULLS LAST;


-- 5. High-priority leads assigned to each sales rep
SELECT
    sr.full_name AS sales_rep,
    COUNT(l.lead_id) AS high_priority_leads
FROM sales_reps sr
LEFT JOIN leads l
    ON sr.sales_rep_id = l.assigned_sales_rep_id
    AND l.urgency_level IN ('High', 'Critical')
    AND l.budget_range IN ('250k-500k', '500k+')
GROUP BY sr.full_name
ORDER BY high_priority_leads DESC;


-- 6. Sales rep workload by source channel
SELECT
    sr.full_name AS sales_rep,
    l.source_channel,
    COUNT(l.lead_id) AS total_leads
FROM sales_reps sr
JOIN leads l
    ON sr.sales_rep_id = l.assigned_sales_rep_id
GROUP BY
    sr.full_name,
    l.source_channel
ORDER BY
    sr.full_name,
    total_leads DESC;


-- 7. Sales rep workload by service category
SELECT
    sr.full_name AS sales_rep,
    l.service_category,
    COUNT(l.lead_id) AS total_leads
FROM sales_reps sr
JOIN leads l
    ON sr.sales_rep_id = l.assigned_sales_rep_id
GROUP BY
    sr.full_name,
    l.service_category
ORDER BY
    sr.full_name,
    total_leads DESC;


-- 8. Estimated lead score by sales rep
-- This uses the temporary SQL scoring model until Java scoring is added.
WITH scored_leads AS (
    SELECT
        assigned_sales_rep_id,
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
    sr.full_name AS sales_rep,
    COUNT(sl.assigned_sales_rep_id) AS total_scored_leads,
    ROUND(AVG(sl.estimated_lead_score), 2) AS average_estimated_lead_score,
    MIN(sl.estimated_lead_score) AS lowest_estimated_lead_score,
    MAX(sl.estimated_lead_score) AS highest_estimated_lead_score
FROM sales_reps sr
LEFT JOIN scored_leads sl
    ON sr.sales_rep_id = sl.assigned_sales_rep_id
GROUP BY sr.full_name
ORDER BY average_estimated_lead_score DESC NULLS LAST;


-- 9. Hot, warm, and cold lead distribution by sales rep
WITH scored_leads AS (
    SELECT
        assigned_sales_rep_id,
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
)

SELECT
    sr.full_name AS sales_rep,
    COUNT(*) FILTER (WHERE sl.estimated_lead_quality = 'Hot') AS hot_leads,
    COUNT(*) FILTER (WHERE sl.estimated_lead_quality = 'Warm') AS warm_leads,
    COUNT(*) FILTER (WHERE sl.estimated_lead_quality = 'Cold') AS cold_leads,
    COUNT(sl.estimated_lead_quality) AS total_leads
FROM sales_reps sr
LEFT JOIN scored_leads sl
    ON sr.sales_rep_id = sl.assigned_sales_rep_id
GROUP BY sr.full_name
ORDER BY hot_leads DESC, warm_leads DESC;


-- 10. Recent assigned leads by sales rep
SELECT
    sr.full_name AS sales_rep,
    l.first_name,
    l.last_name,
    l.company,
    l.email,
    l.service_category,
    l.budget_range,
    l.urgency_level,
    l.source_channel,
    l.lead_status,
    l.created_at
FROM sales_reps sr
JOIN leads l
    ON sr.sales_rep_id = l.assigned_sales_rep_id
ORDER BY l.created_at DESC
LIMIT 25;