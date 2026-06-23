CREATE TABLE IF NOT EXISTS salesforce_sync_logs (
    sync_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id UUID NOT NULL REFERENCES leads(lead_id) ON DELETE CASCADE,
    salesforce_object_type VARCHAR(50) NOT NULL DEFAULT 'Lead',
    salesforce_record_id VARCHAR(100),
    sync_status VARCHAR(50) NOT NULL DEFAULT 'Pending',
    sync_message TEXT,
    synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT unique_salesforce_lead_sync UNIQUE (lead_id, salesforce_object_type)
);