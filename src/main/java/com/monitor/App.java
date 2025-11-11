package com.monitor;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.image.BufferedImage; // Đảm bảo đã import
import java.io.IOException;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import javax.imageio.ImageIO;

public class App {

    // --- CẤU HÌNH ---
    public static final String PASSWORD = "@Hanoi123"; // Đặt mật khẩu thoát của bạn ở đây
    public static final String PROCESS_NAME = "robloxplayerbeta.exe"; // Nhớ đổi tên này nếu cần
    // ------------------

    private static OverlayWindow overlayWindow;
    private static DatabaseManager dbManager;
    private static ProcessMonitor processMonitor;
    private static ScheduledExecutorService scheduler;

    public static void main(String[] args) {
        // 1. Khởi tạo Database
        dbManager = new DatabaseManager();
        dbManager.createNewTable();

        // 2. Khởi tạo Giao diện (ẩn)
        overlayWindow = new OverlayWindow(dbManager);

        // 3. Khởi tạo Bộ giám sát
        processMonitor = new ProcessMonitor(PROCESS_NAME, dbManager, overlayWindow);

        // 4. Thiết lập System Tray
        if (!SystemTray.isSupported()) {
            System.out.println("SystemTray cannot support!");
            return;
        }

        try {
            setupTray();
        } catch (IOException | AWTException e) {
            e.printStackTrace();
        }

        // 5. Bắt đầu giám sát (chạy nền)
        // Kiểm tra mỗi 5 giây
        scheduler = Executors.newSingleThreadScheduledExecutor();
        scheduler.scheduleAtFixedRate(processMonitor, 0, 5, TimeUnit.SECONDS);

        System.out.println("Application started.");
    }

    private static void setupTray() throws IOException, AWTException {
        // Tải ảnh icon (Bạn cần tạo 1 file icon.png 16x16)
        // Tạm thời, chúng ta tự tạo 1 ảnh đơn giản
        Image image = new BufferedImage(16, 16, BufferedImage.TYPE_INT_RGB);
        image.getGraphics().drawString("R", 3, 13); // Vẽ chữ 'R'

        // Tạo PopupMenu
        PopupMenu trayMenu = new PopupMenu();

        // Menu item: Hiển thị
        MenuItem showItem = new MenuItem("Show windows");
        showItem.addActionListener(e -> overlayWindow.showAndRefresh());
        trayMenu.add(showItem);

        // --- THAY ĐỔI: THÊM MENU "ẨN" ---
        MenuItem hideItem = new MenuItem("Hide windows");
        hideItem.addActionListener(e -> overlayWindow.hideWindow());
        trayMenu.add(hideItem);
        // --- KẾT THÚC THAY ĐỔI ---

        trayMenu.addSeparator(); // Thêm 1 đường kẻ ngang

        // Menu item: Thoát
        MenuItem exitItem = new MenuItem("Quit (require password)");
        exitItem.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                // Hiển thị hộp thoại nhập mật khẩu
                JPasswordField passwordField = new JPasswordField();
                int option = JOptionPane.showConfirmDialog(
                        null,
                        passwordField,
                        "Enter password to quit:",
                        JOptionPane.OK_CANCEL_OPTION,
                        JOptionPane.WARNING_MESSAGE
                );

                if (option == JOptionPane.OK_OPTION) {
                    String inputPassword = new String(passwordField.getPassword());
                    if (PASSWORD.equals(inputPassword)) {
                        // Tắt bộ giám sát và thoát
                        scheduler.shutdownNow();
                        dbManager.close();
                        System.exit(0);
                    } else {
                        JOptionPane.showMessageDialog(null, "Wrong password!", "Fail", JOptionPane.ERROR_MESSAGE);
                    }
                }
            }
        });
        trayMenu.add(exitItem);

        // Tạo TrayIcon
        TrayIcon trayIcon = new TrayIcon(image, "Roblox Monitor", trayMenu);
        trayIcon.setImageAutoSize(true);
        SystemTray.getSystemTray().add(trayIcon);
    }
}