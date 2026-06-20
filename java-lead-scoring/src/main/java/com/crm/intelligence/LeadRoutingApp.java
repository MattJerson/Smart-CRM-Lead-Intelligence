package com.crm.intelligence;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class LeadRoutingApp {

    private static final String DB_URL = System.getenv().getOrDefault(
            "JDBC_DATABASE_URL",
            "jdbc:postgresql://localhost:5432/smart_crm"
    );

    private static final String DB_USER = System.getenv().getOrDefault(
            "POSTGRES_USER",
            "crm_user"
    );

    private static final String DB_PASSWORD = System.getenv().getOrDefault(
            "POSTGRES_PASSWORD",
            "crm_password"
    );

    public static void main(String[] args) {
        try (Connection connection = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
            List<ScoredLead> scoredLeads = fetchScoredLeads(connection);

            if (scoredLeads.isEmpty()) {
                System.out.println("No scored leads found. Run LeadScoringApp first.");
                return;
            }

            clearExistingRoutingLogs(connection);
            insertRoutingLogs(connection, scoredLeads);

            System.out.println("Java Lead Routing Engine completed.");
            System.out.println("Total routing logs created: " + scoredLeads.size());

        } catch (Exception exception) {
            System.err.println("Lead routing failed.");
            exception.printStackTrace();
        }
    }

    private static List<ScoredLead> fetchScoredLeads(Connection connection) throws Exception {
        String query = """
                SELECT
                    l.lead_id,
                    l.assigned_sales_rep_id,
                    l.service_category,
                    l.budget_range,
                    l.urgency_level,
                    l.source_channel,
                    ls.total_score,
                    ls.lead_quality
                FROM leads l
                JOIN lead_scores ls
                    ON l.lead_id = ls.lead_id;
                """;

        List<ScoredLead> scoredLeads = new ArrayList<>();

        try (Statement statement = connection.createStatement();
             ResultSet resultSet = statement.executeQuery(query)) {

            while (resultSet.next()) {
                ScoredLead scoredLead = new ScoredLead(
                        resultSet.getObject("lead_id", UUID.class),
                        resultSet.getObject("assigned_sales_rep_id", UUID.class),
                        resultSet.getString("service_category"),
                        resultSet.getString("budget_range"),
                        resultSet.getString("urgency_level"),
                        resultSet.getString("source_channel"),
                        resultSet.getInt("total_score"),
                        resultSet.getString("lead_quality")
                );

                scoredLeads.add(scoredLead);
            }
        }

        return scoredLeads;
    }

    private static void clearExistingRoutingLogs(Connection connection) throws Exception {
        try (Statement statement = connection.createStatement()) {
            statement.executeUpdate("DELETE FROM routing_logs;");
        }
    }

    private static void insertRoutingLogs(Connection connection, List<ScoredLead> scoredLeads) throws Exception {
        String insertQuery = """
                INSERT INTO routing_logs (
                    lead_id,
                    assigned_sales_rep_id,
                    routing_reason,
                    routing_priority,
                    response_status
                )
                VALUES (?, ?, ?, ?, ?);
                """;

        try (PreparedStatement preparedStatement = connection.prepareStatement(insertQuery)) {
            for (ScoredLead lead : scoredLeads) {
                RoutingRecommendation recommendation = createRoutingRecommendation(lead);

                preparedStatement.setObject(1, lead.leadId());
                preparedStatement.setObject(2, lead.assignedSalesRepId());
                preparedStatement.setString(3, recommendation.routingReason());
                preparedStatement.setString(4, recommendation.routingPriority());
                preparedStatement.setString(5, "Pending");

                preparedStatement.addBatch();
            }

            preparedStatement.executeBatch();
        }
    }

    private static RoutingRecommendation createRoutingRecommendation(ScoredLead lead) {
        String priority;
        String reason;

        if ("Hot".equalsIgnoreCase(lead.leadQuality())) {
            priority = "Immediate";
            reason = String.format(
                    "Hot lead with score %d. Prioritize same-day follow-up because urgency is %s, budget is %s, and source is %s.",
                    lead.totalScore(),
                    lead.urgencyLevel(),
                    lead.budgetRange(),
                    lead.sourceChannel()
            );
        } else if ("Warm".equalsIgnoreCase(lead.leadQuality())) {
            priority = "Standard";
            reason = String.format(
                    "Warm lead with score %d. Assign to sales rep and schedule normal follow-up for %s inquiry.",
                    lead.totalScore(),
                    lead.serviceCategory()
            );
        } else {
            priority = "Nurture";
            reason = String.format(
                    "Cold lead with score %d. Add to nurture queue and follow up when engagement improves.",
                    lead.totalScore()
            );
        }

        return new RoutingRecommendation(priority, reason);
    }

    private record ScoredLead(
            UUID leadId,
            UUID assignedSalesRepId,
            String serviceCategory,
            String budgetRange,
            String urgencyLevel,
            String sourceChannel,
            int totalScore,
            String leadQuality
    ) {
    }

    private record RoutingRecommendation(
            String routingPriority,
            String routingReason
    ) {
    }
}