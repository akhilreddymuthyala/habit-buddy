// lib/database/database_helper.dart
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/categories.dart';

/// Single, lazily opened SQLite database in the app's private storage.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String dbFileName = 'habit_buddy.db';
  static const int schemaVersion = 2;

  Future<Database>? _dbFuture;

  Future<Database> get database async {
    final existing = _dbFuture;
    if (existing != null) {
      return existing;
    }
    final opening = _open();
    _dbFuture = opening;
    try {
      return await opening;
    } catch (_) {
      _dbFuture = null;
      rethrow;
    }
  }

  Future<Database> _open() async {
    final String path;
    if (kIsWeb) {
      path = dbFileName;
    } else {
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      path = p.join(dir.path, dbFileName);
    }
    return openDatabase(
      path,
      version: schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        created_date TEXT NOT NULL,
        archived INTEGER NOT NULL DEFAULT 0,
        archived_at INTEGER,
        frequency TEXT NOT NULL,
        weekdays TEXT NOT NULL DEFAULT '',
        weekly_target INTEGER,
        reminder_minutes INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE completions (
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        completed_at INTEGER NOT NULL,
        PRIMARY KEY (habit_id, date),
        FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_completions_date ON completions(date)');
    await db.execute('''
      CREATE TABLE categories (
        name TEXT PRIMARY KEY,
        is_default INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 100
      )
    ''');
    for (var i = 0; i < kDefaultCategories.length; i++) {
      await db.insert('categories', {
        'name': kDefaultCategories[i],
        'is_default': 1,
        'sort_order': i,
      });
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_entries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL DEFAULT '',
        body TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_journal_entries_date ON journal_entries(date)');
  }

  /// Migration steps keyed by the version they upgrade TO. Add new entries
  /// (e.g. 2: (db) async { await db.execute('ALTER TABLE ...'); }) when
  /// bumping [schemaVersion]. User data is preserved across upgrades.
  static final Map<int, Future<void> Function(Database db)> _migrations = {
    2: (db) async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS journal_entries (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL UNIQUE,
          title TEXT NOT NULL DEFAULT '',
          body TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_journal_entries_date ON journal_entries(date)');
    },
  };

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      final step = _migrations[v];
      if (step != null) {
        await step(db);
      }
    }
  }
}