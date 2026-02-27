import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart' as win32;

class NativeService {
  static bool isProcessRunning(String processName) {
    if (Platform.isWindows) {
      return _isWindowsProcessRunning(processName);
    } else if (Platform.isMacOS) {
      return _isMacOSProcessRunning(processName);
    }
    return false;
  }

  static String? getBrowserMatch(List<String> keywords) {
    if (Platform.isWindows) {
      return _getWindowsBrowserMatch(keywords);
    } else if (Platform.isMacOS) {
      return _getMacOSBrowserMatch(keywords);
    }
    return null;
  }

  static void killProcess(String processName) {
    if (Platform.isWindows) {
      _killWindowsProcess(processName);
    } else if (Platform.isMacOS) {
      _killMacOSProcess(processName);
    }
  }

  static void killBrowsers(List<String> keywords) {
    if (Platform.isWindows) {
      _killWindowsBrowsers(keywords);
    } else if (Platform.isMacOS) {
      _killMacOSBrowsers(keywords);
    }
  }

  // --- macOS Implementations ---

  static bool _isMacOSProcessRunning(String processName) {
    try {
      // pgrep -x matches the exact process name
      final result = Process.runSync('pgrep', ['-ix', processName]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint("MacOS Process Check Error: $e");
      return false;
    }
  }

  static String? _getMacOSBrowserMatch(List<String> keywords) {
    if (keywords.isEmpty) return null;

    final script = '''
      set foundTitle to ""
      tell application "System Events"
        set processList to name of every process
      end tell

      if processList contains "Safari" then
        tell application "Safari"
          repeat with w in windows
            repeat with t in tabs of w
              set tabTitle to name of t
              set tabURL to URL of t
              set foundTitle to foundTitle & tabTitle & " | " & tabURL & "\\n"
            end repeat
          end repeat
        end tell
      end if

      if processList contains "Google Chrome" then
        tell application "Google Chrome"
          repeat with w in windows
            repeat with t in tabs of w
              set tabTitle to title of t
              set tabURL to URL of t
              set foundTitle to foundTitle & tabTitle & " | " & tabURL & "\\n"
            end repeat
          end repeat
        end tell
      end if
      
      return foundTitle
    ''';

    try {
      final result = Process.runSync('osascript', ['-e', script]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString().toLowerCase();
        for (final keyword in keywords) {
          if (output.contains(keyword.toLowerCase())) {
            return keyword; // Return the keyword that matched
          }
        }
      }
    } catch (e) {
      debugPrint("MacOS Browser Check Error: $e");
    }
    return null;
  }

  static void _killMacOSProcess(String processName) {
    try {
      Process.runSync('killall', [processName]);
    } catch (e) {
      debugPrint("MacOS Kill Process Error: $e");
    }
  }

  static void _killMacOSBrowsers(List<String> keywords) {
    _killMacOSProcess("Safari");
    _killMacOSProcess("Google Chrome");
    _killMacOSProcess("Brave Browser");
    _killMacOSProcess("Firefox");
  }

  // --- Windows Implementations (Original Win32) ---

  static bool _isWindowsProcessRunning(String processName) {
    final processIds = calloc<win32.DWORD>(1024);
    final bytesReturned = calloc<win32.DWORD>();

    try {
      if (win32.EnumProcesses(processIds, 1024 * sizeOf<win32.DWORD>(), bytesReturned) == 0) {
        return false;
      }

      final count = bytesReturned.value ~/ sizeOf<win32.DWORD>();
      for (var i = 0; i < count; i++) {
        final processId = processIds[i];
        if (processId == 0) continue;

        final hProcess = win32.OpenProcess(win32.PROCESS_QUERY_INFORMATION | win32.PROCESS_VM_READ, win32.FALSE, processId);
        if (hProcess != 0) {
          final hModule = calloc<win32.HMODULE>();
          final moduleBytesReturned = calloc<win32.DWORD>();
          try {
            if (win32.EnumProcessModules(hProcess, hModule, sizeOf<win32.HMODULE>(), moduleBytesReturned) != 0) {
              final moduleName = calloc<Uint16>(win32.MAX_PATH).cast<Utf16>();
              win32.GetModuleBaseName(hProcess, hModule.value, moduleName.cast(), win32.MAX_PATH);
              final name = moduleName.toDartString();
              calloc.free(moduleName);
              if (name.toLowerCase() == processName.toLowerCase()) {
                return true;
              }
            }
          } finally {
            calloc.free(hModule);
            calloc.free(moduleBytesReturned);
            win32.CloseHandle(hProcess);
          }
        }
      }
    } finally {
      calloc.free(processIds);
      calloc.free(bytesReturned);
    }
    return false;
  }

  static String? _getWindowsBrowserMatch(List<String> keywords) {
    String? foundTitle;
    
    final lpEnumFunc = NativeCallable<win32.WNDENUMPROC>.isolateLocal(
      (int hwnd, int lParam) {
        final length = win32.GetWindowTextLength(hwnd);
        if (length == 0) return win32.TRUE;

        final buffer = calloc<Uint16>(length + 1).cast<Utf16>();
        win32.GetWindowText(hwnd, buffer.cast(), length + 1);
        final title = buffer.toDartString();
        final lowerTitle = title.toLowerCase();
        calloc.free(buffer);

        final isBrowser = lowerTitle.contains('chrome') || 
                          lowerTitle.contains('edge') || 
                          lowerTitle.contains('firefox') || 
                          lowerTitle.contains('brave');
        
        if (isBrowser) {
          for (final keyword in keywords) {
            if (lowerTitle.contains(keyword.toLowerCase())) {
              foundTitle = title;
              return win32.FALSE; 
            }
          }
        }

        return win32.TRUE;
      },
      exceptionalReturn: 0,
    );

    win32.EnumWindows(lpEnumFunc.nativeFunction, 0);
    lpEnumFunc.close();
    
    return foundTitle;
  }

  static void _killWindowsProcess(String processName) {
    final processIds = calloc<win32.DWORD>(1024);
    final bytesReturned = calloc<win32.DWORD>();

    try {
      if (win32.EnumProcesses(processIds, 1024 * sizeOf<win32.DWORD>(), bytesReturned) == 0) {
        return;
      }

      final count = bytesReturned.value ~/ sizeOf<win32.DWORD>();
      for (var i = 0; i < count; i++) {
        final processId = processIds[i];
        if (processId == 0) continue;

        final hProcess = win32.OpenProcess(win32.PROCESS_QUERY_INFORMATION | win32.PROCESS_VM_READ | win32.PROCESS_TERMINATE, win32.FALSE, processId);
        if (hProcess != 0) {
          final hModule = calloc<win32.HMODULE>();
          final moduleBytesReturned = calloc<win32.DWORD>();
          try {
            if (win32.EnumProcessModules(hProcess, hModule, sizeOf<win32.HMODULE>(), moduleBytesReturned) != 0) {
              final moduleName = calloc<Uint16>(win32.MAX_PATH).cast<Utf16>();
              win32.GetModuleBaseName(hProcess, hModule.value, moduleName.cast(), win32.MAX_PATH);
              final name = moduleName.toDartString();
              calloc.free(moduleName);
              if (name.toLowerCase() == processName.toLowerCase()) {
                win32.TerminateProcess(hProcess, 0);
              }
            }
          } finally {
            calloc.free(hModule);
            calloc.free(moduleBytesReturned);
            win32.CloseHandle(hProcess);
          }
        }
      }
    } finally {
      calloc.free(processIds);
      calloc.free(bytesReturned);
    }
  }

  static void _killWindowsBrowsers(List<String> keywords) {
    _killWindowsProcess('chrome.exe');
    _killWindowsProcess('msedge.exe');
    _killWindowsProcess('firefox.exe');
    _killWindowsProcess('brave.exe');
  }
}
