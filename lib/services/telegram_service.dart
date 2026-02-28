import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class TelegramService {
  static const String _apiBaseUrlHttps = 'https://api.telegram.org/bot';
  static const String _apiBaseUrlHttp = 'http://api.telegram.org/bot';

  /// Sends a text message to the specified chat via Telegram Bot.
  static Future<bool> sendMessage({
    required String botToken,
    required String chatId,
    required String message,
  }) async {
    if (botToken.isEmpty || chatId.isEmpty) return false;

    // Try HTTPS first
    bool success = await _sendMessageInternal(botToken, chatId, message, _apiBaseUrlHttps);
    
    // If failed, try HTTP
    if (!success) {
      debugPrint('Telegram: HTTPS failed, retrying with HTTP...');
      success = await _sendMessageInternal(botToken, chatId, message, _apiBaseUrlHttp);
    }
    
    return success;
  }

  static Future<bool> _sendMessageInternal(String token, String chatId, String message, String baseUrl) async {
    try {
      final url = Uri.parse('$baseUrl$token/sendMessage');
      final response = await http.post(
        url,
        body: {
          'chat_id': chatId,
          'text': message,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Telegram: Message sent successfully via $baseUrl');
        return true;
      } else {
        debugPrint('Telegram Error ($baseUrl): ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Telegram Exception ($baseUrl): $e');
      return false;
    }
  }

  /// Captures the screen using PowerShell and sends it via Telegram.
  static Future<bool> captureAndSend({
    required String botToken,
    required String chatId,
    String? caption,
  }) async {
    if (botToken.isEmpty || chatId.isEmpty) return false;

    try {
      final directory = await getTemporaryDirectory();
      final String filePath = p.join(directory.path, 'roblox_capture_${DateTime.now().millisecondsSinceEpoch}.png');
      
      // Capture using platform-specific command
      bool captured = false;
      if (Platform.isWindows) {
        captured = await _captureScreenPowerShell(filePath);
      } else if (Platform.isMacOS) {
        captured = await _captureScreenMacOS(filePath);
      }
      
      if (!captured) {
        debugPrint('Telegram Error: Failed to capture screen.');
        return false;
      }

      final File imageFile = File(filePath);
       if (!imageFile.existsSync()) {
        debugPrint('Telegram Error: Capture file not found at $filePath');
        return false;
      }

      // Try HTTPS first
      bool success = await _sendPhotoInternal(botToken, chatId, imageFile, caption, _apiBaseUrlHttps);
      
      // If failed, try HTTP
      if (!success) {
        debugPrint('Telegram: HTTPS failed, retrying with HTTP...');
        success = await _sendPhotoInternal(botToken, chatId, imageFile, caption, _apiBaseUrlHttp);
      }

      // Cleanup
      try {
        await imageFile.delete();
      } catch (_) {}

      return success;
    } catch (e) {
      debugPrint('Telegram Exception: $e');
      return false;
    }
  }

  static Future<bool> _sendPhotoInternal(String token, String chatId, File imageFile, String? caption, String baseUrl) async {
    try {
      final url = Uri.parse('$baseUrl$token/sendPhoto');
      final request = http.MultipartRequest('POST', url)
        ..fields['chat_id'] = chatId
        ..fields['caption'] = caption ?? 'Roblox Detected!'
        ..files.add(await http.MultipartFile.fromPath('photo', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        debugPrint('Telegram: Photo sent successfully via $baseUrl');
        return true;
      } else {
        debugPrint('Telegram Error ($baseUrl): ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Telegram Exception ($baseUrl): $e');
      return false;
    }
  }

  static Future<bool> _captureScreenMacOS(String outputPath) async {
    try {
      // Use absolute path for robustness on macOS
      // -x: mute sound, -t png: format
      final result = await Process.run('/usr/sbin/screencapture', ['-x', '-t', 'png', outputPath]);
      if (result.exitCode != 0) {
        debugPrint('macOS Capture Error: ${result.stderr}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('macOS Capture Exception: $e');
      return false;
    }
  }

  static Future<bool> _captureScreenPowerShell(String outputPath) async {
    try {
      // PowerShell script to capture full screen
      String psScript = '''
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
\$screen = [System.Windows.Forms.Screen]::PrimaryScreen
\$bitmap = New-Object System.Drawing.Bitmap \$screen.Bounds.Width, \$screen.Bounds.Height
\$graphics = [System.Drawing.Graphics]::FromImage(\$bitmap)
\$graphics.CopyFromScreen(\$screen.Bounds.X, \$screen.Bounds.Y, 0, 0, \$bitmap.Size)
\$bitmap.Save('$outputPath')
\$graphics.Dispose()
\$bitmap.Dispose()
''';

      final result = await Process.run('powershell', ['-Command', psScript]);
      
      if (result.exitCode != 0) {
        debugPrint('PowerShell Capture Error: ${result.stderr}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('PowerShell execution failed: $e');
      return false;
    }
  }
}
