package com.monitor;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class ProcessSelectionDialog extends JDialog {
    private JTable table;
    private DefaultTableModel model;
    private String selectedProcess = null;

    private static class ProcessInfo {
        String name, path;
        public ProcessInfo(String n, String p) { name=n; path=p; }
    }

    public ProcessSelectionDialog(JFrame parent) {
        super(parent, "Select Running Application", true); // Translated
        setSize(500, 400);
        setLocationRelativeTo(parent);
        setLayout(new BorderLayout());

        String[] columns = {"Process Name", "Path"};
        model = new DefaultTableModel(columns, 0) {
            public boolean isCellEditable(int r, int c) { return false; }
        };
        table = new JTable(model);
        table.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        table.setAutoCreateRowSorter(true);
        add(new JScrollPane(table), BorderLayout.CENTER);

        JPanel btnPanel = new JPanel();
        JButton btnRefresh = new JButton("Refresh"); // Translated
        JButton btnSelect = new JButton("Select"); // Translated
        JButton btnCancel = new JButton("Cancel"); // Translated
        btnPanel.add(btnRefresh);
        btnPanel.add(btnSelect);
        btnPanel.add(btnCancel);
        add(btnPanel, BorderLayout.SOUTH);

        btnRefresh.addActionListener(e -> loadProcesses());
        btnCancel.addActionListener(e -> dispose());
        btnSelect.addActionListener(e -> {
            int row = table.getSelectedRow();
            if (row != -1) {
                int modelRow = table.convertRowIndexToModel(row);
                selectedProcess = (String) model.getValueAt(modelRow, 0);
                dispose();
            } else JOptionPane.showMessageDialog(this, "Please select a row!");
        });

        loadProcesses();
    }

    private void loadProcesses() {
        model.setRowCount(0);
        List<ProcessInfo> list = new ArrayList<>();
        ProcessHandle.allProcesses().forEach(ph -> ph.info().command().ifPresent(cmd -> {
            String name = cmd;
            if (cmd.contains("\\")) name = cmd.substring(cmd.lastIndexOf("\\") + 1);
            else if (cmd.contains("/")) name = cmd.substring(cmd.lastIndexOf("/") + 1);
            
            if(!name.trim().isEmpty()) {
                list.add(new ProcessInfo(name.toLowerCase(), cmd));
            }
        }));

        Collections.sort(list, Comparator.comparing(p -> p.name));
        for (ProcessInfo p : list) model.addRow(new Object[]{p.name, p.path});
    }

    public String getSelectedProcess() { return selectedProcess; }
}