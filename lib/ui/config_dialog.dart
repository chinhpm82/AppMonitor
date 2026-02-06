import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roblox_monitor/services/app_state.dart';
import 'package:roblox_monitor/services/database_helper.dart';
import 'package:roblox_monitor/ui/schedule_grid.dart';
import 'package:roblox_monitor/services/telegram_service.dart'; // Add import

class ConfigDialog extends StatefulWidget {
  const ConfigDialog({super.key});

  @override
  State<ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<ConfigDialog> {
  bool _isAuthenticated = false;
  final TextEditingController _authPassController = TextEditingController();
  
  final TextEditingController _timeController = TextEditingController(); // For future usage or removing if unused
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  
  final TextEditingController _botTokenController = TextEditingController();
  final TextEditingController _chatIdController = TextEditingController();
  final TextEditingController _telegramFrequencyController = TextEditingController();
  final TextEditingController _telegramTemplateController = TextEditingController();

  final TextEditingController _warningDelayController = TextEditingController();
  final TextEditingController _overlayDelayController = TextEditingController();
  final TextEditingController _killDelayController = TextEditingController();
  
  late Map<String, bool> _tempSchRoblox;
  late Map<String, bool> _tempSchBrowser;
  
  List<String> _tempKeywords = [];
  List<String> _tempApps = [];
  
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
      _tempKeywords = List<String>.from(appState.customKeywords);
      _tempApps = List<String>.from(appState.customApps);
    }
  }

  Future<void> _loadSettings() async {
    final appState = context.read<AppState>();
    // Pre-fill controllers
    _botTokenController.text = appState.telegramBotToken;
    _chatIdController.text = appState.telegramChatId;
    _telegramFrequencyController.text = appState.telegramDebounceMinutes.toString();
    _telegramTemplateController.text = appState.telegramMessageTemplate;

    _warningDelayController.text = appState.warningDelay.toString();
    _overlayDelayController.text = appState.overlayDelay.toString();
    _killDelayController.text = appState.killDelay.toString();
    
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
              Text(context.read<AppState>().t('auth_required'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: _authPassController,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(border: const OutlineInputBorder(), labelText: context.read<AppState>().t('admin_password')),
                onSubmitted: (_) => _authenticate(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.read<AppState>().setWindowMode(WindowMode.tray),
                    child: Text(context.read<AppState>().t('cancel')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _authenticate,
                    child: Text(context.read<AppState>().t('confirm')),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 5, // Increased from 4 to 5
      child: Container(
        color: const Color(0xFF121212),
        child: Column(
          children: [
            AppBar(
              title: Text('${context.watch<AppState>().t('tab_general')} MoniGuard'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.read<AppState>().setWindowMode(WindowMode.tray),
              ),
            ),
            TabBar(
              tabs: [
                Tab(text: context.watch<AppState>().t('tab_schedule')),
                Tab(text: context.watch<AppState>().t('tab_monitoring')),
                Tab(text: context.watch<AppState>().t('tab_stats')),
                Tab(text: context.watch<AppState>().t('tab_notification')),
                Tab(text: context.watch<AppState>().t('tab_account')),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                   _buildScheduleTab(),
                   _buildMonitoringTab(), // New Tab
                   _buildStatsTab(),
                   _buildNotificationTab(),
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
                    child: Text(context.watch<AppState>().t('cancel')),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text(context.watch<AppState>().t('save_all')),
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
            title: context.watch<AppState>().t('schedule_roblox'),
            initialSchedule: _tempSchRoblox,
            onChanged: (val) => _tempSchRoblox = val,
          ),
          const SizedBox(height: 16),
          const Divider(),
          ScheduleGrid(
            title: context.watch<AppState>().t('schedule_other'),
            initialSchedule: _tempSchBrowser,
            onChanged: (val) => _tempSchBrowser = val,
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditableList(
            title: context.watch<AppState>().t('keywords_title'),
            subtitle: context.watch<AppState>().t('keywords_subtitle'),
            items: _tempKeywords,
            hint: context.watch<AppState>().t('keywords_hint'),
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _buildEditableList(
            title: context.watch<AppState>().t('apps_title'),
            subtitle: context.watch<AppState>().t('apps_subtitle'),
            items: _tempApps,
            hint: context.watch<AppState>().t('apps_hint'),
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text(context.watch<AppState>().t('time_config_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildNumberField(context.watch<AppState>().t('delay_warning'), _warningDelayController)),
              const SizedBox(width: 16),
              Expanded(child: _buildNumberField(context.watch<AppState>().t('delay_overlay'), _overlayDelayController)),
              const SizedBox(width: 16),
              Expanded(child: _buildNumberField(context.watch<AppState>().t('delay_kill'), _killDelayController)),
            ],
          ),
          const SizedBox(height: 8),
          Text(context.watch<AppState>().t('overlay_note'), style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixText: 's',
      ),
    );
  }

  Widget _buildEditableList({
    required String title,
    required String subtitle,
    required List<String> items,
    required String hint,
    required VoidCallback onChanged,
  }) {
    final controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.white60)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      items.add(val.trim());
                      controller.clear();
                      onChanged();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    items.add(controller.text.trim());
                    controller.clear();
                    onChanged();
                  });
                }
              },
              child: Text(context.read<AppState>().t('add')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => Chip(
            label: Text(item),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () {
              setState(() {
                items.remove(item);
                onChanged();
              });
            },
          )).toList(),
        ),
      ],
    );
  }


  Widget _buildStatsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.getLogs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final logs = snapshot.data!;
        if (logs.isEmpty) return Center(child: Text(context.watch<AppState>().t('no_stats_data')));

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

  Widget _buildNotificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.watch<AppState>().t('tele_config_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            context.watch<AppState>().t('tele_desc'),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _botTokenController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: context.watch<AppState>().t('bot_token'),
              hintText: '123456:ABC-DEF...',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _chatIdController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: context.watch<AppState>().t('chat_id'),
              hintText: '123456789',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _telegramFrequencyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: context.watch<AppState>().t('debounce'),
                    suffixText: 'm',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _telegramTemplateController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: context.watch<AppState>().t('msg_template'),
                    hintText: context.watch<AppState>().t('template_hint'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(context.watch<AppState>().t('template_note'), style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.send),
            label: Text(context.watch<AppState>().t('send_test')),
            onPressed: () async {
               final token = _botTokenController.text;
               final chat = _chatIdController.text;
               if (token.isEmpty || chat.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Token và Chat ID')));
                 return;
               }
               
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<AppState>().t('test_sending')), duration: const Duration(seconds: 1)));
               
               bool success = await TelegramService.sendMessage(
                 botToken: token,
                 chatId: chat,
                 message: context.read<AppState>().t('test_msg_content'),
               );
               
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<AppState>().t('test_success')), backgroundColor: Colors.green));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<AppState>().t('test_fail')), backgroundColor: Colors.red));
                  }
                }
            },
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          _buildTelegramGuide(),
        ],
      ),
    );
  }

  Widget _buildTelegramGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blueAccent, size: 20),
              SizedBox(width: 8),
              Text(context.watch<AppState>().t('tele_guide_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          _guideStep('1', context.watch<AppState>().t('guide_step_1')),
          _guideStep('2', context.watch<AppState>().t('guide_step_2')),
          _guideStep('3', context.watch<AppState>().t('guide_step_3')),
          _guideStep('4', context.watch<AppState>().t('guide_step_4')),
        ],
      ),
    );
  }

  Widget _guideStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 9, backgroundColor: Colors.blueAccent, child: Text(num, style: const TextStyle(fontSize: 11, color: Colors.white))),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.white70))),
        ],
      ),
    );
  }

  Widget _buildAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.read<AppState>().t('change_pass_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _currentPassController,
            obscureText: true,
            decoration: InputDecoration(border: const OutlineInputBorder(), labelText: context.read<AppState>().t('current_pass')),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newPassController,
            obscureText: true,
            decoration: InputDecoration(border: const OutlineInputBorder(), labelText: context.read<AppState>().t('new_pass')),
            onSubmitted: (_) => _saveSettings(),
          ),
          const SizedBox(height: 32),
          Text(context.read<AppState>().t('language'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: context.watch<AppState>().currentLanguage,
            dropdownColor: const Color(0xFF1E1E1E),
            items: const [
              DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: (val) {
              if (val != null) {
                context.read<AppState>().setLanguage(val);
              }
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 32),
          Text(
            context.watch<AppState>().t('account_note'),
            style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
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
    
    // Save Telegram config
    await appState.saveTelegramConfig(_botTokenController.text, _chatIdController.text);

    // Save common settings
    await appState.saveSettings(
      warningDelay: int.tryParse(_warningDelayController.text) ?? 5,
      overlayDelay: int.tryParse(_overlayDelayController.text) ?? 10,
      killDelay: int.tryParse(_killDelayController.text) ?? 30,
      telegramDebounce: int.tryParse(_telegramFrequencyController.text) ?? 5,
      telegramTemplate: _telegramTemplateController.text,
    );

    // Save schedules
    await appState.saveSchedules(_tempSchRoblox, _tempSchBrowser);

    // Save custom monitoring
    await appState.saveCustomMonitoring(_tempKeywords, _tempApps);
    
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
