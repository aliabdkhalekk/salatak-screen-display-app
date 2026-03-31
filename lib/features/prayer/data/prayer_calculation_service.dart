import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/constants/app_cities.dart';
import '../../../core/time/app_time_service.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/data/settings_repository.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/prayer_models.dart';

final prayerCalculationServiceProvider = Provider<PrayerCalculationService>(
  (ref) {
    final httpClient = http.Client();
    ref.onDispose(httpClient.close);
    return PrayerCalculationService(
      settingsRepository: ref.read(settingsRepositoryProvider),
      httpClient: httpClient,
      timeService: ref.read(appTimeServiceProvider),
    );
  },
);

class PrayerCalculationService {
  PrayerCalculationService({
    required SettingsRepository settingsRepository,
    required http.Client httpClient,
    required AppTimeService timeService,
  })  : _settingsRepository = settingsRepository,
        _httpClient = httpClient,
        _timeService = timeService;

  final SettingsRepository _settingsRepository;
  final http.Client _httpClient;
  final AppTimeService _timeService;

  final Map<String, _MonthlyPrayerCalendar> _memoryCache =
      <String, _MonthlyPrayerCalendar>{};
  final Set<String> _hydratedCacheKeys = <String>{};
  final Map<String, Future<bool>> _inFlightWarmups = <String, Future<bool>>{};
  final Map<String, DateTime> _lastFetchAttempts = <String, DateTime>{};

  static const Duration _remoteRetryCooldown = Duration(minutes: 30);
  static const int calendarCacheSchemaVersion = 2;

  PrayerDayInfo buildPrayerDay({
    required DateTime now,
    required AppCity city,
    required AppSettings settings,
  }) {
    final zonedNow = _timeService.toCityTime(now, city);
    final today = _timeService.startOfDay(zonedNow, city);
    final tomorrow = _timeService.shiftStartOfDay(today, city, 1);
    final yesterday = _timeService.shiftStartOfDay(today, city, -1);

    final todayEntries = _buildEntriesForDate(
      date: today,
      city: city,
      settings: settings,
    );
    final tomorrowEntries = _buildEntriesForDate(
      date: tomorrow,
      city: city,
      settings: settings,
    );
    final yesterdayEntries = _buildEntriesForDate(
      date: yesterday,
      city: city,
      settings: settings,
    );

    final nextPrayer = todayEntries.firstWhere(
      (entry) => entry.time.isAfter(zonedNow),
      orElse: () => tomorrowEntries.first,
    );

    final lastPrayer = todayEntries
            .where((entry) => !entry.time.isAfter(zonedNow))
            .lastOrNull ??
        yesterdayEntries.last;

    return PrayerDayInfo(
      todayEntries: todayEntries,
      nextPrayer: nextPrayer,
      lastPrayer: lastPrayer,
      timeUntilNextPrayer: nextPrayer.time.difference(zonedNow),
    );
  }

  Future<bool> warmRelevantMonths({
    required DateTime around,
    required AppCity city,
    required AppSettings settings,
  }) async {
    final centeredDate = _timeService.startOfDay(around, city);
    final monthTargets = <DateTime>{
      _monthStart(centeredDate, city),
      _monthStart(_timeService.shiftStartOfDay(centeredDate, city, 1), city),
      _monthStart(_timeService.shiftStartOfDay(centeredDate, city, -1), city),
    };

    final results = await Future.wait(
      monthTargets.map(
        (date) => warmMonth(
          date: date,
          city: city,
          settings: settings,
        ),
      ),
    );

    return results.any((didUpdate) => didUpdate);
  }

  Future<bool> warmMonth({
    required DateTime date,
    required AppCity city,
    required AppSettings settings,
  }) async {
    final month = _monthStart(date, city);
    final cacheKey = _calendarCacheKey(
      month: month,
      city: city,
      settings: settings,
    );

    if (_loadCachedMonth(cacheKey, city) != null) {
      return false;
    }

    final inFlight = _inFlightWarmups[cacheKey];
    if (inFlight != null) {
      return inFlight;
    }

    final lastAttempt = _lastFetchAttempts[cacheKey];
    if (lastAttempt != null &&
        DateTime.now().difference(lastAttempt) < _remoteRetryCooldown) {
      return false;
    }

    _lastFetchAttempts[cacheKey] = DateTime.now();

    final warmup = _fetchMonthFromApi(
      month: month,
      city: city,
      settings: settings,
    ).then((calendar) async {
      if (calendar == null) {
        return false;
      }

      _memoryCache[cacheKey] = calendar;
      _hydratedCacheKeys.add(cacheKey);
      await _settingsRepository.savePrayerCalendar(
        cacheKey,
        jsonEncode(calendar.toJson()),
      );
      return true;
    }).catchError((_) {
      return false;
    }).whenComplete(() {
      _inFlightWarmups.remove(cacheKey);
    });

    _inFlightWarmups[cacheKey] = warmup;
    return warmup;
  }

  List<PrayerTimeEntry> _buildEntriesForDate({
    required DateTime date,
    required AppCity city,
    required AppSettings settings,
  }) {
    final normalizedDate = _dateOnly(date, city);
    final location = _timeService.locationForCity(city);
    final month = _loadCachedMonth(
      _calendarCacheKey(
        month: _monthStart(normalizedDate, city),
        city: city,
        settings: settings,
      ),
      city,
    );
    final cachedDay = month?.entryFor(normalizedDate);

    if (cachedDay != null) {
      return cachedDay.toEntries(location);
    }

    final localTimes = _buildLocalPrayerTimes(
      date: normalizedDate,
      city: city,
      settings: settings,
    );

    return _PrayerDayTimes.fromPrayerTimes(
      date: normalizedDate,
      prayerTimes: localTimes,
      location: location,
    ).toEntries(location);
  }

  _MonthlyPrayerCalendar? _loadCachedMonth(
    String cacheKey,
    AppCity city,
  ) {
    final location = _timeService.locationForCity(city);
    final fromMemory = _memoryCache[cacheKey];
    if (fromMemory != null) {
      if (fromMemory.isCompatibleWith(location: location, city: city)) {
        return fromMemory;
      }
      _memoryCache.remove(cacheKey);
    }

    if (_hydratedCacheKeys.contains(cacheKey)) {
      return null;
    }

    _hydratedCacheKeys.add(cacheKey);
    final raw = _settingsRepository.loadPrayerCalendar(cacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final calendar = _MonthlyPrayerCalendar.fromJson(decoded);
      if (!calendar.isCompatibleWith(location: location, city: city)) {
        return null;
      }
      _memoryCache[cacheKey] = calendar;
      return calendar;
    } catch (_) {
      return null;
    }
  }

  Future<_MonthlyPrayerCalendar?> _fetchMonthFromApi({
    required DateTime month,
    required AppCity city,
    required AppSettings settings,
  }) async {
    final uri = Uri.https('api.aladhan.com', '/v1/calendar', <String, String>{
      'latitude': city.latitude.toString(),
      'longitude': city.longitude.toString(),
      'method': _apiMethodId(settings.prayerMethod).toString(),
      'month': month.month.toString(),
      'year': month.year.toString(),
    });

    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      return null;
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'];
    if (data is! List<dynamic>) {
      return null;
    }

    final entries = <String, _PrayerDayTimes>{};
    String? timeZoneId;
    for (final item in data) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final datePayload = item['date'];
      final timingsPayload = item['timings'];
      if (datePayload is! Map<String, dynamic> ||
          timingsPayload is! Map<String, dynamic>) {
        continue;
      }

      final gregorianPayload = datePayload['gregorian'];
      if (gregorianPayload is! Map<String, dynamic>) {
        continue;
      }

      final gregorianDate = gregorianPayload['date'] as String?;
      if (gregorianDate == null || gregorianDate.isEmpty) {
        continue;
      }

      final metaPayload = item['meta'] as Map<String, dynamic>?;
      final responseTimeZoneId = (metaPayload?['timezone'] as String?)?.trim();
      final effectiveTimeZoneId = responseTimeZoneId?.isNotEmpty == true
          ? responseTimeZoneId!
          : city.timeZoneId;

      timeZoneId ??= effectiveTimeZoneId;
      if (timeZoneId != effectiveTimeZoneId) {
        return null;
      }

      final parsedDate = _parseGregorianDate(gregorianDate, city);
      final parsedTimes = _PrayerDayTimes.fromApi(
        date: parsedDate,
        timings: timingsPayload,
        location: tz.getLocation(effectiveTimeZoneId),
      );

      if (parsedTimes == null) {
        continue;
      }

      entries[_isoDate(parsedDate)] = parsedTimes;
    }

    if (entries.isEmpty) {
      return null;
    }

    return _MonthlyPrayerCalendar(
      schemaVersion: calendarCacheSchemaVersion,
      year: month.year,
      month: month.month,
      timeZoneId: timeZoneId ?? city.timeZoneId,
      entries: entries,
    );
  }

  PrayerTimes _buildLocalPrayerTimes({
    required DateTime date,
    required AppCity city,
    required AppSettings settings,
  }) {
    final params = _buildParameters(settings.prayerMethod);
    final coordinates = Coordinates(city.latitude, city.longitude);
    final dateComponents = DateComponents(date.year, date.month, date.day);

    // Keep prayer calculations in UTC and project them into the selected IANA
    // timezone afterwards. Fixed offsets like UTC+2 or UTC+3 break on DST
    // transition days and must not be hardcoded.
    return PrayerTimes.utc(coordinates, dateComponents, params);
  }

  CalculationParameters _buildParameters(PrayerMethodOption method) {
    final calculationMethod = switch (method) {
      PrayerMethodOption.egyptian => CalculationMethod.egyptian,
      PrayerMethodOption.ummAlQura => CalculationMethod.umm_al_qura,
      PrayerMethodOption.muslimWorldLeague =>
        CalculationMethod.muslim_world_league,
      PrayerMethodOption.karachi => CalculationMethod.karachi,
      PrayerMethodOption.northAmerica => CalculationMethod.north_america,
    };

    final params = calculationMethod.getParameters();
    params.madhab = Madhab.shafi;
    return params;
  }

  int _apiMethodId(PrayerMethodOption method) {
    return switch (method) {
      PrayerMethodOption.karachi => 1,
      PrayerMethodOption.northAmerica => 2,
      PrayerMethodOption.muslimWorldLeague => 3,
      PrayerMethodOption.ummAlQura => 4,
      PrayerMethodOption.egyptian => 5,
    };
  }

  String _calendarCacheKey({
    required DateTime month,
    required AppCity city,
    required AppSettings settings,
  }) {
    final monthValue = month.month.toString().padLeft(2, '0');
    return 'v$calendarCacheSchemaVersion'
        '_${city.id}'
        '_${settings.prayerMethod.name}'
        '_${month.year}_$monthValue';
  }

  DateTime _dateOnly(DateTime value, AppCity city) {
    return _timeService.startOfDay(value, city);
  }

  DateTime _monthStart(DateTime value, AppCity city) {
    return _timeService.monthStart(value, city);
  }

  DateTime _parseGregorianDate(String value, AppCity city) {
    final parts = value.split('-');
    if (parts.length != 3) {
      throw FormatException('Unexpected Gregorian date format: $value');
    }

    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    return _timeService.localDateTime(
      city,
      year: year,
      month: month,
      day: day,
    );
  }

  String _isoDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _MonthlyPrayerCalendar {
  const _MonthlyPrayerCalendar({
    required this.schemaVersion,
    required this.year,
    required this.month,
    required this.timeZoneId,
    required this.entries,
  });

  factory _MonthlyPrayerCalendar.fromJson(Map<String, dynamic> json) {
    final entriesPayload =
        json['entries'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return _MonthlyPrayerCalendar(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      timeZoneId: (json['timeZoneId'] as String?) ?? '',
      entries: entriesPayload.map(
        (key, value) => MapEntry(
          key,
          _PrayerDayTimes.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }

  final int schemaVersion;
  final int year;
  final int month;
  final String timeZoneId;
  final Map<String, _PrayerDayTimes> entries;

  _PrayerDayTimes? entryFor(DateTime date) {
    final yearValue = date.year.toString().padLeft(4, '0');
    final monthValue = date.month.toString().padLeft(2, '0');
    final dayValue = date.day.toString().padLeft(2, '0');
    return entries['$yearValue-$monthValue-$dayValue'];
  }

  bool isCompatibleWith({
    required tz.Location location,
    required AppCity city,
  }) {
    if (schemaVersion != PrayerCalculationService.calendarCacheSchemaVersion) {
      return false;
    }
    if (timeZoneId != city.timeZoneId) {
      return false;
    }
    return entries.values.every((entry) => entry.matchesLocation(location));
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'year': year,
      'month': month,
      'timeZoneId': timeZoneId,
      'entries': entries.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }
}

class _PrayerDayTimes {
  const _PrayerDayTimes({
    required this.localDateKey,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory _PrayerDayTimes.fromJson(Map<String, dynamic> json) {
    return _PrayerDayTimes(
      localDateKey: (json['localDateKey'] as String?) ?? '',
      fajr: _StoredPrayerTime.fromJson(
        json['fajr'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      dhuhr: _StoredPrayerTime.fromJson(
        json['dhuhr'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      asr: _StoredPrayerTime.fromJson(
        json['asr'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      maghrib: _StoredPrayerTime.fromJson(
        json['maghrib'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      isha: _StoredPrayerTime.fromJson(
        json['isha'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }

  factory _PrayerDayTimes.fromPrayerTimes({
    required DateTime date,
    required PrayerTimes prayerTimes,
    required tz.Location location,
  }) {
    return _PrayerDayTimes(
      localDateKey: _isoDate(date),
      fajr: _StoredPrayerTime.fromInstant(
        tz.TZDateTime.from(prayerTimes.fajr, location),
      ),
      dhuhr: _StoredPrayerTime.fromInstant(
        tz.TZDateTime.from(prayerTimes.dhuhr, location),
      ),
      asr: _StoredPrayerTime.fromInstant(
        tz.TZDateTime.from(prayerTimes.asr, location),
      ),
      maghrib: _StoredPrayerTime.fromInstant(
        tz.TZDateTime.from(prayerTimes.maghrib, location),
      ),
      isha: _StoredPrayerTime.fromInstant(
        tz.TZDateTime.from(prayerTimes.isha, location),
      ),
    );
  }

  static _PrayerDayTimes? fromApi({
    required DateTime date,
    required Map<String, dynamic> timings,
    required tz.Location location,
  }) {
    // Aladhan timings are local wall-clock strings such as "04:17 (EET)"
    // accompanied by meta.timezone like "Africa/Cairo". Rebuild each time in
    // that IANA timezone so DST is applied for the exact date. Do not add or
    // subtract fixed hours here; that would double-apply the offset.
    final fajr = _parseApiTime(date, timings['Fajr'], location);
    final dhuhr = _parseApiTime(date, timings['Dhuhr'], location);
    final asr = _parseApiTime(date, timings['Asr'], location);
    final maghrib = _parseApiTime(date, timings['Maghrib'], location);
    final isha = _parseApiTime(date, timings['Isha'], location);

    if (fajr == null ||
        dhuhr == null ||
        asr == null ||
        maghrib == null ||
        isha == null) {
      return null;
    }

    return _PrayerDayTimes(
      localDateKey: _isoDate(date),
      fajr: _StoredPrayerTime.fromInstant(fajr),
      dhuhr: _StoredPrayerTime.fromInstant(dhuhr),
      asr: _StoredPrayerTime.fromInstant(asr),
      maghrib: _StoredPrayerTime.fromInstant(maghrib),
      isha: _StoredPrayerTime.fromInstant(isha),
    );
  }

  final String localDateKey;
  final _StoredPrayerTime fajr;
  final _StoredPrayerTime dhuhr;
  final _StoredPrayerTime asr;
  final _StoredPrayerTime maghrib;
  final _StoredPrayerTime isha;

  bool matchesLocation(tz.Location location) {
    return [
      fajr,
      dhuhr,
      asr,
      maghrib,
      isha,
    ].every(
      (time) =>
          time.matchesLocation(location) &&
          _isoDate(time.toLocation(location)) == localDateKey,
    );
  }

  List<PrayerTimeEntry> toEntries(tz.Location location) {
    return <PrayerTimeEntry>[
      PrayerTimeEntry(name: PrayerName.fajr, time: fajr.toLocation(location)),
      PrayerTimeEntry(name: PrayerName.dhuhr, time: dhuhr.toLocation(location)),
      PrayerTimeEntry(name: PrayerName.asr, time: asr.toLocation(location)),
      PrayerTimeEntry(
        name: PrayerName.maghrib,
        time: maghrib.toLocation(location),
      ),
      PrayerTimeEntry(name: PrayerName.isha, time: isha.toLocation(location)),
    ];
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'localDateKey': localDateKey,
      'fajr': fajr.toJson(),
      'dhuhr': dhuhr.toJson(),
      'asr': asr.toJson(),
      'maghrib': maghrib.toJson(),
      'isha': isha.toJson(),
    };
  }

  static tz.TZDateTime? _parseApiTime(
    DateTime date,
    Object? rawValue,
    tz.Location location,
  ) {
    final raw = rawValue?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match == null) {
      return null;
    }

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    return tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  static String _isoDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _StoredPrayerTime {
  const _StoredPrayerTime({
    required this.utcIsoString,
    required this.offsetMinutes,
  });

  factory _StoredPrayerTime.fromInstant(DateTime instant) {
    return _StoredPrayerTime(
      utcIsoString: instant.toUtc().toIso8601String(),
      offsetMinutes: instant.timeZoneOffset.inMinutes,
    );
  }

  factory _StoredPrayerTime.fromJson(Map<String, dynamic> json) {
    return _StoredPrayerTime(
      utcIsoString: (json['utcIsoString'] as String?) ?? '',
      offsetMinutes: (json['offsetMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  final String utcIsoString;
  final int offsetMinutes;

  tz.TZDateTime toLocation(tz.Location location) {
    return tz.TZDateTime.from(DateTime.parse(utcIsoString).toUtc(), location);
  }

  bool matchesLocation(tz.Location location) {
    return toLocation(location).timeZoneOffset.inMinutes == offsetMinutes;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'utcIsoString': utcIsoString,
      'offsetMinutes': offsetMinutes,
    };
  }
}

extension _IterableLastOrNullX<T> on Iterable<T> {
  T? get lastOrNull {
    if (isEmpty) {
      return null;
    }
    return last;
  }
}
