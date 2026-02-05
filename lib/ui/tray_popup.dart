import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roblox_monitor/services/app_state.dart';
import 'package:roblox_monitor/ui/config_dialog.dart';
import 'package:window_manager/window_manager.dart';

class TrayPopup extends StatelessWidget {
  const TrayPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final isEnabled = context.select<AppState, bool>((s) => s.isMonitorEnabled);
    
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text(
                    'Roblox Monitor',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 20, color: Colors.white54),
                    onPressed: () {
                      context.read<AppState>().setWindowMode(WindowMode.settings);
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEnabled ? 'MONITOR: ON' : 'MONITOR: OFF',
                    style: TextStyle(
                      color: isEnabled ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    activeColor: Colors.greenAccent,
                    onChanged: (value) async {
                      final appState = context.read<AppState>();
                      if (isEnabled) {
                         // Turning OFF needs password
                         final password = await _showPasswordDialog(context);
                         if (password != null) {
                            await appState.toggleMonitor(password);
                         }
                      } else {
                        await appState.toggleMonitor(null);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập mật khẩu'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Mật khẩu'),
          onSubmitted: (val) => Navigator.pop(context, val),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
