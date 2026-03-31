import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_cities.dart';
import '../../../core/time/app_time_service.dart';
import '../../content_engine/data/content_repository.dart';
import '../../content_engine/domain/content_catalog.dart';
import '../../content_engine/domain/content_scheduler_service.dart';
import '../../friday/domain/friday_mode_service.dart';
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
  late final ContentRepository _contentRepository;
  late final FridayModeService _fridayModeService;
  late final ContentSchedulerService _contentSchedulerService;
  late final AppTimeService _timeService;

  Timer? _clockTimer;
  ContentCatalog? _catalog;

  @override
  DashboardState build() {
    _prayerService = ref.read(prayerCalculationServiceProvider);
    _hijriService = ref.read(hijriServiceProvider);
    _contentRepository = ref.read(contentRepositoryProvider);
    _fridayModeService = ref.read(fridayModeServiceProvider);
    _contentSchedulerService = ref.read(contentSchedulerServiceProvider);
    _timeService = ref.read(appTimeServiceProvider);
    ref.listen<AppSettings>(settingsControllerProvider, (_, __) {
      _recompute();
    });

    _startClock();
    ref.onDispose(() {
      _clockTimer?.cancel();
    });

    Future<void>.microtask(_loadCatalog);
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
    final contentMessage = await _contentRepository.syncRemoteBundle();
    await _loadCatalog();
    return '$hijriMessage\n$contentMessage';
  }

  Future<void> _loadCatalog() async {
    _catalog = await _contentRepository.loadCatalog();
    _recompute();
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
      ref
          .read(settingsControllerProvider.notifier)
          .resetExpiredSelectedContentIfNeeded(now),
    );
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
    final isFriday = _fridayModeService.isFriday(now);

    if (_catalog == null) {
      state = DashboardState.loading(now: now).copyWith(
        now: now,
        hijriDate: hijriDate,
        prayerDay: prayerDay,
        isFriday: isFriday,
      );
      return;
    }

    final scheduledContent = _contentSchedulerService.resolve(
      now: now,
      prayerDay: prayerDay,
      catalog: _catalog!,
      settings: settings,
    );

    state = DashboardState(
      isLoading: false,
      now: now,
      hijriDate: hijriDate,
      prayerDay: prayerDay,
      activeContent: scheduledContent.item,
      phase: scheduledContent.phase,
      isFriday: isFriday,
      sequenceSteps: const <ContentSequenceStep>[],
      activeSequenceIndex: 0,
      nawawiItems: _catalog!.nawawiItems,
      libraryItems: _catalog!.libraryItems,
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
