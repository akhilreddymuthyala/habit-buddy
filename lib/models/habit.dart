// lib/models/habit.dart
import 'dart:math';

import '../utils/date_utils.dart';

enum HabitFrequency { daily, selectedDays, weeklyTarget }

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.iconKey,
    required this.colorValue,
    required this.createdDate,
    required this.createdAt,
    required this.frequency,
    required this.weekdays,
    this.weeklyTarget,
    this.reminderMinutes,
    this.archived = false,
    this.archivedAt,
  });

  static const int maxNameLength = 40;

  final String id;
  final String name;
  final String description;
  final String category;
  final String iconKey;
  final int colorValue;

  /// Local calendar date (YYYY-MM-DD) the habit was created.
  final String createdDate;
  final int createdAt;
  final HabitFrequency frequency;

  /// 1 = Monday ... 7 = Sunday. Used by [HabitFrequency.selectedDays].
  final List<int> weekdays;
  final int? weeklyTarget;

  /// Minutes since midnight, or null when no reminder is set.
  final int? reminderMinutes;
  final bool archived;
  final int? archivedAt;

  bool get isWeekly => frequency == HabitFrequency.weeklyTarget;

  int get effectiveWeeklyTarget => min(7, max(1, weeklyTarget ?? 1));

  String get scheduleLabel {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Every day';
      case HabitFrequency.selectedDays:
        final sorted = [...weekdays]..sort();
        return sorted.map((d) => kWeekdayShort[d - 1]).join(', ');
      case HabitFrequency.weeklyTarget:
        return '$effectiveWeeklyTarget\u00d7 per week';
    }
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'icon': iconKey,
        'color': colorValue,
        'created_date': createdDate,
        'archived': archived ? 1 : 0,
        'archived_at': archivedAt,
        'frequency': frequency.name,
        'weekdays': weekdays.join(','),
        'weekly_target': weeklyTarget,
        'reminder_minutes': reminderMinutes,
        'created_at': createdAt,
      };

  factory Habit.fromMap(Map<String, Object?> m) {
    final rawDays = (m['weekdays'] as String?) ?? '';
    return Habit(
      id: m['id'] as String,
      name: m['name'] as String,
      description: (m['description'] as String?) ?? '',
      category: m['category'] as String,
      iconKey: m['icon'] as String,
      colorValue: m['color'] as int,
      createdDate: m['created_date'] as String,
      createdAt: m['created_at'] as int,
      archived: (m['archived'] as int) == 1,
      archivedAt: m['archived_at'] as int?,
      frequency: HabitFrequency.values.byName(m['frequency'] as String),
      weekdays: rawDays.isEmpty
          ? <int>[]
          : rawDays.split(',').map(int.parse).toList(),
      weeklyTarget: m['weekly_target'] as int?,
      reminderMinutes: m['reminder_minutes'] as int?,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'icon': iconKey,
        'color': colorValue,
        'createdDate': createdDate,
        'createdAt': createdAt,
        'archived': archived,
        'archivedAt': archivedAt,
        'frequency': frequency.name,
        'weekdays': weekdays,
        'weeklyTarget': weeklyTarget,
        'reminderMinutes': reminderMinutes,
      };

  /// Validates and parses a backup entry. Throws [FormatException].
  factory Habit.fromJson(Map<String, dynamic> j) {
    String reqString(String key) {
      final v = j[key];
      if (v is! String || v.trim().isEmpty) {
        throw FormatException('"$key" is missing or empty');
      }
      return v;
    }

    int reqInt(String key) {
      final v = j[key];
      if (v is! int) {
        throw FormatException('"$key" is missing or not a number');
      }
      return v;
    }

    final freqName = reqString('frequency');
    final frequency = HabitFrequency.values.firstWhere(
      (f) => f.name == freqName,
      orElse: () => throw FormatException('unknown frequency "$freqName"'),
    );

    final rawDays = j['weekdays'];
    final days = <int>{};
    if (rawDays is List) {
      for (final e in rawDays) {
        if (e is! int || e < 1 || e > 7) {
          throw const FormatException('"weekdays" contains an invalid day');
        }
        days.add(e);
      }
    }
    if (frequency == HabitFrequency.selectedDays && days.isEmpty) {
      throw const FormatException('no scheduled weekdays');
    }

    int? weekly;
    final rawWeekly = j['weeklyTarget'];
    if (rawWeekly is int) {
      weekly = min(7, max(1, rawWeekly));
    } else if (frequency == HabitFrequency.weeklyTarget) {
      throw const FormatException('"weeklyTarget" is missing');
    }

    int? reminder;
    final rawReminder = j['reminderMinutes'];
    if (rawReminder is int && rawReminder >= 0 && rawReminder < 1440) {
      reminder = rawReminder;
    }

    final created = reqString('createdDate');
    if (!isValidDateKey(created)) {
      throw const FormatException('"createdDate" is not a valid date');
    }

    final desc = j['description'];
    final cat = j['category'];
    final icon = j['icon'];
    final archivedAt = j['archivedAt'];
    final createdAtRaw = j['createdAt'];

    return Habit(
      id: reqString('id'),
      name: reqString('name').trim(),
      description: desc is String ? desc : '',
      category: cat is String && cat.trim().isNotEmpty
          ? cat.trim()
          : 'Personal Growth',
      iconKey: icon is String && icon.isNotEmpty ? icon : 'star',
      colorValue: reqInt('color'),
      createdDate: created,
      createdAt: createdAtRaw is int ? createdAtRaw : 0,
      archived: j['archived'] == true,
      archivedAt: archivedAt is int ? archivedAt : null,
      frequency: frequency,
      weekdays: days.toList()..sort(),
      weeklyTarget: weekly,
      reminderMinutes: reminder,
    );
  }
}