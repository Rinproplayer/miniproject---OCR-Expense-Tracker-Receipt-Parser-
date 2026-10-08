import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dayMonthYear = DateFormat('dd/MM/yyyy');
  static final DateFormat _dayMonth = DateFormat('dd/MM');
  static final DateFormat _fullDateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _monthYear = DateFormat('MM/yyyy');

  static String format(DateTime date) => _dayMonthYear.format(date);
  static String formatShort(DateTime date) => _dayMonth.format(date);
  static String formatFull(DateTime date) => _fullDateTime.format(date);
  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  static String getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
