// lib/screens/today_screen.dart
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../controllers/app_controller.dart';
import '../models/habit.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';
import '../widgets/habit_tile.dart';
import '../widgets/moon_phase_view.dart';
import '../widgets/progress_ring.dart';
import 'habit_details_screen.dart';
import 'habit_form_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    }
    if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  void _openForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(builder: (_) => const HabitFormScreen()),
    );
  }

  String _subtitle(AppController c, Habit h) {
    if (h.isWeekly) {
      return '${h.category} \u00b7 ${c.weeklyCount(h, c.today)}/${h.effectiveWeeklyTarget} this week';
    }
    return h.category;
  }

  Widget _tile(BuildContext context, AppController c, Habit h) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HabitTile(
        habit: h,
        done: c.isDone(h.id, c.today),
        streak: c.statsFor(h).currentStreak,
        subtitle: _subtitle(c, h),
        onToggle: () => toggleHabitOnDay(context, c, h, c.today),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => HabitDetailsScreen(habitId: h.id),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final due = c.dueToday;
    final met = c.metWeeklyToday;
    final doneCount = due.where((h) => c.isDone(h.id, c.today)).length;
    final total = due.length;
    final progress = total == 0 ? 0.0 : doneCount / total;

    String message;
    if (c.activeHabits.isEmpty) {
      message = 'Add your first habit to get started.';
    } else if (total == 0) {
      message = 'Nothing scheduled today. Enjoy your rest day!';
    } else if (doneCount == total) {
      message = 'All done \u2014 great work today!';
    } else {
      message = '${total - doneCount} to go. You\u2019ve got this!';
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Row(
          children: [
            HabitLogo(size: 32),
            SizedBox(width: 10),
            Text('Habit Buddy'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add habit'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MoonPhaseWidget(date: c.today, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatLongDate(c.today),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  ProgressRing(
                    progress: progress,
                    size: 88,
                    child: Text('${(progress * 100).round()}%',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$doneCount of $total done',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(message, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (c.activeHabits.isEmpty)
            SizedBox(
              height: 360,
              child: EmptyState(
                icon: Icons.spa_outlined,
                title: 'No habits yet',
                message:
                    'Start small: pick one habit you want to build and add it here.',
                actionLabel: 'Add your first habit',
                onAction: () => _openForm(context),
              ),
            )
          else ...[
            const SectionHeader("Today's habits"),
            if (due.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No habits are scheduled for today.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ),
            for (final h in due) _tile(context, c, h),
            if (met.isNotEmpty) ...[
              const SectionHeader('Weekly goals already met'),
              for (final h in met) _tile(context, c, h),
            ],
          ],
        ],
      ),
    );
  }
}