// lib/utils/ids.dart
import 'dart:math';

final Random _random = Random.secure();

/// Stable unique identifier for habits (never based on list position).
String generateId() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final rand = _random.nextInt(1 << 32).toRadixString(36);
  return '$time-$rand';
}