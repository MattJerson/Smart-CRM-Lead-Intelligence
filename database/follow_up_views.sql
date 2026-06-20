-- ============================================================
-- Follow-Up Reporting Views
-- Purpose:
-- Create reusable reporting views for follow-up task tracking,
-- pending tasks, overdue tasks, task type distribution,
-- and sales rep workload.
-- ============================================================


-- ============================================================
-- 1. Follow-up detail view
-- Full task context with lead, sales rep, and score data.
-- ============================================================

CREATE OR REPLACE VIEW vw_follow_up_detail AS
SELECT
    f.follow_up_id,
    f.lead_id,

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

    sr.full_name AS sales_rep,
    sr.region AS sales_rep_region,
    sr.specialization AS sales_rep_specialization,

    ls.total_score,
    ls.lead_quality,
    ls.conversion_likelihood,

    f.follow_up_type,
    f.due_date,
    f.completed_at,
    f.status,
    f.notes,
    f.created_at,

    CASE
        WHEN f.completed_at IS NOT NULL THEN 'Completed'
        WHEN f.due_date < CURRENT_DATE THEN 'Overdue'
        WHEN f.due_date = CURRENT_DATE THEN 'Due Today'
        ELSE 'Upcoming'
    END AS task_timing_status,

    CASE
        WHEN f.due_date < CURRENT_DATE
             AND f.completed_at IS NULL
        THEN CURRENT_DATE - f.due_date
        ELSE 0
    END AS days_overdue

FROM follow_ups f
JOIN leads l
    ON f.lead_id = l.lead_id
LEFT JOIN sales_reps sr
    ON f.sales_rep_id = sr.sales_rep_id
LEFT JOIN lead_scores ls
    ON f.lead_id = ls.lead_id;


-- ============================================================
-- 2. Follow-up summary
-- Overall task health.
-- ============================================================

CREATE OR REPLACE VIEW vw_follow_up_summary AS
SELECT
    COUNT(*) AS total_tasks,
    COUNT(*) FILTER (WHERE status = 'Pending') AS pending_tasks,
    COUNT(*) FILTER (WHERE completed_at IS NOT NULL) AS completed_tasks,
    COUNT(*) FILTER (
        WHERE due_date < CURRENT_DATE
          AND completed_at IS NULL
    ) AS overdue_tasks,
    COUNT(*) FILTER (
        WHERE due_date = CURRENT_DATE
          AND completed_at IS NULL
    ) AS due_today_tasks,
    COUNT(*) FILTER (
        WHERE due_date > CURRENT_DATE
          AND completed_at IS NULL
    ) AS upcoming_tasks
FROM follow_ups;


-- ============================================================
-- 3. Follow-up tasks by type
-- Shows Same-Day Call, Sales Follow-Up, and Nurture Email volume.
-- ============================================================

CREATE OR REPLACE VIEW vw_follow_up_by_type AS
SELECT
    follow_up_type,
    COUNT(*) AS total_tasks,
    COUNT(*) FILTER (WHERE status = 'Pending') AS pending_tasks,
    COUNT(*) FILTER (WHERE completed_at IS NOT NULL) AS completed_tasks,
    COUNT(*) FILTER (
        WHERE due_date < CURRENT_DATE
          AND completed_at IS NULL
    ) AS overdue_tasks
FROM follow_ups
GROUP BY follow_up_type;


-- ============================================================
-- 4. Follow-up workload by sales rep
-- Shows task ownership and overdue workload per rep.
-- ============================================================

CREATE OR REPLACE VIEW vw_follow_up_workload_by_sales_rep AS
SELECT
    sales_rep,
    sales_rep_region,
    sales_rep_specialization,
    COUNT(*) AS total_tasks,
    COUNT(*) FILTER (WHERE status = 'Pending') AS pending_tasks,
    COUNT(*) FILTER (WHERE completed_at IS NOT NULL) AS completed_tasks,
    COUNT(*) FILTER (
        WHERE due_date < CURRENT_DATE
          AND completed_at IS NULL
    ) AS overdue_tasks,
    COUNT(*) FILTER (WHERE follow_up_type = 'Same-Day Call') AS same_day_calls,
    COUNT(*) FILTER (WHERE follow_up_type = 'Sales Follow-Up') AS sales_follow_ups,
    COUNT(*) FILTER (WHERE follow_up_type = 'Nurture Email') AS nurture_emails,
    ROUND(AVG(total_score), 2) AS average_lead_score
FROM vw_follow_up_detail
GROUP BY
    sales_rep,
    sales_rep_region,
    sales_rep_specialization;


-- ============================================================
-- 5. Pending follow-up queue
-- Operational task list for sales reps.
-- ============================================================

CREATE OR REPLACE VIEW vw_pending_follow_up_queue AS
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
    sales_rep,
    total_score,
    lead_quality,
    follow_up_type,
    due_date,
    task_timing_status,
    days_overdue,
    notes
FROM vw_follow_up_detail
WHERE completed_at IS NULL
ORDER BY
    CASE task_timing_status
        WHEN 'Overdue' THEN 1
        WHEN 'Due Today' THEN 2
        WHEN 'Upcoming' THEN 3
        ELSE 4
    END,
    due_date ASC,
    total_score DESC;


-- ============================================================
-- 6. Follow-up by lead quality
-- Shows how follow-up work is distributed across Hot/Warm/Cold.
-- ============================================================

CREATE OR REPLACE VIEW vw_follow_up_by_lead_quality AS
SELECT
    lead_quality,
    COUNT(*) AS total_tasks,
    COUNT(*) FILTER (WHERE status = 'Pending') AS pending_tasks,
    COUNT(*) FILTER (WHERE completed_at IS NOT NULL) AS completed_tasks,
    COUNT(*) FILTER (
        WHERE due_date < CURRENT_DATE
          AND completed_at IS NULL
    ) AS overdue_tasks,
    ROUND(AVG(total_score), 2) AS average_lead_score
FROM vw_follow_up_detail
GROUP BY lead_quality;