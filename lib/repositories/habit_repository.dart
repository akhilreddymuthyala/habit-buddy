// lib/repositories/habit_repository.dart
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/habit.dart';

class HabitRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<Habit>> getAll() async {
    final db = await _db;
    final rows = await db.query('habits', orderBy: 'created_at ASC');
    return rows.map(Habit.fromMap).toList();
  }

  Future<void> insert(Habit habit) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('categories', {
        'name': habit.category,
        'is_default': 0,
        'sort_order': 100,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.insert('habits', habit.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort);
    });
  }

  Future<void> update(Habit habit) async {
    final db = await _db;
    await db.update('habits', habit.toMap(),
        where: 'id = ?', whereArgs: [habit.id]);
  }

  /// Archiving keeps all check-ins; archived habits are excluded from today's
  /// progress and overall statistics.
  Future<void> setArchived(String id, bool archived) async {
    final db = await _db;
    await db.update(
      'habits',
      {
        'archived': archived ? 1 : 0,
        'archived_at': archived ? DateTime.now().millisecondsSinceEpoch : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Permanent delete: removes the habit and ALL of its check-ins.
  Future<void> delete(String id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('completions', where: 'habit_id = ?', whereArgs: [id]);
      await txn.delete('habits', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<String>> categories() async {
    final db = await _db;
    final rows = await db.query('categories', orderBy: 'sort_order ASC, name ASC');
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<void> addCategory(String name) async {
    final db = await _db;
    await db.insert('categories', {
      'name': name,
      'is_default': 0,
      'sort_order': 100,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}