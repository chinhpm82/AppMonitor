package com.monitor;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.List;

public class OverlayWindow extends JFrame {

    private DatabaseManager dbManager;
    private JLabel lblTitle;
    private JLabel lblTotalTime;
    private JComboBox<String> cmbPeriodSelector;
    private JComboBox<String> cmbAppSelector;
    private JTable sessionTable;
    private DefaultTableModel tableModel;
    private Point mousePressPoint;

    private String currentPeriodKey = "day";
    private String currentAppFilter = "All"; // Translated "Tất cả" -> "All"

    public OverlayWindow(DatabaseManager dbManager) {
        this.dbManager = dbManager;

        setTitle("Game Monitor");
        setAlwaysOnTop(true);
        setUndecorated(true);
        setSize(300, 280);
        
        GraphicsEnvironment ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
        Rectangle rect = ge.getDefaultScreenDevice().getDefaultConfiguration().getBounds();
        setLocation(rect.width - 300, 0);

        JPanel mainPanel = new JPanel(new BorderLayout(5, 5));
        mainPanel.setBorder(BorderFactory.createLineBorder(Color.BLACK, 2));

        // --- TOP PANEL ---
        JPanel topPanel = new JPanel();
        topPanel.setLayout(new BoxLayout(topPanel, BoxLayout.Y_AXIS));
        topPanel.setBorder(BorderFactory.createEmptyBorder(5, 5, 0, 5));

        JPanel comboPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 0, 0));
        
        cmbAppSelector = new JComboBox<>();
        cmbAppSelector.setPreferredSize(new Dimension(140, 25));
        reloadAppList();
        
        // Translated Dropdown Items
        String[] periods = {"Today", "This Week", "This Month", "All Time"};
        cmbPeriodSelector = new JComboBox<>(periods);
        cmbPeriodSelector.setPreferredSize(new Dimension(140, 25));

        comboPanel.add(cmbAppSelector);
        comboPanel.add(Box.createHorizontalStrut(5));
        comboPanel.add(cmbPeriodSelector);
        
        topPanel.add(comboPanel);
        topPanel.add(Box.createVerticalStrut(5));

        JPanel timePanel = new JPanel();
        timePanel.setLayout(new BoxLayout(timePanel, BoxLayout.Y_AXIS));
        
        lblTitle = new JLabel("Total Play Time"); // Translated
        lblTitle.setFont(new Font("Arial", Font.PLAIN, 12));
        lblTitle.setAlignmentX(Component.CENTER_ALIGNMENT);

        lblTotalTime = new JLabel("00:00:00");
        lblTotalTime.setFont(new Font("Arial", Font.BOLD, 20));
        lblTotalTime.setAlignmentX(Component.CENTER_ALIGNMENT);

        timePanel.add(lblTitle);
        timePanel.add(lblTotalTime);
        topPanel.add(timePanel);

        mainPanel.add(topPanel, BorderLayout.NORTH);

        // --- TABLE ---
        // Translated Columns
        String[] columnNames = {"App/Web", "Start", "End"};
        tableModel = new DefaultTableModel(columnNames, 0) {
            public boolean isCellEditable(int r, int c) { return false; }
        };
        sessionTable = new JTable(tableModel);
        sessionTable.getColumnModel().getColumn(0).setPreferredWidth(70);
        sessionTable.getColumnModel().getColumn(1).setPreferredWidth(70);
        sessionTable.getColumnModel().getColumn(2).setPreferredWidth(70);

        // [CẬP NHẬT] Đảm bảo bảng lấp đầy vùng nhìn để đẹp hơn
        sessionTable.setFillsViewportHeight(true); 

        mainPanel.add(new JScrollPane(sessionTable), BorderLayout.CENTER);

        MouseAdapter adapter = new MouseAdapter() {
            public void mousePressed(MouseEvent e) { mousePressPoint = e.getPoint(); }
            public void mouseDragged(MouseEvent e) {
                Point curr = e.getLocationOnScreen();
                setLocation(curr.x - mousePressPoint.x, curr.y - mousePressPoint.y);
            }
        };
        mainPanel.addMouseListener(adapter);
        mainPanel.addMouseMotionListener(adapter);

        cmbPeriodSelector.addActionListener(e -> {
            String s = (String) cmbPeriodSelector.getSelectedItem();
            switch (s) {
                case "This Week": currentPeriodKey = "week"; break;
                case "This Month": currentPeriodKey = "month"; break;
                case "All Time": currentPeriodKey = "all"; break;
                default: currentPeriodKey = "day"; break;
            }
            refreshData();
        });

        cmbAppSelector.addActionListener(e -> {
            currentAppFilter = (String) cmbAppSelector.getSelectedItem();
            if (currentAppFilter == null) currentAppFilter = "All";
            updateTitleLabel();
            refreshData();
        });

        add(mainPanel);
        updateTitleLabel();
    }
    
    private void updateTitleLabel() {
        if ("All".equals(currentAppFilter)) {
            lblTitle.setText("Total Play Time");
        } else {
            lblTitle.setText("Time for " + currentAppFilter);
        }
    }

    public void reloadAppList() {
        if (dbManager == null) return;
        Object oldSel = cmbAppSelector.getSelectedItem();
        
        cmbAppSelector.removeAllItems();
        cmbAppSelector.addItem("All"); // Translated

        List<String> allApps = dbManager.getLoggedAppNames();
        allApps.sort(String::compareToIgnoreCase);
        for (String app : allApps) cmbAppSelector.addItem(app);
        
        if (oldSel != null) {
             for (int i=0; i<cmbAppSelector.getItemCount(); i++) {
                if (cmbAppSelector.getItemAt(i).equals(oldSel)) {
                    cmbAppSelector.setSelectedIndex(i);
                    break;
                }
            }
        }
    }

    public void showAndRefresh() {
        reloadAppList();
        refreshData();
        setVisible(true);
    }

    public void hideWindow() { setVisible(false); }

    public void refreshData() {
        if (dbManager == null) return;
        lblTotalTime.setText(dbManager.getTotalTime(currentPeriodKey, currentAppFilter));
        tableModel.setRowCount(0);
        List<String[]> sessions = dbManager.getSessionsByPeriod(currentPeriodKey, currentAppFilter);
        for (String[] row : sessions) tableModel.addRow(row);
    }
}