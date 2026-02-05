import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roblox_monitor/services/app_state.dart';
import 'package:roblox_monitor/services/database_helper.dart';
import 'package:roblox_monitor/ui/schedule_grid.dart';

class ConfigDialog extends StatefulWidget {
  const ConfigDialog({super.key});

  @override
  State<ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<ConfigDialog> {
  bool _isAuthenticated = false;
  final TextEditingController _authPassController = TextEditingController();
  
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  
  late Map<String, bool> _tempSchRoblox;
  late Map<String, bool> _tempSchBrowser;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tempSchRoblox = {};
    _tempSchBrowser = {};
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final appState = context.read<AppState>();
      _tempSchRoblox = Map<String, bool>.from(appState.scheduleRoblox);
      _tempSchBrowser = Map<String, bool>.from(appState.scheduleBrowser);
    }
  }

  Future<void> _loadSettings() async {
    final time = await DatabaseHelper.getSetting('allowed_minutes');
    if (mounted) {
      _timeController.text = time ?? '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Xác thực quyền truy cập', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: _authPassController,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Mật khẩu quản trị'),
                onSubmitted: (_) => _authenticate(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.read<AppState>().setWindowMode(WindowMode.tray),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _authenticate,
                    child: const Text('Xác nhận'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Container(
        color: const Color(0xFF121212),
        child: Column(
          children: [
            AppBar(
              title: const Text('Cài đặt Monitor'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.read<AppState>().setWindowMode(WindowMode.tray),
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Lịch biểu'),
                Tab(text: 'Thống kê'),
                Tab(text: 'Tài khoản'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Schedule Tab
                  _buildScheduleTab(),
                  // Statistics Tab
                  _buildStatsTab(),
                  // Account Tab
                  _buildAccountTab(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.read<AppState>().setWindowMode(WindowMode.tray),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Lưu tất cả'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ScheduleGrid(
            title: 'Lịch cho phép chơi Roblox',
            initialSchedule: _tempSchRoblox,
            onChanged: (val) => _tempSchRoblox = val,
          ),
          const SizedBox(height: 16),
          const Divider(),
          ScheduleGrid(
            title: 'Lịch cho phép xem YouTube (Trình duyệt)',
            initialSchedule: _tempSchBrowser,
            onChanged: (val) => _tempSchBrowser = val,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.getLogs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final logs = snapshot.data!;
        if (logs.isEmpty) return const Center(child: Text('Chưa có dữ liệu thống kê.'));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white10),
          itemBuilder: (context, index) {
            final log = logs[index];
            final startTime = DateTime.parse(log['start_time']);
            final duration = log['duration_seconds'] as int;
            final durationStr = "${(duration ~/ 3600).toString().padLeft(2, '0')}:${((duration % 3600) ~/ 60).toString().padLeft(2, '0')}:${(duration % 60).toString().padLeft(2, '0')}";

            return ListTile(
              leading: Icon(
                log['type'].toString().contains('App') ? Icons.sports_esports : Icons.language,
                color: Colors.blueAccent,
              ),
              title: Text(log['type'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${startTime.day}/${startTime.month}/${startTime.year}  ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}"),
              trailing: Text(durationStr, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            );
          },
        );
      },
    );
  }

  Widget _buildAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đổi mật khẩu:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _currentPassController,
            obscureText: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Mật khẩu hiện tại'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newPassController,
            obscureText: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Mật khẩu mới'),
            onSubmitted: (_) => _saveSettings(),
          ),
          const SizedBox(height: 32),
          const Text(
            'Lưu ý: Bạn chọn các khung giờ ĐƯỢC PHÉP chơi. Các khung giờ không tích sẽ bị chặn hoàn toàn khi Monitor ở trạng thái BẬT.',
            style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticate() async {
    final appState = context.read<AppState>();
    if (await appState.verifyPassword(_authPassController.text)) {
      setState(() => _isAuthenticated = true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu không đúng!')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    final appState = context.read<AppState>();
    
    // Save schedules
    await appState.saveSchedules(_tempSchRoblox, _tempSchBrowser);
    
    // Handle password change if filled
    if (_currentPassController.text.isNotEmpty && _newPassController.text.isNotEmpty) {
      final correct = await appState.verifyPassword(_currentPassController.text);
      if (correct) {
        await appState.changePassword(_currentPassController.text, _newPassController.text);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu cũ không đúng!')),
        );
        return;
      }
    }

    if (mounted) {
      await appState.refreshState();
      await appState.setWindowMode(WindowMode.tray);
    }
  }
}
