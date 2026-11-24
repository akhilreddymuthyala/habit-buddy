// lib/services/csv_export.dart
import '../models/completion.dart';
import '../models/habit.dart';

String buildCompletionsCsv(List<Habit> habits, List<Completion> completions) {
  final byId = {for (final h in habits) h.id: h};
  String esc(String v) => '"${v.replaceAll('"', '""')}"';
  final rows = completions.where((c) => byId.containsKey(c.habitId)).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  final buf = StringBuffer('habit,category,date,note\n');
  for (final c in rows) {
    final h = byId[c.habitId]!;
    buf.writeln('${esc(h.name)},${esc(h.category)},${c.date},${esc(c.note)}');
  }
  return buf.toString();
}