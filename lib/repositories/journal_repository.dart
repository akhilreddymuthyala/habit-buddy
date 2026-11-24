// lib/repositories/journal_repository.dart
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/journal_entry.dart';

class JournalRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<JournalEntry>> getAll() async {
    final db = await _db;
    final rows = await db.query('journal_entries', orderBy: 'date DESC');
    return rows.map(JournalEntry.fromMap).toList();
  }

  Future<JournalEntry?> getByDate(String date) async {
    final db = await _db;
    final rows = await db.query(
      'journal_entries',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return JournalEntry.fromMap(rows.first);
  }

  /// Saves an entry: updates if an entry already exists for that date (preserving
  /// the original createdAt and setting updatedAt to now), or inserts a new one.
  Future<JournalEntry> upsert(JournalEntry entry) async {
    final db = await _db;
    return db.transaction((txn) async {
      final existing = await txn.query(
        'journal_entries',
        where: 'date = ?',
        whereArgs: [entry.date],
        limit: 1,
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      if (existing.isNotEmpty) {
        final row = existing.first;
        final updated = entry.copyWith(
          id: row['id'] as String,
          createdAt: row['created_at'] as int,
          updatedAt: now,
        );
        await txn.update(
          'journal_entries',
          updated.toMap(),
          where: 'id = ?',
          whereArgs: [updated.id],
        );
        return updated;
      } else {
        final created = entry.copyWith(
          createdAt: entry.createdAt > 0 ? entry.createdAt : now,
          updatedAt: entry.updatedAt > 0 ? entry.updatedAt : now,
        );
        await txn.insert(
          'journal_entries',
          created.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return created;
      }
    });
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
