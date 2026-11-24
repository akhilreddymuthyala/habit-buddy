// lib/services/streak_calculator.dart
import 'dart:math';

import '../models/habit.dart';
import '../utils/date_utils.dart';

/// STREAK RULES
/// - Streaks are derived from stored completion dates, never from a counter.
/// - Daily / selected-day habits: only scheduled days count. Unscheduled days
///   neither break nor extend a streak. A scheduled day succeeds only when a
///   completion record exists for it.
/// - If today is scheduled and not yet completed, it is "pending": it does not
///   break a streak that ran through yesterday (it simply is not counted yet).
/// - Weekly-target habits: periods are Monday-Sunday weeks. A week succeeds when
///   completions >= min(target, days of that week available since the habit's
///   first day). The streak counts consecutive successful weeks. The current
///   week is pending (does not break) until it succeeds.
/// - Future dates are ignored. The history start is the earlier of the habit's
///   creation date and its earliest completion.
/// - Longest streak is the maximum run over all stored history.
enum DayStatus { completed, missed, scheduled, none }

enum DaySummary { none, completed, partial, missed, scheduled }

class HabitStats {
  const HabitStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
    required this.scheduledCount,
    required this.completedCount,
    required this.weekly,
  });

  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final int scheduledCount;
  final int completedCount;
  final bool weekly;

  int get missedCount => max(0, scheduledCount - completedCount);
  double get completionRate =>
      scheduledCount == 0 ? 0 : completedCount / scheduledCount;
  String get unit => weekly ? 'weeks' : 'days';
}

class RangeStats {
  const RangeStats(this.expected, this.done);
  final int expected;
  final int done;
  double get rate => expected == 0 ? 0 : done / expected;
}

class StreakCalculator {
  static bool isScheduledOn(Habit h, DateTime day) {
    switch (h.frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.selectedDays:
        return h.weekdays.contains(day.weekday);
      case HabitFrequency.weeklyTarget:
        return true;
    }
  }

  static HabitStats compute(Habit h, Set<String> done, DateTime today) {
    final t = dateOnly(today);
    final todayKey = dateKey(t);
    final valid = <String>{
      for (final k in done)
        if (k.compareTo(todayKey) <= 0) k,
    };
    return h.isWeekly ? _weekly(h, valid, t) : _daily(h, valid, t);
  }

  static String _startKey(Habit h, Iterable<String> keys) {
    var s = h.createdDate;
    for (final k in keys) {
      if (k.compareTo(s) < 0) {
        s = k;
      }
    }
    return s;
  }

  static HabitStats _daily(Habit h, Set<String> valid, DateTime t) {
    final start = parseDateKey(_startKey(h, valid));
    final todayKey = dateKey(t);
    var run = 0;
    var longest = 0;
    var scheduled = 0;
    var completed = 0;
    for (var d = start; !d.isAfter(t); d = addDays(d, 1)) {
      if (!isScheduledOn(h, d)) {
        continue;
      }
      final key = dateKey(d);
      if (valid.contains(key)) {
        run++;
        completed++;
        scheduled++;
        if (run > longest) {
          longest = run;
        }
      } else if (key != todayKey) {
        run = 0;
        scheduled++;
      }
    }
    return HabitStats(
      currentStreak: run,
      longestStreak: longest,
      totalCompletions: valid.length,
      scheduledCount: scheduled,
      completedCount: completed,
      weekly: false,
    );
  }

  static HabitStats _weekly(Habit h, Set<String> valid, DateTime t) {
    final target = h.effectiveWeeklyTarget;
    final start = parseDateKey(_startKey(h, valid));
    final counts = <String, int>{};
    for (final k in valid) {
      final w = dateKey(weekStart(parseDateKey(k)));
      counts[w] = (counts[w] ?? 0) + 1;
    }
    final curWeek = weekStart(t);
    final curKey = dateKey(curWeek);
    var run = 0;
    var longest = 0;
    var scheduled = 0;
    var completed = 0;
    for (var w = weekStart(start); !w.isAfter(curWeek); w = addDays(w, 7)) {
      final key = dateKey(w);
      final available = w.isBefore(start) ? 7 - daysBetween(w, start) : 7;
      final required = min(target, max(1, available));
      if ((counts[key] ?? 0) >= required) {
        run++;
        completed++;
        scheduled++;
        if (run > longest) {
          longest = run;
        }
      } else if (key != curKey) {
        run = 0;
        scheduled++;
      }
    }
    return HabitStats(
      currentStreak: run,
      longestStreak: longest,
      totalCompletions: valid.length,
      scheduledCount: scheduled,
      completedCount: completed,
      weekly: true,
    );
  }

  /// Expected vs done within [from, to] (inclusive), never past [today].
  static RangeStats rangeStats(
    Habit h,
    Set<String> done,
    DateTime from,
    DateTime to,
    DateTime today,
  ) {
    final t = dateOnly(today);
    var s = parseDateKey(_startKey(h, done));
    final f = dateOnly(from);
    if (f.isAfter(s)) {
      s = f;
    }
    var e = dateOnly(to);
    if (e.isAfter(t)) {
      e = t;
    }
    if (s.isAfter(e)) {
      return const RangeStats(0, 0);
    }
    var expected = 0;
    var got = 0;
    if (!h.isWeekly) {
      for (var d = s; !d.isAfter(e); d = addDays(d, 1)) {
        if (isScheduledOn(h, d)) {
          expected++;
          if (done.contains(dateKey(d))) {
            got++;
          }
        }
      }
    } else {
      for (var w = weekStart(s); !w.isAfter(e); w = addDays(w, 7)) {
        final ws = w.isBefore(s) ? s : w;
        final we0 = addDays(w, 6);
        final we = we0.isAfter(e) ? e : we0;
        final days = daysBetween(ws, we) + 1;
        final exp = min(h.effectiveWeeklyTarget, days);
        var c = 0;
        for (var d = ws; !d.isAfter(we); d = addDays(d, 1)) {
          if (done.contains(dateKey(d))) {
            c++;
          }
        }
        expected += exp;
        got += min(c, exp);
      }
    }
    return RangeStats(expected, got);
  }

  static DayStatus dayStatus(
    Habit h,
    Set<String> done,
    DateTime day,
    DateTime today,
  ) {
    final d = dateOnly(day);
    final t = dateOnly(today);
    final key = dateKey(d);
    if (d.isAfter(t)) {
      return (!h.isWeekly &&
              isScheduledOn(h, d) &&
              key.compareTo(h.createdDate) >= 0)
          ? DayStatus.scheduled
          : DayStatus.none;
    }
    if (done.contains(key)) {
      return DayStatus.completed;
    }
    if (key.compareTo(h.createdDate) < 0) {
      return DayStatus.none;
    }
    if (h.isWeekly || !isScheduledOn(h, d)) {
      return DayStatus.none;
    }
    return key == dateKey(t) ? DayStatus.scheduled : DayStatus.missed;
  }

  static DaySummary daySummary(
    Iterable<Habit> habits,
    Map<String, Set<String>> doneMap,
    DateTime day,
    DateTime today,
  ) {
    final d = dateOnly(day);
    final t = dateOnly(today);
    final key = dateKey(d);
    var expected = 0;
    var doneFixed = 0;
    var doneOther = 0;
    for (final h in habits) {
      final isDone = doneMap[h.id]?.contains(key) ?? false;
      final relevant = key.compareTo(h.createdDate) >= 0 || isDone;
      if (!relevant) {
        continue;
      }
      if (h.isWeekly) {
        if (isDone) {
          doneOther++;
        }
      } else if (isScheduledOn(h, d)) {
        expected++;
        if (isDone) {
          doneFixed++;
        }
      } else if (isDone) {
        doneOther++;
      }
    }
    final doneTotal = doneFixed + doneOther;
    if (expected == 0 && doneTotal == 0) {
      return DaySummary.none;
    }
    if (doneFixed == expected && doneTotal > 0) {
      return DaySummary.completed;
    }
    if (doneTotal > 0) {
      return DaySummary.partial;
    }
    return d.isBefore(t) ? DaySummary.missed : DaySummary.scheduled;
  }
}