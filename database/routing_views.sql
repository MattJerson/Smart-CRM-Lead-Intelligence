-- ============================================================
-- Routing Reporting Views
-- Purpose:
-- Create reusable views for lead routing performance,
-- routing priority, pending actions, and sales rep workload.
-- ============================================================


-- ============================================================
-- 1. Routing detail view
-- Full lead + score + routing context.
-- ============================================================

CREATE OR REPLACE VIEW vw_routing_detail AS
SELECT
    rl.routing_log_id,
    rl.lead_id,

    l.first_name,
    l.last_name,
    l.company,
    l.email,
    l.phone,
    l.service_category,
    l.budget_range,
    l.urgency_level,
    l.source_channel,
    l.lead_status,
    l.created_at AS lead_created_at,

    sr.full_name AS assigned_sales_rep,
    sr.region AS sales_rep_region,
    sr.specialization AS sales_rep_specialization,

    ls.total_score,
    ls.lead_quality,
    ls.conversion_likelihood,

    rl.routing_priority,
    rl.routing_reason,
    rl.response_status,
    rl.routed_at,
    rl.responded_at,

    CASE
        WHEN rl.responded_at IS NOT NULL THEN
            EXTRACT(EPOCH FROM (rl.responded_at - rl.routed_at)) / 3600
        ELSE NULL
    END AS response_time_hours

FROM routing_logs rl
JOIN leads l
    ON rl.lead_id = l.lead_id
LEFT JOIN sales_reps sr
    ON rl.assigned_sales_rep_id = sr.sales_rep_id
LEFT JOIN lead_scores ls
    ON rl.lead_id = ls.lead_id;


-- ============================================================
-- 2. Routing priority summary
-- Shows how many leads are immediate, standard, or nurture.
-- ============================================================

CREATE OR REPLACE VIEW vw_routing_priority_summary AS
SELECT
    routing_priority,
    COUNT(*) AS total_leads,
    COUNT(*) FILTER (WHERE response_status = 'Pending') AS pending_leads,
    COUNT(*) FILTER (WHERE response_status <> 'Pending') AS responded_leads,
    ROUND(AVG(total_score), 2) AS average_lead_score,
    ROUND(AVG(conversion_likelihood), 2) AS average_conversion_likelihood
FROM vw_routing_detail
GROUP BY routing_priority;


-- ============================================================
-- 3. Routing workload by sales rep
-- Shows how routing priority is distributed across reps.
-- ============================================================

CREATE OR REPLACE VIEW vw_routing_workload_by_sales_rep AS
SELECT
    assigned_sales_rep,
    sales_rep_region,
    sales_rep_specialization,
    COUNT(*) AS total_routed_leads,
    COUNT(*) FILTER (WHERE routing_priority = 'Immediate') AS immediate_leads,
    COUNT(*) FILTER (WHERE routing_priority = 'Standard') AS standard_leads,
    COUNT(*) FILTER (WHERE routing_priority = 'Nurture') AS nurture_leads,
    COUNT(*) FILTER (WHERE response_status = 'Pending') AS pending_leads,
    ROUND(AVG(total_score), 2) AS average_lead_score
FROM vw_routing_detail
GROUP BY
    assigned_sales_rep,
    sales_rep_region,
    sales_rep_specialization;


-- ============================================================
-- 4. Pending immediate leads
-- High-priority operational queue.
-- These are the leads sales should handle first.
-- ============================================================

CREATE OR REPLACE VIEW vw_pending_immediate_leads AS
SELECT
    first_name,
    last_name,
    company,
    email,
    phone,
    service_category,
    budget_range,
    urgency_level,
    source_channel,
    assigned_sales_rep,
    total_score,
    lead_quality,
    routing_priority,
    response_status,
    routing_reason,
    routed_at
FROM vw_routing_detail
WHERE routing_priority = 'Immediate'
  AND response_status = 'Pending'
ORDER BY total_score DESC, routed_at ASC;


-- ============================================================
-- 5. Routing performance by source channel
-- Shows which sources create the most urgent routing demand.
-- ============================================================

CREATE OR REPLACE VIEW vw_routing_by_source_channel AS
SELECT
    source_channel,
    COUNT(*) AS total_routed_leads,
    COUNT(*) FILTER (WHERE routing_priority = 'Immediate') AS immediate_leads,
    COUNT(*) FILTER (WHERE routing_priority = 'Standard') AS standard_leads,
    COUNT(*) FILTER (WHERE routing_priority = 'Nurture') AS nurture_leads,
    ROUND(AVG(total_score), 2) AS average_lead_score
FROM vw_routing_detail
GROUP BY source_channel;


-- ============================================================
-- 6. Routing performance by service category
-- Shows which services generate the highest-priority routing.
-- ============================================================

CREATE OR REPLACE VIEW vw_routing_by_service_category AS
SELECT
    service_category,
    COUNT(*) AS total_routed_leads,
    COUNT(*) FILTER (WHERE routing_priority = 'Immediate') AS immediate_leads,
    COUNT(*) FILTER (WHERE routing_priority = 'Standard') AS standard_leads,
    COUNT(*) FILTER (WHERE routing_priority = 'Nurture') AS nurture_leads,
    ROUND(AVG(total_score), 2) AS average_lead_score
FROM vw_routing_detail
GROUP BY service_category;