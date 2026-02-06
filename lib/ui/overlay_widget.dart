import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roblox_monitor/services/app_state.dart';
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
    final app = context.watch<AppState>();
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, color: Colors.red, size: 100),
            const SizedBox(height: 20),
            Text(
              app.t('sites_blocked_title'),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              app.t('sites_blocked_msg'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
