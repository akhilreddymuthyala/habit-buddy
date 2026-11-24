// lib/utils/date_utils.dart
const List<String> kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> kWeekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> kWeekdayShort = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// Local calendar date as YYYY-MM-DD. Keys sort lexicographically by date.
String dateKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

final RegExp _dateKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

bool isValidDateKey(String s) {
  if (!_dateKeyPattern.hasMatch(s)) {
    return false;
  }
  final parts = s.split('-');
  final y = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final d = int.parse(parts[2]);
  final dt = DateTime(y, m, d);
  return dt.year == y && dt.month == m && dt.day == d;
}

DateTime parseDateKey(String s) {
  final parts = s.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// DST-safe day arithmetic on local calendar dates.
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Monday-based start of week.
DateTime weekStart(DateTime d) => addDays(dateOnly(d), 1 - d.weekday);

int daysBetween(DateTime a, DateTime b) {
  return DateTime.utc(b.year, b.month, b.day)
      .difference(DateTime.utc(a.year, a.month, a.day))
      .inDays;
}

String formatLongDate(DateTime d) =>
    '${kWeekdayNames[d.weekday - 1]}, ${d.day} ${kMonthNames[d.month - 1]} ${d.year}';

String formatShortDate(DateTime d) =>
    '${kWeekdayShort[d.weekday - 1]}, ${d.day} ${kMonthNames[d.month - 1].substring(0, 3)}';

String formatMonthYear(DateTime d) => '${kMonthNames[d.month - 1]} ${d.year}';

String formatMinutes(int minutes) {
  final h24 = minutes ~/ 60;
  final min = minutes % 60;
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  final suffix = h24 < 12 ? 'AM' : 'PM';
  return '$h12:${min.toString().padLeft(2, '0')} $suffix';
}