import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../settings/application/settings_controller.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/hijri_date.dart';

final hijriServiceProvider = Provider<HijriService>(
  (ref) => HijriService(
    settingsRepository: ref.read(settingsRepositoryProvider),
  ),
);

class HijriService {
  HijriService({
    required SettingsRepository settingsRepository,
  }) : _settingsRepository = settingsRepository;

  final SettingsRepository _settingsRepository;

  HijriDate calculate(DateTime now, {required int offsetDays}) {
    final adjusted = DateTime.utc(now.year, now.month, now.day)
        .add(Duration(days: offsetDays));
    final snapshot = _settingsRepository.loadHijriSyncSnapshot();

    if (snapshot != null && snapshot.gregorianIsoDate == _isoDate(adjusted)) {
      return HijriDate(
        day: snapshot.day,
        month: snapshot.month,
        year: snapshot.year,
        weekdayArabic: _weekdayArabic(adjusted),
        synced: true,
      );
    }

    final julianDay = _gregorianToJulianDay(
      adjusted.year,
      adjusted.month,
      adjusted.day,
    );
    final hijri = _julianDayToHijri(julianDay);
    return HijriDate(
      day: hijri.$1,
      month: hijri.$2,
      year: hijri.$3,
      weekdayArabic: _weekdayArabic(adjusted),
    );
  }

  Future<String> syncToday({
    required DateTime now,
    required int offsetDays,
  }) async {
    final targetDate = DateTime.utc(now.year, now.month, now.day)
        .add(Duration(days: offsetDays));
    final formatted = DateFormat('dd-MM-yyyy').format(targetDate);
    final uri = Uri.parse('https://api.aladhan.com/v1/gToH?date=$formatted');

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return 'تعذرت مزامنة التاريخ الهجري الآن.';
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = payload['data'] as Map<String, dynamic>;
      final hijri = data['hijri'] as Map<String, dynamic>;
      final month = hijri['month'] as Map<String, dynamic>;

      final snapshot = HijriSyncSnapshot(
        gregorianIsoDate: _isoDate(targetDate),
        day: int.parse(hijri['day'] as String),
        month: month['number'] as int,
        year: int.parse(hijri['year'] as String),
      );

      await _settingsRepository.saveHijriSyncSnapshot(snapshot);
      return 'تمت مزامنة التاريخ الهجري بنجاح.';
    } catch (_) {
      return 'التطبيق يعمل دون إنترنت، ولم تكتمل المزامنة.';
    }
  }

  int _gregorianToJulianDay(int year, int month, int day) {
    final a = ((14 - month) / 12).floor();
    final y = year + 4800 - a;
    final m = month + (12 * a) - 3;
    return day +
        ((153 * m + 2) / 5).floor() +
        365 * y +
        (y / 4).floor() -
        (y / 100).floor() +
        (y / 400).floor() -
        32045;
  }

  (int, int, int) _julianDayToHijri(int julianDay) {
    var l = julianDay - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    final j = (((10985 - l) / 5316).floor() * ((50 * l) / 17719).floor()) +
        ((l / 5670).floor() * ((43 * l) / 15238).floor());
    l = l -
        (((30 - j) / 15).floor() * ((17719 * j) / 50).floor()) -
        ((j / 16).floor() * ((15238 * j) / 43).floor()) +
        29;
    final month = ((24 * l) / 709).floor();
    final day = l - ((709 * month) / 24).floor();
    final year = 30 * n + j - 30;
    return (day, month, year);
  }

  String _isoDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _weekdayArabic(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'الاثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
      default:
        return 'الأحد';
    }
  }
}
