import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:roblox_monitor/services/app_state.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class SystemTrayManager {
  final SystemTray _systemTray = SystemTray();
  final Menu _menu = Menu();
  final AppState appState;

  SystemTrayManager(this.appState);

  Future<void> init() async {
    List<String> possiblePaths = [];
    
    // In release mode, look in the installed app data folder
    if (kReleaseMode) {
      possiblePaths.add(p.join(p.dirname(Platform.resolvedExecutable), 'data', 'flutter_assets', 'assets', 'app_icon.ico'));
    }
    
    // Debug mode paths - relative to executable location
    final exeDir = p.dirname(Platform.resolvedExecutable);
    possiblePaths.add(p.join(exeDir, 'assets', 'app_icon.ico'));
    possiblePaths.add(p.join(exeDir, 'data', 'flutter_assets', 'assets', 'app_icon.ico'));
    
    // Current directory paths
    possiblePaths.add(p.join(Directory.current.path, 'assets', 'app_icon.ico'));
    possiblePaths.add(p.join(Directory.current.path, 'windows', 'runner', 'resources', 'app_icon.ico'));
    
    // Hardcoded source path for development
    possiblePaths.add('D:\\IT\\GitHub\\RobloxMonitor\\assets\\app_icon.ico');
    possiblePaths.add('D:\\IT\\GitHub\\RobloxMonitor\\windows\\runner\\resources\\app_icon.ico');
    
    String? iconPath;
    for (var path in possiblePaths) {
      debugPrint("Checking for icon at: $path");
      if (File(path).existsSync()) {
        iconPath = path;
        debugPrint("Found icon at: $iconPath");
        break;
      }
    }

    if (iconPath == null) {
      debugPrint("SystemTray Error: No valid icon found in paths: $possiblePaths");
      // Continue without icon or it will definitely fail
    }

    try {
      debugPrint("Initializing SystemTray with: $iconPath");
      // Use a timeout to prevent hanging the whole initialization flow
      await _systemTray.initSystemTray(
        title: "Roblox Monitor",
        iconPath: iconPath ?? "",
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("SystemTray init failed or timed out: $e");
    }

    _systemTray.registerSystemTrayEventHandler((String eventName) async {
      if (eventName == kSystemTrayEventClick) {
        if (await windowManager.isVisible()) {
          await windowManager.hide();
        } else {
          await windowManager.setSize(const Size(320, 180));
          // Show near bottom right
          await windowManager.setAlignment(Alignment.bottomRight);
          await windowManager.show();
          await windowManager.focus();
        }
      } else if (eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu();
      }
    });

    await updateMenu();
  }

  Future<void> updateMenu() async {
    await _menu.buildFrom([
      MenuItemLabel(
        label: appState.isMonitorEnabled ? 'Tắt [OFF]' : 'Bật [ON]',
        onClicked: (menuItem) async {
          if (!appState.isMonitorEnabled) {
             await appState.toggleMonitor(null);
             updateMenu();
          } else {
             // For turning OFF, we need a password, so show the main window
             windowManager.show();
          }
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Mở cửa sổ',
        onClicked: (menuItem) => windowManager.show(),
      ),
      // MenuItemLabel(label: 'Thoát', onClicked: (menuItem) => exit(0)), // User says no exit menu
    ]);
    await _systemTray.setContextMenu(_menu);
  }
}
