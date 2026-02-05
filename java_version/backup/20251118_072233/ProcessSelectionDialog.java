package com.monitor;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.util.stream.Stream;

public class ProcessSelectionDialog extends JDialog {
    private JTable table;
    private DefaultTableModel model;
    private String selectedProcess = null;

    public ProcessSelectionDialog(JFrame parent) {
        super(parent, "Chọn ứng dụng đang chạy", true);
        setSize(500, 400);
        setLocationRelativeTo(parent);
        setLayout(new BorderLayout());

        // Bảng process
        String[] columns = {"Process Name", "Path"};
        model = new DefaultTableModel(columns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) { return false; }
        };
        table = new JTable(model);
        table.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        add(new JScrollPane(table), BorderLayout.CENTER);

        // Nút bấm
        JPanel btnPanel = new JPanel();
        JButton btnRefresh = new JButton("Làm mới");
        JButton btnSelect = new JButton("Chọn");
        JButton btnCancel = new JButton("Huỷ");

        btnPanel.add(btnRefresh);
        btnPanel.add(btnSelect);
        btnPanel.add(btnCancel);
        add(btnPanel, BorderLayout.SOUTH);

        // Events
        btnRefresh.addActionListener(e -> loadProcesses());
        btnCancel.addActionListener(e -> dispose());
        btnSelect.addActionListener(e -> {
            int row = table.getSelectedRow();
            if (row != -1) {
                // Lấy Process Name
                selectedProcess = (String) model.getValueAt(row, 0);
                dispose();
            } else {
                JOptionPane.showMessageDialog(this, "Vui lòng chọn một dòng!");
            }
        });

        loadProcesses();
    }

    private void loadProcesses() {
        model.setRowCount(0);
        Stream<ProcessHandle> liveProcesses = ProcessHandle.allProcesses();
        
        liveProcesses.forEach(ph -> {
            ph.info().command().ifPresent(cmd -> {
                // Lọc bỏ các process hệ thống nếu cần, hoặc chỉ lấy tên file
                String name = "";
                if (cmd.contains("\\")) {
                    name = cmd.substring(cmd.lastIndexOf("\\") + 1);
                } else if (cmd.contains("/")) {
                    name = cmd.substring(cmd.lastIndexOf("/") + 1);
                } else {
                    name = cmd;
                }
                
                // Chỉ hiện các process có đuôi .exe hoặc tên rõ ràng để tránh rác
                if(!name.isEmpty()) {
                    model.addRow(new Object[]{name.toLowerCase(), cmd});
                }
            });
        });
    }

    public String getSelectedProcess() {
        return selectedProcess;
    }
}