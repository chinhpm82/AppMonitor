package com.monitor;

import javax.swing.SwingUtilities;

public class ProcessMonitor implements Runnable {

    private String processName;
    private DatabaseManager dbManager;
    private OverlayWindow overlayWindow;

    private boolean isCurrentlyRunning = false;
    private long currentSessionId = -1;

    public ProcessMonitor(String processName, DatabaseManager dbManager, OverlayWindow overlayWindow) {
        this.processName = processName.toLowerCase();
        this.dbManager = dbManager;
        this.overlayWindow = overlayWindow;
    }

    @Override
    public void run() {
        try {
            boolean found = isProcessRunning();

            if (found && !isCurrentlyRunning) {
                // Game VỪA MỚI BẬT
                System.out.println("Phát hiện " + processName + ". Bắt đầu phiên.");
                isCurrentlyRunning = true;
                currentSessionId = dbManager.startSession();

                // Hiển thị cửa sổ (Phải chạy trên luồng EDT của Swing)
                SwingUtilities.invokeLater(() -> overlayWindow.showAndRefresh());

            } else if (!found && isCurrentlyRunning) {
                // Game VỪA MỚI TẮT
                System.out.println(processName + " đã tắt. Kết thúc phiên.");
                isCurrentlyRunning = false;
                dbManager.endSession(currentSessionId);
                currentSessionId = -1;

                // --- ĐÃ XÓA ---
                // Dòng code tự động ẩn cửa sổ đã bị xóa (hoặc vô hiệu hóa)
                // SwingUtilities.invokeLater(() -> overlayWindow.hideWindow());
                // --- KẾT THÚC THAY ĐỔI ---

            } else if (found && isCurrentlyRunning) {
                // Game VẪN ĐANG CHẠY
                // Cập nhật dữ liệu trên cửa sổ
                SwingUtilities.invokeLater(() -> overlayWindow.refreshData());
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // Kiểm tra xem process có đang chạy không (dùng Java 9+ Process API)
    private boolean isProcessRunning() {
        return ProcessHandle.allProcesses()
                .anyMatch(process -> process.info().command()
                        .map(cmd -> cmd.toLowerCase().contains(processName))
                        .orElse(false));
    }
}