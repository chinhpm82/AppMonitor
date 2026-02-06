import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:roblox_monitor/services/app_state.dart';
import 'package:roblox_monitor/services/database_helper.dart';
import 'package:roblox_monitor/ui/stats_page.dart';
import 'package:roblox_monitor/ui/config_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isEnabled = context.select<AppState, bool>((s) => s.isMonitorEnabled);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<AppState>().t('app_name')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const ConfigDialog(),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(isEnabled, context),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.watch<AppState>().t('usage_log'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const StatsPage()),
                            ),
                            child: Text(context.watch<AppState>().t('view_all')),
                          ),
                        ],
                      ),
                      const Expanded(child: RecentLogsList()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isEnabled, BuildContext context) {
    return Card(
      color: isEnabled ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              isEnabled ? Icons.security : Icons.security_outlined,
              size: 64,
              color: isEnabled ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              isEnabled ? context.watch<AppState>().t('monitor_status_on') : context.watch<AppState>().t('monitor_status_off'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.watch<AppState>().t('monitor_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final appState = context.read<AppState>();
                if (isEnabled) {
                  // Prompt for password
                  final password = await _showPasswordDialog(context);
                  if (password != null) {
                    final success = await appState.toggleMonitor(password);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(appState.t('password_incorrect'))),
                      );
                    }
                  }
                } else {
                  await appState.toggleMonitor(null);
                }
              },
              icon: Icon(isEnabled ? Icons.power_settings_new : Icons.play_arrow),
              label: Text(isEnabled ? context.watch<AppState>().t('turn_off') : context.watch<AppState>().t('turn_on')),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabled ? Colors.redAccent : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.read<AppState>().t('enter_password')),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(labelText: context.read<AppState>().t('password')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.read<AppState>().t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.read<AppState>().t('confirm')),
          ),
        ],
      ),
    );
  }
}

class RecentLogsList extends StatelessWidget {
  const RecentLogsList({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.getLogs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final logs = snapshot.data!.take(5).toList(); // Show only top 5
        if (logs.isEmpty) {
          return Center(child: Text(context.watch<AppState>().t('no_recent_activity')));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final startTime = DateTime.parse(log['start_time']);
            final duration = log['duration_seconds'] as int;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, size: 20),
              title: Text(
                '${context.watch<AppState>().t('playing')} ${log['type']}',
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                DateFormat('HH:mm dd/MM').format(startTime),
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Text(
                '${(duration / 60).toStringAsFixed(1)}m',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
    );
  }
}
