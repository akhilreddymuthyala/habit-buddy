// lib/services/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

/// Local (offline) reminders. Notification ids are stable per habit:
/// id = baseId(habit.id) * 10 + slot, where slot is 0 for daily/weekly-target
/// habits and 1..7 (weekday) for selected-day habits.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const String _channelId = 'habit_reminders';

  static int baseId(String habitId) {
    var hash = 0x811C9DC5;
    for (final unit in habitId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash % 100000000;
  }

  Future<void> init() async {
    if (kIsWeb || _ready) {
      return;
    }
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      final offset = DateTime.now().timeZoneOffset;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (tz.TZDateTime.now(loc).timeZoneOffset == offset) {
          tz.setLocalLocation(loc);
          break;
        }
      }
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    _ready = true;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) {
      return true;
    }
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return true;
    }
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancelAll();
  }

  Future<void> cancelHabit(String habitId) async {
    if (kIsWeb) return;
    await init();
    final base = baseId(habitId);
    for (var slot = 0; slot <= 7; slot++) {
      await _plugin.cancel(base * 10 + slot);
    }
  }

  Future<void> scheduleHabit(Habit h) async {
    if (kIsWeb) return;
    await init();
    await cancelHabit(h.id);
    final minutes = h.reminderMinutes;
    if (minutes == null || h.archived) {
      return;
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Habit reminders',
        channelDescription: 'Reminders for your habits',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    final body = 'Time for: ${h.name}';
    final base = baseId(h.id);
    if (h.frequency == HabitFrequency.selectedDays) {
      for (final wd in h.weekdays) {
        await _plugin.zonedSchedule(
          base * 10 + wd,
          'Habit Buddy',
          body,
          _next(minutes, weekday: wd),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } else {
      await _plugin.zonedSchedule(
        base * 10,
        'Habit Buddy',
        body,
        _next(minutes),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  tz.TZDateTime _next(int minutes, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (t.isBefore(now) || (weekday != null && t.weekday != weekday)) {
      t = tz.TZDateTime(tz.local, t.year, t.month, t.day + 1, hour, minute);
    }
    return t;
  }
}