CREATE OR REPLACE VIEW vw_salesforce_sync_status AS
SELECT
    l.lead_id,
    CONCAT(l.first_name, ' ', l.last_name) AS lead_name,
    l.company,
    l.email,
    l.phone,
    l.service_category,
    l.budget_range,
    l.urgency_level,
    l.source_channel,
    ls.total_score,
    ls.lead_quality,
    rl.routing_priority,
    COALESCE(ssl.sync_status, 'Not Synced') AS sync_status,
    ssl.salesforce_record_id AS salesforce_lead_id,
    ssl.salesforce_task_id,
    ssl.sync_message,
    ssl.synced_at
FROM leads l
LEFT JOIN lead_scores ls
    ON l.lead_id = ls.lead_id
LEFT JOIN routing_logs rl
    ON l.lead_id = rl.lead_id
LEFT JOIN salesforce_sync_logs ssl
    ON l.lead_id = ssl.lead_id
    AND ssl.salesforce_object_type = 'Lead';


CREATE OR REPLACE VIEW vw_salesforce_sync_summary AS
SELECT
    COUNT(*) AS total_leads,
    COUNT(*) FILTER (
        WHERE sync_status = 'Success'
    ) AS synced_to_salesforce,
    COUNT(*) FILTER (
        WHERE sync_status = 'Failed'
    ) AS failed_syncs,
    COUNT(*) FILTER (
        WHERE sync_status IS NULL
    ) AS not_synced,
    COUNT(*) FILTER (
        WHERE salesforce_record_id IS NOT NULL
    ) AS leads_with_salesforce_id,
    COUNT(*) FILTER (
        WHERE salesforce_task_id IS NOT NULL
    ) AS leads_with_salesforce_task
FROM salesforce_sync_logs;


CREATE OR REPLACE VIEW vw_salesforce_failed_syncs AS
SELECT
    l.lead_id,
    CONCAT(l.first_name, ' ', l.last_name) AS lead_name,
    l.company,
    l.email,
    l.service_category,
    l.source_channel,
    ls.total_score,
    ls.lead_quality,
    ssl.sync_status,
    ssl.sync_message,
    ssl.synced_at
FROM salesforce_sync_logs ssl
JOIN leads l
    ON ssl.lead_id = l.lead_id
LEFT JOIN lead_scores ls
    ON l.lead_id = ls.lead_id
WHERE ssl.sync_status = 'Failed'
ORDER BY ssl.synced_at DESC;


CREATE OR REPLACE VIEW vw_salesforce_successful_syncs AS
SELECT
    l.lead_id,
    CONCAT(l.first_name, ' ', l.last_name) AS lead_name,
    l.company,
    l.email,
    l.service_category,
    l.source_channel,
    ls.total_score,
    ls.lead_quality,
    rl.routing_priority,
    ssl.salesforce_record_id AS salesforce_lead_id,
    ssl.salesforce_task_id,
    ssl.synced_at
FROM salesforce_sync_logs ssl
JOIN leads l
    ON ssl.lead_id = l.lead_id
LEFT JOIN lead_scores ls
    ON l.lead_id = ls.lead_id
LEFT JOIN routing_logs rl
    ON l.lead_id = rl.lead_id
WHERE ssl.sync_status = 'Success'
ORDER BY ssl.synced_at DESC;