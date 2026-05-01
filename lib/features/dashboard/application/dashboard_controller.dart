import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_cities.dart';
import '../../../core/time/app_time_service.dart';
import '../../automation/application/display_state_manager.dart';
import '../../automation/domain/display_state_service.dart';
import '../../automation/domain/prayer_flow_models.dart';
import '../../hijri/data/hijri_service.dart';
import '../../prayer/application/prayer_schedule_service.dart';
import '../../prayer/domain/prayer_models.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/dashboard_state.dart';

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
  DashboardController.new,
);

class DashboardController extends Notifier<DashboardState>
    with WidgetsBindingObserver {
  late final PrayerScheduleService _prayerService;
  late final HijriService _hijriService;
  late final DisplayStateService _displayStateService;
  late final DisplayStateManager _displayStateManager;
  late final AppTimeService _timeService;

  Timer? _clockTimer;

  @override
  DashboardState build() {
    _prayerService = ref.read(prayerScheduleServiceProvider);
    _hijriService = ref.read(hijriServiceProvider);
    _displayStateService = ref.read(displayStateServiceProvider);
    _displayStateManager = ref.read(displayStateManagerProvider);
    _timeService = ref.read(appTimeServiceProvider);
    ref.listen<AppSettings>(settingsControllerProvider, (_, __) {
      _recompute(reason: _ScheduleRecomputeReason.settingsChanged);
    });

    WidgetsBinding.instance.addObserver(this);
    _startClock();
    ref.onDispose(() {
      _clockTimer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });

    Future<void>.microtask(
      () => _recompute(reason: _ScheduleRecomputeReason.appStart),
    );
    final settings = ref.read(settingsControllerProvider);
    final city = appCityById(settings.cityId);
    return DashboardState.loading(
      now: _timeService.nowInCity(city),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recompute(reason: _ScheduleRecomputeReason.appResume);
    }
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
    _recompute(reason: _ScheduleRecomputeReason.manualSync);
    return '$hijriMessage\nتم تحديث مواقيت الصلاة عند توفر الاتصال.';
  }

  void recalculateNow() {
    _recompute(reason: _ScheduleRecomputeReason.debugButton);
  }

  void recalculateAfterUnlock() {
    _recompute(reason: _ScheduleRecomputeReason.unlock);
  }

  void _startClock() {
    _clockTimer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => _recompute(reason: _ScheduleRecomputeReason.tick),
    );
  }

  void _recompute({
    required _ScheduleRecomputeReason reason,
  }) {
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
    try {
      final prayerDay = _prayerService.buildToday(
        now: now,
        city: city,
        settings: settings,
      );
      final hijriDate = _hijriService.calculate(
        now,
        offsetDays: settings.hijriOffset,
      );
      final automation = _displayStateService.resolve(
        now: now,
        prayerDay: prayerDay,
        settings: settings,
      );
      _displayStateManager.apply(snapshot: automation, settings: settings);
      _logScheduleDecision(
        reason: reason,
        now: now,
        prayerDay: prayerDay,
        automation: automation,
      );

      state = DashboardState(
        isLoading: false,
        now: now,
        hijriDate: hijriDate,
        prayerDay: prayerDay,
        automation: automation,
      );
    } catch (error, stackTrace) {
      final automation = PrayerFlowSnapshot.black();
      _displayStateManager.apply(snapshot: automation, settings: settings);
      debugPrint(
        '[Schedule] now=${_formatDateTime(now)} nextPrayer=unavailable '
        'activeWindow=none calculatedState=${automation.mode.name} '
        'reason=error_after_${reason.label}: $error',
      );
      debugPrintStack(
        stackTrace: stackTrace,
        label: 'Schedule recompute failed',
        maxFrames: 8,
      );
      state = DashboardState(
        isLoading: false,
        now: now,
        automation: automation,
        errorMessage: 'تعذر تحميل مواقيت الصلاة. افتح الإعدادات للمراجعة.',
      );
    }
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

    _recompute(reason: _ScheduleRecomputeReason.prayerCacheUpdated);
  }

  void _logScheduleDecision({
    required _ScheduleRecomputeReason reason,
    required DateTime now,
    required PrayerDayInfo prayerDay,
    required PrayerFlowSnapshot automation,
  }) {
    final previous = state.automation;
    final changed = previous.sideEffectKey != automation.sideEffectKey;
    final changeReason = changed
        ? _describeScheduleChange(previous, automation, reason)
        : 'unchanged_after_${reason.label}';

    debugPrint(
      '[Schedule] now=${_formatDateTime(now)} '
      'nextPrayer=${_describeNextPrayer(prayerDay)} '
      'activeWindow=${_describeActiveWindow(automation)} '
      'calculatedState=${automation.mode.name} '
      'reason=$changeReason',
    );
  }

  String _describeScheduleChange(
    PrayerFlowSnapshot previous,
    PrayerFlowSnapshot next,
    _ScheduleRecomputeReason trigger,
  ) {
    if (previous.mode != next.mode) {
      return 'mode_changed_${previous.mode.name}_to_${next.mode.name}'
          '_after_${trigger.label}';
    }
    if (previous.prayer != next.prayer) {
      final previousPrayer = previous.prayer?.name ?? 'none';
      final nextPrayer = next.prayer?.name ?? 'none';
      return 'prayer_changed_${previousPrayer}_to_$nextPrayer'
          '_after_${trigger.label}';
    }
    return 'window_changed_after_${trigger.label}';
  }

  String _describeNextPrayer(PrayerDayInfo prayerDay) {
    final nextPrayer = prayerDay.nextPrayer;
    return '${nextPrayer.name.name}@${_formatDateTime(nextPrayer.time)}';
  }

  String _describeActiveWindow(PrayerFlowSnapshot snapshot) {
    if (snapshot.mode == DisplayStateMode.blackScreen) {
      return 'none';
    }

    final prayer = snapshot.prayer?.name ?? 'unknown';
    final start = _formatNullableDateTime(snapshot.stageStartedAt);
    final end = _formatNullableDateTime(snapshot.stageEndsAt);
    return '${snapshot.mode.name}:$prayer:$start->$end';
  }

  String _formatNullableDateTime(DateTime? dateTime) {
    return dateTime == null ? 'unknown' : _formatDateTime(dateTime);
  }

  String _formatDateTime(DateTime dateTime) {
    return dateTime.toIso8601String();
  }
}

enum _ScheduleRecomputeReason {
  appStart,
  appResume,
  tick,
  settingsChanged,
  manualSync,
  prayerCacheUpdated,
  debugButton,
  unlock,
}

extension on _ScheduleRecomputeReason {
  String get label {
    return switch (this) {
      _ScheduleRecomputeReason.appStart => 'app_start',
      _ScheduleRecomputeReason.appResume => 'app_resume',
      _ScheduleRecomputeReason.tick => 'tick',
      _ScheduleRecomputeReason.settingsChanged => 'settings_changed',
      _ScheduleRecomputeReason.manualSync => 'manual_sync',
      _ScheduleRecomputeReason.prayerCacheUpdated => 'prayer_cache_updated',
      _ScheduleRecomputeReason.debugButton => 'debug_button',
      _ScheduleRecomputeReason.unlock => 'unlock',
    };
  }
}
