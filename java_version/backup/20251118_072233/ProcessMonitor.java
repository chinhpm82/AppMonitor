package com.monitor;

import javax.swing.SwingUtilities;
import java.util.List;

public class ProcessMonitor implements Runnable {

    private DatabaseManager dbManager;
    private OverlayWindow overlayWindow;
    private boolean isMonitoringEnabled = true;

    private boolean isCurrentlyRunning = false;
    private long currentSessionId = -1;
    private String currentRunningApp = null; // Lưu tên app đang chạy hiện tại
    private List<String> monitoredApps;

    public ProcessMonitor(DatabaseManager dbManager, OverlayWindow overlayWindow) {
        this.dbManager = dbManager;
        this.overlayWindow = overlayWindow;
        refreshMonitoredApps();
    }

    public void setMonitoringEnabled(boolean enabled) {
        this.isMonitoringEnabled = enabled;
        if (!enabled && isCurrentlyRunning) endCurrentSession();
    }

    public void refreshMonitoredApps() {
        this.monitoredApps = dbManager.getMonitoredApps();
    }

    @Override
    public void run() {
        if (!isMonitoringEnabled) return;

        try {
            String detectedApp = getRunningApp(); // Trả về tên app hoặc null

            if (detectedApp != null && !isCurrentlyRunning) {
                // App vừa bật
                System.out.println("Phát hiện: " + detectedApp);
                isCurrentlyRunning = true;
                currentRunningApp = detectedApp;
                
                // Gửi tên app vào hàm startSession
                currentSessionId = dbManager.startSession(detectedApp);
                
                SwingUtilities.invokeLater(() -> overlayWindow.showAndRefresh());

            } else if (detectedApp == null && isCurrentlyRunning) {
                // App vừa tắt
                endCurrentSession();

            } else if (detectedApp != null && isCurrentlyRunning) {
                // Vẫn đang chạy
                SwingUtilities.invokeLater(() -> overlayWindow.refreshData());
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void endCurrentSession() {
        if (currentSessionId != -1) {
            System.out.println("Kết thúc phiên: " + currentRunningApp);
            dbManager.endSession(currentSessionId);
            currentSessionId = -1;
            isCurrentlyRunning = false;
            currentRunningApp = null;
        }
    }

    // Trả về tên process nếu tìm thấy trong danh sách theo dõi, ngược lại trả về null
    private String getRunningApp() {
        if (monitoredApps == null || monitoredApps.isEmpty()) return null;

        // Tìm process đầu tiên khớp
        return ProcessHandle.allProcesses()
                .map(process -> process.info().command().orElse(""))
                .map(String::toLowerCase)
                .filter(cmd -> !cmd.isEmpty())
                .map(cmd -> {
                    for (String appName : monitoredApps) {
                        if (cmd.endsWith(appName) || cmd.contains("\\" + appName) || cmd.contains("/" + appName)) {
                            return appName; // Trả về đúng tên trong DB
                        }
                    }
                    return null;
                })
                .filter(name -> name != null)
                .findFirst()
                .orElse(null);
    }
}