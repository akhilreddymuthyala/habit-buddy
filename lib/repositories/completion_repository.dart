// lib/repositories/completion_repository.dart
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/completion.dart';

class CompletionRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<Completion>> all() async {
    final db = await _db;
    final rows = await db.query('completions', orderBy: 'date ASC');
    return rows.map(Completion.fromMap).toList();
  }

  /// Toggles a check-in atomically. The (habit_id, date) primary key
  /// guarantees a habit can never be completed twice on one date.
  /// Returns true when the day is now completed.
  Future<bool> toggle(String habitId, String date) async {
    final db = await _db;
    return db.transaction((txn) async {
      final existing = await txn.query(
        'completions',
        where: 'habit_id = ? AND date = ?',
        whereArgs: [habitId, date],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        await txn.delete('completions',
            where: 'habit_id = ? AND date = ?', whereArgs: [habitId, date]);
        return false;
      }
      await txn.insert(
        'completions',
        Completion(
          habitId: habitId,
          date: date,
          completedAt: DateTime.now().millisecondsSinceEpoch,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return true;
    });
  }

  Future<void> setNote(String habitId, String date, String note) async {
    final db = await _db;
    await db.update(
      'completions',
      {'note': note},
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, date],
    );
  }
}