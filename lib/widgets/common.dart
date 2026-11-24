// lib/widgets/common.dart
import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/habit.dart';
import '../services/streak_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/habit_style.dart';

const String kLogoAsset = 'assets/images/habit_buddy_logo.png';

/// Shows the provided logo asset unchanged. If the file has not been copied
/// into assets/images yet, a neutral badge is shown (not a replacement logo).
class HabitLogo extends StatelessWidget {
  const HabitLogo({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      kLogoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Habit Buddy logo',
      errorBuilder: (context, error, stack) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.gold,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded,
            size: size * 0.55, color: AppColors.charcoal),
      ),
    );
  }
}

class HabitAvatar extends StatelessWidget {
  const HabitAvatar({super.key, required this.habit, this.size = 44});
  final Habit habit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(habitIcon(habit.iconKey), color: color, size: size * 0.52),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class StatBox extends StatelessWidget {
  const StatBox({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: scheme.secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single day marker with status shown by color AND icon.
class DayCircle extends StatelessWidget {
  const DayCircle({
    super.key,
    required this.label,
    required this.status,
    required this.color,
    this.size = 38,
  });
  final String label;
  final DayStatus status;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color? fill;
    Color border = Colors.transparent;
    Widget content = Text(label, style: TextStyle(color: scheme.onSurface));
    switch (status) {
      case DayStatus.completed:
        fill = color;
        content = Icon(Icons.check, size: size * 0.55, color: onColor(color));
      case DayStatus.missed:
        border = scheme.error;
        content = Icon(Icons.close, size: size * 0.5, color: scheme.error);
      case DayStatus.scheduled:
        border = scheme.outline;
      case DayStatus.none:
        content = Text(label,
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.4)));
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
      ),
      child: content,
    );
  }
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Toggles a check-in with validation and visible feedback (with Undo).
Future<void> toggleHabitOnDay(
  BuildContext context,
  AppController c,
  Habit h,
  DateTime day,
) async {
  final messenger = ScaffoldMessenger.of(context);
  void say(String m, {SnackBarAction? action}) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(m), action: action));
  }

  final d = dateOnly(day);
  if (d.isAfter(c.today)) {
    say('You can only check off today or past days.');
    return;
  }
  if (h.archived) {
    say('Restore this habit to change its check-ins.');
    return;
  }
  if (!StreakCalculator.isScheduledOn(h, d) && !c.isDone(h.id, d)) {
    say('"${h.name}" is not scheduled on ${kWeekdayNames[d.weekday - 1]}s.');
    return;
  }
  try {
    final nowDone = await c.toggleCompletion(h.id, d);
    if (nowDone == null) {
      return;
    }
    final suffix = d == c.today ? '' : ' for ${formatShortDate(d)}';
    say(
      nowDone
          ? 'Checked off "${h.name}"$suffix.'
          : 'Unchecked "${h.name}"$suffix.',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          c.toggleCompletion(h.id, d);
        },
      ),
    );
  } catch (_) {
    say('Could not save that change. Please try again.');
  }
}