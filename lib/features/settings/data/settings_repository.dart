import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../hijri/domain/hijri_date.dart';
import '../domain/app_settings.dart';

class SettingsRepository {
  Box<dynamic> get _settingsBox => Hive.box<dynamic>(HiveBoxes.settings);
  Box<String> get _cacheBox => Hive.box<String>(HiveBoxes.cache);

  AppSettings loadSettings() {
    return AppSettings(
      cityId: (_settingsBox.get(HiveKeys.cityId) as String?) ?? 'cairo',
      prayerMethod: PrayerMethodOptionX.fromStorage(
        (_settingsBox.get(HiveKeys.prayerMethod) as String?) ??
            PrayerMethodOption.egyptian.name,
      ),
      hijriOffset: (_settingsBox.get(HiveKeys.hijriOffset) as int?) ?? 0,
      displayFontSize: DisplayFontSizeOptionX.fromStorage(
        _settingsBox.get(HiveKeys.displayFontSize) as String?,
      ),
      displayFontWeight: DisplayFontWeightOptionX.fromStorage(
        _settingsBox.get(HiveKeys.displayFontWeight) as String?,
      ),
      prePrayerWindowMinutes:
          (_settingsBox.get(HiveKeys.prePrayerWindowMinutes) as int?) ?? 10,
      entryDuaDurationMinutes:
          (_settingsBox.get(HiveKeys.entryDuaDurationMinutes) as int?) ?? 10,
      azkarDurationMinutes:
          (_settingsBox.get(HiveKeys.azkarDurationMinutes) as int?) ??
              (_settingsBox.get(HiveKeys.postPrayerWindowMinutes) as int?) ??
              20,
      exitDuaDurationMinutes:
          (_settingsBox.get(HiveKeys.exitDuaDurationMinutes) as int?) ?? 20,
      uiScalePercent:
          (_settingsBox.get(HiveKeys.uiScalePercent) as int?) ?? 100,
      zikrTextScalePercent:
          (_settingsBox.get(HiveKeys.zikrTextScalePercent) as int?) ?? 100,
      sleepBrightnessPercent:
          (_settingsBox.get(HiveKeys.sleepBrightnessPercent) as int?) ?? 5,
      autoScreenControlEnabled:
          (_settingsBox.get(HiveKeys.autoScreenControlEnabled) as bool?) ??
              true,
      entryDuaEnabled:
          (_settingsBox.get(HiveKeys.entryDuaEnabled) as bool?) ?? true,
      afterPrayerAzkarEnabled:
          (_settingsBox.get(HiveKeys.afterPrayerAzkarEnabled) as bool?) ?? true,
      exitDuaEnabled:
          (_settingsBox.get(HiveKeys.exitDuaEnabled) as bool?) ?? true,
      manualOverrideMode:
          (_settingsBox.get(HiveKeys.manualOverrideMode) as bool?) ?? false,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put(HiveKeys.cityId, settings.cityId);
    await _settingsBox.put(HiveKeys.prayerMethod, settings.prayerMethod.name);
    await _settingsBox.put(HiveKeys.hijriOffset, settings.hijriOffset);
    await _settingsBox.put(
      HiveKeys.displayFontSize,
      settings.displayFontSize.name,
    );
    await _settingsBox.put(
      HiveKeys.displayFontWeight,
      settings.displayFontWeight.name,
    );
    await _settingsBox.put(
      HiveKeys.prePrayerWindowMinutes,
      settings.prePrayerWindowMinutes,
    );
    await _settingsBox.put(
      HiveKeys.entryDuaDurationMinutes,
      settings.entryDuaDurationMinutes,
    );
    await _settingsBox.put(
      HiveKeys.azkarDurationMinutes,
      settings.azkarDurationMinutes,
    );
    await _settingsBox.put(
      HiveKeys.exitDuaDurationMinutes,
      settings.exitDuaDurationMinutes,
    );
    await _settingsBox.put(
      HiveKeys.uiScalePercent,
      settings.uiScalePercent,
    );
    await _settingsBox.put(
      HiveKeys.zikrTextScalePercent,
      settings.zikrTextScalePercent,
    );
    await _settingsBox.put(
      HiveKeys.sleepBrightnessPercent,
      settings.sleepBrightnessPercent,
    );
    await _settingsBox.put(
      HiveKeys.autoScreenControlEnabled,
      settings.autoScreenControlEnabled,
    );
    await _settingsBox.put(
      HiveKeys.entryDuaEnabled,
      settings.entryDuaEnabled,
    );
    await _settingsBox.put(
      HiveKeys.afterPrayerAzkarEnabled,
      settings.afterPrayerAzkarEnabled,
    );
    await _settingsBox.put(
      HiveKeys.exitDuaEnabled,
      settings.exitDuaEnabled,
    );
    await _settingsBox.put(
      HiveKeys.manualOverrideMode,
      settings.manualOverrideMode,
    );
  }

  HijriSyncSnapshot? loadHijriSyncSnapshot() {
    final raw = _cacheBox.get(HiveKeys.hijriSyncSnapshot);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return HijriSyncSnapshot.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> saveHijriSyncSnapshot(HijriSyncSnapshot snapshot) async {
    await _cacheBox.put(
        HiveKeys.hijriSyncSnapshot, jsonEncode(snapshot.toJson()));
  }

  String? loadRemoteContentBundle() {
    return _cacheBox.get(HiveKeys.remoteContentBundle);
  }

  Future<void> saveRemoteContentBundle(String bundle) async {
    await _cacheBox.put(HiveKeys.remoteContentBundle, bundle);
  }

  String? loadPrayerCalendar(String cacheKey) {
    return _cacheBox.get('${HiveKeys.prayerCalendarPrefix}$cacheKey');
  }

  Future<void> savePrayerCalendar(String cacheKey, String bundle) async {
    await _cacheBox.put('${HiveKeys.prayerCalendarPrefix}$cacheKey', bundle);
  }
}
