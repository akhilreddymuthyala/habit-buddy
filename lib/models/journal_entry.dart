// lib/models/journal_entry.dart
import '../utils/date_utils.dart';

class JournalEntry {
  JournalEntry({
    required this.id,
    required this.date,
    this.title = '',
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  }) {
    validate();
  }

  final String id;
  final String date;
  final String title;
  final String body;
  final int createdAt;
  final int updatedAt;

  void validate() {
    if (id.trim().isEmpty) {
      throw const FormatException('Journal entry id cannot be empty.');
    }
    if (!isValidDateKey(date)) {
      throw FormatException('Journal entry date "$date" is not a valid YYYY-MM-DD date.');
    }
    if (body.trim().isEmpty) {
      throw const FormatException('Journal entry body cannot be empty.');
    }
    if (body.length > 5000) {
      throw const FormatException('Journal entry body exceeds 5000 characters.');
    }
    if (title.length > 60) {
      throw const FormatException('Journal entry title exceeds 60 characters.');
    }
  }

  JournalEntry copyWith({
    String? id,
    String? date,
    String? title,
    String? body,
    int? createdAt,
    int? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date,
        'title': title,
        'body': body,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory JournalEntry.fromMap(Map<String, Object?> map) {
    final id = map['id'];
    final date = map['date'];
    final title = map['title'];
    final body = map['body'];
    final createdAt = map['created_at'];
    final updatedAt = map['updated_at'];

    if (id is! String || date is! String || body is! String) {
      throw const FormatException('Malformed journal entry in database.');
    }

    return JournalEntry(
      id: id,
      date: date,
      title: title is String ? title : '',
      body: body,
      createdAt: createdAt is int ? createdAt : 0,
      updatedAt: updatedAt is int ? updatedAt : 0,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'date': date,
        'title': title,
        'body': body,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final date = json['date'];
    final title = json['title'];
    final body = json['body'];
    final createdAt = json['createdAt'] ?? json['created_at'];
    final updatedAt = json['updatedAt'] ?? json['updated_at'];

    if (id is! String || date is! String || body is! String) {
      throw const FormatException('Missing required journal entry fields.');
    }

    return JournalEntry(
      id: id,
      date: date,
      title: title is String ? title : '',
      body: body,
      createdAt: createdAt is int ? createdAt : 0,
      updatedAt: updatedAt is int ? updatedAt : 0,
    );
  }
}
