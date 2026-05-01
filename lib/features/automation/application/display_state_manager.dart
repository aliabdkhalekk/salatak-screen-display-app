import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/platform/screen_control_service.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/prayer_flow_models.dart';

final displayStateManagerProvider = Provider<DisplayStateManager>(
  (ref) => DisplayStateManager(
    screenControlService: ref.read(screenControlServiceProvider),
  ),
);

class DisplayStateManager {
  DisplayStateManager({
    required ScreenControlService screenControlService,
  }) : _screenControlService = screenControlService;

  final ScreenControlService _screenControlService;

  String? _lastScreenSideEffectKey;
  int? _lastScheduledLaunchMillis;
  bool? _lastKeepScreenOnSetting;

  void apply({
    required PrayerFlowSnapshot snapshot,
    required AppSettings settings,
  }) {
    _applyKeepScreenPolicy(settings);

    if (!settings.autoScreenControlEnabled || settings.manualOverrideMode) {
      _lastScreenSideEffectKey = null;
      _cancelScheduledLaunchIfNeeded();
      return;
    }

    _applyScreenSideEffect(snapshot, settings);
    _scheduleLaunch(snapshot.nextTransitionAt);
  }

  void _applyScreenSideEffect(
    PrayerFlowSnapshot snapshot,
    AppSettings settings,
  ) {
    final sideEffectKey = [
      snapshot.sideEffectKey,
      settings.offModeType.name,
      settings.keepScreenAlwaysOn,
      settings.screenLockModeEnabled,
    ].join(':');
    if (_lastScreenSideEffectKey == sideEffectKey) {
      return;
    }
    _lastScreenSideEffectKey = sideEffectKey;

    if (snapshot.mode.keepsScreenAwake) {
      unawaited(_screenControlService.wakeForPrayerFlow());
      return;
    }

    if (snapshot.mode == DisplayStateMode.blackScreen) {
      if (!settings.screenLockModeEnabled) {
        unawaited(_screenControlService.wakeForPrayerFlow());
        return;
      }

      if (settings.offModeType == OffModeTypeOption.realStandby) {
        unawaited(_enterRealStandbyWithFallback(settings));
      }
    }
  }

  void _applyKeepScreenPolicy(AppSettings settings) {
    if (_lastKeepScreenOnSetting == settings.keepScreenAlwaysOn) {
      return;
    }

    _lastKeepScreenOnSetting = settings.keepScreenAlwaysOn;
    if (settings.keepScreenAlwaysOn) {
      unawaited(WakelockPlus.enable());
    } else {
      unawaited(WakelockPlus.disable());
    }
    unawaited(
        _screenControlService.setKeepScreenOn(settings.keepScreenAlwaysOn));
  }

  Future<void> _enterRealStandbyWithFallback(AppSettings settings) async {
    final supported = await _screenControlService.enterRealStandby();
    if (!supported) {
      await _screenControlService.setKeepScreenOn(settings.keepScreenAlwaysOn);
    }
  }

  void _scheduleLaunch(DateTime? dateTime) {
    if (dateTime == null) {
      return;
    }

    final millis = dateTime.toUtc().millisecondsSinceEpoch;
    if (_lastScheduledLaunchMillis == millis) {
      return;
    }

    _lastScheduledLaunchMillis = millis;
    unawaited(_screenControlService.scheduleLaunchAt(dateTime));
  }

  void _cancelScheduledLaunchIfNeeded() {
    if (_lastScheduledLaunchMillis == null) {
      return;
    }

    _lastScheduledLaunchMillis = null;
    unawaited(_screenControlService.cancelScheduledLaunch());
  }
}
