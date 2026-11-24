// lib/controllers/app_controller.dart
import 'package:flutter/material.dart';

import '../models/backup_data.dart';
import '../models/completion.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';
import '../repositories/backup_repository.dart';
import '../repositories/completion_repository.dart';
import '../repositories/habit_repository.dart';
import '../repositories/journal_repository.dart';
import '../services/csv_export.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/streak_calculator.dart';
import '../utils/date_utils.dart';
import '../utils/ids.dart';
import '../database/database_helper.dart';

/// Holds app state; all business logic lives here and in services/repositories.
class AppController extends ChangeNotifier {
  final HabitRepository _habits = HabitRepository();
  final CompletionRepository _completions = CompletionRepository();
  final JournalRepository _journals = JournalRepository();
  final BackupRepository _backup = BackupRepository();
  final SettingsService _settings = SettingsService();
  final NotificationService _notifications = NotificationService.instance;

  List<Habit> _all = const [];
  List<String> _categories = const [];
  List<JournalEntry> _journalEntries = const [];
  final Map<String, JournalEntry> _byDate = {};
  final Map<String, Map<String, Completion>> _byHabit = {};
  final Map<String, Set<String>> _doneKeys = {};
  final Map<String, HabitStats> _statsCache = {};
  final Set<String> _busy = {};

  bool _initialized = false;
  Future<void>? _initFuture;
  ThemeMode _themeMode = ThemeMode.system;
  bool _remindersEnabled = true;
  bool _onboardingDone = false;
  DateTime _today = dateOnly(DateTime.now());

  bool get initialized => _initialized;
  ThemeMode get themeMode => _themeMode;
  bool get remindersEnabled => _remindersEnabled;
  bool get onboardingDone => _onboardingDone;
  DateTime get today => _today;
  List<String> get categories => _categories;
  List<Habit> get allHabits => _all;
  List<Habit> get activeHabits =>
      _all.where((h) => !h.archived).toList(growable: false);
  List<Habit> get archivedHabits =>
      _all.where((h) => h.archived).toList(growable: false);
  Map<String, Set<String>> get doneMap => _doneKeys;
  List<JournalEntry> get journalEntries => _journalEntries;

  JournalEntry? journalFor(String dateKey) => _byDate[dateKey];

  Future<JournalEntry> saveJournal({
    String? id,
    required String date,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final entryId = (id != null && id.isNotEmpty) ? id : generateId();
    final existing = _byDate[date];
    final entry = JournalEntry(
      id: existing?.id ?? entryId,
      date: date,
      title: title,
      body: body,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    final saved = await _journals.upsert(entry);
    await _reload();
    return saved;
  }

  Future<void> deleteJournal(String id) async {
    await _journals.delete(id);
    await _reload();
  }

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    final pending = _initFuture;
    if (pending != null) {
      return pending;
    }
    final f = _doInit();
    _initFuture = f;
    try {
      await f;
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }

  Future<void> _doInit() async {
    await _settings.load();
    _themeMode = _settings.themeMode;
    _remindersEnabled = _settings.remindersEnabled;
    _onboardingDone = _settings.onboardingDone;
    _today = dateOnly(DateTime.now());
    await _reload();
    _initialized = true;
    notifyListeners();
    await _syncRemindersSafe();
  }

  Future<void> _reload() async {
    final habits = await _habits.getAll();
    final cats = await _habits.categories();
    final comps = await _completions.all();
    final entries = await _journals.getAll();
    _all = habits;
    _categories = cats;
    _journalEntries = entries;
    _byDate.clear();
    for (final j in entries) {
      _byDate[j.date] = j;
    }
    _byHabit.clear();
    _doneKeys.clear();
    for (final c in comps) {
      (_byHabit[c.habitId] ??= {})[c.date] = c;
      (_doneKeys[c.habitId] ??= <String>{}).add(c.date);
    }
    _statsCache.clear();
    notifyListeners();
  }

  void onResume() {
    final t = dateOnly(DateTime.now());
    if (t != _today) {
      _today = t;
      _statsCache.clear();
      notifyListeners();
    }
  }

  // ---- queries -----------------------------------------------------------

  Habit? habitById(String id) {
    for (final h in _all) {
      if (h.id == id) {
        return h;
      }
    }
    return null;
  }

  Set<String> doneKeys(String habitId) => _doneKeys[habitId] ?? const <String>{};

  bool isDone(String habitId, DateTime day) =>
      doneKeys(habitId).contains(dateKey(day));

  Completion? completionFor(String habitId, String key) =>
      _byHabit[habitId]?[key];

  HabitStats statsFor(Habit h) => _statsCache.putIfAbsent(
        h.id,
        () => StreakCalculator.compute(h, doneKeys(h.id), _today),
      );

  RangeStats rangeStatsFor(Habit h, DateTime from, DateTime to) =>
      StreakCalculator.rangeStats(h, doneKeys(h.id), from, to, _today);

  int weeklyCount(Habit h, DateTime day) {
    final ws = weekStart(day);
    var n = 0;
    for (var i = 0; i < 7; i++) {
      if (isDone(h.id, addDays(ws, i))) {
        n++;
      }
    }
    return n;
  }

  bool isDueOn(Habit h, DateTime day) {
    if (h.isWeekly) {
      return isDone(h.id, day) || weeklyCount(h, day) < h.effectiveWeeklyTarget;
    }
    return StreakCalculator.isScheduledOn(h, day);
  }

  /// Habits that count toward today's progress (archived never included).
  List<Habit> get dueToday =>
      activeHabits.where((h) => isDueOn(h, _today)).toList(growable: false);

  /// Weekly-target habits whose target was already met earlier this week.
  List<Habit> get metWeeklyToday => activeHabits
      .where((h) => h.isWeekly && !isDueOn(h, _today))
      .toList(growable: false);

  List<Habit> habitsForDay(DateTime day) {
    final key = dateKey(day);
    return activeHabits.where((h) {
      final done = doneKeys(h.id).contains(key);
      if (done) {
        return true;
      }
      return key.compareTo(h.createdDate) >= 0 &&
          StreakCalculator.isScheduledOn(h, day);
    }).toList(growable: false);
  }

  DaySummary daySummary(DateTime day) =>
      StreakCalculator.daySummary(activeHabits, _doneKeys, day, _today);

  bool nameExists(String name, {String? excludeId}) {
    final n = name.trim().toLowerCase();
    return _all.any((h) =>
        !h.archived && h.id != excludeId && h.name.trim().toLowerCase() == n);
  }

  // ---- mutations ---------------------------------------------------------

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    await _settings.setOnboardingDone(true);
    notifyListeners();
  }

  Future<void> saveHabit(Habit habit, {required bool isNew}) async {
    final lock = 'save:${habit.id}';
    if (!_busy.add(lock)) {
      return;
    }
    try {
      if (isNew) {
        await _habits.insert(habit);
      } else {
        await _habits.update(habit);
      }
      await _reload();
      await _scheduleSafe(habit);
    } finally {
      _busy.remove(lock);
    }
  }

  Future<void> addCategory(String name) async {
    await _habits.addCategory(name.trim());
    await _reload();
  }

  Future<void> archiveHabit(String id) async {
    await _habits.setArchived(id, true);
    await _reload();
    await _safe(() => _notifications.cancelHabit(id));
  }

  Future<void> restoreHabit(String id) async {
    await _habits.setArchived(id, false);
    await _reload();
    final h = habitById(id);
    if (h != null) {
      await _scheduleSafe(h);
    }
  }

  Future<void> deleteHabit(String id) async {
    await _habits.delete(id);
    await _reload();
    await _safe(() => _notifications.cancelHabit(id));
  }

  /// Returns the new completion state, or null when ignored (future date or
  /// an identical request still in flight).
  Future<bool?> toggleCompletion(String habitId, DateTime day) async {
    final d = dateOnly(day);
    if (d.isAfter(_today)) {
      return null;
    }
    final lock = 'toggle:$habitId|${dateKey(d)}';
    if (!_busy.add(lock)) {
      return null;
    }
    try {
      final nowDone = await _completions.toggle(habitId, dateKey(d));
      await _reload();
      return nowDone;
    } finally {
      _busy.remove(lock);
    }
  }

  Future<void> setNote(String habitId, String key, String note) async {
    await _completions.setNote(habitId, key, note.trim());
    await _reload();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _settings.setThemeMode(mode);
  }

  Future<bool> requestNotificationPermission() async {
    try {
      return await _notifications.requestPermission();
    } catch (_) {
      return false;
    }
  }

  /// Returns false when the user turned reminders on but permission was denied.
  Future<bool> setRemindersEnabled(bool value) async {
    if (value) {
      final granted = await requestNotificationPermission();
      if (!granted) {
        _remindersEnabled = false;
        await _settings.setRemindersEnabled(false);
        notifyListeners();
        return false;
      }
    }
    _remindersEnabled = value;
    await _settings.setRemindersEnabled(value);
    notifyListeners();
    await _syncRemindersSafe();
    return true;
  }

  // ---- backup / restore --------------------------------------------------

  Future<BackupData> buildBackup() async {
    final habits = await _habits.getAll();
    final cats = await _habits.categories();
    final comps = await _completions.all();
    final db = await DatabaseHelper.instance.database;
    final catRows = await db.query('categories');
    final meta = {
      for (final r in catRows)
        r['name'] as String: (
          (r['is_default'] as int) == 1,
          r['sort_order'] as int,
        ),
    };
    return BackupData(
      formatVersion: kBackupFormatVersion,
      schemaVersion: DatabaseHelper.schemaVersion,
      exportedAt: DateTime.now(),
      settings: {
        'themeMode': SettingsService.themeModeName(_themeMode),
        'remindersEnabled': _remindersEnabled,
      },
      categories: [
        for (final name in cats)
          BackupCategory(
            name: name,
            isDefault: meta[name]?.$1 ?? false,
            sortOrder: meta[name]?.$2 ?? 100,
          ),
      ],
      habits: habits,
      completions: comps,
      journals: _journalEntries,
      hasJournals: true,
    );
  }

  Future<String> buildCsv() async {
    final habits = await _habits.getAll();
    final comps = await _completions.all();
    return buildCompletionsCsv(habits, comps);
  }

  Future<RestoreSummary> restoreBackup(BackupData data, RestoreMode mode) async {
    final summary = await _backup.restore(data, mode);
    if (mode == RestoreMode.replace) {
      final theme = data.settings['themeMode'];
      if (theme is String) {
        _themeMode = SettingsService.themeModeFromName(theme);
        await _settings.setThemeMode(_themeMode);
      }
      final reminders = data.settings['remindersEnabled'];
      if (reminders is bool) {
        _remindersEnabled = reminders;
        await _settings.setRemindersEnabled(reminders);
      }
    }
    await _reload();
    await _syncRemindersSafe();
    return summary;
  }

  // ---- reminders ---------------------------------------------------------

  Future<void> _scheduleSafe(Habit h) async {
    final fresh = habitById(h.id) ?? h;
    await _safe(() async {
      if (_remindersEnabled && fresh.reminderMinutes != null && !fresh.archived) {
        await _notifications.scheduleHabit(fresh);
      } else {
        await _notifications.cancelHabit(fresh.id);
      }
    });
  }

  Future<void> _syncRemindersSafe() async {
    await _safe(() async {
      await _notifications.cancelAll();
      if (!_remindersEnabled) {
        return;
      }
      for (final h in activeHabits) {
        if (h.reminderMinutes != null) {
          await _notifications.scheduleHabit(h);
        }
      }
    });
  }

  /// Reminder failures must never block core, offline habit tracking.
  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Notifications are optional; ignore platform failures.
    }
  }
}