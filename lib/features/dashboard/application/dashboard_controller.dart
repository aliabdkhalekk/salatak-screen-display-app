import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_cities.dart';
import '../../../core/time/app_time_service.dart';
import '../../automation/application/display_state_manager.dart';
import '../../automation/domain/prayer_scheduler_service.dart';
import '../../hijri/data/hijri_service.dart';
import '../../prayer/data/prayer_calculation_service.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/dashboard_state.dart';

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
  DashboardController.new,
);

class DashboardController extends Notifier<DashboardState> {
  late final PrayerCalculationService _prayerService;
  late final HijriService _hijriService;
  late final PrayerSchedulerService _prayerSchedulerService;
  late final DisplayStateManager _displayStateManager;
  late final AppTimeService _timeService;

  Timer? _clockTimer;

  @override
  DashboardState build() {
    _prayerService = ref.read(prayerCalculationServiceProvider);
    _hijriService = ref.read(hijriServiceProvider);
    _prayerSchedulerService = ref.read(prayerSchedulerServiceProvider);
    _displayStateManager = ref.read(displayStateManagerProvider);
    _timeService = ref.read(appTimeServiceProvider);
    ref.listen<AppSettings>(settingsControllerProvider, (_, __) {
      _recompute();
    });

    _startClock();
    ref.onDispose(() {
      _clockTimer?.cancel();
    });

    Future<void>.microtask(_recompute);
    final settings = ref.read(settingsControllerProvider);
    final city = appCityById(settings.cityId);
    return DashboardState.loading(
      now: _timeService.nowInCity(city),
    );
  }

  Future<String> syncNow() async {
    final settings = ref.read(settingsControllerProvider);
    final city = appCityById(settings.cityId);
    final now = _timeService.nowInCity(city);
    final hijriMessage = await _hijriService.syncToday(
      now: now,
      offsetDays: settings.hijriOffset,
    );
    await _prayerService.warmRelevantMonths(
      around: now,
      city: city,
      settings: settings,
    );
    _recompute();
    return '$hijriMessage\nتم تحديث مواقيت الصلاة عند توفر الاتصال.';
  }

  void _startClock() {
    _clockTimer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => _recompute(),
    );
  }

  void _recompute() {
    final settings = ref.read(settingsControllerProvider);
    final city = appCityById(settings.cityId);
    final now = _timeService.nowInCity(city);
    unawaited(
      _warmPrayerMonths(
        now: now,
        city: city,
        settings: settings,
      ),
    );
    final prayerDay = _prayerService.buildPrayerDay(
      now: now,
      city: city,
      settings: settings,
    );
    final hijriDate = _hijriService.calculate(
      now,
      offsetDays: settings.hijriOffset,
    );
    final automation = _prayerSchedulerService.resolve(
      now: now,
      prayerDay: prayerDay,
      settings: settings,
    );
    _displayStateManager.apply(snapshot: automation, settings: settings);

    state = DashboardState(
      isLoading: false,
      now: now,
      hijriDate: hijriDate,
      prayerDay: prayerDay,
      automation: automation,
    );
  }

  Future<void> _warmPrayerMonths({
    required DateTime now,
    required AppCity city,
    required AppSettings settings,
  }) async {
    final didUpdate = await _prayerService.warmRelevantMonths(
      around: now,
      city: city,
      settings: settings,
    );

    if (!didUpdate || !ref.mounted) {
      return;
    }

    _recompute();
  }
}
