// lib/repositories/backup_repository.dart
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/backup_data.dart';
import '../models/categories.dart';

class BackupRepository {
  /// Applies [data] inside ONE transaction: either everything is imported or
  /// nothing changes.
  Future<RestoreSummary> restore(BackupData data, RestoreMode mode) async {
    final db = await DatabaseHelper.instance.database;
    return db.transaction((txn) async {
      if (mode == RestoreMode.replace) {
        await txn.delete('completions');
        await txn.delete('habits');
        await txn.delete('categories');
      }
      final existing = (await txn.query('habits', columns: ['id']))
          .map((r) => r['id'] as String)
          .toSet();
      final before = Sqflite.firstIntValue(
              await txn.rawQuery('SELECT COUNT(*) FROM completions')) ??
          0;

      final batch = txn.batch();
      for (var i = 0; i < kDefaultCategories.length; i++) {
        batch.insert('categories', {
          'name': kDefaultCategories[i],
          'is_default': 1,
          'sort_order': i,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final c in data.categories) {
        batch.insert('categories', {
          'name': c.name,
          'is_default': c.isDefault ? 1 : 0,
          'sort_order': c.sortOrder,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      final known = <String>{...existing};
      var habitsAdded = 0;
      for (final h in data.habits) {
        batch.insert('categories', {
          'name': h.category,
          'is_default': 0,
          'sort_order': 100,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        if (existing.contains(h.id)) {
          continue;
        }
        batch.insert('habits', h.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
        known.add(h.id);
        habitsAdded++;
      }
      for (final c in data.completions) {
        if (known.contains(c.habitId)) {
          batch.insert('completions', c.toMap(),
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      if (data.hasJournals) {
        if (mode == RestoreMode.replace) {
          await txn.delete('journal_entries');
          for (final j in data.journals) {
            batch.insert(
              'journal_entries',
              j.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        } else {
          final existingDates =
              (await txn.query('journal_entries', columns: ['date']))
                  .map((r) => r['date'] as String)
                  .toSet();
          for (final j in data.journals) {
            if (!existingDates.contains(j.date)) {
              batch.insert(
                'journal_entries',
                j.toMap(),
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }
        }
      }
      await batch.commit(noResult: true);

      final after = Sqflite.firstIntValue(
              await txn.rawQuery('SELECT COUNT(*) FROM completions')) ??
          0;
      return RestoreSummary(
        habitsAdded: habitsAdded,
        completionsAdded: after - before,
      );
    });
  }
}