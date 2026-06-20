TRUNCATE TABLE
    follow_ups,
    routing_logs,
    lead_scores,
    opportunities,
    leads,
    campaigns,
    sales_reps
RESTART IDENTITY CASCADE;

INSERT INTO sales_reps (
    full_name,
    email,
    region,
    specialization,
    is_active
)
VALUES
    ('Alyssa Reyes', 'alyssa.reyes@smartcrm.test', 'Metro Manila', 'Enterprise Services', TRUE),
    ('Marco Santos', 'marco.santos@smartcrm.test', 'Metro Manila', 'SMB Services', TRUE),
    ('Janelle Cruz', 'janelle.cruz@smartcrm.test', 'Cebu', 'Technology Solutions', TRUE),
    ('Rafael Lim', 'rafael.lim@smartcrm.test', 'Davao', 'Business Consulting', TRUE),
    ('Bianca Tan', 'bianca.tan@smartcrm.test', 'Remote', 'General Sales', TRUE);

INSERT INTO campaigns (
    campaign_name,
    source_channel,
    campaign_budget,
    start_date,
    end_date
)
VALUES
    ('Q1 LinkedIn Lead Campaign', 'LinkedIn', 50000.00, '2026-01-01', '2026-03-31'),
    ('Google Search High Intent Campaign', 'Google Search', 75000.00, '2026-01-15', '2026-04-15'),
    ('Referral Partner Program', 'Referral', 25000.00, '2026-02-01', '2026-06-30'),
    ('Facebook Awareness Campaign', 'Facebook', 30000.00, '2026-02-15', '2026-05-15'),
    ('Email Nurture Campaign', 'Email', 15000.00, '2026-03-01', '2026-06-30'),
    ('Website Inquiry Campaign', 'Website', 0.00, '2026-01-01', '2026-12-31');