// lib/screens/journal_editor_screen.dart
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';

class JournalEditorScreen extends StatefulWidget {
  const JournalEditorScreen({super.key, this.initialDate});

  final String? initialDate;

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  late DateTime _selectedDate;
  String? _existingId;
  String _savedTitle = '';
  String _savedBody = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();

    if (widget.initialDate != null && isValidDateKey(widget.initialDate!)) {
      _selectedDate = parseDateKey(widget.initialDate!);
    } else {
      _selectedDate = dateOnly(DateTime.now());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForDate(_selectedDate);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _loadForDate(DateTime date) {
    final c = AppScope.read(context);
    final key = dateKey(date);
    final entry = c.journalFor(key);

    setState(() {
      _selectedDate = date;
      if (entry != null) {
        _existingId = entry.id;
        _titleController.text = entry.title;
        _bodyController.text = entry.body;
        _savedTitle = entry.title;
        _savedBody = entry.body;
      } else {
        _existingId = null;
        _titleController.text = '';
        _bodyController.text = '';
        _savedTitle = '';
        _savedBody = '';
      }
    });
  }

  bool _hasUnsavedChanges() {
    return _titleController.text.trim() != _savedTitle.trim() ||
        _bodyController.text.trim() != _savedBody.trim();
  }

  Future<void> _pickDate() async {
    final c = AppScope.read(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(c.today) ? c.today : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: c.today,
    );
    if (picked != null && picked != _selectedDate && mounted) {
      if (_hasUnsavedChanges()) {
        final confirmed = await showConfirmDialog(
          context,
          title: 'Switch date?',
          message:
              'You have unsaved changes. Switching dates will discard your changes for this date.',
          confirmLabel: 'Switch',
          destructive: true,
        );
        if (!confirmed || !mounted) {
          return;
        }
      }
      _loadForDate(picked);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    final c = AppScope.read(context);
    final key = dateKey(_selectedDate);

    try {
      await c.saveJournal(
        id: _existingId,
        date: key,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );
      if (!mounted) return;
      _savedTitle = _titleController.text.trim();
      _savedBody = _bodyController.text.trim();
      showSnack(context, 'Journal entry saved.');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, 'Could not save journal entry. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existingId != null;

    return PopScope(
      canPop: !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await showConfirmDialog(
          context,
          title: 'Discard changes?',
          message:
              'You have unsaved changes. Are you sure you want to discard them?',
          confirmLabel: 'Discard',
          destructive: true,
        );
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Entry' : 'New Entry'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Date'),
                  subtitle: Text(formatLongDate(_selectedDate)),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                  hintText: 'What is on your mind today?',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (val) {
                  if (val != null && val.length > 60) {
                    return 'Title cannot exceed 60 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                maxLines: 12,
                minLines: 6,
                maxLength: 5000,
                decoration: const InputDecoration(
                  labelText: 'Body *',
                  hintText: 'Write your thoughts, reflections, or notes...',
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Body cannot be empty';
                  }
                  if (val.length > 5000) {
                    return 'Body cannot exceed 5000 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
