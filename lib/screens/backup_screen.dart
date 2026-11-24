// lib/screens/backup_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../models/backup_data.dart';
import '../services/backup_service.dart';
import '../widgets/common.dart';
import '../theme/app_theme.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _service = BackupService();
  bool _busy = false;
  String? _status;
  bool _statusIsError = false;

  void _setStatus(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }
    setState(() {
      _status = message;
      _statusIsError = error;
    });
  }

  String _stamp() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${two(n.month)}${two(n.day)}_${two(n.hour)}${two(n.minute)}';
  }

  String _describe(Object e) {
    if (e is BackupException) {
      return e.message;
    }
    if (e is PlatformException) {
      return 'Storage or permission problem: ${e.message ?? e.code}';
    }
    return 'Something went wrong. Nothing was changed.';
  }

  Future<void> _createBackup() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final c = AppScope.read(context);
      final data = await c.buildBackup();
      final bytes = Uint8List.fromList(utf8.encode(data.toPrettyJson()));
      final location = await _service.saveBytes(
        bytes,
        fileName: 'habit_buddy_backup_${_stamp()}.json',
        extension: 'json',
      );
      if (location == null) {
        _setStatus('Backup cancelled. No file was created.');
      } else {
        _setStatus(
            'Backup saved (${data.habits.length} habits, ${data.completions.length} check-ins).');
      }
    } catch (e) {
      _setStatus('Backup failed. ${_describe(e)}', error: true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _exportCsv() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final c = AppScope.read(context);
      final csv = await c.buildCsv();
      final location = await _service.saveBytes(
        Uint8List.fromList(utf8.encode(csv)),
        fileName: 'habit_buddy_export_${_stamp()}.csv',
        extension: 'csv',
      );
      if (location == null) {
        _setStatus('Export cancelled. No file was created.');
      } else {
        _setStatus('CSV exported.');
      }
    } catch (e) {
      _setStatus('Export failed. ${_describe(e)}', error: true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<RestoreMode?> _askMode(BackupData data) {
    return showDialog<RestoreMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: Text(
          'Found ${data.habits.length} habits and ${data.completions.length} check-ins.\n\n'
          'Merge adds anything missing and keeps your current data.\n'
          'Replace all deletes your current habits and history first.\n\n'
          'Tip: create a backup of your current data before replacing it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, RestoreMode.merge),
            child: const Text('Merge'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, RestoreMode.replace),
            child: const Text('Replace all'),
          ),
        ],
      ),
    );
  }

  Future<void> _restore() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final text = await _service.pickFileText();
      if (text == null) {
        _setStatus('Restore cancelled. Your data was not changed.');
        return;
      }
      final data = BackupData.parse(text);
      if (!mounted) {
        return;
      }
      final mode = await _askMode(data);
      if (mode == null || !mounted) {
        _setStatus('Restore cancelled. Your data was not changed.');
        return;
      }
      if (mode == RestoreMode.replace) {
        final ok = await showConfirmDialog(
          context,
          title: 'Replace all current data?',
          message:
              'Your current habits, check-ins and notes will be permanently replaced by the backup. This cannot be undone.',
          confirmLabel: 'Replace everything',
          destructive: true,
        );
        if (!ok || !mounted) {
          _setStatus('Restore cancelled. Your data was not changed.');
          return;
        }
      }
      final c = AppScope.read(context);
      final summary = await c.restoreBackup(data, mode);
      final skipped = data.skippedCompletions > 0
          ? ' ${data.skippedCompletions} orphaned check-ins were skipped.'
          : '';
      _setStatus(mode == RestoreMode.replace
          ? 'Restore complete. Your data was replaced (${data.habits.length} habits, ${data.completions.length} check-ins).$skipped'
          : 'Merge complete. Added ${summary.habitsAdded} habits and ${summary.completionsAdded} check-ins.$skipped');
    } catch (e) {
      _setStatus('Restore failed. ${_describe(e)} Your data was not changed.',
          error: true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget action({
      required IconData icon,
      required String title,
      required String text,
      required String button,
      required VoidCallback onPressed,
      bool filled = false,
    }) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: scheme.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(text, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: filled
                    ? FilledButton(
                        onPressed: _busy ? null : onPressed, child: Text(button))
                    : OutlinedButton(
                        onPressed: _busy ? null : onPressed, child: Text(button)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & restore')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          action(
            icon: Icons.upload_file,
            title: 'Create backup',
            text:
                'Save all habits, categories, schedules, check-in history, notes and key settings to a JSON file you choose.',
            button: 'Create backup',
            onPressed: _createBackup,
            filled: true,
          ),
          const SizedBox(height: 12),
          action(
            icon: Icons.download_for_offline_outlined,
            title: 'Restore backup',
            text:
                'Pick a Habit Buddy backup file. You can merge it with your data or replace everything. Nothing changes until you confirm.',
            button: 'Choose backup file',
            onPressed: _restore,
          ),
          const SizedBox(height: 12),
          action(
            icon: Icons.table_chart_outlined,
            title: 'Export check-ins (CSV)',
            text:
                'Export your completion history as a spreadsheet-friendly CSV file. CSV files cannot be restored.',
            button: 'Export CSV',
            onPressed: _exportCsv,
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(),
            ),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                color: _statusIsError
                    ? scheme.error.withValues(alpha: 0.1)
                    : scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _statusIsError
                            ? Icons.error_outline
                            : Icons.info_outline,
                        color: _statusIsError ? scheme.error : scheme.onSurface,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_status!)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Local alias to keep this file self-contained for the destructive button color.
