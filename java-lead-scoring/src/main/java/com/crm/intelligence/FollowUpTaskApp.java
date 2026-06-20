package com.crm.intelligence;

import java.sql.Connection;
import java.sql.Date;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class FollowUpTaskApp {

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
            List<RoutedLead> routedLeads = fetchRoutedLeads(connection);

            if (routedLeads.isEmpty()) {
                System.out.println("No routed leads found. Run LeadRoutingApp first.");
                return;
            }

            clearExistingFollowUps(connection);
            insertFollowUps(connection, routedLeads);

            System.out.println("Follow-up Task Generator completed.");
            System.out.println("Total follow-up tasks created: " + routedLeads.size());

        } catch (Exception exception) {
            System.err.println("Follow-up task generation failed.");
            exception.printStackTrace();
        }
    }

    private static List<RoutedLead> fetchRoutedLeads(Connection connection) throws Exception {
        String query = """
                SELECT
                    rl.lead_id,
                    rl.assigned_sales_rep_id,
                    rl.routing_priority,
                    rl.routing_reason,
                    ls.total_score,
                    ls.lead_quality
                FROM routing_logs rl
                JOIN lead_scores ls
                    ON rl.lead_id = ls.lead_id;
                """;

        List<RoutedLead> routedLeads = new ArrayList<>();

        try (Statement statement = connection.createStatement();
             ResultSet resultSet = statement.executeQuery(query)) {

            while (resultSet.next()) {
                RoutedLead routedLead = new RoutedLead(
                        resultSet.getObject("lead_id", UUID.class),
                        resultSet.getObject("assigned_sales_rep_id", UUID.class),
                        resultSet.getString("routing_priority"),
                        resultSet.getString("routing_reason"),
                        resultSet.getInt("total_score"),
                        resultSet.getString("lead_quality")
                );

                routedLeads.add(routedLead);
            }
        }

        return routedLeads;
    }

    private static void clearExistingFollowUps(Connection connection) throws Exception {
        try (Statement statement = connection.createStatement()) {
            statement.executeUpdate("DELETE FROM follow_ups;");
        }
    }

    private static void insertFollowUps(Connection connection, List<RoutedLead> routedLeads) throws Exception {
        String insertQuery = """
                INSERT INTO follow_ups (
                    lead_id,
                    sales_rep_id,
                    follow_up_type,
                    due_date,
                    status,
                    notes
                )
                VALUES (?, ?, ?, ?, ?, ?);
                """;

        try (PreparedStatement preparedStatement = connection.prepareStatement(insertQuery)) {
            for (RoutedLead lead : routedLeads) {
                FollowUpRecommendation recommendation = createFollowUpRecommendation(lead);

                preparedStatement.setObject(1, lead.leadId());
                preparedStatement.setObject(2, lead.salesRepId());
                preparedStatement.setString(3, recommendation.followUpType());
                preparedStatement.setDate(4, Date.valueOf(recommendation.dueDate()));
                preparedStatement.setString(5, "Pending");
                preparedStatement.setString(6, recommendation.notes());

                preparedStatement.addBatch();
            }

            preparedStatement.executeBatch();
        }
    }

    private static FollowUpRecommendation createFollowUpRecommendation(RoutedLead lead) {
        LocalDate today = LocalDate.now();

        if ("Immediate".equalsIgnoreCase(lead.routingPriority())) {
            return new FollowUpRecommendation(
                    "Same-Day Call",
                    today,
                    "Immediate follow-up required. Hot lead with score "
                            + lead.totalScore()
                            + ". Routing reason: "
                            + lead.routingReason()
            );
        }

        if ("Standard".equalsIgnoreCase(lead.routingPriority())) {
            return new FollowUpRecommendation(
                    "Sales Follow-Up",
                    today.plusDays(2),
                    "Standard follow-up recommended within 2 days. Lead quality: "
                            + lead.leadQuality()
                            + ", score: "
                            + lead.totalScore()
            );
        }

        return new FollowUpRecommendation(
                "Nurture Email",
                today.plusDays(7),
                "Lower-priority nurture follow-up. Lead quality: "
                        + lead.leadQuality()
                        + ", score: "
                        + lead.totalScore()
        );
    }

    private record RoutedLead(
            UUID leadId,
            UUID salesRepId,
            String routingPriority,
            String routingReason,
            int totalScore,
            String leadQuality
    ) {
    }

    private record FollowUpRecommendation(
            String followUpType,
            LocalDate dueDate,
            String notes
    ) {
    }
}