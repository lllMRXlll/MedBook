import 'package:intl/intl.dart';

final class DateFormatter {
  static final DateFormat _dayMonth = DateFormat('d MMMM', 'ru_RU');
  static final DateFormat _fullDate = DateFormat('d MMMM yyyy', 'ru_RU');
  static final DateFormat _weekday = DateFormat('EEEE', 'ru_RU');
  static final DateFormat _weekdayShort = DateFormat('E', 'ru_RU');
  static final DateFormat _time = DateFormat('HH:mm', 'ru_RU');
  static final DateFormat _appointment = DateFormat('d MMMM, HH:mm', 'ru_RU');
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 0,
  );

  static String dayMonth(DateTime date) => _dayMonth.format(date);
  static String fullDate(DateTime date) => _fullDate.format(date);
  static String weekday(DateTime date) => _weekday.format(date);
  static String weekdayShort(DateTime date) => _weekdayShort.format(date);
  static String time(DateTime date) => _time.format(date);
  static String appointment(DateTime date) => _appointment.format(date);
  static String currency(num value) => _currency.format(value);
}
