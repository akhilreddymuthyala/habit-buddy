// lib/models/completion.dart
class Completion {
  const Completion({
    required this.habitId,
    required this.date,
    this.note = '',
    required this.completedAt,
  });

  final String habitId;

  /// Local calendar date, YYYY-MM-DD.
  final String date;
  final String note;
  final int completedAt;

  Map<String, Object?> toMap() => {
        'habit_id': habitId,
        'date': date,
        'note': note,
        'completed_at': completedAt,
      };

  factory Completion.fromMap(Map<String, Object?> m) => Completion(
        habitId: m['habit_id'] as String,
        date: m['date'] as String,
        note: (m['note'] as String?) ?? '',
        completedAt: m['completed_at'] as int,
      );

  Map<String, Object?> toJson() => {
        'habitId': habitId,
        'date': date,
        'note': note,
        'completedAt': completedAt,
      };
}