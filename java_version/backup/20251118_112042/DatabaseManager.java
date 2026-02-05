package com.monitor;

import java.sql.*;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DatabaseManager {
    private String url = "jdbc:sqlite:playlog.db";
    private Connection conn = null;

    public DatabaseManager() {
        try {
            conn = DriverManager.getConnection(url);
            Statement stmt = conn.createStatement();
            stmt.execute("PRAGMA foreign_keys = ON;");
        } catch (SQLException e) {
            System.out.println("Database connection error: " + e.getMessage());
        }
    }

    public synchronized void initTables() {
        try (Statement stmt = conn.createStatement()) {
            // 1. Sessions
            stmt.execute("CREATE TABLE IF NOT EXISTS play_sessions (id INTEGER PRIMARY KEY AUTOINCREMENT, app_name TEXT, start_time TEXT NOT NULL, end_time TEXT);");
            // 2. Settings
            stmt.execute("CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT);");
            // 3. Apps
            stmt.execute("CREATE TABLE IF NOT EXISTS monitored_apps (process_name TEXT PRIMARY KEY);");
            // 4. Webs
            stmt.execute("CREATE TABLE IF NOT EXISTS monitored_webs (keyword TEXT PRIMARY KEY, display_name TEXT);");

            checkAndInitPassword();
            initDefaultWebs();

        } catch (SQLException e) { e.printStackTrace(); }
    }

    private void checkAndInitPassword() {
        if (getPassword() == null) setPassword("admin");
    }

    private void initDefaultWebs() {
        if (getMonitoredWebs().isEmpty()) {
            addMonitoredWeb("youtube", "YouTube");
            addMonitoredWeb("facebook", "Facebook");
            addMonitoredWeb("tiktok", "TikTok");
        }
    }

    // --- PASSWORD ---
    public String getPassword() {
        String sql = "SELECT value FROM settings WHERE key = 'password'";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) return rs.getString("value");
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public void setPassword(String newPass) {
        String sql = "INSERT OR REPLACE INTO settings(key, value) VALUES('password', ?)";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, newPass);
            pstmt.executeUpdate();
        } catch (SQLException e) { e.printStackTrace(); }
    }

    // --- APPS ---
    public List<String> getMonitoredApps() {
        List<String> apps = new ArrayList<>();
        String sql = "SELECT process_name FROM monitored_apps";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) apps.add(rs.getString("process_name"));
        } catch (SQLException e) { e.printStackTrace(); }
        return apps;
    }

    public void addMonitoredApp(String processName) {
        String sql = "INSERT OR IGNORE INTO monitored_apps(process_name) VALUES(?)";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, processName.toLowerCase());
            pstmt.executeUpdate();
        } catch (SQLException e) { e.printStackTrace(); }
    }

    public void removeMonitoredApp(String processName) {
        String sql = "DELETE FROM monitored_apps WHERE process_name = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, processName);
            pstmt.executeUpdate();
        } catch (SQLException e) { e.printStackTrace(); }
    }

    // --- WEBS ---
    public Map<String, String> getMonitoredWebs() {
        Map<String, String> webs = new HashMap<>();
        String sql = "SELECT keyword, display_name FROM monitored_webs";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                webs.put(rs.getString("keyword"), rs.getString("display_name"));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return webs;
    }

    public void addMonitoredWeb(String keyword, String displayName) {
        String sql = "INSERT OR REPLACE INTO monitored_webs(keyword, display_name) VALUES(?, ?)";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, keyword.toLowerCase());
            pstmt.setString(2, displayName);
            pstmt.executeUpdate();
        } catch (SQLException e) { e.printStackTrace(); }
    }

    public void removeMonitoredWeb(String keyword) {
        String sql = "DELETE FROM monitored_webs WHERE keyword = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, keyword);
            pstmt.executeUpdate();
        } catch (SQLException e) { e.printStackTrace(); }
    }

    public synchronized List<String> getLoggedAppNames() {
        List<String> apps = new ArrayList<>();
        String sql = "SELECT DISTINCT app_name FROM play_sessions " +
                     "UNION SELECT process_name FROM monitored_apps " +
                     "UNION SELECT display_name FROM monitored_webs";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                String name = rs.getString(1);
                if (name != null && !name.trim().isEmpty()) apps.add(name);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return apps;
    }

    // --- SESSIONS ---
    public synchronized long startSession(String appName) {
        String sql = "INSERT INTO play_sessions(app_name, start_time) VALUES(?, ?)";
        try (PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            pstmt.setString(1, appName);
            pstmt.setString(2, LocalDateTime.now().toString());
            pstmt.executeUpdate();
            try (ResultSet generatedKeys = pstmt.getGeneratedKeys()) {
                if (generatedKeys.next()) return generatedKeys.getLong(1);
            }
        } catch (SQLException e) { System.out.println(e.getMessage()); }
        return -1;
    }

    public synchronized void endSession(long sessionId) {
        if (sessionId == -1) return;
        String sql = "UPDATE play_sessions SET end_time = ? WHERE id = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, LocalDateTime.now().toString());
            pstmt.setLong(2, sessionId);
            pstmt.executeUpdate();
        } catch (SQLException e) { System.out.println(e.getMessage()); }
    }

    public synchronized List<String[]> getSessionsByPeriod(String periodKey, String appFilter) {
        List<String[]> sessions = new ArrayList<>();
        DateTimeFormatter dbFormatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME;
        DateTimeFormatter displayFormatter = DateTimeFormatter.ofPattern("HH:mm:ss");

        String sql = "SELECT app_name, start_time, end_time FROM play_sessions WHERE ";
        switch (periodKey) {
            case "day": sql += "DATE(start_time) = DATE('now', 'localtime') "; break;
            case "week": sql += "STRFTIME('%Y-%W', start_time) = STRFTIME('%Y-%W', 'now', 'localtime') "; displayFormatter = DateTimeFormatter.ofPattern("HH:mm (dd/MM)"); break;
            case "month": sql += "STRFTIME('%Y-%m', start_time) = STRFTIME('%Y-%m', 'now', 'localtime') "; displayFormatter = DateTimeFormatter.ofPattern("HH:mm (dd/MM)"); break;
            case "all": sql += "1 = 1 "; displayFormatter = DateTimeFormatter.ofPattern("HH:mm (dd/MM)"); break;
            default: return sessions;
        }

        if (appFilter != null && !appFilter.equals("All")) { // Changed "Tất cả" to "All"
            sql += " AND app_name = '" + appFilter + "' ";
        }

        sql += "ORDER BY start_time DESC LIMIT 10";

        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                String appName = rs.getString("app_name");
                if (appName == null) appName = "Unknown";

                LocalDateTime start = LocalDateTime.parse(rs.getString("start_time"), dbFormatter);
                String endStr = rs.getString("end_time");
                String startDisplay = start.format(displayFormatter);
                String endDisplay = (endStr != null) ? LocalDateTime.parse(endStr, dbFormatter).format(displayFormatter) : "Playing..."; // Translated
                
                sessions.add(new String[]{appName, startDisplay, endDisplay});
            }
        } catch (SQLException e) { System.out.println(e.getMessage()); }
        return sessions;
    }

    public synchronized String getTotalTime(String periodKey, String appFilter) {
        String sql = "SELECT start_time, end_time FROM play_sessions WHERE ";
        switch (periodKey) {
            case "day": sql += "DATE(start_time) = DATE('now', 'localtime')"; break;
            case "week": sql += "STRFTIME('%Y-%W', start_time) = STRFTIME('%Y-%W', 'now', 'localtime')"; break;
            case "month": sql += "STRFTIME('%Y-%m', start_time) = STRFTIME('%Y-%m', 'now', 'localtime')"; break;
            case "all": sql += "1 = 1"; break;
            default: return "00:00:00";
        }

        if (appFilter != null && !appFilter.equals("All")) { // Changed "Tất cả" to "All"
            sql += " AND app_name = '" + appFilter + "' ";
        }

        long totalSeconds = 0;
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                LocalDateTime start = LocalDateTime.parse(rs.getString("start_time"));
                String endStr = rs.getString("end_time");
                LocalDateTime end = (endStr == null) ? LocalDateTime.now() : LocalDateTime.parse(endStr);
                totalSeconds += Duration.between(start, end).toSeconds();
            }
        } catch (SQLException e) { System.out.println(e.getMessage()); }

        return String.format("%02d:%02d:%02d", totalSeconds / 3600, (totalSeconds % 3600) / 60, (totalSeconds % 60));
    }

    public void close() {
        try { if (conn != null) conn.close(); } catch (SQLException e) { System.out.println(e.getMessage()); }
    }
}