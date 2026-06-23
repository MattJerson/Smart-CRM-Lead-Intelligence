#!/bin/bash

set -e

echo "Starting Smart CRM pipeline..."

echo "1. Starting Docker services..."
docker compose up -d

echo "2. Seeding sales reps and campaigns..."
docker compose exec -T postgres psql -U crm_user -d smart_crm < database/seed.sql

echo "3. Generating sample lead data..."
python3 scripts/python/generate_sample_leads.py --rows 500

echo "4. Loading leads into PostgreSQL..."
python3 scripts/python/load_to_postgres.py

echo "5. Running Java Lead Scoring Engine..."
cd java-lead-scoring
mvn clean compile exec:java -Dexec.mainClass=com.crm.intelligence.LeadScoringApp

echo "6. Running Java Lead Routing Engine..."
mvn clean compile exec:java -Dexec.mainClass=com.crm.intelligence.LeadRoutingApp

echo "7. Running Java Follow-Up Task Generator..."
mvn clean compile exec:java -Dexec.mainClass=com.crm.intelligence.FollowUpTaskApp
cd ..

echo "8. Refreshing base reporting views..."
docker compose exec -T postgres psql -U crm_user -d smart_crm < database/views.sql

echo "9. Switching reporting views to Java-generated scores..."
docker compose exec -T postgres psql -U crm_user -d smart_crm < database/use_java_scores.sql

echo "10. Refreshing routing reporting views..."
docker compose exec -T postgres psql -U crm_user -d smart_crm < database/routing_views.sql

echo "11. Refreshing follow-up reporting views..."
docker compose exec -T postgres psql -U crm_user -d smart_crm < database/follow_up_views.sql

echo "12. Ensuring Salesforce sync table exists..."
docker compose exec -T postgres psql -U crm_user -d smart_crm < database/salesforce_sync.sql

echo "13. Refreshing Salesforce sync reporting views..."
docker compose exec -T postgres psql -U crm_user -d smart_crm < database/salesforce_reporting_views.sql

echo "14. Syncing high-priority leads to Salesforce through n8n..."
python3 scripts/python/send_salesforce_leads.py --limit 5

echo "15. Sending CRM operations summary to live n8n webhook..."
python3 scripts/python/send_n8n_summary.py

echo "16. Sending high-priority lead alert to live n8n webhook..."
python3 scripts/python/send_high_priority_alert.py

echo "17. Validating full pipeline output..."
python3 scripts/python/validate_pipeline.py

echo "Pipeline completed successfully."

echo "Summary:"
docker compose exec postgres psql -U crm_user -d smart_crm -c "
SELECT 'leads' AS table_name, COUNT(*) FROM leads
UNION ALL
SELECT 'lead_scores', COUNT(*) FROM lead_scores
UNION ALL
SELECT 'routing_logs', COUNT(*) FROM routing_logs
UNION ALL
SELECT 'follow_ups', COUNT(*) FROM follow_ups
UNION ALL
SELECT 'salesforce_successful_syncs', COUNT(*) FROM salesforce_sync_logs WHERE sync_status = 'Success'
UNION ALL
SELECT 'salesforce_failed_syncs', COUNT(*) FROM salesforce_sync_logs WHERE sync_status = 'Failed';
"