import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roblox_monitor/services/app_state.dart';

class EditableList extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> items;
  final String hint;
  final VoidCallback onChanged;

  const EditableList({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<EditableList> createState() => _EditableListState();
}

class _EditableListState extends State<EditableList> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final val = _controller.text.trim();
    if (val.isNotEmpty) {
      widget.items.add(val);
      _controller.clear();
      widget.onChanged();
      // Force rebuild to show new item in chip list
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(widget.subtitle, style: const TextStyle(fontSize: 14, color: Colors.white60)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _add,
              child: Text(context.read<AppState>().t('add')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.items.map((item) => Chip(
            label: Text(item),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () {
              widget.items.remove(item);
              widget.onChanged();
              setState(() {});
            },
          )).toList(),
        ),
      ],
    );
  }
}
