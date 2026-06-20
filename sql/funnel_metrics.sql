-- ============================================================
-- Funnel Metrics
-- Purpose:
-- Analyze how leads move through the sales funnel from intake
-- to qualification, opportunity creation, conversion, and loss.
-- ============================================================


-- 1. Lead status funnel count
SELECT
    lead_status,
    COUNT(*) AS total_leads,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_total
FROM leads
GROUP BY lead_status
ORDER BY
    CASE lead_status
        WHEN 'New' THEN 1
        WHEN 'Contacted' THEN 2
        WHEN 'Qualified' THEN 3
        WHEN 'Converted' THEN 4
        WHEN 'Lost' THEN 5
        WHEN 'Unqualified' THEN 6
        ELSE 7
    END;


-- 2. Overall conversion rate
SELECT
    COUNT(*) AS total_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Converted') AS converted_leads,
    ROUND(
        COUNT(*) FILTER (WHERE lead_status = 'Converted') * 100.0 / COUNT(*),
        2
    ) AS conversion_rate_percentage
FROM leads;


-- 3. Qualification rate
SELECT
    COUNT(*) AS total_leads,
    COUNT(*) FILTER (WHERE lead_status IN ('Qualified', 'Converted')) AS qualified_or_converted_leads,
    ROUND(
        COUNT(*) FILTER (WHERE lead_status IN ('Qualified', 'Converted')) * 100.0 / COUNT(*),
        2
    ) AS qualification_rate_percentage
FROM leads;


-- 4. Lost lead rate
SELECT
    COUNT(*) AS total_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Lost') AS lost_leads,
    ROUND(
        COUNT(*) FILTER (WHERE lead_status = 'Lost') * 100.0 / COUNT(*),
        2
    ) AS lost_rate_percentage
FROM leads;


-- 5. Funnel performance by source channel
SELECT
    source_channel,
    COUNT(*) AS total_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Qualified') AS qualified_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Converted') AS converted_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Lost') AS lost_leads,
    ROUND(
        COUNT(*) FILTER (WHERE lead_status = 'Converted') * 100.0 / COUNT(*),
        2
    ) AS conversion_rate_percentage
FROM leads
GROUP BY source_channel
ORDER BY conversion_rate_percentage DESC;


-- 6. Funnel performance by service category
SELECT
    service_category,
    COUNT(*) AS total_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Qualified') AS qualified_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Converted') AS converted_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Lost') AS lost_leads,
    ROUND(
        COUNT(*) FILTER (WHERE lead_status = 'Converted') * 100.0 / COUNT(*),
        2
    ) AS conversion_rate_percentage
FROM leads
GROUP BY service_category
ORDER BY conversion_rate_percentage DESC;


-- 7. Monthly lead intake
SELECT
    DATE_TRUNC('month', created_at)::DATE AS month,
    COUNT(*) AS total_leads
FROM leads
GROUP BY month
ORDER BY month;


-- 8. Monthly conversions
SELECT
    DATE_TRUNC('month', created_at)::DATE AS month,
    COUNT(*) FILTER (WHERE lead_status = 'Converted') AS converted_leads,
    COUNT(*) AS total_leads,
    ROUND(
        COUNT(*) FILTER (WHERE lead_status = 'Converted') * 100.0 / COUNT(*),
        2
    ) AS monthly_conversion_rate
FROM leads
GROUP BY month
ORDER BY month;


-- 9. Funnel by urgency level
SELECT
    urgency_level,
    COUNT(*) AS total_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Qualified') AS qualified_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Converted') AS converted_leads,
    ROUND(
        COUNT(*) FILTER (WHERE lead_status = 'Converted') * 100.0 / COUNT(*),
        2
    ) AS conversion_rate_percentage
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


-- 10. Funnel by budget range
SELECT
    budget_range,
    COUNT(*) AS total_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Qualified') AS qualified_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Converted') AS converted_leads,
    ROUND(
        COUNT(*) FILTER (WHERE lead_status = 'Converted') * 100.0 / COUNT(*),
        2
    ) AS conversion_rate_percentage
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