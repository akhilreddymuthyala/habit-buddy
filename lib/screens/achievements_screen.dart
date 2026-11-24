// lib/screens/achievements_screen.dart
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../services/achievement_service.dart';


class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  IconData _icon(AchievementKind kind) => switch (kind) {
        AchievementKind.dayStreak => Icons.local_fire_department,
        AchievementKind.weekStreak => Icons.date_range,
        AchievementKind.totalCheckIns => Icons.task_alt,
      };

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final list =
        AchievementService.evaluate(c.allHabits, c.doneMap, c.today);
    final unlocked = list.where((a) => a.unlocked).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, size: 36, color: scheme.secondary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('$unlocked of ${list.length} badges unlocked',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final a in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                color: a.unlocked ? null : scheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: a.unlocked
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                        child: Icon(
                          a.unlocked ? _icon(a.kind) : Icons.lock_outline,
                          color: a.unlocked
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(a.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: a.fraction,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.unlocked
                                  ? 'Unlocked'
                                  : '${a.progress} / ${a.target}',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
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