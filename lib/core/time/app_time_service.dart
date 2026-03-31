import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_cities.dart';

final appTimeServiceProvider = Provider<AppTimeService>(
  (ref) => const AppTimeService(),
);

class AppTimeService {
  const AppTimeService();

  tz.Location locationForCity(AppCity city) => tz.getLocation(city.timeZoneId);

  tz.TZDateTime nowInCity(AppCity city, {DateTime? clockNow}) {
    final instant = (clockNow ?? DateTime.now()).toUtc();
    return tz.TZDateTime.from(instant, locationForCity(city));
  }

  tz.TZDateTime toCityTime(DateTime instant, AppCity city) {
    return tz.TZDateTime.from(instant.toUtc(), locationForCity(city));
  }

  tz.TZDateTime startOfDay(DateTime instant, AppCity city) {
    final zoned = toCityTime(instant, city);
    return tz.TZDateTime(
      zoned.location,
      zoned.year,
      zoned.month,
      zoned.day,
    );
  }

  tz.TZDateTime shiftCalendarDays(DateTime instant, AppCity city, int days) {
    final zoned = toCityTime(instant, city);
    return tz.TZDateTime(
      zoned.location,
      zoned.year,
      zoned.month,
      zoned.day + days,
      zoned.hour,
      zoned.minute,
      zoned.second,
      zoned.millisecond,
      zoned.microsecond,
    );
  }

  tz.TZDateTime shiftStartOfDay(DateTime instant, AppCity city, int days) {
    final start = startOfDay(instant, city);
    return tz.TZDateTime(
      start.location,
      start.year,
      start.month,
      start.day + days,
    );
  }

  tz.TZDateTime monthStart(DateTime instant, AppCity city) {
    final zoned = toCityTime(instant, city);
    return tz.TZDateTime(zoned.location, zoned.year, zoned.month);
  }

  tz.TZDateTime localDateTime(
    AppCity city, {
    required int year,
    required int month,
    required int day,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  }) {
    return tz.TZDateTime(
      locationForCity(city),
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  }
}
