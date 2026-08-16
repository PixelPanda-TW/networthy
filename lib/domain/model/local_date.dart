import 'domain_validation.dart';

class LocalDate implements Comparable<LocalDate> {
  LocalDate(this.year, this.month, this.day) {
    if (month < 1 || month > 12) {
      throw const DomainValidationException('Month must be between 1 and 12.');
    }
    final maxDay = _daysInMonth(year, month);
    if (day < 1 || day > maxDay) {
      throw DomainValidationException(
        'Day must be between 1 and $maxDay for the given month.',
      );
    }
  }

  factory LocalDate.fromLocalDateTime(DateTime dateTime) {
    return LocalDate(dateTime.year, dateTime.month, dateTime.day);
  }

  final int year;
  final int month;
  final int day;

  bool isInMonth(int year, int month) {
    return this.year == year && this.month == month;
  }

  @override
  int compareTo(LocalDate other) {
    final yearComparison = year.compareTo(other.year);
    if (yearComparison != 0) {
      return yearComparison;
    }
    final monthComparison = month.compareTo(other.month);
    if (monthComparison != 0) {
      return monthComparison;
    }
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) {
    return other is LocalDate &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() {
    final paddedMonth = month.toString().padLeft(2, '0');
    final paddedDay = day.toString().padLeft(2, '0');
    return '$year-$paddedMonth-$paddedDay';
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
