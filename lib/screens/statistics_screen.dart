// lib/screens/statistics_screen.dart
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/habit.dart';
import '../services/streak_calculator.dart';
import '../utils/date_utils.dart';
import '../widgets/activity_chart.dart';
import '../widgets/common.dart';
import '../widgets/progress_ring.dart';
import 'achievements_screen.dart';

enum StatRange { week, month, year }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatRange _range = StatRange.week;

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = c.today;
    final habits = c.activeHabits;

    final (from, to) = switch (_range) {
      StatRange.week => (weekStart(today), addDays(weekStart(today), 6)),
      StatRange.month => (
          DateTime(today.year, today.month, 1),
          DateTime(today.year, today.month + 1, 0),
        ),
      StatRange.year => (DateTime(today.year, 1, 1), DateTime(today.year, 12, 31)),
    };
    final periodLabel = switch (_range) {
      StatRange.week => 'This week',
      StatRange.month => formatMonthYear(today),
      StatRange.year => '${today.year}',
    };

    final fromKey = dateKey(from);
    final toKey = dateKey(to);
    final todayKey = dateKey(today);
    final bucketCount = switch (_range) {
      StatRange.week => 7,
      StatRange.month => to.day,
      StatRange.year => 12,
    };
    final values = List<double>.filled(bucketCount, 0);
    for (final h in habits) {
      for (final key in c.doneKeys(h.id)) {
        if (key.compareTo(fromKey) < 0 ||
            key.compareTo(toKey) > 0 ||
            key.compareTo(todayKey) > 0) {
          continue;
        }
        final d = parseDateKey(key);
        final idx = switch (_range) {
          StatRange.week => d.weekday - 1,
          StatRange.month => d.day - 1,
          StatRange.year => d.month - 1,
        };
        values[idx] += 1;
      }
    }
    final labels = switch (_range) {
      StatRange.week => List<String>.of(kWeekdayShort),
      StatRange.month => List<String>.generate(
          bucketCount, (i) => (i == 0 || (i + 1) % 5 == 0) ? '${i + 1}' : ''),
      StatRange.year => [
          for (final m in kMonthNames) m.substring(0, 3),
        ],
    };
    final barWidth = switch (_range) {
      StatRange.week => 20.0,
      StatRange.month => 6.0,
      StatRange.year => 14.0,
    };

    var expected = 0;
    var done = 0;
    final rows = <(Habit, RangeStats)>[];
    for (final h in habits) {
      final rs = c.rangeStatsFor(h, from, to);
      expected += rs.expected;
      done += rs.done;
      rows.add((h, rs));
    }
    final consistency = expected == 0 ? 0.0 : done / expected;
    final totalInRange = values.fold<double>(0, (a, b) => a + b).round();

    Habit? bestCurrent;
    Habit? bestLongest;
    for (final h in habits) {
      final s = c.statsFor(h);
      if (s.currentStreak > 0 &&
          (bestCurrent == null ||
              s.currentStreak > c.statsFor(bestCurrent).currentStreak)) {
        bestCurrent = h;
      }
      if (s.longestStreak > 0 &&
          (bestLongest == null ||
              s.longestStreak > c.statsFor(bestLongest).longestStreak)) {
        bestLongest = h;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            tooltip: 'Achievements',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
            ),
          ),
        ],
      ),
      body: habits.isEmpty
          ? const EmptyState(
              icon: Icons.bar_chart,
              title: 'No statistics yet',
              message: 'Add a habit and check it off to see your progress here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                SegmentedButton<StatRange>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: StatRange.week, label: Text('Week')),
                    ButtonSegment(value: StatRange.month, label: Text('Month')),
                    ButtonSegment(value: StatRange.year, label: Text('Year')),
                  ],
                  selected: {_range},
                  onSelectionChanged: (s) => setState(() => _range = s.first),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        ProgressRing(
                          progress: consistency,
                          size: 84,
                          child: Text('${(consistency * 100).round()}%',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Overall consistency',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              Text(periodLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant)),
                              const SizedBox(height: 6),
                              Text('$done of $expected expected check-ins',
                                  style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: StatBox(
                        label: 'Check-ins ($periodLabel)',
                        value: '$totalInRange',
                        icon: Icons.task_alt,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatBox(
                        label: 'Active habits',
                        value: '${habits.length}',
                        icon: Icons.list_alt,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                StatBox(
                  label: bestCurrent == null
                      ? 'Best current streak'
                      : 'Best current streak \u00b7 ${bestCurrent.name}',
                  value: bestCurrent == null
                      ? '\u2014'
                      : '${c.statsFor(bestCurrent).currentStreak} ${c.statsFor(bestCurrent).unit}',
                  icon: Icons.local_fire_department,
                ),
                const SizedBox(height: 10),
                StatBox(
                  label: bestLongest == null
                      ? 'Longest streak ever'
                      : 'Longest streak ever \u00b7 ${bestLongest.name}',
                  value: bestLongest == null
                      ? '\u2014'
                      : '${c.statsFor(bestLongest).longestStreak} ${c.statsFor(bestLongest).unit}',
                  icon: Icons.emoji_events_outlined,
                ),
                const SectionHeader('Check-ins over time'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 18, 16, 12),
                    child: ActivityChart(
                      values: values,
                      labels: labels,
                      barWidth: barWidth,
                    ),
                  ),
                ),
                const SectionHeader('Per-habit progress'),
                for (final (h, rs) in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      color: scheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                HabitAvatar(habit: h, size: 36),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(h.name,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700)),
                                ),
                                Text('${rs.done}/${rs.expected}',
                                    style: theme.textTheme.labelLarge),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: rs.rate,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Streak ${c.statsFor(h).currentStreak} ${c.statsFor(h).unit} \u00b7 Longest ${c.statsFor(h).longestStreak} \u00b7 ${(rs.rate * 100).round()}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant),
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