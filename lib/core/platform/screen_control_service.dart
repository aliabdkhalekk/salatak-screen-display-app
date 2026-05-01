import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef RemoteKeyHandler = void Function(RemoteUnlockKey key, String action);

enum RemoteUnlockKey {
  ok,
  back,
}

final screenControlServiceProvider = Provider<ScreenControlService>(
  (ref) => const ScreenControlService(),
);

class ScreenControlService {
  const ScreenControlService();

  static const MethodChannel _channel = MethodChannel(
    'com.salatak.smartdisplay/screen_control',
  );

  Future<void> wakeForPrayerFlow() async {
    if (!_supportsNativeScreenControl) {
      return;
    }

    await _invoke('wakeScreen');
  }

  Future<void> setKeepScreenOn(bool enabled) async {
    if (!_supportsNativeScreenControl) {
      return;
    }

    await _invoke(
      'setKeepScreenOn',
      <String, Object?>{
        'enabled': enabled,
      },
    );
  }

  Future<bool> enterRealStandby() async {
    if (!_supportsNativeScreenControl) {
      return false;
    }

    return _invokeBool('enterRealStandby');
  }

  Future<String> realScreenOffSupportStatus() async {
    if (!_supportsNativeScreenControl) {
      return 'unknown';
    }

    return await _invokeString('getRealScreenOffSupportStatus') ?? 'unknown';
  }

  Future<void> enterSleepMode({
    required int brightnessPercent,
  }) async {
    if (!_supportsNativeScreenControl) {
      return;
    }

    await _invoke(
      'sleepScreen',
      <String, Object?>{
        'brightnessPercent': brightnessPercent.clamp(1, 100),
      },
    );
  }

  Future<void> scheduleLaunchAt(DateTime? dateTime) async {
    if (!_supportsNativeScreenControl || dateTime == null) {
      return;
    }

    await _invoke(
      'scheduleLaunchAt',
      <String, Object?>{
        'epochMillis': dateTime.toUtc().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> cancelScheduledLaunch() async {
    if (!_supportsNativeScreenControl) {
      return;
    }

    await _invoke('cancelScheduledLaunch');
  }

  Future<void> setRemoteUnlockCapture(bool enabled) async {
    if (!_supportsNativeScreenControl) {
      return;
    }

    await _invoke(
      'setRemoteUnlockCapture',
      <String, Object?>{
        'enabled': enabled,
      },
    );
  }

  void setRemoteKeyHandler(RemoteKeyHandler? handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'remoteKey') {
        return null;
      }

      final arguments = call.arguments;
      if (arguments is! Map<dynamic, dynamic>) {
        return null;
      }

      final keyLabel = arguments['key']?.toString();
      final action = arguments['action']?.toString() ?? '';
      final key = switch (keyLabel) {
        'OK' => RemoteUnlockKey.ok,
        'BACK' => RemoteUnlockKey.back,
        _ => null,
      };

      if (key != null) {
        handler?.call(key, action);
      }
      return null;
    });
  }

  Future<void> _invoke(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException {
      // Android TV vendors differ in how much screen control they expose.
      // The UI scheduler must keep running even when native control is denied.
    } on MissingPluginException {
      // Desktop, web, and tests do not register the platform channel.
    }
  }

  Future<bool> _invokeBool(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await _channel.invokeMethod<bool>(method, arguments) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<String?> _invokeString(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await _channel.invokeMethod<String>(method, arguments);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

bool get _supportsNativeScreenControl {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.android;
}
