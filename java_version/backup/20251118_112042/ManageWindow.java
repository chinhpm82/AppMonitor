package com.monitor;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.util.Map;

public class ManageWindow extends JFrame {
    private DatabaseManager dbManager;
    private ProcessMonitor processMonitor;
    private OverlayWindow overlayWindow;

    private DefaultTableModel appModel;
    private JTable appTable;
    private DefaultTableModel webModel;
    private JTable webTable;

    private JPasswordField txtOldPass;
    private JPasswordField txtNewPass;
    private JPasswordField txtConfirmPass;

    public ManageWindow(DatabaseManager dbManager, ProcessMonitor processMonitor, OverlayWindow overlayWindow) {
        this.dbManager = dbManager;
        this.processMonitor = processMonitor;
        this.overlayWindow = overlayWindow;

        setTitle("Monitor Manager"); // Translated
        setSize(500, 450);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(JFrame.HIDE_ON_CLOSE);

        JTabbedPane tabbedPane = new JTabbedPane();

        // --- TAB 1: APPS ---
        JPanel pnlApps = new JPanel(new BorderLayout());
        appModel = new DefaultTableModel(new String[]{"Process Name (.exe)"}, 0); // Translated
        appTable = new JTable(appModel);
        pnlApps.add(new JScrollPane(appTable), BorderLayout.CENTER);

        JPanel pnlAppBtns = new JPanel();
        JButton btnAddApp = new JButton("Add Running App"); // Translated
        JButton btnRemoveApp = new JButton("Remove"); // Translated
        pnlAppBtns.add(btnAddApp);
        pnlAppBtns.add(btnRemoveApp);
        pnlApps.add(pnlAppBtns, BorderLayout.SOUTH);

        btnAddApp.addActionListener(e -> {
            ProcessSelectionDialog dialog = new ProcessSelectionDialog(this);
            dialog.setVisible(true);
            String selected = dialog.getSelectedProcess();
            if (selected != null) {
                dbManager.addMonitoredApp(selected);
                refreshAllData();
                JOptionPane.showMessageDialog(this, "Added process: " + selected);
            }
        });

        btnRemoveApp.addActionListener(e -> {
            int row = appTable.getSelectedRow();
            if (row != -1) {
                String name = (String) appModel.getValueAt(row, 0);
                dbManager.removeMonitoredApp(name);
                refreshAllData();
            }
        });
        tabbedPane.addTab("Applications", pnlApps); // Translated

        // --- TAB 2: WEBS ---
        JPanel pnlWebs = new JPanel(new BorderLayout());
        webModel = new DefaultTableModel(new String[]{"Title Keyword", "Display Name"}, 0); // Translated
        webTable = new JTable(webModel);
        pnlWebs.add(new JScrollPane(webTable), BorderLayout.CENTER);
        
        JPanel pnlWebBtns = new JPanel();
        JButton btnAddWeb = new JButton("Add Website Manually"); // Translated
        JButton btnRemoveWeb = new JButton("Remove"); // Translated
        pnlWebBtns.add(btnAddWeb);
        pnlWebBtns.add(btnRemoveWeb);
        pnlWebs.add(pnlWebBtns, BorderLayout.SOUTH);
        
        btnAddWeb.addActionListener(e -> {
            JPanel inputPanel = new JPanel(new GridLayout(2, 2, 5, 5));
            JTextField txtKeyword = new JTextField();
            JTextField txtDisplay = new JTextField();
            inputPanel.add(new JLabel("Keyword (e.g., youtube):")); // Translated
            inputPanel.add(txtKeyword);
            inputPanel.add(new JLabel("Display Name (e.g., YouTube):")); // Translated
            inputPanel.add(txtDisplay);
            
            int result = JOptionPane.showConfirmDialog(this, inputPanel, 
                    "Add Monitored Website", JOptionPane.OK_CANCEL_OPTION); // Translated
            
            if (result == JOptionPane.OK_OPTION) {
                String kw = txtKeyword.getText().trim();
                String dp = txtDisplay.getText().trim();
                if (!kw.isEmpty() && !dp.isEmpty()) {
                    dbManager.addMonitoredWeb(kw, dp);
                    refreshAllData();
                } else {
                    JOptionPane.showMessageDialog(this, "Please enter all fields!"); // Translated
                }
            }
        });
        
        btnRemoveWeb.addActionListener(e -> {
            int row = webTable.getSelectedRow();
            if (row != -1) {
                String keyword = (String) webModel.getValueAt(row, 0);
                dbManager.removeMonitoredWeb(keyword);
                refreshAllData();
            }
        });
        
        tabbedPane.addTab("Websites", pnlWebs); // Translated

        // --- TAB 3: SECURITY ---
        JPanel pnlPass = new JPanel(new GridBagLayout());
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(5, 5, 5, 5);
        gbc.fill = GridBagConstraints.HORIZONTAL;

        txtOldPass = new JPasswordField(15);
        txtNewPass = new JPasswordField(15);
        txtConfirmPass = new JPasswordField(15);
        JButton btnChangePass = new JButton("Change Password"); // Translated

        gbc.gridx = 0; gbc.gridy = 0; pnlPass.add(new JLabel("Old Password:"), gbc);
        gbc.gridx = 1; pnlPass.add(txtOldPass, gbc);
        gbc.gridx = 0; gbc.gridy = 1; pnlPass.add(new JLabel("New Password:"), gbc);
        gbc.gridx = 1; pnlPass.add(txtNewPass, gbc);
        gbc.gridx = 0; gbc.gridy = 2; pnlPass.add(new JLabel("Confirm Password:"), gbc);
        gbc.gridx = 1; pnlPass.add(txtConfirmPass, gbc);
        gbc.gridx = 1; gbc.gridy = 3; pnlPass.add(btnChangePass, gbc);

        btnChangePass.addActionListener(e -> changePassword());
        tabbedPane.addTab("Security", pnlPass); // Translated

        add(tabbedPane);
    }

    public void refreshAllData() {
        loadApps();
        loadWebs();
        processMonitor.refreshMonitoredLists();
        overlayWindow.reloadAppList();
    }

    public void loadApps() {
        appModel.setRowCount(0);
        for (String app : dbManager.getMonitoredApps()) appModel.addRow(new Object[]{app});
    }
    
    public void loadWebs() {
        webModel.setRowCount(0);
        Map<String, String> webs = dbManager.getMonitoredWebs();
        for (Map.Entry<String, String> entry : webs.entrySet()) {
            webModel.addRow(new Object[]{entry.getKey(), entry.getValue()});
        }
    }

    public void focusPasswordTab() {
        ((JTabbedPane) getContentPane().getComponent(0)).setSelectedIndex(2);
    }

    private void changePassword() {
        String oldP = new String(txtOldPass.getPassword());
        String newP = new String(txtNewPass.getPassword());
        String confP = new String(txtConfirmPass.getPassword());

        if (!oldP.equals(dbManager.getPassword())) {
            JOptionPane.showMessageDialog(this, "Incorrect old password!", "Error", JOptionPane.ERROR_MESSAGE);
            return;
        }
        if (newP.isEmpty() || !newP.equals(confP)) {
            JOptionPane.showMessageDialog(this, "New password empty or mismatch!", "Error", JOptionPane.ERROR_MESSAGE);
            return;
        }

        dbManager.setPassword(newP);
        JOptionPane.showMessageDialog(this, "Password changed successfully!");
        txtOldPass.setText(""); txtNewPass.setText(""); txtConfirmPass.setText("");
    }
}