package com.monitor;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;

public class ManageWindow extends JFrame {
    private DatabaseManager dbManager;
    private ProcessMonitor processMonitor; // Để cập nhật ngay khi thêm/xoá

    // Tab Apps
    private DefaultTableModel appModel;
    private JTable appTable;

    // Tab Password
    private JPasswordField txtOldPass;
    private JPasswordField txtNewPass;
    private JPasswordField txtConfirmPass;

    public ManageWindow(DatabaseManager dbManager, ProcessMonitor processMonitor) {
        this.dbManager = dbManager;
        this.processMonitor = processMonitor;

        setTitle("Quản lý Monitoring");
        setSize(500, 400);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(JFrame.HIDE_ON_CLOSE);

        JTabbedPane tabbedPane = new JTabbedPane();

        // --- TAB 1: DANH SÁCH ỨNG DỤNG ---
        JPanel pnlApps = new JPanel(new BorderLayout());
        
        // Bảng
        appModel = new DefaultTableModel(new String[]{"Tên Process"}, 0);
        appTable = new JTable(appModel);
        pnlApps.add(new JScrollPane(appTable), BorderLayout.CENTER);

        // Nút điều khiển
        JPanel pnlAppBtns = new JPanel();
        JButton btnAdd = new JButton("Thêm ứng dụng đang mở");
        JButton btnRemove = new JButton("Xoá dòng chọn");
        pnlAppBtns.add(btnAdd);
        pnlAppBtns.add(btnRemove);
        pnlApps.add(pnlAppBtns, BorderLayout.SOUTH);

        // Logic Thêm
        btnAdd.addActionListener(e -> {
            ProcessSelectionDialog dialog = new ProcessSelectionDialog(this);
            dialog.setVisible(true);
            String selected = dialog.getSelectedProcess();
            if (selected != null) {
                dbManager.addMonitoredApp(selected);
                loadApps();
                processMonitor.refreshMonitoredApps();
                JOptionPane.showMessageDialog(this, "Đã thêm: " + selected);
            }
        });

        // Logic Xoá
        btnRemove.addActionListener(e -> {
            int row = appTable.getSelectedRow();
            if (row != -1) {
                String name = (String) appModel.getValueAt(row, 0);
                dbManager.removeMonitoredApp(name);
                loadApps();
                processMonitor.refreshMonitoredApps();
            }
        });

        tabbedPane.addTab("Ứng dụng theo dõi", pnlApps);

        // --- TAB 2: ĐỔI MẬT KHẨU ---
        JPanel pnlPass = new JPanel(new GridBagLayout());
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(5, 5, 5, 5);
        gbc.fill = GridBagConstraints.HORIZONTAL;

        txtOldPass = new JPasswordField(15);
        txtNewPass = new JPasswordField(15);
        txtConfirmPass = new JPasswordField(15);
        JButton btnChangePass = new JButton("Đổi mật khẩu");

        gbc.gridx = 0; gbc.gridy = 0; pnlPass.add(new JLabel("Mật khẩu cũ:"), gbc);
        gbc.gridx = 1; pnlPass.add(txtOldPass, gbc);

        gbc.gridx = 0; gbc.gridy = 1; pnlPass.add(new JLabel("Mật khẩu mới:"), gbc);
        gbc.gridx = 1; pnlPass.add(txtNewPass, gbc);

        gbc.gridx = 0; gbc.gridy = 2; pnlPass.add(new JLabel("Nhập lại mới:"), gbc);
        gbc.gridx = 1; pnlPass.add(txtConfirmPass, gbc);

        gbc.gridx = 1; gbc.gridy = 3; pnlPass.add(btnChangePass, gbc);

        btnChangePass.addActionListener(e -> changePassword());

        tabbedPane.addTab("Bảo mật", pnlPass);

        add(tabbedPane);
    }

    public void loadApps() {
        appModel.setRowCount(0);
        for (String app : dbManager.getMonitoredApps()) {
            appModel.addRow(new Object[]{app});
        }
    }

    // Chuyển sang tab đổi pass (dùng khi ép buộc đổi)
    public void focusPasswordTab() {
        JTabbedPane tabs = (JTabbedPane) getContentPane().getComponent(0);
        tabs.setSelectedIndex(1);
    }

    private void changePassword() {
        String oldP = new String(txtOldPass.getPassword());
        String newP = new String(txtNewPass.getPassword());
        String confP = new String(txtConfirmPass.getPassword());

        String currentDbPass = dbManager.getPassword();

        if (!oldP.equals(currentDbPass)) {
            JOptionPane.showMessageDialog(this, "Mật khẩu cũ không đúng!", "Lỗi", JOptionPane.ERROR_MESSAGE);
            return;
        }

        if (newP.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Mật khẩu mới không được để trống!", "Lỗi", JOptionPane.ERROR_MESSAGE);
            return;
        }

        if (!newP.equals(confP)) {
            JOptionPane.showMessageDialog(this, "Mật khẩu xác nhận không khớp!", "Lỗi", JOptionPane.ERROR_MESSAGE);
            return;
        }

        dbManager.setPassword(newP);
        JOptionPane.showMessageDialog(this, "Đổi mật khẩu thành công!");
        
        // Xoá trắng fields
        txtOldPass.setText("");
        txtNewPass.setText("");
        txtConfirmPass.setText("");
        
        // Thông báo cho App biết trạng thái pass đã thay đổi (Nếu cần)
        // Ở đây ta đơn giản hoá: Người dùng sẽ phải khởi động lại hoặc App tự check lại sau
    }
}