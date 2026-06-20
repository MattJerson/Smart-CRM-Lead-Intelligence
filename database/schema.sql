CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP TABLE IF EXISTS follow_ups CASCADE;
DROP TABLE IF EXISTS routing_logs CASCADE;
DROP TABLE IF EXISTS lead_scores CASCADE;
DROP TABLE IF EXISTS opportunities CASCADE;
DROP TABLE IF EXISTS leads CASCADE;
DROP TABLE IF EXISTS campaigns CASCADE;
DROP TABLE IF EXISTS sales_reps CASCADE;

CREATE TABLE sales_reps (
    sales_rep_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    region VARCHAR(100),
    specialization VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE campaigns (
    campaign_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_name VARCHAR(150) NOT NULL,
    source_channel VARCHAR(100) NOT NULL,
    campaign_budget NUMERIC(12, 2),
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE leads (
    lead_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    company VARCHAR(150),
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(50),
    service_category VARCHAR(100) NOT NULL,
    budget_range VARCHAR(50) NOT NULL,
    urgency_level VARCHAR(50) NOT NULL,
    source_channel VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    inquiry_details TEXT,
    lead_status VARCHAR(50) DEFAULT 'New',
    campaign_id UUID REFERENCES campaigns(campaign_id),
    assigned_sales_rep_id UUID REFERENCES sales_reps(sales_rep_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE opportunities (
    opportunity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id UUID REFERENCES leads(lead_id) ON DELETE CASCADE,
    opportunity_name VARCHAR(150) NOT NULL,
    stage VARCHAR(50) NOT NULL,
    estimated_value NUMERIC(12, 2),
    probability NUMERIC(5, 2),
    expected_close_date DATE,
    is_closed BOOLEAN DEFAULT FALSE,
    is_won BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lead_scores (
    lead_score_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id UUID REFERENCES leads(lead_id) ON DELETE CASCADE,
    budget_score INTEGER NOT NULL,
    urgency_score INTEGER NOT NULL,
    source_score INTEGER NOT NULL,
    completeness_score INTEGER NOT NULL,
    engagement_score INTEGER NOT NULL,
    total_score INTEGER NOT NULL,
    lead_quality VARCHAR(20) NOT NULL,
    conversion_likelihood NUMERIC(5, 2),
    scoring_notes TEXT,
    scored_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE routing_logs (
    routing_log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id UUID REFERENCES leads(lead_id) ON DELETE CASCADE,
    assigned_sales_rep_id UUID REFERENCES sales_reps(sales_rep_id),
    routing_reason TEXT,
    routing_priority VARCHAR(50),
    routed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    response_status VARCHAR(50) DEFAULT 'Pending',
    responded_at TIMESTAMP
);

CREATE TABLE follow_ups (
    follow_up_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id UUID REFERENCES leads(lead_id) ON DELETE CASCADE,
    sales_rep_id UUID REFERENCES sales_reps(sales_rep_id),
    follow_up_type VARCHAR(50) NOT NULL,
    due_date DATE NOT NULL,
    completed_at TIMESTAMP,
    status VARCHAR(50) DEFAULT 'Pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);