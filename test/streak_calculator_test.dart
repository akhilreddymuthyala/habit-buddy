// test/streak_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_buddy/models/habit.dart';
import 'package:habit_buddy/services/streak_calculator.dart';

Habit makeHabit({
  HabitFrequency frequency = HabitFrequency.daily,
  List<int> weekdays = const [],
  int? target,
  String created = '2026-10-01',
}) {
  return Habit(
    id: 'h1',
    name: 'Test',
    description: '',
    category: 'Health',
    iconKey: 'star',
    colorValue: 0xFFD4A017,
    createdDate: created,
    createdAt: 0,
    frequency: frequency,
    weekdays: weekdays,
    weeklyTarget: target,
  );
}

HabitStats stats(Habit h, List<String> done, DateTime today) =>
    StreakCalculator.compute(h, done.toSet(), today);

void main() {
  final wed = DateTime(2026, 10, 14); // Wednesday

  group('daily habits', () {
    test('consecutive days build the streak', () {
      final s = stats(
        makeHabit(),
        ['2026-10-10', '2026-10-11', '2026-10-12', '2026-10-13', '2026-10-14'],
        wed,
      );
      expect(s.currentStreak, 5);
      expect(s.longestStreak, 5);
    });

    test('a pending today does not break a streak that ended yesterday', () {
      final s = stats(
        makeHabit(),
        ['2026-10-11', '2026-10-12', '2026-10-13'],
        wed,
      );
      expect(s.currentStreak, 3);
      expect(s.longestStreak, 3);
    });

    test('a missed day resets the current streak', () {
      final s = stats(
        makeHabit(),
        ['2026-10-10', '2026-10-12', '2026-10-13', '2026-10-14'],
        wed,
      );
      expect(s.currentStreak, 3);
      expect(s.longestStreak, 3);
    });

    test('duplicate check-ins are counted once', () {
      final s = stats(
        makeHabit(),
        ['2026-10-13', '2026-10-13', '2026-10-14'],
        wed,
      );
      expect(s.currentStreak, 2);
      expect(s.totalCompletions, 2);
    });

    test('longest streak is preserved after the current streak breaks', () {
      final s = stats(
        makeHabit(),
        [
          '2026-10-01',
          '2026-10-02',
          '2026-10-03',
          '2026-10-04',
          '2026-10-05',
          '2026-10-07',
          '2026-10-08',
        ],
        DateTime(2026, 10, 8),
      );
      expect(s.currentStreak, 2);
      expect(s.longestStreak, 5);
    });

    test('future completions are ignored', () {
      final s = stats(makeHabit(), ['2026-10-14', '2026-10-20'], wed);
      expect(s.totalCompletions, 1);
      expect(s.currentStreak, 1);
    });

    test('completion rate and missed days come from stored records', () {
      final s = stats(
        makeHabit(created: '2026-10-11'),
        ['2026-10-11', '2026-10-13'],
        wed,
      );
      expect(s.scheduledCount, 3);
      expect(s.completedCount, 2);
      expect(s.missedCount, 1);
      expect(s.completionRate, closeTo(2 / 3, 0.0001));
    });

    test('streak continues across a year boundary', () {
      final s = stats(
        makeHabit(created: '2025-12-01'),
        ['2025-12-30', '2025-12-31', '2026-01-01', '2026-01-02'],
        DateTime(2026, 1, 2),
      );
      expect(s.currentStreak, 4);
      expect(s.longestStreak, 4);
    });

    test('streak continues across a month boundary (non-leap February)', () {
      final s = stats(
        makeHabit(created: '2026-02-20'),
        ['2026-02-27', '2026-02-28', '2026-03-01'],
        DateTime(2026, 3, 1),
      );
      expect(s.currentStreak, 3);
    });

    test('streak includes Feb 29 in a leap year', () {
      final s = stats(
        makeHabit(created: '2028-02-20'),
        ['2028-02-28', '2028-02-29', '2028-03-01'],
        DateTime(2028, 3, 1),
      );
      expect(s.currentStreak, 3);
    });
  });

  group('selected-day habits (rest days)', () {
    test('unscheduled weekdays do not break the streak', () {
      // Mon, Wed, Fri. Mon 5 missed; Wed 7, Fri 9, Mon 12 done; Wed 14 pending.
      final h = makeHabit(
        frequency: HabitFrequency.selectedDays,
        weekdays: [1, 3, 5],
        created: '2026-10-05',
      );
      final s = stats(h, ['2026-10-07', '2026-10-09', '2026-10-12'], wed);
      expect(s.currentStreak, 3);
      expect(s.longestStreak, 3);
      expect(s.scheduledCount, 4);
      expect(s.missedCount, 1);
    });

    test('missing a scheduled day breaks the streak', () {
      final h = makeHabit(
        frequency: HabitFrequency.selectedDays,
        weekdays: [1, 3, 5],
        created: '2026-10-05',
      );
      final s = stats(h, ['2026-10-05', '2026-10-09', '2026-10-12'], wed);
      expect(s.currentStreak, 2);
      expect(s.longestStreak, 2);
    });
  });

  group('weekly-target habits', () {
    final h = makeHabit(
      frequency: HabitFrequency.weeklyTarget,
      target: 3,
      created: '2026-09-28', // Monday
    );

    test('consecutive successful weeks build the streak', () {
      final s = stats(
        h,
        [
          '2026-09-28', '2026-09-30', '2026-10-02',
          '2026-10-05', '2026-10-06', '2026-10-07',
          '2026-10-12', '2026-10-13', '2026-10-14',
        ],
        wed,
      );
      expect(s.weekly, isTrue);
      expect(s.currentStreak, 3);
      expect(s.longestStreak, 3);
    });

    test('a failed week breaks the chain at the week transition', () {
      final s = stats(
        h,
        [
          '2026-09-28', '2026-09-30', '2026-10-02',
          '2026-10-05', '2026-10-06',
          '2026-10-12', '2026-10-13', '2026-10-14',
        ],
        wed,
      );
      expect(s.currentStreak, 1);
      expect(s.longestStreak, 1);
    });

    test('the unfinished current week is pending, not a break', () {
      final s = stats(
        h,
        [
          '2026-09-28', '2026-09-30', '2026-10-02',
          '2026-10-05', '2026-10-06', '2026-10-07',
          '2026-10-12',
        ],
        wed,
      );
      expect(s.currentStreak, 2);
      expect(s.longestStreak, 2);
    });
  });

  group('range stats and day status', () {
    test('weekly range expectation is limited to elapsed days', () {
      final h = makeHabit(
        frequency: HabitFrequency.weeklyTarget,
        target: 3,
        created: '2026-09-28',
      );
      final r = StreakCalculator.rangeStats(
        h,
        {'2026-10-12', '2026-10-13'},
        DateTime(2026, 10, 12),
        DateTime(2026, 10, 18),
        wed,
      );
      expect(r.expected, 3);
      expect(r.done, 2);
    });

    test('daily range counts only scheduled days up to today', () {
      final h = makeHabit(created: '2026-10-01');
      final r = StreakCalculator.rangeStats(
        h,
        {'2026-10-12', '2026-10-14'},
        DateTime(2026, 10, 12),
        DateTime(2026, 10, 18),
        wed,
      );
      expect(r.expected, 3);
      expect(r.done, 2);
    });

    test('day status reflects completed, missed and scheduled', () {
      final h = makeHabit(created: '2026-10-01');
      final done = {'2026-10-13'};
      expect(StreakCalculator.dayStatus(h, done, DateTime(2026, 10, 13), wed),
          DayStatus.completed);
      expect(StreakCalculator.dayStatus(h, done, DateTime(2026, 10, 12), wed),
          DayStatus.missed);
      expect(StreakCalculator.dayStatus(h, done, DateTime(2026, 10, 14), wed),
          DayStatus.scheduled);
      expect(StreakCalculator.dayStatus(h, done, DateTime(2026, 9, 30), wed),
          DayStatus.none);
    });
  });
}