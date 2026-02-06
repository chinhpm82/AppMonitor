import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class Win32Service {
  static bool isProcessRunning(String processName) {
    final processIds = calloc<DWORD>(1024);
    final bytesReturned = calloc<DWORD>();

    try {
      if (EnumProcesses(processIds, 1024 * sizeOf<DWORD>(), bytesReturned) == 0) {
        return false;
      }

      final count = bytesReturned.value ~/ sizeOf<DWORD>();
      for (var i = 0; i < count; i++) {
        final processId = processIds[i];
        if (processId == 0) continue;

        final hProcess = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, processId);
        if (hProcess != 0) {
          final hModule = calloc<HMODULE>();
          final moduleBytesReturned = calloc<DWORD>();
          try {
            if (EnumProcessModules(hProcess, hModule, sizeOf<HMODULE>(), moduleBytesReturned) != 0) {
              final moduleName = calloc<Uint16>(MAX_PATH).cast<Utf16>();
              GetModuleBaseName(hProcess, hModule.value, moduleName.cast(), MAX_PATH);
              final name = moduleName.toDartString();
              calloc.free(moduleName);
              if (name.toLowerCase() == processName.toLowerCase()) {
              // Handle will be closed in finally block
              return true;
            }
            }
          } finally {
            calloc.free(hModule);
            calloc.free(moduleBytesReturned);
            CloseHandle(hProcess);
          }
        }
      }
    } finally {
      calloc.free(processIds);
      calloc.free(bytesReturned);
    }
    return false;
  }

  static String? getBrowserMatch(List<String> keywords) {
    String? foundTitle;
    
    final lpEnumFunc = NativeCallable<WNDENUMPROC>.isolateLocal(
      (int hwnd, int lParam) {
        final length = GetWindowTextLength(hwnd);
        if (length == 0) return TRUE;

        final buffer = calloc<Uint16>(length + 1).cast<Utf16>();
        GetWindowText(hwnd, buffer.cast(), length + 1);
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
              return FALSE; 
            }
          }
        }

        return TRUE;
      },
      exceptionalReturn: 0,
    );

    EnumWindows(lpEnumFunc.nativeFunction, 0);
    lpEnumFunc.close();
    
    return foundTitle;
  }

  static void killProcess(String processName) {
    final processIds = calloc<DWORD>(1024);
    final bytesReturned = calloc<DWORD>();

    try {
      if (EnumProcesses(processIds, 1024 * sizeOf<DWORD>(), bytesReturned) == 0) {
        return;
      }

      final count = bytesReturned.value ~/ sizeOf<DWORD>();
      for (var i = 0; i < count; i++) {
        final processId = processIds[i];
        if (processId == 0) continue;

        final hProcess = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ | PROCESS_TERMINATE, FALSE, processId);
        if (hProcess != 0) {
          final hModule = calloc<HMODULE>();
          final moduleBytesReturned = calloc<DWORD>();
          try {
            if (EnumProcessModules(hProcess, hModule, sizeOf<HMODULE>(), moduleBytesReturned) != 0) {
              final moduleName = calloc<Uint16>(MAX_PATH).cast<Utf16>();
              GetModuleBaseName(hProcess, hModule.value, moduleName.cast(), MAX_PATH);
              final name = moduleName.toDartString();
              calloc.free(moduleName);
              if (name.toLowerCase() == processName.toLowerCase()) {
                TerminateProcess(hProcess, 0);
              }
            }
          } finally {
            calloc.free(hModule);
            calloc.free(moduleBytesReturned);
            CloseHandle(hProcess);
          }
        }
      }
    } finally {
      calloc.free(processIds);
      calloc.free(bytesReturned);
    }
  }

  static void killBrowsers(List<String> keywords) {
    // Killing the whole browser might be aggressive, but it's what requested.
    // Usually browser processes are: chrome.exe, msedge.exe, firefox.exe
    killProcess('chrome.exe');
    killProcess('msedge.exe');
    killProcess('firefox.exe');
    killProcess('brave.exe');
  }
}
