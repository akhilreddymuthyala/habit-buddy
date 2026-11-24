// test/journal_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_buddy/models/journal_entry.dart';

void main() {
  final sampleEntry = JournalEntry(
    id: 'entry-1',
    date: '2026-10-15',
    title: 'Morning reflection',
    body: 'Today I started waking up early and reading.',
    createdAt: 1700000000000,
    updatedAt: 1700000005000,
  );

  test('map round trip preserves all fields', () {
    final map = sampleEntry.toMap();
    final restored = JournalEntry.fromMap(map);

    expect(restored.id, sampleEntry.id);
    expect(restored.date, sampleEntry.date);
    expect(restored.title, sampleEntry.title);
    expect(restored.body, sampleEntry.body);
    expect(restored.createdAt, sampleEntry.createdAt);
    expect(restored.updatedAt, sampleEntry.updatedAt);
  });

  test('JSON round trip preserves all fields', () {
    final json = sampleEntry.toJson();
    final restored = JournalEntry.fromJson(json);

    expect(restored.id, sampleEntry.id);
    expect(restored.date, sampleEntry.date);
    expect(restored.title, sampleEntry.title);
    expect(restored.body, sampleEntry.body);
    expect(restored.createdAt, sampleEntry.createdAt);
    expect(restored.updatedAt, sampleEntry.updatedAt);
  });

  test('validation fails when body is empty or whitespace', () {
    expect(
      () => JournalEntry(
        id: '1',
        date: '2026-10-15',
        title: 'Title',
        body: '',
        createdAt: 0,
        updatedAt: 0,
      ),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => JournalEntry(
        id: '1',
        date: '2026-10-15',
        title: 'Title',
        body: '   \n\t  ',
        createdAt: 0,
        updatedAt: 0,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('validation fails when date is invalid', () {
    expect(
      () => JournalEntry(
        id: '1',
        date: 'invalid-date',
        title: 'Title',
        body: 'Valid body text',
        createdAt: 0,
        updatedAt: 0,
      ),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => JournalEntry(
        id: '1',
        date: '2026-02-31', // non-existent date
        title: 'Title',
        body: 'Valid body text',
        createdAt: 0,
        updatedAt: 0,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('validation fails when limits are exceeded', () {
    expect(
      () => JournalEntry(
        id: '1',
        date: '2026-10-15',
        title: 'A' * 61,
        body: 'Body text',
        createdAt: 0,
        updatedAt: 0,
      ),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => JournalEntry(
        id: '1',
        date: '2026-10-15',
        title: 'Valid title',
        body: 'B' * 5001,
        createdAt: 0,
        updatedAt: 0,
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
