import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class FullScreenOverlay extends StatefulWidget {
  const FullScreenOverlay({super.key});

  @override
  State<FullScreenOverlay> createState() => _FullScreenOverlayState();
}

class _FullScreenOverlayState extends State<FullScreenOverlay> {
  @override
  void initState() {
    super.initState();
    _makeFullScreen();
  }

  Future<void> _makeFullScreen() async {
    await windowManager.setFullScreen(true);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.show();
  }

  @override
  void dispose() {
    _restoreWindow();
    super.dispose();
  }

  Future<void> _restoreWindow() async {
    await windowManager.setFullScreen(false);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setSize(const Size(400, 600));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, color: Colors.red, size: 100),
            SizedBox(height: 20),
            Text(
              'TRANG WEB BỊ CHẶN',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Bạn đang truy cập trang web có nội dung Roblox.\nTrình duyệt sẽ bị tắt sau giây lát.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
