// lib/utils/habit_style.dart
import 'package:flutter/material.dart';

const Map<String, IconData> kHabitIcons = {
  'star': Icons.star_outline,
  'water': Icons.water_drop_outlined,
  'run': Icons.directions_run,
  'walk': Icons.directions_walk,
  'fitness': Icons.fitness_center,
  'book': Icons.menu_book_outlined,
  'study': Icons.school_outlined,
  'work': Icons.work_outline,
  'sleep': Icons.bedtime_outlined,
  'meditate': Icons.self_improvement,
  'food': Icons.restaurant_outlined,
  'heart': Icons.favorite_border,
  'write': Icons.edit_note,
  'music': Icons.music_note,
  'code': Icons.code,
  'clean': Icons.cleaning_services_outlined,
  'money': Icons.savings_outlined,
  'sun': Icons.wb_sunny_outlined,
  'brush': Icons.brush_outlined,
  'nophone': Icons.phone_disabled_outlined,
  'plant': Icons.eco_outlined,
  'pill': Icons.medication_outlined,
  'people': Icons.people_outline,
  'target': Icons.flag_outlined,
};

const List<Color> kHabitColors = [
  Color(0xFFD4A017),
  Color(0xFFE67E22),
  Color(0xFFC0392B),
  Color(0xFFAD5E8A),
  Color(0xFF7E57C2),
  Color(0xFF3F7CAC),
  Color(0xFF2A9D8F),
  Color(0xFF4C9A52),
  Color(0xFF6D4C41),
  Color(0xFF546E7A),
];

IconData habitIcon(String key) => kHabitIcons[key] ?? Icons.flag_outlined;

Color onColor(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : const Color(0xFF262626);
}