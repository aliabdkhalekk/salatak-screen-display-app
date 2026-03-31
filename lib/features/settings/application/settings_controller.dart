import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/tv_screen_profile.dart';
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

  Future<void> updateTvScreenProfile(TvScreenProfile profile) async {
    state = state.copyWith(tvScreenProfile: profile);
    await _repository.saveSettings(state);
  }

  Future<void> updateDisplayFontSize(DisplayFontSizeOption option) async {
    state = state.copyWith(displayFontSize: option);
    await _repository.saveSettings(state);
  }

  Future<void> updateDisplayFontWeight(DisplayFontWeightOption option) async {
    state = state.copyWith(displayFontWeight: option);
    await _repository.saveSettings(state);
  }

  Future<void> updateAutoScrollSpeed(AutoScrollSpeedOption option) async {
    state = state.copyWith(autoScrollSpeed: option);
    await _repository.saveSettings(state);
  }

  Future<void> selectContentForToday({
    required String contentId,
    required String title,
    DateTime? now,
  }) async {
    state = state.withSelectedContentForToday(
      contentId: contentId,
      title: title,
      now: now ?? DateTime.now(),
    );
    await _repository.saveSettings(state);
  }

  Future<void> pinContentSelection({
    required String contentId,
    required String title,
  }) async {
    state = state.withPinnedContentSelection(
      contentId: contentId,
      title: title,
    );
    await _repository.saveSettings(state);
  }

  Future<void> clearManualContentSelection() async {
    state = state.withAutomaticContentSelection();
    await _repository.saveSettings(state);
  }

  Future<void> resetExpiredSelectedContentIfNeeded([DateTime? now]) async {
    final currentTime = now ?? DateTime.now();
    if (state.contentSelectionMode != ContentSelectionMode.selectedForToday) {
      return;
    }

    if (state.selectedContentDateKey == AppSettings.dayKeyFrom(currentTime)) {
      return;
    }

    if (!state.hasStoredContentSelection) {
      return;
    }

    state = state.withAutomaticContentSelection();
    await _repository.saveSettings(state);
  }

  Future<void> updatePrePrayerWindowMinutes(int minutes) async {
    state = state.copyWith(prePrayerWindowMinutes: minutes);
    await _repository.saveSettings(state);
  }

  Future<void> updatePostPrayerWindowMinutes(int minutes) async {
    state = state.copyWith(postPrayerWindowMinutes: minutes);
    await _repository.saveSettings(state);
  }
}
