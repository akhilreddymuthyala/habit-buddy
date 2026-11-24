// lib/screens/habit_details_screen.dart
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../controllers/app_controller.dart';
import '../models/habit.dart';
import '../services/streak_calculator.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';
import 'habit_form_screen.dart';

class HabitDetailsScreen extends StatelessWidget {
  const HabitDetailsScreen({super.key, required this.habitId});
  final String habitId;

  Future<void> _delete(BuildContext context, AppController c, Habit h) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete "${h.name}"?',
      message:
          'This permanently deletes the habit and all of its check-ins and notes. This cannot be undone. Archive it instead to keep your history.',
      confirmLabel: 'Delete forever',
      destructive: true,
    );
    if (!ok || !context.mounted) {
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await c.deleteHabit(h.id);
      navigator.pop();
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('"${h.name}" was deleted.')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not delete the habit.')));
    }
  }

  Future<void> _archive(BuildContext context, AppController c, Habit h) async {
    if (h.archived) {
      await c.restoreHabit(h.id);
      if (context.mounted) {
        showSnack(context, '"${h.name}" was restored.');
      }
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: 'Archive "${h.name}"?',
      message:
          'Archived habits are hidden from Today and statistics, but all check-ins are kept. You can restore it any time.',
      confirmLabel: 'Archive',
    );
    if (!ok || !context.mounted) {
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await c.archiveHabit(h.id);
    navigator.pop();
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('"${h.name}" was archived.')));
  }

  Future<void> _editNote(
      BuildContext context, AppController c, Habit h, String key) async {
    final existing = c.completionFor(h.id, key)?.note ?? '';
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(initial: existing),
    );
    if (text == null) {
      return;
    }
    await c.setNote(h.id, key, text);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final h = c.habitById(habitId);
    if (h == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off,
          title: 'Habit not found',
          message: 'This habit no longer exists.',
        ),
      );
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stats = c.statsFor(h);
    final color = Color(h.colorValue);
    final doneToday = c.isDone(h.id, c.today);
    final scheduledToday = StreakCalculator.isScheduledOn(h, c.today);
    final keys = c.doneKeys(h.id).toList()..sort((a, b) => b.compareTo(a));
    final recent = keys.take(30).toList();
    final ws = weekStart(c.today);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<bool>(
                builder: (_) => HabitFormScreen(habit: h),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'archive') {
                _archive(context, c, h);
              } else if (v == 'delete') {
                _delete(context, c, h);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(h.archived ? 'Restore habit' : 'Archive habit'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Delete habit')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HabitAvatar(habit: h, size: 56),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.name,
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('${h.category} \u00b7 ${h.scheduleLabel}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (h.archived || h.reminderMinutes != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (h.archived)
                          const Chip(
                              avatar: Icon(Icons.archive_outlined, size: 18),
                              label: Text('Archived')),
                        if (h.reminderMinutes != null)
                          Chip(
                              avatar: const Icon(Icons.alarm, size: 18),
                              label: Text(formatMinutes(h.reminderMinutes!))),
                      ],
                    ),
                  ],
                  if (h.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(h.description, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: (h.archived || !scheduledToday && !doneToday)
                ? null
                : () => toggleHabitOnDay(context, c, h, c.today),
            icon: Icon(doneToday ? Icons.undo : Icons.check_circle_outline),
            label: Text(h.archived
                ? 'Archived'
                : !scheduledToday && !doneToday
                    ? 'Not scheduled today'
                    : doneToday
                        ? 'Completed today \u2014 tap to undo'
                        : 'Mark as done today'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatBox(
                  label: 'Current streak (${stats.unit})',
                  value: '${stats.currentStreak}',
                  icon: Icons.local_fire_department,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatBox(
                  label: 'Longest streak (${stats.unit})',
                  value: '${stats.longestStreak}',
                  icon: Icons.emoji_events_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatBox(
                  label: 'Completion rate',
                  value: '${(stats.completionRate * 100).round()}%',
                  icon: Icons.donut_large,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatBox(
                  label: 'Total check-ins',
                  value: '${stats.totalCompletions}',
                  icon: Icons.task_alt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StatBox(
            label: h.isWeekly
                ? 'Weeks missed'
                : 'Scheduled days missed',
            value: '${stats.missedCount}',
            icon: Icons.event_busy_outlined,
          ),
          const SectionHeader('This week'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
              child: Column(
                children: [
                  if (h.isWeekly)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '${c.weeklyCount(h, c.today)} of ${h.effectiveWeeklyTarget} this week',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Builder(builder: (context) {
                            final day = addDays(ws, i);
                            final status = StreakCalculator.dayStatus(
                                h, c.doneKeys(h.id), day, c.today);
                            final isToday = day == c.today;
                            return Column(
                              children: [
                                Text(kWeekdayShort[i],
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: isToday
                                            ? FontWeight.w800
                                            : FontWeight.w500)),
                                const SizedBox(height: 6),
                                InkResponse(
                                  radius: 26,
                                  onTap: () =>
                                      toggleHabitOnDay(context, c, h, day),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Center(
                                      child: DayCircle(
                                        label: '${day.day}',
                                        status: status,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SectionHeader('Completion history',
              trailing: Text('${keys.length} total',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant))),
          if (recent.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text('No check-ins yet. Complete this habit to start your history.',
                    style: theme.textTheme.bodyMedium),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < recent.length; i++) ...[
                    if (i > 0) const Divider(),
                    ListTile(
                      leading: Icon(Icons.check_circle, color: color),
                      title: Text(formatShortDate(parseDateKey(recent[i]))),
                      subtitle: Text(
                        (c.completionFor(h.id, recent[i])?.note ?? '').isEmpty
                            ? 'Tap to add a note'
                            : c.completionFor(h.id, recent[i])!.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.edit_note),
                      onTap: () => _editNote(context, c, h, recent[i]),
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

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.initial});
  final String initial;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Check-in note'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 4,
        maxLength: 200,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'How did it go?'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}