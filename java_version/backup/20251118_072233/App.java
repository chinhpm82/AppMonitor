package com.monitor;

import javax.swing.*;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

public class App {

    // Mặc định ban đầu
    public static final String DEFAULT_PASSWORD = "admin"; 

    private static OverlayWindow overlayWindow;
    private static ManageWindow manageWindow;
    private static DatabaseManager dbManager;
    private static ProcessMonitor processMonitor;
    private static ScheduledExecutorService scheduler;

    // Các Menu Item cần quản lý bật/tắt
    private static MenuItem showItem;
    private static MenuItem hideItem;
    private static MenuItem manageItem;
    private static TrayIcon trayIcon;

    public static void main(String[] args) {
        // 1. Khởi tạo Database
        dbManager = new DatabaseManager();
        dbManager.initTables(); // Khởi tạo bảng & pass mặc định

        // 2. Khởi tạo Giao diện
        overlayWindow = new OverlayWindow(dbManager);
        
        // 3. Khởi tạo Monitor (ban đầu chưa chạy vội)
        processMonitor = new ProcessMonitor(dbManager, overlayWindow);

        // 4. Khởi tạo cửa sổ Manage
        manageWindow = new ManageWindow(dbManager, processMonitor);

        // 5. System Tray
        if (!SystemTray.isSupported()) {
            System.out.println("SystemTray not supported!");
            return;
        }
        try {
            setupTray();
        } catch (Exception e) {
            e.printStackTrace();
        }

        // 6. Chạy Monitor (nhưng Monitor sẽ tự check cờ isMonitoringEnabled)
        scheduler = Executors.newSingleThreadScheduledExecutor();
        scheduler.scheduleAtFixedRate(processMonitor, 0, 5, TimeUnit.SECONDS);

        // 7. KIỂM TRA TRẠNG THÁI MẬT KHẨU LẦN ĐẦU
        checkPasswordStatus();

        System.out.println("App started.");
    }

    // Hàm kiểm tra logic mật khẩu
    public static void checkPasswordStatus() {
        String currentPass = dbManager.getPassword();
        
        if (DEFAULT_PASSWORD.equals(currentPass)) {
            // NẾU LÀ MẬT KHẨU MẶC ĐỊNH
            System.out.println("Mật khẩu mặc định được phát hiện. Yêu cầu đổi.");
            
            // Vô hiệu hoá chức năng
            processMonitor.setMonitoringEnabled(false); 
            if(showItem != null) showItem.setEnabled(false);
            if(hideItem != null) hideItem.setEnabled(false);
            
            // Hiển thị thông báo và mở cửa sổ Manage -> Tab đổi pass
            SwingUtilities.invokeLater(() -> {
                JOptionPane.showMessageDialog(null, 
                    "Đây là lần chạy đầu tiên (hoặc DB đã bị reset).\n" +
                    "Mật khẩu hiện tại là: " + DEFAULT_PASSWORD + "\n" +
                    "Vui lòng đổi mật khẩu để kích hoạt tính năng giám sát.", 
                    "Yêu cầu bảo mật", JOptionPane.WARNING_MESSAGE);
                
                manageWindow.focusPasswordTab();
                manageWindow.setVisible(true);
                
                // Lắng nghe khi cửa sổ Manage đóng để kiểm tra lại
                manageWindow.addWindowListener(new java.awt.event.WindowAdapter() {
                    @Override
                    public void windowClosing(java.awt.event.WindowEvent windowEvent) {
                        checkPasswordStatus(); // Kiểm tra lại khi tắt cửa sổ
                    }
                });
            });

        } else {
            // NẾU MẬT KHẨU ĐÃ ĐƯỢC ĐỔI (AN TOÀN)
            System.out.println("Mật khẩu an toàn. Kích hoạt giám sát.");
            
            processMonitor.setMonitoringEnabled(true);
            if(showItem != null) showItem.setEnabled(true);
            if(hideItem != null) hideItem.setEnabled(true);
        }
    }

    private static void setupTray() throws Exception {
        Image image = new BufferedImage(16, 16, BufferedImage.TYPE_INT_RGB);
        Graphics g = image.getGraphics();
        g.setColor(Color.WHITE);
        g.fillRect(0,0,16,16);
        g.setColor(Color.BLACK);
        g.drawString("M", 3, 13);

        PopupMenu trayMenu = new PopupMenu();

        // Menu: Show/Hide (Ban đầu có thể bị disable)
        showItem = new MenuItem("Show Overlay");
        showItem.addActionListener(e -> overlayWindow.showAndRefresh());
        trayMenu.add(showItem);

        hideItem = new MenuItem("Hide Overlay");
        hideItem.addActionListener(e -> overlayWindow.hideWindow());
        trayMenu.add(hideItem);

        trayMenu.addSeparator();

        // Menu: Manage (Yêu cầu pass)
        manageItem = new MenuItem("Manage...");
        manageItem.addActionListener(e -> showManageWindowAuth());
        trayMenu.add(manageItem);

        trayMenu.addSeparator();

        // Menu: Quit (Yêu cầu pass)
        MenuItem exitItem = new MenuItem("Quit");
        exitItem.addActionListener(e -> requestExit());
        trayMenu.add(exitItem);

        trayIcon = new TrayIcon(image, "Game Monitor", trayMenu);
        trayIcon.setImageAutoSize(true);
        SystemTray.getSystemTray().add(trayIcon);
    }

    // Hàm yêu cầu mật khẩu trước khi mở Manage
    private static void showManageWindowAuth() {
        // Nếu đang dùng mật khẩu mặc định thì cho vào luôn để đổi
        if (DEFAULT_PASSWORD.equals(dbManager.getPassword())) {
            manageWindow.setVisible(true);
            return;
        }

        // Nếu không thì bắt nhập pass
        String input = JOptionPane.showInputDialog("Nhập mật khẩu quản lý:");
        if (input != null && input.equals(dbManager.getPassword())) {
            manageWindow.loadApps(); // Load danh sách app
            manageWindow.setVisible(true);
        } else if (input != null) {
            JOptionPane.showMessageDialog(null, "Sai mật khẩu!");
        }
    }

    // Hàm yêu cầu mật khẩu trước khi thoát
    private static void requestExit() {
        JPasswordField pf = new JPasswordField();
        int ok = JOptionPane.showConfirmDialog(null, pf, "Nhập mật khẩu để thoát:", JOptionPane.OK_CANCEL_OPTION);
        if (ok == JOptionPane.OK_OPTION) {
            String pass = new String(pf.getPassword());
            if (pass.equals(dbManager.getPassword())) {
                scheduler.shutdownNow();
                dbManager.close();
                System.exit(0);
            } else {
                JOptionPane.showMessageDialog(null, "Sai mật khẩu!");
            }
        }
    }
}