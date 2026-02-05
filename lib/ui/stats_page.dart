import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roblox_monitor/services/database_helper.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê thời gian chơi')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.getLogs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final logs = snapshot.data!;
          if (logs.isEmpty) {
            return const Center(child: Text('Chưa có nhật ký nào.'));
          }

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final startTime = DateTime.parse(log['start_time']);
              final duration = log['duration_seconds'] as int;
              final type = log['type'] as String;

              return ListTile(
                leading: Icon(
                  type.contains('App') ? Icons.sports_esports : Icons.public,
                  color: Colors.blueAccent,
                ),
                title: Text(type),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(startTime)),
                trailing: Text(
                  _formatDuration(duration),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
