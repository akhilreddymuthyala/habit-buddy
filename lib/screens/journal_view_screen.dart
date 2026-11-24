// lib/screens/journal_view_screen.dart
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/journal_entry.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';
import 'journal_editor_screen.dart';

class JournalViewScreen extends StatelessWidget {
  const JournalViewScreen({super.key, required this.entryDate});

  final String entryDate;

  Future<void> _delete(BuildContext context, JournalEntry entry) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete journal entry?',
      message: 'Are you sure you want to delete this entry? This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final c = AppScope.read(context);
    await c.deleteJournal(entry.id);
    if (!context.mounted) {
      return;
    }
    showSnack(context, 'Journal entry deleted.');
    Navigator.of(context).pop();
  }

  void _edit(BuildContext context, JournalEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JournalEditorScreen(initialDate: entry.date),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entry = c.journalFor(entryDate);

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Journal')),
        body: const Center(child: Text('Entry not found.')),
      );
    }

    final dateObj = parseDateKey(entry.date);
    final displayDate = formatLongDate(dateObj);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit entry',
            onPressed: () => _edit(context, entry),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete entry',
            onPressed: () => _delete(context, entry),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
        children: [
          Text(
            displayDate,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (entry.title.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          SelectableText(
            entry.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
