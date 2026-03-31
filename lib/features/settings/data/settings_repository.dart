import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../../core/layout/tv_screen_profile.dart';
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
      tvScreenProfile: TvScreenProfileX.fromStorage(
        _settingsBox.get(HiveKeys.tvScreenProfile) as String?,
      ),
      displayFontSize: DisplayFontSizeOptionX.fromStorage(
        _settingsBox.get(HiveKeys.displayFontSize) as String?,
      ),
      displayFontWeight: DisplayFontWeightOptionX.fromStorage(
        _settingsBox.get(HiveKeys.displayFontWeight) as String?,
      ),
      autoScrollSpeed: AutoScrollSpeedOptionX.fromStorage(
        _settingsBox.get(HiveKeys.autoScrollSpeed) as String?,
      ),
      contentSelectionMode: ContentSelectionModeX.fromStorage(
        _settingsBox.get(HiveKeys.contentSelectionMode) as String?,
      ),
      selectedContentId: _settingsBox.get(HiveKeys.selectedContentId) as String?,
      selectedContentTitle:
          _settingsBox.get(HiveKeys.selectedContentTitle) as String?,
      selectedContentDateKey:
          _settingsBox.get(HiveKeys.selectedContentDateKey) as String?,
      prePrayerWindowMinutes:
          (_settingsBox.get(HiveKeys.prePrayerWindowMinutes) as int?) ?? 20,
      postPrayerWindowMinutes:
          (_settingsBox.get(HiveKeys.postPrayerWindowMinutes) as int?) ?? 30,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put(HiveKeys.cityId, settings.cityId);
    await _settingsBox.put(HiveKeys.prayerMethod, settings.prayerMethod.name);
    await _settingsBox.put(HiveKeys.hijriOffset, settings.hijriOffset);
    await _settingsBox.put(
      HiveKeys.tvScreenProfile,
      settings.tvScreenProfile.storageValue,
    );
    await _settingsBox.put(
      HiveKeys.displayFontSize,
      settings.displayFontSize.name,
    );
    await _settingsBox.put(
      HiveKeys.displayFontWeight,
      settings.displayFontWeight.name,
    );
    await _settingsBox.put(
      HiveKeys.autoScrollSpeed,
      settings.autoScrollSpeed.name,
    );
    await _settingsBox.put(
      HiveKeys.contentSelectionMode,
      settings.contentSelectionMode.name,
    );
    await _settingsBox.put(
      HiveKeys.selectedContentId,
      settings.selectedContentId,
    );
    await _settingsBox.put(
      HiveKeys.selectedContentTitle,
      settings.selectedContentTitle,
    );
    await _settingsBox.put(
      HiveKeys.selectedContentDateKey,
      settings.selectedContentDateKey,
    );
    await _settingsBox.put(
      HiveKeys.prePrayerWindowMinutes,
      settings.prePrayerWindowMinutes,
    );
    await _settingsBox.put(
      HiveKeys.postPrayerWindowMinutes,
      settings.postPrayerWindowMinutes,
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
    await _cacheBox.put(HiveKeys.hijriSyncSnapshot, jsonEncode(snapshot.toJson()));
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
