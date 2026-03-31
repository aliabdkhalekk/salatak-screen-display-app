import '../../../core/layout/tv_screen_profile.dart';

enum PrayerMethodOption {
  egyptian,
  ummAlQura,
  muslimWorldLeague,
  karachi,
  northAmerica,
}

extension PrayerMethodOptionX on PrayerMethodOption {
  String get labelArabic {
    switch (this) {
      case PrayerMethodOption.egyptian:
        return 'الهيئة المصرية';
      case PrayerMethodOption.ummAlQura:
        return 'أم القرى';
      case PrayerMethodOption.muslimWorldLeague:
        return 'رابطة العالم الإسلامي';
      case PrayerMethodOption.karachi:
        return 'كراتشي';
      case PrayerMethodOption.northAmerica:
        return 'أمريكا الشمالية';
    }
  }

  static PrayerMethodOption fromStorage(String value) {
    return PrayerMethodOption.values.firstWhere(
      (method) => method.name == value,
      orElse: () => PrayerMethodOption.egyptian,
    );
  }
}

enum DisplayFontSizeOption {
  small,
  medium,
  large,
  extraLarge,
}

extension DisplayFontSizeOptionX on DisplayFontSizeOption {
  String get labelArabic {
    switch (this) {
      case DisplayFontSizeOption.small:
        return 'صغير';
      case DisplayFontSizeOption.medium:
        return 'متوسط';
      case DisplayFontSizeOption.large:
        return 'كبير';
      case DisplayFontSizeOption.extraLarge:
        return 'كبير جدًا';
    }
  }

  double get scaleFactor {
    switch (this) {
      case DisplayFontSizeOption.small:
        return 0.92;
      case DisplayFontSizeOption.medium:
        return 1.00;
      case DisplayFontSizeOption.large:
        return 1.10;
      case DisplayFontSizeOption.extraLarge:
        return 1.18;
    }
  }

  static DisplayFontSizeOption fromStorage(String? value) {
    return DisplayFontSizeOption.values.firstWhere(
      (option) => option.name == value,
      orElse: () => DisplayFontSizeOption.medium,
    );
  }
}

enum DisplayFontWeightOption {
  normal,
  bold,
}

extension DisplayFontWeightOptionX on DisplayFontWeightOption {
  String get labelArabic {
    switch (this) {
      case DisplayFontWeightOption.normal:
        return 'عادي';
      case DisplayFontWeightOption.bold:
        return 'عريض';
    }
  }

  static DisplayFontWeightOption fromStorage(String? value) {
    return DisplayFontWeightOption.values.firstWhere(
      (option) => option.name == value,
      orElse: () => DisplayFontWeightOption.normal,
    );
  }
}

enum AutoScrollSpeedOption {
  verySlow,
  slow,
  medium,
  fast,
}

extension AutoScrollSpeedOptionX on AutoScrollSpeedOption {
  String get labelArabic {
    switch (this) {
      case AutoScrollSpeedOption.verySlow:
        return 'بطيء جدًا';
      case AutoScrollSpeedOption.slow:
        return 'بطيء';
      case AutoScrollSpeedOption.medium:
        return 'متوسط';
      case AutoScrollSpeedOption.fast:
        return 'سريع';
    }
  }

  double get pixelsPerSecond {
    switch (this) {
      case AutoScrollSpeedOption.verySlow:
        return 10;
      case AutoScrollSpeedOption.slow:
        return 14;
      case AutoScrollSpeedOption.medium:
        return 18;
      case AutoScrollSpeedOption.fast:
        return 24;
    }
  }

  static AutoScrollSpeedOption fromStorage(String? value) {
    return AutoScrollSpeedOption.values.firstWhere(
      (option) => option.name == value,
      orElse: () => AutoScrollSpeedOption.slow,
    );
  }
}

enum ContentSelectionMode {
  auto,
  selectedForToday,
  pinned,
}

extension ContentSelectionModeX on ContentSelectionMode {
  String get labelArabic {
    switch (this) {
      case ContentSelectionMode.auto:
        return 'تلقائي';
      case ContentSelectionMode.selectedForToday:
        return 'عرض اليوم';
      case ContentSelectionMode.pinned:
        return 'محتوى مثبت';
    }
  }

  static ContentSelectionMode fromStorage(String? value) {
    return ContentSelectionMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ContentSelectionMode.auto,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.cityId,
    required this.prayerMethod,
    required this.hijriOffset,
    required this.tvScreenProfile,
    required this.displayFontSize,
    required this.displayFontWeight,
    required this.autoScrollSpeed,
    required this.contentSelectionMode,
    required this.selectedContentId,
    required this.selectedContentTitle,
    required this.selectedContentDateKey,
    required this.prePrayerWindowMinutes,
    required this.postPrayerWindowMinutes,
  });

  final String cityId;
  final PrayerMethodOption prayerMethod;
  final int hijriOffset;
  final TvScreenProfile tvScreenProfile;
  final DisplayFontSizeOption displayFontSize;
  final DisplayFontWeightOption displayFontWeight;
  final AutoScrollSpeedOption autoScrollSpeed;
  final ContentSelectionMode contentSelectionMode;
  final String? selectedContentId;
  final String? selectedContentTitle;
  final String? selectedContentDateKey;
  final int prePrayerWindowMinutes;
  final int postPrayerWindowMinutes;

  factory AppSettings.defaults() {
    return const AppSettings(
      cityId: 'cairo',
      prayerMethod: PrayerMethodOption.egyptian,
      hijriOffset: 0,
      tvScreenProfile: TvScreenProfile.inch55,
      displayFontSize: DisplayFontSizeOption.medium,
      displayFontWeight: DisplayFontWeightOption.normal,
      autoScrollSpeed: AutoScrollSpeedOption.slow,
      contentSelectionMode: ContentSelectionMode.auto,
      selectedContentId: null,
      selectedContentTitle: null,
      selectedContentDateKey: null,
      prePrayerWindowMinutes: 20,
      postPrayerWindowMinutes: 30,
    );
  }

  AppSettings copyWith({
    String? cityId,
    PrayerMethodOption? prayerMethod,
    int? hijriOffset,
    TvScreenProfile? tvScreenProfile,
    DisplayFontSizeOption? displayFontSize,
    DisplayFontWeightOption? displayFontWeight,
    AutoScrollSpeedOption? autoScrollSpeed,
    ContentSelectionMode? contentSelectionMode,
    String? selectedContentId,
    String? selectedContentTitle,
    String? selectedContentDateKey,
    int? prePrayerWindowMinutes,
    int? postPrayerWindowMinutes,
  }) {
    return AppSettings(
      cityId: cityId ?? this.cityId,
      prayerMethod: prayerMethod ?? this.prayerMethod,
      hijriOffset: hijriOffset ?? this.hijriOffset,
      tvScreenProfile: tvScreenProfile ?? this.tvScreenProfile,
      displayFontSize: displayFontSize ?? this.displayFontSize,
      displayFontWeight: displayFontWeight ?? this.displayFontWeight,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
      contentSelectionMode: contentSelectionMode ?? this.contentSelectionMode,
      selectedContentId: selectedContentId ?? this.selectedContentId,
      selectedContentTitle: selectedContentTitle ?? this.selectedContentTitle,
      selectedContentDateKey:
          selectedContentDateKey ?? this.selectedContentDateKey,
      prePrayerWindowMinutes:
          prePrayerWindowMinutes ?? this.prePrayerWindowMinutes,
      postPrayerWindowMinutes:
          postPrayerWindowMinutes ?? this.postPrayerWindowMinutes,
    );
  }

  bool get hasStoredContentSelection =>
      (selectedContentId?.trim().isNotEmpty ?? false);

  ContentSelectionMode effectiveContentSelectionMode(DateTime now) {
    return effectiveContentSelectionModeForDayKey(dayKeyFrom(now));
  }

  ContentSelectionMode effectiveContentSelectionModeForDayKey(String dayKey) {
    if (!hasStoredContentSelection) {
      return ContentSelectionMode.auto;
    }

    if (contentSelectionMode == ContentSelectionMode.selectedForToday &&
        selectedContentDateKey != dayKey) {
      return ContentSelectionMode.auto;
    }

    return contentSelectionMode;
  }

  bool hasActiveManualContent(DateTime now) {
    return hasActiveManualContentForDayKey(dayKeyFrom(now));
  }

  bool hasActiveManualContentForDayKey(String dayKey) {
    return effectiveContentSelectionModeForDayKey(dayKey) !=
            ContentSelectionMode.auto &&
        hasStoredContentSelection;
  }

  String? activeSelectedContentId(DateTime now) {
    return activeSelectedContentIdForDayKey(dayKeyFrom(now));
  }

  String? activeSelectedContentIdForDayKey(String dayKey) {
    if (!hasActiveManualContentForDayKey(dayKey)) {
      return null;
    }
    return selectedContentId;
  }

  String? activeSelectedContentTitle(DateTime now) {
    return activeSelectedContentTitleForDayKey(dayKeyFrom(now));
  }

  String? activeSelectedContentTitleForDayKey(String dayKey) {
    if (!hasActiveManualContentForDayKey(dayKey)) {
      return null;
    }
    return selectedContentTitle;
  }

  AppSettings withAutomaticContentSelection() {
    return AppSettings(
      cityId: cityId,
      prayerMethod: prayerMethod,
      hijriOffset: hijriOffset,
      tvScreenProfile: tvScreenProfile,
      displayFontSize: displayFontSize,
      displayFontWeight: displayFontWeight,
      autoScrollSpeed: autoScrollSpeed,
      contentSelectionMode: ContentSelectionMode.auto,
      selectedContentId: null,
      selectedContentTitle: null,
      selectedContentDateKey: null,
      prePrayerWindowMinutes: prePrayerWindowMinutes,
      postPrayerWindowMinutes: postPrayerWindowMinutes,
    );
  }

  AppSettings withSelectedContentForToday({
    required String contentId,
    required String title,
    required DateTime now,
  }) {
    return AppSettings(
      cityId: cityId,
      prayerMethod: prayerMethod,
      hijriOffset: hijriOffset,
      tvScreenProfile: tvScreenProfile,
      displayFontSize: displayFontSize,
      displayFontWeight: displayFontWeight,
      autoScrollSpeed: autoScrollSpeed,
      contentSelectionMode: ContentSelectionMode.selectedForToday,
      selectedContentId: contentId.trim(),
      selectedContentTitle: title.trim(),
      selectedContentDateKey: dayKeyFrom(now),
      prePrayerWindowMinutes: prePrayerWindowMinutes,
      postPrayerWindowMinutes: postPrayerWindowMinutes,
    );
  }

  AppSettings withPinnedContentSelection({
    required String contentId,
    required String title,
  }) {
    return AppSettings(
      cityId: cityId,
      prayerMethod: prayerMethod,
      hijriOffset: hijriOffset,
      tvScreenProfile: tvScreenProfile,
      displayFontSize: displayFontSize,
      displayFontWeight: displayFontWeight,
      autoScrollSpeed: autoScrollSpeed,
      contentSelectionMode: ContentSelectionMode.pinned,
      selectedContentId: contentId.trim(),
      selectedContentTitle: title.trim(),
      selectedContentDateKey: null,
      prePrayerWindowMinutes: prePrayerWindowMinutes,
      postPrayerWindowMinutes: postPrayerWindowMinutes,
    );
  }

  static String dayKeyFrom(DateTime date) {
    // The caller must pass a value already expressed in the app's active
    // timezone. "Today" changes with the selected timezone and DST rules, so
    // manual hour shifting must not be used to build day keys.
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
