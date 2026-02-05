import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:roblox_monitor/services/database_helper.dart';
import 'package:roblox_monitor/services/win32_service.dart';
import 'package:roblox_monitor/utils/constants.dart';
import 'package:window_manager/window_manager.dart';

enum WindowMode { tray, settings }

class AppState extends ChangeNotifier {
  bool _isMonitorEnabled = true;
  bool _isRobloxRunning = false;
  bool _isBrowserRobloxRunning = false;
  
  String? _currentRobloxTitle; 
  String? _currentBrowserTitle;
  
  DateTime? _robloxStartTime;
  DateTime? _browserStartTime;

  int _robloxViolationSeconds = 0;
  int _browserViolationSeconds = 0;

  bool _showWarning = false;
  bool _showOverlay = false;
  String _warningMessage = '';

  // Schedule storage: key: "day_hour" (e.g. "1_18" for Mon 18:00), value: true/false
  Map<String, bool> _scheduleRoblox = {};
  Map<String, bool> _scheduleBrowser = {};

  Timer? _timer;
  bool _isChecking = false;
  bool _isTransitioning = false; // Add lock
  WindowMode _windowMode = WindowMode.tray;

  bool get isTransitioning => _isTransitioning;

  bool get isMonitorEnabled => _isMonitorEnabled;
  bool get showWarning => _showWarning;
  bool get showOverlay => _showOverlay;
  String get warningMessage => _warningMessage;
  WindowMode get windowMode => _windowMode;

  int _todayPlayTimeSeconds = 0;
  int _allowedPlayTimeMinutes = 0;

  Map<String, bool> get scheduleRoblox => _scheduleRoblox;
  Map<String, bool> get scheduleBrowser => _scheduleBrowser;

  AppState() {
    _loadSettings();
    _startMonitor();
    _updateTodayPlayTime();
  }

  Future<void> refreshState() async {
    await _loadSettings();
    await _updateTodayPlayTime();
  }

  Future<void> _loadSettings() async {
    final enabled = await DatabaseHelper.getSetting('monitor_enabled');
    if (enabled != null) {
      _isMonitorEnabled = enabled == 'true';
    }
    
    final allowed = await DatabaseHelper.getSetting('allowed_minutes');
    if (allowed != null) {
      _allowedPlayTimeMinutes = int.tryParse(allowed) ?? 0;
    }

    final schRoblox = await DatabaseHelper.getSetting('schedule_roblox');
    if (schRoblox != null) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(schRoblox));
        _scheduleRoblox = decoded.map((k, v) => MapEntry(k, v as bool));
      } catch (_) {}
    }

    final schBrowser = await DatabaseHelper.getSetting('schedule_browser');
    if (schBrowser != null) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(schBrowser));
        _scheduleBrowser = decoded.map((k, v) => MapEntry(k, v as bool));
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> saveSchedules(Map<String, bool> roblox, Map<String, bool> browser) async {
    _scheduleRoblox = roblox;
    _scheduleBrowser = browser;
    await DatabaseHelper.saveSetting('schedule_roblox', jsonEncode(roblox));
    await DatabaseHelper.saveSetting('schedule_browser', jsonEncode(browser));
    notifyListeners();
  }

  Future<void> _updateTodayPlayTime() async {
    final logs = await DatabaseHelper.getLogs();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int total = 0;
    for (var log in logs) {
      final start = DateTime.parse(log['start_time']);
      if (start.isAfter(today)) {
        total += log['duration_seconds'] as int;
      }
    }
    _todayPlayTimeSeconds = total;
  }

  Future<bool> toggleMonitor(String? password) async {
    if (_isMonitorEnabled) {
      // Trying to turn OFF
      if (password == null || !(await verifyPassword(password))) {
        return false;
      }
    }
    
    _isMonitorEnabled = !_isMonitorEnabled;
    DatabaseHelper.saveSetting('monitor_enabled', _isMonitorEnabled.toString());
    if (!_isMonitorEnabled) {
      _resetViolations();
    }
    notifyListeners();
    return true;
  }

  void _resetViolations() {
    _robloxViolationSeconds = 0;
    _browserViolationSeconds = 0;
    _showWarning = false;
    _showOverlay = false;
  }

  void _startMonitor() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkStatus();
    });
  }

  Future<String> get _password async => await DatabaseHelper.getSetting('app_password') ?? Constants.defaultPassword;

  Future<bool> verifyPassword(String input) async {
    return input == await _password;
  }

  Future<void> changePassword(String current, String next) async {
    if (current == await _password) {
      await DatabaseHelper.saveSetting('app_password', next);
    }
  }

  void _checkStatus() {
    if (_isChecking) return;
    _isChecking = true;
    
    try {
      _performCheck();
    } finally {
      _isChecking = false;
    }
  }

  void _performCheck() {
    bool robloxNow = Win32Service.isProcessRunning(Constants.robloxProcessName);
    String? browserMatchRoblox = Win32Service.getBrowserMatch(Constants.robloxKeywords);
    String? browserMatchSite = Win32Service.getBrowserMatch(Constants.siteKeywords);

    bool hasBrowserRoblox = browserMatchRoblox != null;
    bool hasBrowserSite = browserMatchSite != null;

    // Preserve the detected title for logging
    if (hasBrowserRoblox) _currentRobloxTitle = browserMatchRoblox;
    if (hasBrowserSite && !hasBrowserRoblox) _currentBrowserTitle = browserMatchSite;

    // Logging play time (always)
    _handleLogging(robloxNow, hasBrowserRoblox, hasBrowserSite);

    if (!_isMonitorEnabled) {
       _resetViolations();
       return;
    }

    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Mon, 7 = Sun
    final hour = now.hour;
    final key = "${weekday}_${hour}";

    bool allowRoblox = _scheduleRoblox[key] ?? false;
    bool allowYouTube = _scheduleBrowser[key] ?? false;

    // Default legacy logic if schedule is empty
    if (_scheduleRoblox.isEmpty && _scheduleBrowser.isEmpty) {
      allowRoblox = false; // Block Roblox by default to prevent bypass
      allowYouTube = true; // Allow general YouTube
    }

    // Violation logic for Roblox
    if (robloxNow && !allowRoblox) {
      _robloxViolationSeconds++;
      if (_robloxViolationSeconds == Constants.warningDelaySeconds) {
        _showWarning = true;
        _warningMessage = 'Không được phép chơi Roblox vào thời gian này!';
        notifyListeners();
      } else if (_robloxViolationSeconds >= Constants.killDelaySeconds) {
        Win32Service.killProcess(Constants.robloxProcessName);
        _robloxViolationSeconds = 0;
        _showWarning = false;
        notifyListeners();
      }
    } else {
      _robloxViolationSeconds = 0;
    }

    // Violation logic for Browser
    bool browserRobloxViolation = hasBrowserRoblox && !allowRoblox;
    bool browserSiteViolation = hasBrowserSite && !hasBrowserRoblox && !allowYouTube;
    
    if (browserRobloxViolation || browserSiteViolation) {
      _browserViolationSeconds++;
      if (_browserViolationSeconds == Constants.warningDelaySeconds) {
        _showWarning = true;
        _warningMessage = browserRobloxViolation 
            ? 'Không được phép xem nội dung Roblox vào lúc này!' 
            : 'Không được phép xem YouTube vào lúc này!';
        notifyListeners();
      } else if (_browserViolationSeconds == Constants.overlayDelaySeconds) {
        _showOverlay = true;
        notifyListeners();
      } else if (_browserViolationSeconds >= Constants.killDelaySeconds) {
        Win32Service.killBrowsers(Constants.robloxKeywords);
        _browserViolationSeconds = 0;
        _showWarning = false;
        _showOverlay = false;
        notifyListeners();
      }
    } else {
      _browserViolationSeconds = 0;
      if (!robloxNow || allowRoblox) {
        _showWarning = false;
      }
      _showOverlay = false;
    }

    if (!(robloxNow && !allowRoblox) && !browserRobloxViolation && !browserSiteViolation) {
      _showWarning = false;
      _showOverlay = false;
      notifyListeners();
    }
  }

  void _handleLogging(bool robloxNow, bool browserRoblox, bool browserSite) {
    if (robloxNow) {
      _robloxStartTime ??= DateTime.now();
      _todayPlayTimeSeconds++; // increment today's counter in real-time
    } else {
      if (_robloxStartTime != null) {
        final duration = DateTime.now().difference(_robloxStartTime!).inSeconds;
        if (duration > 0) {
          DatabaseHelper.logPlay(_robloxStartTime!, DateTime.now(), duration, 'Roblox App');
          _updateTodayPlayTime(); // persist update
        }
        _robloxStartTime = null;
      }
    }

    if (browserRoblox || browserSite) {
      _browserStartTime ??= DateTime.now();
      _todayPlayTimeSeconds++;
    } else {
      if (_browserStartTime != null) {
        final duration = DateTime.now().difference(_browserStartTime!).inSeconds;
        if (duration > 0) {
          String detail = browserRoblox ? (_currentRobloxTitle ?? 'Roblox Web') : (_currentBrowserTitle ?? 'YouTube');
          DatabaseHelper.logPlay(_browserStartTime!, DateTime.now(), duration, 'Trình duyệt: $detail');
          _updateTodayPlayTime();
        }
        _browserStartTime = null;
        _currentRobloxTitle = null;
        _currentBrowserTitle = null;
      }
    }
  }

  Future<void> setWindowMode(WindowMode mode) async {
    debugPrint("setWindowMode called with mode: $mode");
    if (_isTransitioning) {
      debugPrint("Already transitioning, returning");
      return;
    }
    _isTransitioning = true;
    
    try {
      // Simply update the UI state - avoid window_manager calls that cause native crash
      _windowMode = mode;
      notifyListeners();
      
      // Small delay to let UI update
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Just ensure window stays visible
      await windowManager.show();
      await windowManager.focus();
      
      debugPrint("Window mode changed to: $mode");
      
    } catch (e, stackTrace) {
      debugPrint("Window Mode Error: $e");
      debugPrint("Stack trace: $stackTrace");
    } finally {
      _isTransitioning = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
