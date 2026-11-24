// lib/screens/habit_form_screen.dart
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/habit.dart';
import '../utils/date_utils.dart';
import '../utils/habit_style.dart';
import '../utils/ids.dart';
import '../widgets/common.dart';

class HabitFormScreen extends StatefulWidget {
  const HabitFormScreen({super.key, this.habit});

  /// When non-null the screen edits this habit.
  final Habit? habit;

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late String _category;
  late String _iconKey;
  late int _colorValue;
  late HabitFrequency _frequency;
  late Set<int> _weekdays;
  late int _weeklyTarget;
  int? _reminderMinutes;
  bool _weekdayError = false;
  bool _saving = false;

  bool get _isEdit => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _name = TextEditingController(text: h?.name ?? '');
    _description = TextEditingController(text: h?.description ?? '');
    _category = h?.category ?? 'Health';
    _iconKey = h?.iconKey ?? 'star';
    _colorValue = h?.colorValue ?? kHabitColors.first.toARGB32();
    _frequency = h?.frequency ?? HabitFrequency.daily;
    _weekdays = Set<int>.of(h?.weekdays ?? const <int>[]);
    _weeklyTarget = h?.weeklyTarget ?? 3;
    _reminderMinutes = h?.reminderMinutes;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final m = _reminderMinutes ?? 9 * 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
    );
    if (picked != null && mounted) {
      setState(() => _reminderMinutes = picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _addCategory() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewCategoryDialog(),
    );
    if (name == null || !mounted) {
      return;
    }
    final c = AppScope.read(context);
    await c.addCategory(name);
    if (!mounted) {
      return;
    }
    setState(() => _category = name);
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    final valid = _formKey.currentState!.validate();
    final daysOk =
        _frequency != HabitFrequency.selectedDays || _weekdays.isNotEmpty;
    setState(() => _weekdayError = !daysOk);
    if (!valid || !daysOk) {
      return;
    }
    setState(() => _saving = true);
    final c = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final existing = widget.habit;
    final habit = Habit(
      id: existing?.id ?? generateId(),
      name: _name.text.trim(),
      description: _description.text.trim(),
      category: _category,
      iconKey: _iconKey,
      colorValue: _colorValue,
      createdDate: existing?.createdDate ?? dateKey(c.today),
      createdAt: existing?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      archived: existing?.archived ?? false,
      archivedAt: existing?.archivedAt,
      frequency: _frequency,
      weekdays: _frequency == HabitFrequency.selectedDays
          ? (_weekdays.toList()..sort())
          : <int>[],
      weeklyTarget: _frequency == HabitFrequency.weeklyTarget ? _weeklyTarget : null,
      reminderMinutes: _reminderMinutes,
    );
    try {
      var permissionNote = '';
      if (_reminderMinutes != null && c.remindersEnabled) {
        final granted = await c.requestNotificationPermission();
        if (!granted) {
          permissionNote =
              ' Notifications are not allowed, so the reminder will not show until you allow them in Android settings.';
        }
      }
      await c.saveHabit(habit, isNew: !_isEdit);
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(
              _isEdit ? 'Habit updated.$permissionNote' : 'Habit created.$permissionNote'),
        ));
      navigator.pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      showSnack(context, 'Could not save the habit. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cats = <String>{...c.categories, _category}.toList();
    final label = theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit habit' : 'New habit')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(_isEdit ? 'Save changes' : 'Create habit'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text('Name', style: label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: Habit.maxNameLength,
              decoration: const InputDecoration(hintText: 'e.g. Read 10 pages'),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) {
                  return 'Please enter a habit name.';
                }
                if (t.length > Habit.maxNameLength) {
                  return 'Keep the name under ${Habit.maxNameLength} characters.';
                }
                if (AppScope.read(context)
                    .nameExists(t, excludeId: widget.habit?.id)) {
                  return 'You already have a habit with this name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text('Notes (optional)', style: label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              maxLength: 300,
              decoration:
                  const InputDecoration(hintText: 'Why this habit matters to you'),
            ),
            const SizedBox(height: 12),
            Text('Category', style: label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final cat in cats)
                  ChoiceChip(
                    label: Text(cat),
                    selected: cat == _category,
                    onSelected: (_) => setState(() => _category = cat),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                  onPressed: _addCategory,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Icon', style: label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in kHabitIcons.entries)
                  Semantics(
                    button: true,
                    selected: entry.key == _iconKey,
                    label: 'Icon ${entry.key}',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _iconKey = entry.key),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: entry.key == _iconKey
                              ? scheme.primaryContainer
                              : scheme.surface,
                          border: Border.all(
                            color: entry.key == _iconKey
                                ? scheme.primary
                                : scheme.outlineVariant,
                            width: entry.key == _iconKey ? 2 : 1,
                          ),
                        ),
                        child: Icon(entry.value, color: scheme.onSurface),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Color', style: label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in kHabitColors)
                  Semantics(
                    button: true,
                    selected: color.toARGB32() == _colorValue,
                    label: 'Habit color',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () =>
                          setState(() => _colorValue = color.toARGB32()),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.toARGB32() == _colorValue
                                ? scheme.onSurface
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: color.toARGB32() == _colorValue
                            ? Icon(Icons.check, color: onColor(color))
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Schedule', style: label),
            const SizedBox(height: 8),
            SegmentedButton<HabitFrequency>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: HabitFrequency.daily, label: Text('Daily')),
                ButtonSegment(
                    value: HabitFrequency.selectedDays, label: Text('Days')),
                ButtonSegment(
                    value: HabitFrequency.weeklyTarget, label: Text('Weekly')),
              ],
              selected: {_frequency},
              onSelectionChanged: (s) => setState(() {
                _frequency = s.first;
                _weekdayError = false;
              }),
            ),
            const SizedBox(height: 12),
            if (_frequency == HabitFrequency.selectedDays) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (var d = 1; d <= 7; d++)
                    FilterChip(
                      label: Text(kWeekdayShort[d - 1]),
                      selected: _weekdays.contains(d),
                      onSelected: (on) => setState(() {
                        if (on) {
                          _weekdays.add(d);
                        } else {
                          _weekdays.remove(d);
                        }
                        _weekdayError = false;
                      }),
                    ),
                ],
              ),
              if (_weekdayError)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Pick at least one day.',
                      style: TextStyle(color: scheme.error)),
                ),
            ],
            if (_frequency == HabitFrequency.weeklyTarget)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Times per week')),
                      IconButton(
                        tooltip: 'Fewer',
                        onPressed: _weeklyTarget > 1
                            ? () => setState(() => _weeklyTarget--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_weeklyTarget',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      IconButton(
                        tooltip: 'More',
                        onPressed: _weeklyTarget < 7
                            ? () => setState(() => _weeklyTarget++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text('Reminder', style: label),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Remind me'),
                    subtitle: Text(_reminderMinutes == null
                        ? 'Off'
                        : formatMinutes(_reminderMinutes!)),
                    value: _reminderMinutes != null,
                    onChanged: (on) {
                      if (on) {
                        _pickTime();
                      } else {
                        setState(() => _reminderMinutes = null);
                      }
                    },
                  ),
                  if (_reminderMinutes != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: TextButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule),
                          label: const Text('Change time'),
                        ),
                      ),
                    ),
                  if (!c.remindersEnabled)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'Reminders are turned off in Settings, so none will show yet.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog();

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _controller.text.trim();
    if (t.isEmpty) {
      setState(() => _error = 'Enter a category name.');
      return;
    }
    Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New category'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 24,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: 'Category name', errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}