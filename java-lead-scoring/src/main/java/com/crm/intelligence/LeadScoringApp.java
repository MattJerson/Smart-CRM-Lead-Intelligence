package com.crm.intelligence;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class LeadScoringApp {

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
            List<Lead> leads = fetchLeads(connection);

            if (leads.isEmpty()) {
                System.out.println("No leads found. Load sample leads first.");
                return;
            }

            clearExistingScores(connection);
            insertLeadScores(connection, leads);

            System.out.println("Java Lead Scoring Engine completed.");
            System.out.println("Total leads scored: " + leads.size());

        } catch (Exception exception) {
            System.err.println("Lead scoring failed.");
            exception.printStackTrace();
        }
    }

    private static List<Lead> fetchLeads(Connection connection) throws Exception {
        String query = """
                SELECT
                    lead_id,
                    budget_range,
                    urgency_level,
                    source_channel,
                    inquiry_details,
                    lead_status
                FROM leads;
                """;

        List<Lead> leads = new ArrayList<>();

        try (Statement statement = connection.createStatement();
             ResultSet resultSet = statement.executeQuery(query)) {

            while (resultSet.next()) {
                Lead lead = new Lead(
                        resultSet.getObject("lead_id", UUID.class),
                        resultSet.getString("budget_range"),
                        resultSet.getString("urgency_level"),
                        resultSet.getString("source_channel"),
                        resultSet.getString("inquiry_details"),
                        resultSet.getString("lead_status")
                );

                leads.add(lead);
            }
        }

        return leads;
    }

    private static void clearExistingScores(Connection connection) throws Exception {
        try (Statement statement = connection.createStatement()) {
            statement.executeUpdate("DELETE FROM lead_scores;");
        }
    }

    private static void insertLeadScores(Connection connection, List<Lead> leads) throws Exception {
        String insertQuery = """
                INSERT INTO lead_scores (
                    lead_id,
                    budget_score,
                    urgency_score,
                    source_score,
                    completeness_score,
                    engagement_score,
                    total_score,
                    lead_quality,
                    conversion_likelihood,
                    scoring_notes
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
                """;

        try (PreparedStatement preparedStatement = connection.prepareStatement(insertQuery)) {
            for (Lead lead : leads) {
                LeadScore score = calculateLeadScore(lead);

                preparedStatement.setObject(1, lead.leadId());
                preparedStatement.setInt(2, score.budgetScore());
                preparedStatement.setInt(3, score.urgencyScore());
                preparedStatement.setInt(4, score.sourceScore());
                preparedStatement.setInt(5, score.completenessScore());
                preparedStatement.setInt(6, score.engagementScore());
                preparedStatement.setInt(7, score.totalScore());
                preparedStatement.setString(8, score.leadQuality());
                preparedStatement.setDouble(9, score.conversionLikelihood());
                preparedStatement.setString(10, score.scoringNotes());

                preparedStatement.addBatch();
            }

            preparedStatement.executeBatch();
        }
    }

    private static LeadScore calculateLeadScore(Lead lead) {
        int budgetScore = calculateBudgetScore(lead.budgetRange());
        int urgencyScore = calculateUrgencyScore(lead.urgencyLevel());
        int sourceScore = calculateSourceScore(lead.sourceChannel());
        int completenessScore = calculateCompletenessScore(lead.inquiryDetails());
        int engagementScore = calculateEngagementScore(lead.leadStatus());

        int totalScore = budgetScore
                + urgencyScore
                + sourceScore
                + completenessScore
                + engagementScore;

        String leadQuality = classifyLeadQuality(totalScore);
        double conversionLikelihood = Math.min(95.0, Math.max(5.0, totalScore));

        String scoringNotes = "Java scoring engine v1: score based on budget, urgency, source, inquiry completeness, and lead status.";

        return new LeadScore(
                budgetScore,
                urgencyScore,
                sourceScore,
                completenessScore,
                engagementScore,
                totalScore,
                leadQuality,
                conversionLikelihood,
                scoringNotes
        );
    }

    private static int calculateBudgetScore(String budgetRange) {
        if (budgetRange == null) {
            return 0;
        }

        return switch (budgetRange) {
            case "500k+" -> 25;
            case "250k-500k" -> 20;
            case "100k-250k" -> 15;
            case "50k-100k" -> 10;
            case "Below 50k" -> 5;
            default -> 0;
        };
    }

    private static int calculateUrgencyScore(String urgencyLevel) {
        if (urgencyLevel == null) {
            return 0;
        }

        return switch (urgencyLevel) {
            case "Critical" -> 25;
            case "High" -> 20;
            case "Medium" -> 10;
            case "Low" -> 5;
            default -> 0;
        };
    }

    private static int calculateSourceScore(String sourceChannel) {
        if (sourceChannel == null) {
            return 0;
        }

        return switch (sourceChannel) {
            case "Referral" -> 20;
            case "Google Search" -> 18;
            case "LinkedIn" -> 15;
            case "Website" -> 12;
            case "Email" -> 10;
            case "Facebook" -> 8;
            default -> 0;
        };
    }

    private static int calculateCompletenessScore(String inquiryDetails) {
        if (inquiryDetails == null || inquiryDetails.isBlank()) {
            return 5;
        }

        int length = inquiryDetails.length();

        if (length >= 80) {
            return 15;
        }

        if (length >= 40) {
            return 10;
        }

        return 5;
    }

    private static int calculateEngagementScore(String leadStatus) {
        if (leadStatus == null) {
            return 0;
        }

        return switch (leadStatus) {
            case "Converted" -> 15;
            case "Qualified" -> 12;
            case "Contacted" -> 8;
            case "New" -> 5;
            case "Unqualified" -> 2;
            case "Lost" -> 0;
            default -> 0;
        };
    }

    private static String classifyLeadQuality(int totalScore) {
        if (totalScore >= 70) {
            return "Hot";
        }

        if (totalScore >= 40) {
            return "Warm";
        }

        return "Cold";
    }

    private record Lead(
            UUID leadId,
            String budgetRange,
            String urgencyLevel,
            String sourceChannel,
            String inquiryDetails,
            String leadStatus
    ) {
    }

    private record LeadScore(
            int budgetScore,
            int urgencyScore,
            int sourceScore,
            int completenessScore,
            int engagementScore,
            int totalScore,
            String leadQuality,
            double conversionLikelihood,
            String scoringNotes
    ) {
    }
}