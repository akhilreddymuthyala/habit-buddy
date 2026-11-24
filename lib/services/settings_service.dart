// lib/services/settings_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple preferences only. The habit database is NOT stored here.
class SettingsService {
  static const String _kTheme = 'theme_mode';
  static const String _kOnboarding = 'onboarding_done';
  static const String _kReminders = 'reminders_enabled';

  late SharedPreferences _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
  }

  ThemeMode get themeMode => switch (_prefs.getString(_kTheme)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  bool get onboardingDone => _prefs.getBool(_kOnboarding) ?? false;
  bool get remindersEnabled => _prefs.getBool(_kReminders) ?? true;

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_kTheme, themeModeName(mode));

  Future<void> setOnboardingDone(bool v) => _prefs.setBool(_kOnboarding, v);

  Future<void> setRemindersEnabled(bool v) => _prefs.setBool(_kReminders, v);

  static String themeModeName(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  static ThemeMode themeModeFromName(String n) => switch (n) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}