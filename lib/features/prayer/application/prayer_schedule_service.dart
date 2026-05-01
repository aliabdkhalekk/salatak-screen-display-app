import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_cities.dart';
import '../../settings/domain/app_settings.dart';
import '../data/prayer_calculation_service.dart';
import '../domain/prayer_models.dart';

final prayerScheduleServiceProvider = Provider<PrayerScheduleService>(
  (ref) => PrayerScheduleService(
    calculationService: ref.read(prayerCalculationServiceProvider),
  ),
);

class PrayerScheduleService {
  const PrayerScheduleService({
    required PrayerCalculationService calculationService,
  }) : _calculationService = calculationService;

  final PrayerCalculationService _calculationService;

  PrayerDayInfo buildToday({
    required DateTime now,
    required AppCity city,
    required AppSettings settings,
  }) {
    return _calculationService.buildPrayerDay(
      now: now,
      city: city,
      settings: settings,
    );
  }

  Future<bool> warmRelevantMonths({
    required DateTime around,
    required AppCity city,
    required AppSettings settings,
  }) {
    return _calculationService.warmRelevantMonths(
      around: around,
      city: city,
      settings: settings,
    );
  }
}
