import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:salatak_smart_display/core/constants/app_cities.dart';
import 'package:salatak_smart_display/core/time/app_time_service.dart';
import 'package:salatak_smart_display/features/prayer/data/prayer_calculation_service.dart';
import 'package:salatak_smart_display/features/prayer/domain/prayer_models.dart';
import 'package:salatak_smart_display/features/settings/data/settings_repository.dart';
import 'package:salatak_smart_display/features/settings/domain/app_settings.dart';

void main() {
  const cairoCity = AppCity(
    id: 'test_cairo',
    arabicName: 'Cairo',
    englishName: 'Cairo',
    latitude: 30.0444,
    longitude: 31.2357,
    timeZoneId: 'Africa/Cairo',
  );
  const newYorkCity = AppCity(
    id: 'test_new_york',
    arabicName: 'New York',
    englishName: 'New York',
    latitude: 40.7128,
    longitude: -74.0060,
    timeZoneId: 'America/New_York',
  );
  final settings = AppSettings.defaults();

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('PrayerCalculationService timezone handling', () {
    test('uses the standard-time offset for Cairo outside DST', () {
      final location = tz.getLocation(cairoCity.timeZoneId);
      final service = _buildService();

      final prayerDay = service.buildPrayerDay(
        now: tz.TZDateTime(location, 2026, 1, 15, 12),
        city: cairoCity,
        settings: settings,
      );

      expect(prayerDay.todayEntries, hasLength(5));
      for (final entry in prayerDay.todayEntries) {
        expect(entry.time.timeZoneOffset, const Duration(hours: 2));
        expect(entry.time.year, 2026);
        expect(entry.time.month, 1);
        expect(entry.time.day, 15);
      }
    });

    test('uses the DST offset for Cairo during summer time', () {
      final location = tz.getLocation(cairoCity.timeZoneId);
      final service = _buildService();

      final prayerDay = service.buildPrayerDay(
        now: tz.TZDateTime(location, 2026, 7, 1, 12),
        city: cairoCity,
        settings: settings,
      );

      expect(prayerDay.todayEntries, hasLength(5));
      for (final entry in prayerDay.todayEntries) {
        expect(entry.time.timeZoneOffset, const Duration(hours: 3));
        expect(entry.time.year, 2026);
        expect(entry.time.month, 7);
        expect(entry.time.day, 1);
      }
    });

    test('can disable daylight saving adjustments for displayed prayer times',
        () {
      final location = tz.getLocation(cairoCity.timeZoneId);
      final service = _buildService();

      final enabledDay = service.buildPrayerDay(
        now: tz.TZDateTime(location, 2026, 7, 1, 12),
        city: cairoCity,
        settings: settings,
      );
      final disabledDay = service.buildPrayerDay(
        now: tz.TZDateTime(location, 2026, 7, 1, 12),
        city: cairoCity,
        settings: settings.copyWith(useDaylightSavingTime: false),
      );

      expect(
        disabledDay
            .timeFor(PrayerName.fajr)
            .difference(enabledDay.timeFor(PrayerName.fajr)),
        const Duration(hours: -1),
      );
    });

    test(
        'countdown crosses the DST spring-forward boundary by real elapsed time',
        () {
      final location = tz.getLocation(newYorkCity.timeZoneId);
      final service = _buildService();
      final beforeTransition = tz.TZDateTime(location, 2026, 3, 8, 1, 59);
      final afterTransition = tz.TZDateTime(location, 2026, 3, 8, 3, 1);

      final beforePrayerDay = service.buildPrayerDay(
        now: beforeTransition,
        city: newYorkCity,
        settings: settings,
      );
      final afterPrayerDay = service.buildPrayerDay(
        now: afterTransition,
        city: newYorkCity,
        settings: settings,
      );

      expect(afterPrayerDay.nextPrayer.name, beforePrayerDay.nextPrayer.name);
      expect(
        afterPrayerDay.nextPrayer.time.millisecondsSinceEpoch,
        beforePrayerDay.nextPrayer.time.millisecondsSinceEpoch,
      );
      expect(
        beforePrayerDay.timeUntilNextPrayer -
            afterPrayerDay.timeUntilNextPrayer,
        const Duration(minutes: 2),
      );
    });

    test(
        'reuses cached month data correctly across a DST offset change after restart',
        () async {
      final repository = FakeSettingsRepository();
      final responseBody = jsonEncode({
        'data': [
          _apiDay(
            date: '07-03-2026',
            timeZoneId: newYorkCity.timeZoneId,
            fajr: '05:10',
            dhuhr: '12:05',
            asr: '15:20',
            maghrib: '17:55',
            isha: '19:15',
          ),
          _apiDay(
            date: '08-03-2026',
            timeZoneId: newYorkCity.timeZoneId,
            fajr: '06:05',
            dhuhr: '13:05',
            asr: '16:20',
            maghrib: '18:56',
            isha: '20:16',
          ),
        ],
      });

      final service = _buildService(
        repository: repository,
        client: MockClient((_) async => http.Response(responseBody, 200)),
      );

      final warmed = await service.warmMonth(
        date: tz.TZDateTime(tz.getLocation(newYorkCity.timeZoneId), 2026, 3, 7),
        city: newYorkCity,
        settings: settings,
      );

      expect(warmed, isTrue);
      expect(repository.prayerCalendars.values.single,
          contains(newYorkCity.timeZoneId));

      final restartedService = _buildService(
        repository: repository,
        client: MockClient((_) async => http.Response('', 500)),
      );
      final location = tz.getLocation(newYorkCity.timeZoneId);

      final standardDay = restartedService.buildPrayerDay(
        now: tz.TZDateTime(location, 2026, 3, 7, 12),
        city: newYorkCity,
        settings: settings,
      );
      final dstDay = restartedService.buildPrayerDay(
        now: tz.TZDateTime(location, 2026, 3, 8, 12),
        city: newYorkCity,
        settings: settings,
      );

      expect(
        DateFormat('HH:mm').format(standardDay.timeFor(PrayerName.fajr)),
        '05:10',
      );
      expect(
        standardDay.timeFor(PrayerName.fajr).timeZoneOffset,
        const Duration(hours: -5),
      );
      expect(
        DateFormat('HH:mm').format(dstDay.timeFor(PrayerName.fajr)),
        '06:05',
      );
      expect(
        dstDay.timeFor(PrayerName.fajr).timeZoneOffset,
        const Duration(hours: -4),
      );
    });

    test('ignores legacy cached data that does not carry timezone metadata',
        () {
      final repository = FakeSettingsRepository();
      repository.prayerCalendars[_cacheKey(
        city: cairoCity,
        settings: settings,
        year: 2026,
        month: 1,
      )] = jsonEncode({
        'year': 2026,
        'month': 1,
        'entries': {
          '2026-01-15': {
            'fajr': '2026-01-15T00:01:00',
            'dhuhr': '2026-01-15T00:02:00',
            'asr': '2026-01-15T00:03:00',
            'maghrib': '2026-01-15T00:04:00',
            'isha': '2026-01-15T00:05:00',
          },
        },
      });

      final service = _buildService(repository: repository);
      final prayerDay = service.buildPrayerDay(
        now: tz.TZDateTime(
            tz.getLocation(cairoCity.timeZoneId), 2026, 1, 15, 12),
        city: cairoCity,
        settings: settings,
      );

      expect(
        DateFormat('HH:mm').format(prayerDay.timeFor(PrayerName.fajr)),
        isNot('00:01'),
      );
      expect(
        prayerDay.timeFor(PrayerName.fajr).timeZoneOffset,
        const Duration(hours: 2),
      );
    });
  });
}

PrayerCalculationService _buildService({
  FakeSettingsRepository? repository,
  http.Client? client,
}) {
  return PrayerCalculationService(
    settingsRepository: repository ?? FakeSettingsRepository(),
    httpClient: client ?? MockClient((_) async => http.Response('', 500)),
    timeService: const AppTimeService(),
  );
}

String _cacheKey({
  required AppCity city,
  required AppSettings settings,
  required int year,
  required int month,
}) {
  final monthValue = month.toString().padLeft(2, '0');
  return 'v${PrayerCalculationService.calendarCacheSchemaVersion}'
      '_${city.id}'
      '_${settings.prayerMethod.name}'
      '_${year}_$monthValue';
}

Map<String, dynamic> _apiDay({
  required String date,
  required String timeZoneId,
  required String fajr,
  required String dhuhr,
  required String asr,
  required String maghrib,
  required String isha,
}) {
  return {
    'timings': {
      'Fajr': '$fajr (LOCAL)',
      'Dhuhr': '$dhuhr (LOCAL)',
      'Asr': '$asr (LOCAL)',
      'Maghrib': '$maghrib (LOCAL)',
      'Isha': '$isha (LOCAL)',
    },
    'date': {
      'gregorian': {
        'date': date,
      },
    },
    'meta': {
      'timezone': timeZoneId,
    },
  };
}

class FakeSettingsRepository extends SettingsRepository {
  final Map<String, String> prayerCalendars = <String, String>{};

  @override
  String? loadPrayerCalendar(String cacheKey) {
    return prayerCalendars[cacheKey];
  }

  @override
  Future<void> savePrayerCalendar(String cacheKey, String bundle) async {
    prayerCalendars[cacheKey] = bundle;
  }
}
