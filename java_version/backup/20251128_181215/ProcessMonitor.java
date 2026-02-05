package com.monitor;

import javax.swing.SwingUtilities;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class ProcessMonitor implements Runnable {

    private DatabaseManager dbManager;
    private OverlayWindow overlayWindow;
    private boolean isMonitoringEnabled = true;
    
    private Map<String, Long> activeSessions = new HashMap<>();
    private List<String> monitoredApps;
    private Map<String, String> monitoredWebs = new HashMap<>();

    public ProcessMonitor(DatabaseManager dbManager, OverlayWindow overlayWindow) {
        this.dbManager = dbManager;
        this.overlayWindow = overlayWindow;
        refreshMonitoredLists();
    }

    public void setMonitoringEnabled(boolean enabled) {
        this.isMonitoringEnabled = enabled;
        if (!enabled) endAllSessions();
    }

    public void refreshMonitoredLists() {
        this.monitoredApps = dbManager.getMonitoredApps();
        this.monitoredWebs = dbManager.getMonitoredWebs();
    }

    @Override
    public void run() {
        if (!isMonitoringEnabled) return;

        try {
            boolean hasNewSessionStarted = false;
            boolean isAnyActivityDetected = false;

            List<String> runningProcesses = ProcessHandle.allProcesses()
                    .map(p -> p.info().command().orElse("").toLowerCase())
                    .filter(cmd -> !cmd.isEmpty())
                    .toList();

            String activeWindowTitle = getActiveWindowTitle();

            if (monitoredApps != null) {
                for (String appName : monitoredApps) {
                    String lowerAppName = appName.toLowerCase();

                    if (isBrowser(lowerAppName)) {
                        if (checkProcessRunning(runningProcesses, lowerAppName)) {
                            String detectedWeb = detectWebActivity(activeWindowTitle);
                            if (detectedWeb != null) {
                                handleAppActivity(detectedWeb, true, activeSessions, dbManager);
                                if (!activeSessions.containsKey(detectedWeb.toLowerCase())) hasNewSessionStarted = true;
                                isAnyActivityDetected = true;
                            }
                        }
                        cleanupInactiveWebSessions(activeWindowTitle);
                    } else {
                        boolean isRunning = checkProcessRunning(runningProcesses, lowerAppName);
                        if (isRunning) {
                            handleAppActivity(appName, true, activeSessions, dbManager);
                            if (!activeSessions.containsKey(appName.toLowerCase())) hasNewSessionStarted = true;
                            isAnyActivityDetected = true;
                        } else {
                            handleAppActivity(appName, false, activeSessions, dbManager);
                        }
                    }
                }
            }

            if (hasNewSessionStarted) {
                SwingUtilities.invokeLater(() -> overlayWindow.showAndRefresh());
            } else if (isAnyActivityDetected) {
                SwingUtilities.invokeLater(() -> overlayWindow.refreshData());
            }

        } catch (Exception e) { e.printStackTrace(); }
    }

    private boolean checkProcessRunning(List<String> runningProcesses, String appName) {
        return runningProcesses.stream().anyMatch(cmd ->
                cmd.endsWith(appName) || cmd.contains("\\" + appName) || cmd.contains("/" + appName));
    }

    private void handleAppActivity(String appName, boolean isRunning, Map<String, Long> sessions, DatabaseManager db) {
        String key = appName.toLowerCase();
        if (isRunning) {
            if (!sessions.containsKey(key)) {
                System.out.println("Start session: " + appName);
                long id = db.startSession(appName);
                sessions.put(key, id);
            }
        } else {
            if (sessions.containsKey(key)) {
                System.out.println("End session: " + appName);
                db.endSession(sessions.get(key));
                sessions.remove(key);
            }
        }
    }

    private boolean isBrowser(String processName) {
        return processName.contains("chrome") || processName.contains("msedge") 
            || processName.contains("brave") || processName.contains("firefox") 
            || processName.contains("coccoc") || processName.contains("opera");
    }

    private String detectWebActivity(String windowTitle) {
        if (windowTitle == null || windowTitle.isEmpty()) return null;
        for (Map.Entry<String, String> entry : monitoredWebs.entrySet()) {
            if (windowTitle.toLowerCase().contains(entry.getKey())) return entry.getValue();
        }
        return null; 
    }

    private void cleanupInactiveWebSessions(String currentTitle) {
        Set<String> activeKeys = Set.copyOf(activeSessions.keySet());
        for (String sessionKey : activeKeys) {
            boolean isWebSession = false;
            String matchedKeyword = null;
            for (Map.Entry<String, String> entry : monitoredWebs.entrySet()) {
                if (entry.getValue().equalsIgnoreCase(sessionKey)) {
                    isWebSession = true;
                    matchedKeyword = entry.getKey();
                    break;
                }
            }
            if (isWebSession && matchedKeyword != null) {
                if (currentTitle == null || !currentTitle.toLowerCase().contains(matchedKeyword)) {
                    handleAppActivity(sessionKey, false, activeSessions, dbManager);
                }
            }
        }
    }

    private String getActiveWindowTitle() {
        try {
            String command = "powershell -command \"Get-Process | Where-Object {$_.MainWindowTitle -ne \\\"\\\"} | Select-Object -ExpandProperty MainWindowTitle\"";
            Process p = Runtime.getRuntime().exec(command);
            BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()));
            StringBuilder builder = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) builder.append(line).append(" ");
            return builder.toString();
        } catch (Exception e) { return ""; }
    }

    private void endAllSessions() {
        if (activeSessions.isEmpty()) return;
        for (Map.Entry<String, Long> entry : activeSessions.entrySet()) {
            dbManager.endSession(entry.getValue());
        }
        activeSessions.clear();
    }
}