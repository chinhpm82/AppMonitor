import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:roblox_monitor/services/database_helper.dart';
import 'package:roblox_monitor/services/native_service.dart';
import 'package:roblox_monitor/services/telegram_service.dart';
import 'package:roblox_monitor/utils/constants.dart';
import 'package:roblox_monitor/utils/translations.dart';
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

  // Configurable delays
  int _warningDelay = Constants.warningDelaySeconds;
  int _overlayDelay = Constants.overlayDelaySeconds;
  int _killDelay = Constants.killDelaySeconds;

  // Schedule storage: key: "day_hour" (e.g. "1_18" for Mon 18:00), value: true/false
  Map<String, bool> _scheduleRoblox = {};
  Map<String, bool> _scheduleBrowser = {};

  // Custom monitoring lists
  List<String> _customKeywords = [];
  List<String> _customApps = [];

  Timer? _timer;
  bool _isChecking = false;
  bool _isTransitioning = false;
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

  List<String> get customKeywords => _customKeywords;
  List<String> get customApps => _customApps;

  int get warningDelay => _warningDelay;
  int get overlayDelay => _overlayDelay;
  int get killDelay => _killDelay;

  // Telegram Config
  String _telegramBotToken = '';
  String _telegramChatId = '';
  int _telegramDebounceMinutes = 5;
  String _telegramMessageTemplate = "Phát hiện nội dung giới hạn: {reason}"; // Legacy fallback

  // Localization
  String _language = 'vi';
  String get currentLanguage => _language;
  DateTime? _lastTelegramSentTime;

  String get telegramBotToken => _telegramBotToken;
  String get telegramChatId => _telegramChatId;
  int get telegramDebounceMinutes => _telegramDebounceMinutes;
  String get telegramMessageTemplate => _telegramMessageTemplate;

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

    _telegramBotToken = await DatabaseHelper.getSetting('telegram_bot_token') ?? '';
    _telegramChatId = await DatabaseHelper.getSetting('telegram_chat_id') ?? '';

    final keywords = await DatabaseHelper.getSetting('custom_keywords');
    if (keywords != null) {
      try {
        _customKeywords = List<String>.from(jsonDecode(keywords));
      } catch (_) {}
    } else {
      // Default initial keywords
      _customKeywords = [...Constants.robloxKeywords];
    }

    // Load language
    _language = await DatabaseHelper.getSetting('language') ?? 'vi';

    // Load custom apps
    final savedApps = await DatabaseHelper.getSetting('custom_apps');
    if (savedApps != null) {
      try {
        _customApps = List<String>.from(jsonDecode(savedApps));
      } catch (_) {}
    } else {
      // Default initial apps
      _customApps = [Constants.robloxProcessName];
    }

    // Load delays
    _warningDelay = int.tryParse(await DatabaseHelper.getSetting('delay_warning') ?? '') ?? Constants.warningDelaySeconds;
    _overlayDelay = int.tryParse(await DatabaseHelper.getSetting('delay_overlay') ?? '') ?? Constants.overlayDelaySeconds;
    _killDelay = int.tryParse(await DatabaseHelper.getSetting('delay_kill') ?? '') ?? Constants.killDelaySeconds;

    // Load Telegram extra configs
    _telegramDebounceMinutes = int.tryParse(await DatabaseHelper.getSetting('telegram_debounce') ?? '') ?? 5;
    _telegramMessageTemplate = await DatabaseHelper.getSetting('telegram_template') ?? "Phát hiện nội dung giới hạn: {reason}";

    notifyListeners();
  }

  Future<void> saveSettings({
    required int warningDelay,
    required int overlayDelay,
    required int killDelay,
    required int telegramDebounce,
    required String telegramTemplate,
  }) async {
    _warningDelay = warningDelay;
    _overlayDelay = overlayDelay;
    _killDelay = killDelay;
    _telegramDebounceMinutes = telegramDebounce;
    _telegramMessageTemplate = telegramTemplate;

    await DatabaseHelper.saveSetting('delay_warning', warningDelay.toString());
    await DatabaseHelper.saveSetting('delay_overlay', overlayDelay.toString());
    await DatabaseHelper.saveSetting('delay_kill', killDelay.toString());
    await DatabaseHelper.saveSetting('telegram_debounce', telegramDebounce.toString());
    await DatabaseHelper.saveSetting('telegram_template', telegramTemplate);
    
    notifyListeners();
  }

  Future<void> saveSchedules(Map<String, bool> roblox, Map<String, bool> browser) async {
    _scheduleRoblox = roblox;
    _scheduleBrowser = browser;
    await DatabaseHelper.saveSetting('schedule_roblox', jsonEncode(roblox));
    await DatabaseHelper.saveSetting('schedule_browser', jsonEncode(browser));
    notifyListeners();
  }

  Future<void> saveTelegramConfig(String token, String chatId) async {
    _telegramBotToken = token;
    _telegramChatId = chatId;
    await DatabaseHelper.saveSetting('telegram_bot_token', token);
    await DatabaseHelper.saveSetting('telegram_chat_id', chatId);
    notifyListeners();
  }

  Future<void> saveCustomMonitoring(List<String> keywords, List<String> apps) async {
    _customKeywords = keywords;
    _customApps = apps;
    await DatabaseHelper.saveSetting('custom_keywords', jsonEncode(keywords));
    await DatabaseHelper.saveSetting('custom_apps', jsonEncode(apps));
    notifyListeners();
  }

  Future<void> _checkAndSendTelegramAlert(String reason) async {
    if (_telegramBotToken.isEmpty || _telegramChatId.isEmpty) return;

    final now = DateTime.now();
    if (_lastTelegramSentTime != null && 
        now.difference(_lastTelegramSentTime!).inMinutes < _telegramDebounceMinutes) {
      return;
    }

    _lastTelegramSentTime = now;
    
    String message = _telegramMessageTemplate.replaceAll('{reason}', reason);
    message = message.replaceAll('{time}', "${now.hour}:${now.minute.toString().padLeft(2, '0')}");

    // Run in background
    TelegramService.captureAndSend(
      botToken: _telegramBotToken,
      chatId: _telegramChatId,
      caption: message,
    );
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

  Future<void> setLanguage(String lang) async {
    if (_language != lang) {
      _language = lang;
      await DatabaseHelper.saveSetting('language', lang);
      notifyListeners();
    }
  }

  String t(String key, {List<String>? args}) {
    String? val = AppTranslations.languages[_language]?[key];
    val ??= AppTranslations.languages['vi']?[key] ?? key;
    if (args != null && args.isNotEmpty) {
      for (int i = 0; i < args.length; i++) {
        val = val!.replaceAll('{$i}', args[i]);
      }
    }
    return val!;
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
    // 1. Check Desktop Apps
    bool robloxNow = NativeService.isProcessRunning(Constants.robloxProcessName);
    bool customAppNow = false;
    String? foundCustomAppName;
    
    for (final app in _customApps) {
      if (NativeService.isProcessRunning(app)) {
        customAppNow = true;
        foundCustomAppName = app;
        break;
      }
    }

    // 2. Check Browser Keywords
    // Use custom keywords as the primary list now
    String? browserMatch = _customKeywords.isNotEmpty 
        ? NativeService.getBrowserMatch(_customKeywords)
        : null;

    bool hasBrowserViolation = browserMatch != null;
    
    // Check if it's specifically Roblox for separate logging/alerts
    bool isRobloxWeb = false;
    if (browserMatch != null) {
      final lowerMatch = browserMatch.toLowerCase();
      isRobloxWeb = lowerMatch.contains('roblox') || lowerMatch.contains('blox');
    }

    // Logging play time
    _handleLogging(robloxNow || customAppNow, isRobloxWeb, hasBrowserViolation && !isRobloxWeb);
    
    // Check Telegram Notification
    // Check Telegram Notification
    if (robloxNow) {
       _checkAndSendTelegramAlert(t('msg_roblox_app'));
    } else if (customAppNow) {
       _checkAndSendTelegramAlert(t('msg_restricted_app', args: [foundCustomAppName ?? '']));
    } else if (isRobloxWeb) {
       _checkAndSendTelegramAlert(t('msg_roblox_web', args: [_currentRobloxTitle ?? '']));
    } else if (hasBrowserViolation) {
       _checkAndSendTelegramAlert(t('msg_restricted_web', args: [browserMatch ?? '']));
    }

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

    // Violation logic for Roblox & Custom Apps
    bool appViolation = (robloxNow && !allowRoblox) || (customAppNow && !allowRoblox);
    
    if (appViolation) {
      _robloxViolationSeconds++;
      if (_robloxViolationSeconds == _warningDelay) {
        _showWarning = true;
        _warningMessage = customAppNow 
           ? t('warn_app', args: [foundCustomAppName ?? '']) 
           : t('warn_roblox');
        notifyListeners();
      } else if (_robloxViolationSeconds >= _killDelay) {
        if (robloxNow) NativeService.killProcess(Constants.robloxProcessName);
        if (customAppNow && foundCustomAppName != null) NativeService.killProcess(foundCustomAppName);
        _robloxViolationSeconds = 0;
        _showWarning = false;
        notifyListeners();
      }
    } else {
      _robloxViolationSeconds = 0;
    }

    // Violation logic for Browser
    // Simplified: browser violation is any keyword match when not allowed
    bool isAllowedInBrowser = true;
    if (isRobloxWeb) {
      isAllowedInBrowser = allowRoblox;
    } else {
      isAllowedInBrowser = allowYouTube;
    }

    bool browserViolation = hasBrowserViolation && !isAllowedInBrowser;
    
    if (browserViolation) {
      _browserViolationSeconds++;
      if (_browserViolationSeconds == _warningDelay) {
        _showWarning = true;
        _warningMessage = isRobloxWeb 
            ? t('warn_web_roblox') 
            : t('warn_web_restricted');
        notifyListeners();
      } else if (_browserViolationSeconds == _overlayDelay) {
        _showOverlay = true;
        notifyListeners();
      } else if (_browserViolationSeconds >= _killDelay) {
        NativeService.killBrowsers(_customKeywords);
        _browserViolationSeconds = 0;
        _showWarning = false;
        _showOverlay = false;
        notifyListeners();
      }
    } else {
      _browserViolationSeconds = 0;
      if (!appViolation) {
        _showWarning = false;
      }
      _showOverlay = false;
    }

    if (!appViolation && !browserViolation) {
      _showWarning = false;
      _showOverlay = false;
      notifyListeners();
    }
  }

  void _handleLogging(bool robloxNow, bool browserRoblox, bool browserSite) {
    // Preserve detection for logging details
    if (browserRoblox) _currentRobloxTitle ??= 'Start Detected';
    if (browserSite && !browserRoblox) _currentBrowserTitle ??= 'Start Detected';

    if (robloxNow) {
      _robloxStartTime ??= DateTime.now();
      _todayPlayTimeSeconds++;
    } else {
      if (_robloxStartTime != null) {
        final duration = DateTime.now().difference(_robloxStartTime!).inSeconds;
        if (duration > 0) {
          DatabaseHelper.logPlay(_robloxStartTime!, DateTime.now(), duration, 'Roblox App');
          _updateTodayPlayTime();
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
}

  Future<void> setWindowMode(WindowMode mode) async {
    debugPrint("setWindowMode called with mode: $mode");
    if (_isTransitioning) {
      debugPrint("Already transitioning, returning");
      return;
    }
    _isTransitioning = true;
    
    try {
      _windowMode = mode;
      notifyListeners();
      
      await Future.delayed(const Duration(milliseconds: 50));
      
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
