import 'package:flutter/material.dart';

class ScheduleGrid extends StatefulWidget {
  final Map<String, bool> initialSchedule;
  final String title;
  final Function(Map<String, bool>) onChanged;

  const ScheduleGrid({
    super.key,
    required this.initialSchedule,
    required this.title,
    required this.onChanged,
  });

  @override
  State<ScheduleGrid> createState() => _ScheduleGridState();
}

class _ScheduleGridState extends State<ScheduleGrid> {
  late Map<String, bool> _schedule;
  final List<String> _days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void initState() {
    super.initState();
    _schedule = Map<String, bool>.from(widget.initialSchedule);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(28),
            border: TableBorder.all(color: Colors.white10),
            children: [
              // Header row: Empty cell + Hours 0-23
              TableRow(
                children: [
                  const SizedBox(width: 32, height: 24, child: Center(child: Text('', style: TextStyle(fontSize: 10)))),
                  ...List.generate(24, (hour) => SizedBox(
                    width: 28,
                    height: 24,
                    child: Center(child: Text('$hour', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                  )),
                ],
              ),
              // Data rows: Day label + 24 hour cells
              ...List.generate(7, (dayIdx) {
                final day = dayIdx + 1; // 1 = Monday, 7 = Sunday
                return TableRow(
                  children: [
                    // Day label cell
                    SizedBox(
                      width: 32,
                      height: 28,
                      child: Center(child: Text(_days[dayIdx], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                    ),
                    // Hour cells for this day
                    ...List.generate(24, (hour) {
                      final key = "${day}_$hour";
                      final isSelected = _schedule[key] ?? false;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _schedule[key] = !isSelected;
                          });
                          widget.onChanged(_schedule);
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          color: isSelected ? Colors.green.withOpacity(0.6) : Colors.transparent,
                          child: isSelected 
                            ? const Icon(Icons.check, size: 14, color: Colors.white) 
                            : null,
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
