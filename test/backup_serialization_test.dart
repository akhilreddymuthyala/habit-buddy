// test/backup_serialization_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_buddy/models/backup_data.dart';
import 'package:habit_buddy/models/completion.dart';
import 'package:habit_buddy/models/habit.dart';
import 'package:habit_buddy/models/journal_entry.dart';

Habit sampleHabit(String id, {HabitFrequency f = HabitFrequency.selectedDays}) {
  return Habit(
    id: id,
    name: 'Read $id',
    description: 'notes',
    category: 'Learning',
    iconKey: 'book',
    colorValue: 0xFF3F7CAC,
    createdDate: '2026-10-01',
    createdAt: 1000,
    frequency: f,
    weekdays: f == HabitFrequency.selectedDays ? [1, 3, 5] : <int>[],
    weeklyTarget: f == HabitFrequency.weeklyTarget ? 3 : null,
    reminderMinutes: 540,
  );
}

BackupData sample() {
  return BackupData(
    formatVersion: kBackupFormatVersion,
    schemaVersion: kSupportedSchemaVersion,
    exportedAt: DateTime.utc(2026, 10, 13, 8),
    settings: {'themeMode': 'dark', 'remindersEnabled': false},
    categories: const [
      BackupCategory(name: 'Learning', isDefault: true, sortOrder: 1),
    ],
    habits: [sampleHabit('a'), sampleHabit('b', f: HabitFrequency.weeklyTarget)],
    completions: const [
      Completion(habitId: 'a', date: '2026-10-05', note: 'good', completedAt: 5),
      Completion(habitId: 'b', date: '2026-10-06', completedAt: 6),
    ],
  );
}

Map<String, Object?> base() => sample().toJson();

void main() {
  test('round trip keeps habits, completions, notes and settings', () {
    final parsed = BackupData.parse(sample().toPrettyJson());
    expect(parsed.habits.length, 2);
    expect(parsed.habits.first.id, 'a');
    expect(parsed.habits.first.weekdays, [1, 3, 5]);
    expect(parsed.habits.first.reminderMinutes, 540);
    expect(parsed.habits.last.frequency, HabitFrequency.weeklyTarget);
    expect(parsed.habits.last.weeklyTarget, 3);
    expect(parsed.completions.length, 2);
    expect(parsed.completions.first.note, 'good');
    expect(parsed.settings['themeMode'], 'dark');
    expect(parsed.settings['remindersEnabled'], false);
    expect(parsed.categories.single.name, 'Learning');
    expect(parsed.formatVersion, kBackupFormatVersion);
  });

  test('invalid JSON is rejected with a friendly error', () {
    expect(() => BackupData.parse('not json'), throwsA(isA<BackupException>()));
  });

  test('a file from another app is rejected', () {
    final m = base()..['app'] = 'something_else';
    expect(() => BackupData.parse(jsonEncode(m)),
        throwsA(isA<BackupException>()));
  });

  test('unsupported format versions are rejected', () {
    final m = base()..['formatVersion'] = kBackupFormatVersion + 1;
    expect(() => BackupData.parse(jsonEncode(m)),
        throwsA(isA<BackupException>()));
  });

  test('a backup without habits is rejected', () {
    final m = base()..remove('habits');
    expect(() => BackupData.parse(jsonEncode(m)),
        throwsA(isA<BackupException>()));
  });

  test('a selected-days habit without weekdays is rejected', () {
    final m = base();
    final habits = m['habits']! as List;
    (habits.first as Map<String, Object?>)['weekdays'] = <int>[];
    expect(() => BackupData.parse(jsonEncode(m)),
        throwsA(isA<BackupException>()));
  });

  test('an invalid completion date is rejected', () {
    final m = base();
    final completions = m['completions']! as List;
    (completions.first as Map<String, Object?>)['date'] = '2026-13-45';
    expect(() => BackupData.parse(jsonEncode(m)),
        throwsA(isA<BackupException>()));
  });

  test('duplicate completions are collapsed and orphans are skipped', () {
    final m = base();
    final completions = m['completions']! as List;
    completions.add({'habitId': 'a', 'date': '2026-10-05', 'note': 'dup'});
    completions.add({'habitId': 'ghost', 'date': '2026-10-07'});
    final parsed = BackupData.parse(jsonEncode(m));
    expect(parsed.completions.length, 2);
    expect(parsed.skippedCompletions, 1);
  });

  test('duplicate habit ids are rejected', () {
    final m = base();
    final habits = m['habits']! as List;
    habits.add(Map<String, Object?>.from(habits.first as Map<String, Object?>));
    expect(() => BackupData.parse(jsonEncode(m)),
        throwsA(isA<BackupException>()));
  });

  test('a v1 backup without journals still parses', () {
    final m = base()..remove('journals')..['schemaVersion'] = 1;
    final parsed = BackupData.parse(jsonEncode(m));
    expect(parsed.journals, isEmpty);
    expect(parsed.hasJournals, isFalse);
    expect(parsed.habits.length, 2);
  });

  test('a backup with journals round-trips', () {
    final data = BackupData(
      formatVersion: kBackupFormatVersion,
      schemaVersion: kSupportedSchemaVersion,
      exportedAt: DateTime.utc(2026, 10, 13, 8),
      settings: {'themeMode': 'dark', 'remindersEnabled': false},
      categories: const [
        BackupCategory(name: 'Learning', isDefault: true, sortOrder: 1),
      ],
      habits: [sampleHabit('a')],
      completions: const [
        Completion(habitId: 'a', date: '2026-10-05', completedAt: 5),
      ],
      journals: [
        JournalEntry(
          id: 'j1',
          date: '2026-10-15',
          title: 'Notes',
          body: 'Productive day working on Flutter.',
          createdAt: 1000,
          updatedAt: 2000,
        ),
      ],
      hasJournals: true,
    );

    final jsonStr = data.toPrettyJson();
    final parsed = BackupData.parse(jsonStr);
    expect(parsed.hasJournals, isTrue);
    expect(parsed.journals.length, 1);
    expect(parsed.journals.first.id, 'j1');
    expect(parsed.journals.first.date, '2026-10-15');
    expect(parsed.journals.first.title, 'Notes');
    expect(parsed.journals.first.body, 'Productive day working on Flutter.');
  });

  test('duplicate journal dates collapse', () {
    final m = base();
    m['journals'] = [
      {
        'id': 'j1',
        'date': '2026-10-15',
        'title': 'First',
        'body': 'Initial thoughts',
        'createdAt': 100,
        'updatedAt': 200,
      },
      {
        'id': 'j2',
        'date': '2026-10-15',
        'title': 'Second',
        'body': 'Duplicate thoughts for same date',
        'createdAt': 300,
        'updatedAt': 400,
      },
    ];
    final parsed = BackupData.parse(jsonEncode(m));
    expect(parsed.journals.length, 1);
    expect(parsed.journals.first.id, 'j1');
  });

  test('an invalid journal date is rejected', () {
    final m = base();
    m['journals'] = [
      {
        'id': 'j1',
        'date': '2026-15-99',
        'title': 'Bad date',
        'body': 'Body text',
        'createdAt': 100,
        'updatedAt': 200,
      },
    ];
    expect(() => BackupData.parse(jsonEncode(m)),
        throwsA(isA<BackupException>()));
  });
}