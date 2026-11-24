// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../widgets/common.dart';
import 'achievements_screen.dart';
import 'archived_habits_screen.dart';
import 'backup_screen.dart';

const String kAppVersion = '2.0.0';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const SectionHeader('Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('System')),
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light')),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark')),
                ],
                selected: {c.themeMode},
                onSelectionChanged: (s) => c.setThemeMode(s.first),
              ),
            ),
          ),
          const SectionHeader('Reminders'),
          Card(
            child: SwitchListTile(
              title: const Text('Habit reminders'),
              subtitle: const Text(
                  'Show a notification at each habit\u2019s reminder time. Works offline.'),
              value: c.remindersEnabled,
              onChanged: (v) async {
                final ok = await c.setRemindersEnabled(v);
                if (v && !ok && context.mounted) {
                  showSnack(context,
                      'Notification permission was not granted. You can allow it in Android settings.');
                }
              },
            ),
          ),
          const SectionHeader('Your data'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Backup & restore'),
                  subtitle: const Text('Create a backup, restore, or export CSV'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const BackupScreen()),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('Archived habits'),
                  subtitle: Text('${c.archivedHabits.length} archived'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const ArchivedHabitsScreen()),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: const Text('Achievements'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const AchievementsScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('About'),
          Card(
            child: ListTile(
              leading: const HabitLogo(size: 36),
              title: const Text('Habit Buddy'),
              subtitle: Text('Version $kAppVersion \u00b7 All data stays on this device',
                  style: theme.textTheme.bodySmall),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Habit Buddy',
                applicationVersion: kAppVersion,
                applicationIcon: const HabitLogo(size: 48),
                children: const [
                  Text(
                      'An offline-first habit tracker. Your habits and check-ins are stored only on this phone. Use Backup & restore to keep a copy.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}