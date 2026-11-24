// lib/screens/archived_habits_screen.dart
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../widgets/common.dart';
import 'habit_details_screen.dart';

class ArchivedHabitsScreen extends StatelessWidget {
  const ArchivedHabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final archived = c.archivedHabits;
    return Scaffold(
      appBar: AppBar(title: const Text('Archived habits')),
      body: archived.isEmpty
          ? const EmptyState(
              icon: Icons.archive_outlined,
              title: 'Nothing archived',
              message:
                  'Archive a habit to hide it from Today while keeping its history.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                for (final h in archived)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      color: Theme.of(context).colorScheme.surface,
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: HabitAvatar(habit: h),
                        title: Text(h.name),
                        subtitle: Text(
                            '${h.category} \u00b7 ${c.statsFor(h).totalCompletions} check-ins'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => HabitDetailsScreen(habitId: h.id),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Restore',
                              icon: const Icon(Icons.unarchive_outlined),
                              onPressed: () async {
                                await c.restoreHabit(h.id);
                                if (context.mounted) {
                                  showSnack(context, '"${h.name}" was restored.');
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Delete permanently',
                              icon: Icon(Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error),
                              onPressed: () async {
                                final ok = await showConfirmDialog(
                                  context,
                                  title: 'Delete "${h.name}"?',
                                  message:
                                      'This permanently deletes the habit and all of its check-ins. This cannot be undone.',
                                  confirmLabel: 'Delete forever',
                                  destructive: true,
                                );
                                if (!ok) {
                                  return;
                                }
                                await c.deleteHabit(h.id);
                                if (context.mounted) {
                                  showSnack(context, '"${h.name}" was deleted.');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}