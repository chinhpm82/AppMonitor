package com.monitor;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*; // Import này đã bao gồm GraphicsEnvironment, GraphicsDevice, Rectangle
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.List;

public class OverlayWindow extends JFrame {

    private DatabaseManager dbManager;
    private JLabel lblTotalTime;
    private JComboBox<String> cmbPeriodSelector;
    private JTable sessionTable;
    private DefaultTableModel tableModel;
    private Point mousePressPoint; // Để kéo thả cửa sổ

    // Biến lưu trữ lựa chọn hiện tại
    private String currentPeriodKey = "day";

    public OverlayWindow(DatabaseManager dbManager) {
        this.dbManager = dbManager;

        // --- Cài đặt cửa sổ ---
        setTitle("Giám sát Roblox");
        setAlwaysOnTop(true);      // Luôn nổi
        setUndecorated(true);      // Không có viền (nút đóng/thu nhỏ)

        // Kích thước nhỏ hơn, cao hơn một chút
        int windowWidth = 280;
        int windowHeight = 240;
        setSize(windowWidth, windowHeight);

        // --- CẬP NHẬT: Đặt vị trí ở góc trên bên phải ---
        GraphicsEnvironment ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
        GraphicsDevice defaultScreen = ge.getDefaultScreenDevice();
        Rectangle rect = defaultScreen.getDefaultConfiguration().getBounds();
        int screenWidth = rect.width;

        // Tọa độ x = (Chiều rộng màn hình) - (Chiều rộng cửa sổ)
        // Tọa độ y = 0 (trên cùng)
        int x = screenWidth - windowWidth;
        int y = 0;
        setLocation(x, y);
        // setLocationRelativeTo(null); // Đã xóa dòng căn giữa


        // --- Thêm nội dung ---
        JPanel mainPanel = new JPanel(new BorderLayout(5, 5));
        mainPanel.setBorder(BorderFactory.createLineBorder(Color.BLACK, 2)); // Viền

        // --- Panel Phía Trên (ComboBox và Đồng hồ) ---
        JPanel topPanel = new JPanel();
        // Dùng layout FlowLayout để các thành phần nằm ngang
        topPanel.setLayout(new FlowLayout(FlowLayout.LEFT, 5, 5));

        // 1. Drop-down
        String[] periods = {"Hôm nay", "Tuần này", "Tháng này", "Tất cả"};
        cmbPeriodSelector = new JComboBox<>(periods);
        topPanel.add(cmbPeriodSelector); // Thêm ComboBox vào

        // 2. Panel cho Đồng hồ (gồm 2 label)
        JPanel timePanel = new JPanel();
        timePanel.setLayout(new BoxLayout(timePanel, BoxLayout.Y_AXIS)); // Xếp dọc

        // Label tiêu đề
        JLabel lblTitle = new JLabel("Tổng thời gian chơi Roblox");
        lblTitle.setFont(new Font("Arial", Font.PLAIN, 12));

        // Đồng hồ (Label)
        lblTotalTime = new JLabel("00:00:00"); // Định dạng HH:MM:SS
        lblTotalTime.setFont(new Font("Arial", Font.BOLD, 20)); // Tăng cỡ chữ lên

        timePanel.add(lblTitle);
        timePanel.add(lblTotalTime);

        topPanel.add(timePanel); // Thêm panel đồng hồ vào
        mainPanel.add(topPanel, BorderLayout.NORTH);

        // --- Bảng danh sách phiên chơi (Chỉ 2 cột) ---
        String[] columnNames = {"Bắt đầu", "Kết thúc"};
        tableModel = new DefaultTableModel(columnNames, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false; // Không cho sửa bảng
            }
        };
        sessionTable = new JTable(tableModel);
        JScrollPane scrollPane = new JScrollPane(sessionTable);
        // Đặt kích thước cho bảng
        scrollPane.setPreferredSize(new Dimension(270, 150));
        mainPanel.add(scrollPane, BorderLayout.CENTER);


        // --- Logic Kéo-Thả cửa sổ ---
        // (Không thay đổi, người dùng vẫn có thể kéo đi nếu muốn)
        MouseAdapter adapter = new MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent e) {
                mousePressPoint = e.getPoint();
            }
            @Override
            public void mouseDragged(MouseEvent e) {
                Point currentPoint = e.getLocationOnScreen();
                setLocation(currentPoint.x - mousePressPoint.x, currentPoint.y - mousePressPoint.y);
            }
        };
        mainPanel.addMouseListener(adapter);
        mainPanel.addMouseMotionListener(adapter);
        topPanel.addMouseListener(adapter);
        topPanel.addMouseMotionListener(adapter);
        timePanel.addMouseListener(adapter);
        timePanel.addMouseMotionListener(adapter);
        lblTitle.addMouseListener(adapter);
        lblTitle.addMouseListener(adapter);
        lblTotalTime.addMouseListener(adapter);
        lblTotalTime.addMouseMotionListener(adapter);

        // --- Logic xử lý khi chọn ComboBox ---
        cmbPeriodSelector.addActionListener(e -> {
            String selectedItem = (String) cmbPeriodSelector.getSelectedItem();

            switch (selectedItem) {
                case "Tuần này":
                    currentPeriodKey = "week";
                    break;
                case "Tháng này":
                    currentPeriodKey = "month";
                    break;
                case "Tất cả":
                    currentPeriodKey = "all";
                    break;
                default: // "Hôm nay"
                    currentPeriodKey = "day";
                    break;
            }
            refreshData();
        });

        add(mainPanel);
    }

    // Hiển thị và làm mới dữ liệu
    public void showAndRefresh() {
        refreshData();
        setVisible(true);
    }

    // Ẩn cửa sổ
    public void hideWindow() {
        setVisible(false);
    }

    // Tải lại dữ liệu từ DB (dựa trên currentPeriodKey)
    public void refreshData() {
        if (dbManager == null) return;

        // Cập nhật tổng thời gian
        lblTotalTime.setText(dbManager.getTotalTime(currentPeriodKey));

        // Cập nhật bảng
        tableModel.setRowCount(0); // Xóa dữ liệu cũ
        List<String[]> sessions = dbManager.getSessionsByPeriod(currentPeriodKey);
        for (String[] row : sessions) {
            tableModel.addRow(row);
        }
    }
}