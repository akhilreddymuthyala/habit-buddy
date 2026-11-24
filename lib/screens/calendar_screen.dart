// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/habit.dart';
import '../services/streak_calculator.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';
import 'habit_details_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selected;

  void _shift(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = _selected ?? c.today;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = _month.weekday - 1;
    final rows = ((offset + daysInMonth) / 7).ceil();
    final dayHabits = c.habitsForDay(selected);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(formatMonthYear(_month),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => _shift(1),
                icon: const Icon(Icons.chevron_right),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _month = DateTime(c.today.year, c.today.month, 1);
                  _selected = c.today;
                }),
                child: const Text('Today'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final d in kWeekdayShort)
                Expanded(
                  child: Center(
                    child: Text(d.substring(0, 2),
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var r = 0; r < rows; r++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: Builder(builder: (context) {
                      final dayNum = r * 7 + col - offset + 1;
                      if (dayNum < 1 || dayNum > daysInMonth) {
                        return const AspectRatio(
                            aspectRatio: 1, child: SizedBox.shrink());
                      }
                      final day = DateTime(_month.year, _month.month, dayNum);
                      return _DayCell(
                        day: day,
                        summary: c.daySummary(day),
                        isToday: day == c.today,
                        isSelected: day == selected,
                        onTap: () => setState(() => _selected = day),
                      );
                    }),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: const [
              _LegendItem(icon: Icons.check, label: 'All done'),
              _LegendItem(icon: Icons.remove, label: 'Partly done'),
              _LegendItem(icon: Icons.close, label: 'Missed'),
              _LegendItem(icon: Icons.circle_outlined, label: 'Scheduled'),
            ],
          ),
          SectionHeader(formatLongDate(selected)),
          if (dayHabits.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text('Nothing was scheduled on this day.',
                    style: theme.textTheme.bodyMedium),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < dayHabits.length; i++) ...[
                    if (i > 0) const Divider(),
                    _DayHabitRow(
                      habit: dayHabits[i],
                      day: selected,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.summary,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final DaySummary summary;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color? fill;
    Color border = Colors.transparent;
    IconData? icon;
    Color iconColor = scheme.onSurface;
    switch (summary) {
      case DaySummary.completed:
        fill = scheme.primary;
        icon = Icons.check;
        iconColor = scheme.onPrimary;
      case DaySummary.partial:
        fill = scheme.primaryContainer;
        border = scheme.primary;
        icon = Icons.remove;
      case DaySummary.missed:
        fill = scheme.error.withValues(alpha: 0.12);
        icon = Icons.close;
        iconColor = scheme.error;
      case DaySummary.scheduled:
        border = scheme.outline;
      case DaySummary.none:
        break;
    }
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Semantics(
          button: true,
          selected: isSelected,
          label: formatLongDate(day),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? scheme.onSurface : border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                        color: summary == DaySummary.completed
                            ? scheme.onPrimary
                            : scheme.onSurface,
                        decoration:
                            isToday ? TextDecoration.underline : null,
                      ),
                    ),
                  ),
                  if (icon != null) Icon(icon, size: 12, color: iconColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _DayHabitRow extends StatelessWidget {
  const _DayHabitRow({required this.habit, required this.day});
  final Habit habit;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final status = StreakCalculator.dayStatus(
        habit, c.doneKeys(habit.id), day, c.today);
    final done = status == DayStatus.completed;
    final future = day.isAfter(c.today);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: HabitAvatar(habit: habit, size: 40),
      title: Text(habit.name),
      subtitle: Text(done
          ? 'Completed'
          : status == DayStatus.missed
              ? 'Missed'
              : future
                  ? 'Upcoming'
                  : 'Not done yet'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => HabitDetailsScreen(habitId: habit.id),
        ),
      ),
      trailing: IconButton(
        tooltip: done ? 'Mark as not done' : 'Mark as done',
        onPressed: future
            ? null
            : () => toggleHabitOnDay(context, c, habit, day),
        icon: Icon(
          done ? Icons.check_circle : Icons.circle_outlined,
          color: done ? scheme.primary : scheme.outline,
        ),
      ),
    );
  }
}