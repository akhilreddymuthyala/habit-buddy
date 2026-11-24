// lib/services/achievement_service.dart
import 'dart:math';

import '../models/habit.dart';
import 'streak_calculator.dart';

enum AchievementKind { dayStreak, weekStreak, totalCheckIns }

class Achievement {
  const Achievement({
    required this.id,
    required this.kind,
    required this.target,
    required this.title,
    required this.description,
    required this.progress,
  });

  final String id;
  final AchievementKind kind;
  final int target;
  final String title;
  final String description;
  final int progress;

  bool get unlocked => progress >= target;
  double get fraction => min(1.0, progress / target);
}

/// Badges are derived from stored history, so they are only unlocked when the
/// real condition is satisfied (and archived habits keep their history).
class AchievementService {
  static const List<(AchievementKind, int, String, String)> _defs = [
    (AchievementKind.totalCheckIns, 1, 'First Step', 'Complete your first check-in.'),
    (AchievementKind.totalCheckIns, 10, 'Getting Going', 'Complete 10 check-ins.'),
    (AchievementKind.totalCheckIns, 50, 'Habit Builder', 'Complete 50 check-ins.'),
    (AchievementKind.totalCheckIns, 100, 'Centurion', 'Complete 100 check-ins.'),
    (AchievementKind.totalCheckIns, 500, 'Unstoppable', 'Complete 500 check-ins.'),
    (AchievementKind.dayStreak, 3, '3-Day Streak', 'Keep one habit going for 3 scheduled days in a row.'),
    (AchievementKind.dayStreak, 7, '7-Day Streak', 'Keep one habit going for 7 scheduled days in a row.'),
    (AchievementKind.dayStreak, 14, '14-Day Streak', 'Keep one habit going for 14 scheduled days in a row.'),
    (AchievementKind.dayStreak, 30, '30-Day Streak', 'Keep one habit going for 30 scheduled days in a row.'),
    (AchievementKind.dayStreak, 60, '60-Day Streak', 'Keep one habit going for 60 scheduled days in a row.'),
    (AchievementKind.dayStreak, 100, '100-Day Streak', 'Keep one habit going for 100 scheduled days in a row.'),
    (AchievementKind.weekStreak, 4, '4-Week Streak', 'Hit a weekly target 4 weeks in a row.'),
    (AchievementKind.weekStreak, 12, '12-Week Streak', 'Hit a weekly target 12 weeks in a row.'),
  ];

  static List<Achievement> evaluate(
    Iterable<Habit> habits,
    Map<String, Set<String>> doneMap,
    DateTime today,
  ) {
    var bestDays = 0;
    var bestWeeks = 0;
    var total = 0;
    for (final h in habits) {
      final stats =
          StreakCalculator.compute(h, doneMap[h.id] ?? const <String>{}, today);
      total += stats.totalCompletions;
      if (stats.weekly) {
        bestWeeks = max(bestWeeks, stats.longestStreak);
      } else {
        bestDays = max(bestDays, stats.longestStreak);
      }
    }
    return [
      for (final d in _defs)
        Achievement(
          id: '${d.$1.name}_${d.$2}',
          kind: d.$1,
          target: d.$2,
          title: d.$3,
          description: d.$4,
          progress: switch (d.$1) {
            AchievementKind.dayStreak => bestDays,
            AchievementKind.weekStreak => bestWeeks,
            AchievementKind.totalCheckIns => total,
          },
        ),
    ];
  }
}