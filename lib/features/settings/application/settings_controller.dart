import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(),
);

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  late final SettingsRepository _repository;

  @override
  AppSettings build() {
    _repository = ref.read(settingsRepositoryProvider);
    return _repository.loadSettings();
  }

  Future<void> updateCity(String cityId) async {
    state = state.copyWith(cityId: cityId);
    await _repository.saveSettings(state);
  }

  Future<void> updatePrayerMethod(PrayerMethodOption method) async {
    state = state.copyWith(prayerMethod: method);
    await _repository.saveSettings(state);
  }

  Future<void> updateHijriOffset(int offset) async {
    state = state.copyWith(hijriOffset: offset);
    await _repository.saveSettings(state);
  }

  Future<void> updateDisplayFontSize(DisplayFontSizeOption option) async {
    state = state.copyWith(displayFontSize: option);
    await _repository.saveSettings(state);
  }

  Future<void> increaseDisplayFontSize() async {
    await updateDisplayFontSize(state.displayFontSize.next());
  }

  Future<void> decreaseDisplayFontSize() async {
    await updateDisplayFontSize(state.displayFontSize.previous());
  }

  Future<void> updateDisplayFontWeight(DisplayFontWeightOption option) async {
    state = state.copyWith(displayFontWeight: option);
    await _repository.saveSettings(state);
  }

  Future<void> updatePrePrayerWindowMinutes(int minutes) async {
    state = state.copyWith(prePrayerWindowMinutes: minutes.clamp(1, 120));
    await _repository.saveSettings(state);
  }

  Future<void> updateEntryDuaDurationMinutes(int minutes) async {
    state = state.copyWith(entryDuaDurationMinutes: minutes.clamp(1, 120));
    await _repository.saveSettings(state);
  }

  Future<void> updateAzkarDurationMinutes(int minutes) async {
    state = state.copyWith(azkarDurationMinutes: minutes.clamp(1, 180));
    await _repository.saveSettings(state);
  }

  Future<void> updateExitDuaDurationMinutes(int minutes) async {
    state = state.copyWith(exitDuaDurationMinutes: minutes.clamp(1, 180));
    await _repository.saveSettings(state);
  }

  Future<void> updateUiScalePercent(int percent) async {
    state = state.copyWith(uiScalePercent: percent.clamp(80, 140));
    await _repository.saveSettings(state);
  }

  Future<void> updateZikrTextScalePercent(int percent) async {
    state = state.copyWith(zikrTextScalePercent: percent.clamp(70, 160));
    await _repository.saveSettings(state);
  }

  Future<void> updateSleepBrightnessPercent(int percent) async {
    state = state.copyWith(sleepBrightnessPercent: percent.clamp(1, 100));
    await _repository.saveSettings(state);
  }

  Future<void> updateAutoScreenControlEnabled(bool enabled) async {
    state = state.copyWith(autoScreenControlEnabled: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> updateEntryDuaEnabled(bool enabled) async {
    state = state.copyWith(entryDuaEnabled: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> updateAfterPrayerAzkarEnabled(bool enabled) async {
    state = state.copyWith(afterPrayerAzkarEnabled: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> updateExitDuaEnabled(bool enabled) async {
    state = state.copyWith(exitDuaEnabled: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> updateManualOverrideMode(bool enabled) async {
    state = state.copyWith(manualOverrideMode: enabled);
    await _repository.saveSettings(state);
  }
}
