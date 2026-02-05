package com.monitor;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

public class DatabaseManager {
    private String url = "jdbc:sqlite:playlog.db";
    private Connection conn = null;

    public DatabaseManager() {
        try {
            conn = DriverManager.getConnection(url);
            System.out.println("Kết nối SQLite thành công.");
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    public synchronized void createNewTable() {
        String sql = "CREATE TABLE IF NOT EXISTS play_sessions ("
                + " id INTEGER PRIMARY KEY AUTOINCREMENT,"
                + " start_time TEXT NOT NULL,"
                + " end_time TEXT"
                + ");";
        try (Statement stmt = conn.createStatement()) {
            stmt.execute(sql);
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    // Bắt đầu 1 phiên chơi
    public synchronized long startSession() {
        String sql = "INSERT INTO play_sessions(start_time) VALUES(?)";
        try (PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            pstmt.setString(1, LocalDateTime.now().toString());
            pstmt.executeUpdate();

            try (ResultSet generatedKeys = pstmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    return generatedKeys.getLong(1);
                }
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
        return -1;
    }

    // Kết thúc 1 phiên chơi
    public synchronized void endSession(long sessionId) {
        if (sessionId == -1) return;
        String sql = "UPDATE play_sessions SET end_time = ? WHERE id = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, LocalDateTime.now().toString());
            pstmt.setLong(2, sessionId);
            pstmt.executeUpdate();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    // Lấy 10 phiên chơi gần nhất theo thời gian (day, week, month, all)
    public synchronized List<String[]> getSessionsByPeriod(String periodKey) {
        List<String[]> sessions = new ArrayList<>();
        DateTimeFormatter dbFormatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

        // Mặc định hiển thị HH:mm:ss (cho "Hôm nay")
        DateTimeFormatter displayFormatter = DateTimeFormatter.ofPattern("HH:mm:ss");

        String sql = "SELECT start_time, end_time FROM play_sessions WHERE ";

        switch (periodKey) {
            case "day":
                sql += "DATE(start_time) = DATE('now', 'localtime') ";
                break;
            case "week":
                sql += "STRFTIME('%Y-%W', start_time) = STRFTIME('%Y-%W', 'now', 'localtime') ";
                // Nếu là tuần, tháng, tất cả -> hiển thị thêm ngày cho dễ hiểu
                displayFormatter = DateTimeFormatter.ofPattern("HH:mm (dd/MM)");
                break;
            case "month":
                sql += "STRFTIME('%Y-%m', start_time) = STRFTIME('%Y-%m', 'now', 'localtime') ";
                displayFormatter = DateTimeFormatter.ofPattern("HH:mm (dd/MM)");
                break;
            case "all":
                sql += "1 = 1 "; // Lấy tất cả
                displayFormatter = DateTimeFormatter.ofPattern("HH:mm (dd/MM)");
                break;
            default:
                return sessions; // Trả về danh sách rỗng nếu key sai
        }

        sql += "ORDER BY start_time DESC LIMIT 10"; // Vẫn giới hạn 10 dòng

        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                LocalDateTime start = LocalDateTime.parse(rs.getString("start_time"), dbFormatter);
                String endStr = rs.getString("end_time");

                String startDisplay = start.format(displayFormatter);
                String endDisplay = "Đang chơi...";

                if (endStr != null) {
                    LocalDateTime end = LocalDateTime.parse(endStr, dbFormatter);
                    endDisplay = end.format(displayFormatter);
                }

                // Chỉ trả về 2 cột theo yêu cầu
                sessions.add(new String[]{
                        startDisplay,
                        endDisplay
                });
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
        return sessions;
    }

    // *** CẬP NHẬT ***
    // Tính tổng thời gian chơi (trả về HH:MM:SS)
    public synchronized String getTotalTime(String periodKey) {
        String sql = "SELECT start_time, end_time FROM play_sessions WHERE ";
        switch (periodKey) {
            case "day":
                sql += "DATE(start_time) = DATE('now', 'localtime')";
                break;
            case "week":
                sql += "STRFTIME('%Y-%W', start_time) = STRFTIME('%Y-%W', 'now', 'localtime')";
                break;
            case "month":
                sql += "STRFTIME('%Y-%m', start_time) = STRFTIME('%Y-%m', 'now', 'localtime')";
                break;
            case "all":
                sql += "1 = 1"; // Lấy tất cả
                break;
            default:
                return "000:00:00"; // Định dạng HH:MM:SS
        }

        long totalSeconds = 0;
        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                LocalDateTime start = LocalDateTime.parse(rs.getString("start_time"));
                String endStr = rs.getString("end_time");
                LocalDateTime end = (endStr == null) ? LocalDateTime.now() : LocalDateTime.parse(endStr);
                totalSeconds += Duration.between(start, end).toSeconds();
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }

        // ĐỊNH DẠNG LẠI OUTPUT
        return String.format("%02d:%02d:%02d",
                totalSeconds / 3600,
                (totalSeconds % 3600) / 60,
                (totalSeconds % 60));
    }

    public void close() {
        try {
            if (conn != null) conn.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }
}