package com.monitor;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.List;

public class OverlayWindow extends JFrame {

    private DatabaseManager dbManager;
    
    // UI Components
    private JLabel lblTitle;
    private JLabel lblTotalTime;
    private JComboBox<String> cmbPeriodSelector;
    private JComboBox<String> cmbAppSelector; // Dropdown mới cho App
    private JTable sessionTable;
    private DefaultTableModel tableModel;
    private Point mousePressPoint;

    // State
    private String currentPeriodKey = "day";
    private String currentAppFilter = "Tất cả"; // Mặc định là tất cả

    public OverlayWindow(DatabaseManager dbManager) {
        this.dbManager = dbManager;

        // --- Cài đặt cửa sổ ---
        setTitle("Giám sát Game");
        setAlwaysOnTop(true);
        setUndecorated(true);
        int windowWidth = 280;
        int windowHeight = 280; // Tăng chiều cao xíu vì có thêm dropdown
        setSize(windowWidth, windowHeight);

        GraphicsEnvironment ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
        Rectangle rect = ge.getDefaultScreenDevice().getDefaultConfiguration().getBounds();
        setLocation(rect.width - windowWidth, 0);

        // --- Nội dung chính ---
        JPanel mainPanel = new JPanel(new BorderLayout(5, 5));
        mainPanel.setBorder(BorderFactory.createLineBorder(Color.BLACK, 2));

        // --- Panel Phía Trên ---
        JPanel topPanel = new JPanel();
        topPanel.setLayout(new BoxLayout(topPanel, BoxLayout.Y_AXIS)); 
        topPanel.setBorder(BorderFactory.createEmptyBorder(5, 5, 0, 5));

        // 1. Panel chứa 2 Dropdown (Hàng ngang)
        JPanel comboPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 0, 0));
        
        // Dropdown App
        cmbAppSelector = new JComboBox<>();
        cmbAppSelector.setPreferredSize(new Dimension(130, 25));
        cmbAppSelector.addItem("Tất cả");
        // Load danh sách app
        reloadAppList();
        
        // Dropdown Thời gian
        String[] periods = {"Hôm nay", "Tuần này", "Tháng này", "Tất cả"};
        cmbPeriodSelector = new JComboBox<>(periods);
        cmbPeriodSelector.setPreferredSize(new Dimension(130, 25));
        
        comboPanel.add(cmbAppSelector);
        comboPanel.add(Box.createHorizontalStrut(5)); // Khoảng cách
        comboPanel.add(cmbPeriodSelector);

        topPanel.add(comboPanel);
        topPanel.add(Box.createVerticalStrut(5));

        // 2. Đồng hồ & Tiêu đề
        JPanel timePanel = new JPanel();
        timePanel.setLayout(new BoxLayout(timePanel, BoxLayout.Y_AXIS));
        
        lblTitle = new JLabel("Thời gian chơi"); // Tiêu đề động
        lblTitle.setFont(new Font("Arial", Font.PLAIN, 12));
        lblTitle.setAlignmentX(Component.CENTER_ALIGNMENT);

        lblTotalTime = new JLabel("00:00:00");
        lblTotalTime.setFont(new Font("Arial", Font.BOLD, 20));
        lblTotalTime.setAlignmentX(Component.CENTER_ALIGNMENT);

        timePanel.add(lblTitle);
        timePanel.add(lblTotalTime);
        topPanel.add(timePanel);

        mainPanel.add(topPanel, BorderLayout.NORTH);

        // --- Bảng ---
        String[] columnNames = {"Bắt đầu", "Kết thúc"};
        tableModel = new DefaultTableModel(columnNames, 0) {
            @Override public boolean isCellEditable(int r, int c) { return false; }
        };
        sessionTable = new JTable(tableModel);
        JScrollPane scrollPane = new JScrollPane(sessionTable);
        mainPanel.add(scrollPane, BorderLayout.CENTER);

        // --- Logic Kéo Thả ---
        MouseAdapter adapter = new MouseAdapter() {
            @Override public void mousePressed(MouseEvent e) { mousePressPoint = e.getPoint(); }
            @Override public void mouseDragged(MouseEvent e) {
                Point curr = e.getLocationOnScreen();
                setLocation(curr.x - mousePressPoint.x, curr.y - mousePressPoint.y);
            }
        };
        mainPanel.addMouseListener(adapter);
        mainPanel.addMouseMotionListener(adapter);
        // Add listener cho các thành phần con nếu cần thiết để kéo dễ hơn

        // --- Logic ComboBox Thời gian ---
        cmbPeriodSelector.addActionListener(e -> {
            String selected = (String) cmbPeriodSelector.getSelectedItem();
            switch (selected) {
                case "Tuần này": currentPeriodKey = "week"; break;
                case "Tháng này": currentPeriodKey = "month"; break;
                case "Tất cả": currentPeriodKey = "all"; break;
                default: currentPeriodKey = "day"; break;
            }
            refreshData();
        });

        // --- Logic ComboBox App ---
        cmbAppSelector.addActionListener(e -> {
            currentAppFilter = (String) cmbAppSelector.getSelectedItem();
            updateTitleLabel(); // Cập nhật chữ trên label
            refreshData();
        });

        add(mainPanel);
        updateTitleLabel(); // Init label
    }

    // Hàm load lại danh sách app vào dropdown (gọi khi mở hoặc khi thêm app mới)
    public void reloadAppList() {
        if (dbManager == null) return;
        
        // Giữ lại selection cũ nếu có
        Object currentSel = cmbAppSelector.getSelectedItem();
        
        cmbAppSelector.removeAllItems();
        cmbAppSelector.addItem("Tất cả");
        
        List<String> apps = dbManager.getMonitoredApps();
        for (String app : apps) {
            cmbAppSelector.addItem(app);
        }
        
        // Restore selection
        if (currentSel != null) {
            // Check xem item cũ còn tồn tại không
            for (int i=0; i<cmbAppSelector.getItemCount(); i++) {
                if (cmbAppSelector.getItemAt(i).equals(currentSel)) {
                    cmbAppSelector.setSelectedIndex(i);
                    break;
                }
            }
        }
    }
    
    private void updateTitleLabel() {
        if ("Tất cả".equals(currentAppFilter)) {
            lblTitle.setText("Tổng thời gian chơi");
        } else {
            // Yêu cầu: "Thời gian %ứng_dụng_đó%"
            lblTitle.setText("Thời gian " + currentAppFilter);
        }
    }

    public void showAndRefresh() {
        reloadAppList(); // Cập nhật list app đề phòng có app mới thêm
        refreshData();
        setVisible(true);
    }

    public void hideWindow() { setVisible(false); }

    public void refreshData() {
        if (dbManager == null) return;

        // Truyền thêm tham số App Filter
        lblTotalTime.setText(dbManager.getTotalTime(currentPeriodKey, currentAppFilter));

        tableModel.setRowCount(0);
        List<String[]> sessions = dbManager.getSessionsByPeriod(currentPeriodKey, currentAppFilter);
        for (String[] row : sessions) {
            tableModel.addRow(row);
        }
    }
}