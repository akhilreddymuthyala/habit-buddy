// lib/screens/journal_screen.dart
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/journal_entry.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';
import 'journal_editor_screen.dart';
import 'journal_view_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditor(BuildContext context, {String? date}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JournalEditorScreen(initialDate: date),
      ),
    );
  }

  void _openView(BuildContext context, String date) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JournalViewScreen(entryDate: date),
      ),
    );
  }

  Future<void> _jumpToDate() async {
    final c = AppScope.read(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: c.today,
      firstDate: DateTime(2000),
      lastDate: c.today,
    );
    if (picked == null || !mounted) {
      return;
    }
    final key = dateKey(picked);
    final existing = c.journalFor(key);
    if (existing != null) {
      if (!mounted) return;
      _openView(context, key);
    } else {
      if (!mounted) return;
      final shouldCreate = await showConfirmDialog(
        context,
        title: 'No entry for ${formatShortDate(picked)}',
        message: 'Would you like to write a journal entry for this date?',
        confirmLabel: 'Write entry',
      );
      if (shouldCreate && mounted) {
        _openEditor(context, date: key);
      }
    }
  }

  Map<String, List<JournalEntry>> _groupByMonth(List<JournalEntry> entries) {
    final groups = <String, List<JournalEntry>>{};
    for (final entry in entries) {
      final d = parseDateKey(entry.date);
      final monthKey = formatMonthYear(d);
      (groups[monthKey] ??= []).add(entry);
    }
    return groups;
  }

  Widget _entryCard(
      BuildContext context, JournalEntry entry, ThemeData theme) {
    final scheme = theme.colorScheme;
    final d = parseDateKey(entry.date);
    final displayDate = formatLongDate(d);

    // Title or first non-empty line of body as fallback
    String displayTitle = entry.title.trim();
    if (displayTitle.isEmpty) {
      final lines = entry.body
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty);
      displayTitle = lines.isNotEmpty ? lines.first : 'Journal Entry';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openView(context, entry.date),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayDate,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final theme = Theme.of(context);
    final allEntries = c.journalEntries;

    final filtered = _query.isEmpty
        ? allEntries
        : allEntries.where((e) {
            final t = e.title.toLowerCase();
            final b = e.body.toLowerCase();
            return t.contains(_query) || b.contains(_query);
          }).toList();

    final monthGroups = _groupByMonth(filtered);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_outlined),
            tooltip: 'Jump to date',
            onPressed: _jumpToDate,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final todayKey = dateKey(c.today);
          _openEditor(context, date: todayKey);
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Write'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search journals...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          if (allEntries.isEmpty)
            SizedBox(
              height: 380,
              child: EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No journal entries yet',
                message:
                    'Reflect on your day, track your feelings, and capture your personal journey.',
                actionLabel: 'Write today\u2019s entry',
                onAction: () =>
                    _openEditor(context, date: dateKey(c.today)),
              ),
            )
          else if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No journal entries match "$_query".',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (final entry in monthGroups.entries) ...[
              SectionHeader(entry.key),
              for (final j in entry.value) _entryCard(context, j, theme),
            ],
        ],
      ),
    );
  }
}
