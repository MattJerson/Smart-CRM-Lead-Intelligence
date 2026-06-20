SELECT
    full_name,
    email,
    region,
    specialization
FROM sales_reps
ORDER BY full_name;

SELECT
    campaign_name,
    source_channel,
    campaign_budget,
    start_date,
    end_date
FROM campaigns
ORDER BY start_date;

SELECT
    COUNT(*) AS total_sales_reps
FROM sales_reps;

SELECT
    COUNT(*) AS total_campaigns
FROM campaigns;