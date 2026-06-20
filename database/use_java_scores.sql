-- ============================================================
-- Java-Based Reporting View
-- Purpose:
-- Replace temporary SQL scoring with Java-generated scores
-- from the lead_scores table.
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

    COALESCE(ls.budget_score, 0) AS budget_score,
    COALESCE(ls.urgency_score, 0) AS urgency_score,
    COALESCE(ls.source_score, 0) AS source_score,
    COALESCE(ls.completeness_score, 0) AS completeness_score,
    COALESCE(ls.engagement_score, 0) AS status_score,

    COALESCE(ls.total_score, 0) AS estimated_lead_score,

    COALESCE(ls.lead_quality, 'Unscored')::TEXT AS estimated_lead_quality

FROM leads l
LEFT JOIN sales_reps sr
    ON l.assigned_sales_rep_id = sr.sales_rep_id
LEFT JOIN campaigns c
    ON l.campaign_id = c.campaign_id
LEFT JOIN lead_scores ls
    ON l.lead_id = ls.lead_id;