package com.monitor;

import javax.swing.*;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

public class App {
    public static final String DEFAULT_PASSWORD = "admin";

    private static OverlayWindow overlayWindow;
    private static ManageWindow manageWindow;
    private static DatabaseManager dbManager;
    private static ProcessMonitor processMonitor;
    private static ScheduledExecutorService scheduler;

    private static MenuItem showItem;
    private static MenuItem hideItem;

    public static void main(String[] args) {
        dbManager = new DatabaseManager();
        dbManager.initTables();

        overlayWindow = new OverlayWindow(dbManager);
        processMonitor = new ProcessMonitor(dbManager, overlayWindow);
        manageWindow = new ManageWindow(dbManager, processMonitor, overlayWindow);

        if (!SystemTray.isSupported()) {
            System.out.println("SystemTray not supported!");
            return;
        }
        try { setupTray(); } catch (Exception e) { e.printStackTrace(); }

        scheduler = Executors.newSingleThreadScheduledExecutor();
        scheduler.scheduleAtFixedRate(processMonitor, 0, 5, TimeUnit.SECONDS);

        checkPasswordStatus();
        System.out.println("App started.");
    }

    public static void checkPasswordStatus() {
        String currentPass = dbManager.getPassword();
        
        if (DEFAULT_PASSWORD.equals(currentPass)) {
            processMonitor.setMonitoringEnabled(false);
            if(showItem != null) showItem.setEnabled(false);
            if(hideItem != null) hideItem.setEnabled(false);
            
            SwingUtilities.invokeLater(() -> {
                JOptionPane.showMessageDialog(null, 
                    "First run detected: Please change the default password (admin).", 
                    "Security Alert", JOptionPane.WARNING_MESSAGE);
                manageWindow.focusPasswordTab();
                manageWindow.setVisible(true);
                
                manageWindow.addWindowListener(new java.awt.event.WindowAdapter() {
                    public void windowClosing(java.awt.event.WindowEvent e) {
                        checkPasswordStatus();
                    }
                });
            });
        } else {
            processMonitor.setMonitoringEnabled(true);
            if(showItem != null) showItem.setEnabled(true);
            if(hideItem != null) hideItem.setEnabled(true);
        }
    }

    private static void setupTray() throws Exception {
        Image image = new BufferedImage(16, 16, BufferedImage.TYPE_INT_RGB);
        Graphics g = image.getGraphics();
        g.setColor(Color.WHITE); g.fillRect(0,0,16,16);
        g.setColor(Color.BLUE); g.drawString("M", 3, 13);

        PopupMenu trayMenu = new PopupMenu();

        showItem = new MenuItem("Show Overlay"); // Translated
        showItem.addActionListener(e -> overlayWindow.showAndRefresh());
        trayMenu.add(showItem);

        hideItem = new MenuItem("Hide Overlay"); // Translated
        hideItem.addActionListener(e -> overlayWindow.hideWindow());
        trayMenu.add(hideItem);

        trayMenu.addSeparator();

        MenuItem manageItem = new MenuItem("Manage..."); // Translated
        manageItem.addActionListener(e -> showManageWindowAuth());
        trayMenu.add(manageItem);

        trayMenu.addSeparator();

        MenuItem exitItem = new MenuItem("Quit"); // Translated
        exitItem.addActionListener(e -> requestExit());
        trayMenu.add(exitItem);

        TrayIcon trayIcon = new TrayIcon(image, "Game Monitor", trayMenu);
        trayIcon.setImageAutoSize(true);
        SystemTray.getSystemTray().add(trayIcon);
    }

    private static void showManageWindowAuth() {
        if (DEFAULT_PASSWORD.equals(dbManager.getPassword())) {
            manageWindow.setVisible(true);
            return;
        }
        JPasswordField pf = new JPasswordField();
        int ok = JOptionPane.showConfirmDialog(null, pf, "Enter Password:", JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);
        if (ok == JOptionPane.OK_OPTION) {
            if (new String(pf.getPassword()).equals(dbManager.getPassword())) {
                manageWindow.refreshAllData(); // Ensure fresh data on open
                manageWindow.setVisible(true);
            } else {
                JOptionPane.showMessageDialog(null, "Wrong Password!", "Error", JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    private static void requestExit() {
        JPasswordField pf = new JPasswordField();
        int ok = JOptionPane.showConfirmDialog(null, pf, "Enter Password to Quit:", JOptionPane.OK_CANCEL_OPTION, JOptionPane.WARNING_MESSAGE);
        if (ok == JOptionPane.OK_OPTION) {
            if (new String(pf.getPassword()).equals(dbManager.getPassword())) {
                scheduler.shutdownNow();
                dbManager.close();
                System.exit(0);
            } else {
                JOptionPane.showMessageDialog(null, "Wrong Password!", "Error", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
}