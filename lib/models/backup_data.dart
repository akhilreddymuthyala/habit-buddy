// lib/models/backup_data.dart
import 'dart:convert';

import 'completion.dart';
import 'habit.dart';
import 'journal_entry.dart';
import '../utils/date_utils.dart';

/// Backup JSON format (documented):
/// {
///   "app": "habit_buddy",
///   "formatVersion": 1,            // backup file format version
///   "schemaVersion": 1,            // SQLite schema version that produced it
///   "exportedAt": "ISO-8601",
///   "settings": {"themeMode": "system|light|dark", "remindersEnabled": true},
///   "categories": [{"name": "Health", "isDefault": true, "sortOrder": 0}],
///   "habits": [ { id, name, description, category, icon, color, createdDate,
///                 createdAt, archived, archivedAt, frequency, weekdays,
///                 weeklyTarget, reminderMinutes } ],
///   "completions": [ {"habitId": "...", "date": "YYYY-MM-DD",
///                     "note": "", "completedAt": 0} ]
/// }
const int kBackupFormatVersion = 1;
const int kSupportedSchemaVersion = 2;

enum RestoreMode { merge, replace }

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

class RestoreSummary {
  const RestoreSummary({
    required this.habitsAdded,
    required this.completionsAdded,
  });
  final int habitsAdded;
  final int completionsAdded;
}

class BackupCategory {
  const BackupCategory({
    required this.name,
    required this.isDefault,
    required this.sortOrder,
  });
  final String name;
  final bool isDefault;
  final int sortOrder;
}

class BackupData {
  const BackupData({
    required this.formatVersion,
    required this.schemaVersion,
    required this.exportedAt,
    required this.settings,
    required this.categories,
    required this.habits,
    required this.completions,
    this.journals = const [],
    this.hasJournals = false,
    this.skippedCompletions = 0,
  });

  final int formatVersion;
  final int schemaVersion;
  final DateTime exportedAt;
  final Map<String, Object?> settings;
  final List<BackupCategory> categories;
  final List<Habit> habits;
  final List<Completion> completions;
  final List<JournalEntry> journals;
  final bool hasJournals;
  final int skippedCompletions;

  Map<String, Object?> toJson() => {
        'app': 'habit_buddy',
        'formatVersion': formatVersion,
        'schemaVersion': schemaVersion,
        'exportedAt': exportedAt.toIso8601String(),
        'settings': settings,
        'categories': [
          for (final c in categories)
            {'name': c.name, 'isDefault': c.isDefault, 'sortOrder': c.sortOrder},
        ],
        'habits': [for (final h in habits) h.toJson()],
        'completions': [for (final c in completions) c.toJson()],
        if (hasJournals || journals.isNotEmpty)
          'journals': [for (final j in journals) j.toJson()],
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Parses and validates backup text. Throws [BackupException].
  static BackupData parse(String source) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const BackupException(
          'This file is not valid JSON, so it cannot be a Habit Buddy backup.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const BackupException('This file does not look like a Habit Buddy backup.');
    }
    if (decoded['app'] != 'habit_buddy') {
      throw const BackupException('This file was not created by Habit Buddy.');
    }
    final version = decoded['formatVersion'];
    if (version is! int) {
      throw const BackupException('The backup is missing its format version.');
    }
    if (version < 1 || version > kBackupFormatVersion) {
      throw BackupException(
          'Unsupported backup version $version. This app supports version $kBackupFormatVersion.');
    }
    final schemaRaw = decoded['schemaVersion'];
    final schema = schemaRaw is int ? schemaRaw : 1;
    if (schema > kSupportedSchemaVersion) {
      throw const BackupException(
          'This backup was created by a newer version of Habit Buddy. Please update the app.');
    }

    final rawHabits = decoded['habits'];
    final rawCompletions = decoded['completions'];
    if (rawHabits is! List) {
      throw const BackupException('The backup is missing its list of habits.');
    }
    if (rawCompletions is! List) {
      throw const BackupException('The backup is missing its check-in history.');
    }

    final habits = <Habit>[];
    final ids = <String>{};
    for (var i = 0; i < rawHabits.length; i++) {
      final entry = rawHabits[i];
      if (entry is! Map<String, dynamic>) {
        throw BackupException('Habit ${i + 1} in the backup is malformed.');
      }
      final Habit habit;
      try {
        habit = Habit.fromJson(entry);
      } on FormatException catch (e) {
        throw BackupException('Habit ${i + 1} is invalid: ${e.message}.');
      }
      if (!ids.add(habit.id)) {
        throw BackupException('The backup contains the habit "${habit.name}" twice.');
      }
      habits.add(habit);
    }

    final completions = <Completion>[];
    final seen = <String>{};
    var skipped = 0;
    for (var i = 0; i < rawCompletions.length; i++) {
      final entry = rawCompletions[i];
      if (entry is! Map<String, dynamic>) {
        throw BackupException('Check-in ${i + 1} in the backup is malformed.');
      }
      final habitId = entry['habitId'];
      final date = entry['date'];
      if (habitId is! String || date is! String || !isValidDateKey(date)) {
        throw BackupException('Check-in ${i + 1} has a missing or invalid field.');
      }
      if (!ids.contains(habitId)) {
        skipped++;
        continue;
      }
      if (!seen.add('$habitId|$date')) {
        continue;
      }
      final note = entry['note'];
      final at = entry['completedAt'];
      completions.add(Completion(
        habitId: habitId,
        date: date,
        note: note is String ? note : '',
        completedAt: at is int ? at : 0,
      ));
    }

    final categories = <BackupCategory>[];
    final rawCategories = decoded['categories'];
    if (rawCategories is List) {
      for (final e in rawCategories) {
        if (e is Map<String, dynamic>) {
          final name = e['name'];
          if (name is String && name.trim().isNotEmpty) {
            final order = e['sortOrder'];
            categories.add(BackupCategory(
              name: name.trim(),
              isDefault: e['isDefault'] == true,
              sortOrder: order is int ? order : 100,
            ));
          }
        }
      }
    }

    final rawSettings = decoded['settings'];
    final settings = <String, Object?>{};
    if (rawSettings is Map<String, dynamic>) {
      final theme = rawSettings['themeMode'];
      if (theme is String && const ['system', 'light', 'dark'].contains(theme)) {
        settings['themeMode'] = theme;
      }
      final reminders = rawSettings['remindersEnabled'];
      if (reminders is bool) {
        settings['remindersEnabled'] = reminders;
      }
    }

    final rawJournals = decoded['journals'];
    final journals = <JournalEntry>[];
    var hasJournals = false;
    if (rawJournals != null) {
      hasJournals = true;
      if (rawJournals is! List) {
        throw const BackupException('The backup has an invalid journals list.');
      }
      final seenDates = <String>{};
      for (var i = 0; i < rawJournals.length; i++) {
        final entry = rawJournals[i];
        if (entry is! Map<String, dynamic>) {
          throw BackupException('Journal entry ${i + 1} is malformed.');
        }
        final date = entry['date'];
        if (date is! String || !isValidDateKey(date)) {
          throw BackupException('Journal entry ${i + 1} has an invalid date.');
        }
        final body = entry['body'];
        if (body is! String || body.trim().isEmpty) {
          throw BackupException('Journal entry ${i + 1} has an empty body.');
        }
        final JournalEntry j;
        try {
          j = JournalEntry.fromJson(entry);
        } on FormatException catch (e) {
          throw BackupException('Journal entry ${i + 1} is invalid: ${e.message}');
        }
        if (!seenDates.add(j.date)) {
          continue;
        }
        journals.add(j);
      }
    }

    final exported = decoded['exportedAt'];
    return BackupData(
      formatVersion: version,
      schemaVersion: schema,
      exportedAt: (exported is String ? DateTime.tryParse(exported) : null) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      settings: settings,
      categories: categories,
      habits: habits,
      completions: completions,
      journals: journals,
      hasJournals: hasJournals,
      skippedCompletions: skipped,
    );
  }
}