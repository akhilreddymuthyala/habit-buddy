// lib/widgets/habit_tile.dart
import 'package:flutter/material.dart';

import '../models/habit.dart';
import 'common.dart';

class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.done,
    required this.streak,
    required this.subtitle,
    required this.onToggle,
    required this.onTap,
  });

  final Habit habit;
  final bool done;
  final int streak;
  final String subtitle;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final unit = habit.isWeekly ? 'weeks' : 'days';
    return Card(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              HabitAvatar(habit: habit),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (streak > 0)
                Semantics(
                  label: 'Current streak: $streak $unit',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department,
                          size: 18, color: Colors.deepOrange.shade400),
                      const SizedBox(width: 2),
                      Text('$streak${habit.isWeekly ? 'w' : 'd'}',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              const SizedBox(width: 4),
              Semantics(
                button: true,
                checked: done,
                label: done
                    ? 'Mark ${habit.name} as not done'
                    : 'Mark ${habit.name} as done',
                child: InkResponse(
                  onTap: onToggle,
                  radius: 28,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? scheme.primary : Colors.transparent,
                          border: Border.all(
                            color: done ? scheme.primary : scheme.outline,
                            width: 2,
                          ),
                        ),
                        child: done
                            ? Icon(Icons.check,
                                size: 20, color: scheme.onPrimary)
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}