import '../../../core/layout/tv_screen_profile.dart';
import '../../prayer/domain/prayer_models.dart';

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

  DisplayFontSizeOption next() {
    final index = DisplayFontSizeOption.values.indexOf(this);
    final nextIndex =
        (index + 1).clamp(0, DisplayFontSizeOption.values.length - 1);
    return DisplayFontSizeOption.values[nextIndex];
  }

  DisplayFontSizeOption previous() {
    final index = DisplayFontSizeOption.values.indexOf(this);
    final previousIndex = (index - 1).clamp(0, index);
    return DisplayFontSizeOption.values[previousIndex];
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

enum ArabicFontStyleOption {
  classicQuranic,
  modernKufi,
  elegantRuqaa,
  simpleReadable,
}

extension ArabicFontStyleOptionX on ArabicFontStyleOption {
  String get labelArabic {
    switch (this) {
      case ArabicFontStyleOption.classicQuranic:
        return 'Classic Quranic / كلاسيكي قرآني';
      case ArabicFontStyleOption.modernKufi:
        return 'Modern Kufi / كوفي حديث';
      case ArabicFontStyleOption.elegantRuqaa:
        return 'Elegant Ruqaa / رقعة أنيقة';
      case ArabicFontStyleOption.simpleReadable:
        return 'Simple Readable / واضح وبسيط';
    }
  }

  String get fontFamily {
    switch (this) {
      case ArabicFontStyleOption.classicQuranic:
        return 'ScheherazadeNew';
      case ArabicFontStyleOption.modernKufi:
        return 'NotoKufiArabic';
      case ArabicFontStyleOption.elegantRuqaa:
        return 'ArefRuqaa';
      case ArabicFontStyleOption.simpleReadable:
        return 'Cairo';
    }
  }

  static ArabicFontStyleOption fromStorage(String? value) {
    return ArabicFontStyleOption.values.firstWhere(
      (option) => option.name == value,
      orElse: () => ArabicFontStyleOption.classicQuranic,
    );
  }
}

enum OffModeTypeOption {
  realStandby,
  blackScreenFallback,
}

extension OffModeTypeOptionX on OffModeTypeOption {
  String get labelArabic {
    switch (this) {
      case OffModeTypeOption.realStandby:
        return 'Real standby / إطفاء حقيقي إن أمكن';
      case OffModeTypeOption.blackScreenFallback:
        return 'Black screen fallback / شاشة سوداء فقط';
    }
  }

  static OffModeTypeOption fromStorage(String? value) {
    return OffModeTypeOption.values.firstWhere(
      (option) => option.name == value,
      orElse: () => OffModeTypeOption.realStandby,
    );
  }
}

const List<double> kAutoScrollSpeedMultipliers = <double>[
  0.5,
  0.75,
  1.0,
  1.25,
  1.5,
  2.0,
  3.0,
];

double normalizeAutoScrollSpeedMultiplier(double value) {
  return kAutoScrollSpeedMultipliers.reduce(
    (closest, current) =>
        (current - value).abs() < (closest - value).abs() ? current : closest,
  );
}

double nextAutoScrollSpeedMultiplier(double current) {
  final normalized = normalizeAutoScrollSpeedMultiplier(current);
  final currentIndex = kAutoScrollSpeedMultipliers.indexOf(normalized);
  if (currentIndex >= kAutoScrollSpeedMultipliers.length - 1) {
    return normalized;
  }
  return kAutoScrollSpeedMultipliers[currentIndex + 1];
}

double previousAutoScrollSpeedMultiplier(double current) {
  final normalized = normalizeAutoScrollSpeedMultiplier(current);
  final currentIndex = kAutoScrollSpeedMultipliers.indexOf(normalized);
  if (currentIndex <= 0) {
    return normalized;
  }
  return kAutoScrollSpeedMultipliers[currentIndex - 1];
}

String autoScrollSpeedText(double value) {
  final normalized = normalizeAutoScrollSpeedMultiplier(value);
  if (normalized == normalized.roundToDouble()) {
    return '${normalized.toStringAsFixed(1)}x';
  }
  return '${normalized.toStringAsFixed(2)}x';
}

class AppSettings {
  const AppSettings({
    required this.screenProfile,
    required this.cityId,
    required this.prayerMethod,
    required this.useDaylightSavingTime,
    required this.fajrAdjustmentMinutes,
    required this.dhuhrAdjustmentMinutes,
    required this.asrAdjustmentMinutes,
    required this.maghribAdjustmentMinutes,
    required this.ishaAdjustmentMinutes,
    required this.hijriOffset,
    required this.displayFontSize,
    required this.displayFontWeight,
    required this.arabicFontStyle,
    required this.prePrayerWindowMinutes,
    required this.entryDuaDurationMinutes,
    required this.afterAdhanAzkarStartOffsetMinutes,
    required this.azkarDurationMinutes,
    required this.exitDuaDurationMinutes,
    required this.uiScalePercent,
    required this.sleepBrightnessPercent,
    required this.screenLockModeEnabled,
    required this.showNextPrayerFooter,
    required this.keepScreenAlwaysOn,
    required this.offModeType,
    required this.autoScreenControlEnabled,
    required this.entryDuaEnabled,
    required this.afterPrayerAzkarEnabled,
    required this.exitDuaEnabled,
    required this.manualOverrideMode,
    required this.autoScrollSpeedMultiplier,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      screenProfile: TvScreenProfile.inch55,
      cityId: 'cairo',
      prayerMethod: PrayerMethodOption.egyptian,
      useDaylightSavingTime: true,
      fajrAdjustmentMinutes: 0,
      dhuhrAdjustmentMinutes: 0,
      asrAdjustmentMinutes: 0,
      maghribAdjustmentMinutes: 0,
      ishaAdjustmentMinutes: 0,
      hijriOffset: 0,
      displayFontSize: DisplayFontSizeOption.medium,
      displayFontWeight: DisplayFontWeightOption.normal,
      arabicFontStyle: ArabicFontStyleOption.classicQuranic,
      prePrayerWindowMinutes: 20,
      entryDuaDurationMinutes: 20,
      afterAdhanAzkarStartOffsetMinutes: 30,
      azkarDurationMinutes: 20,
      exitDuaDurationMinutes: 20,
      uiScalePercent: 100,
      sleepBrightnessPercent: 5,
      screenLockModeEnabled: true,
      showNextPrayerFooter: true,
      keepScreenAlwaysOn: true,
      offModeType: OffModeTypeOption.realStandby,
      autoScreenControlEnabled: true,
      entryDuaEnabled: true,
      afterPrayerAzkarEnabled: true,
      exitDuaEnabled: true,
      manualOverrideMode: false,
      autoScrollSpeedMultiplier: 1.0,
    );
  }

  final TvScreenProfile screenProfile;
  final String cityId;
  final PrayerMethodOption prayerMethod;
  final bool useDaylightSavingTime;
  final int fajrAdjustmentMinutes;
  final int dhuhrAdjustmentMinutes;
  final int asrAdjustmentMinutes;
  final int maghribAdjustmentMinutes;
  final int ishaAdjustmentMinutes;
  final int hijriOffset;
  final DisplayFontSizeOption displayFontSize;
  final DisplayFontWeightOption displayFontWeight;
  final ArabicFontStyleOption arabicFontStyle;
  final int prePrayerWindowMinutes;
  final int entryDuaDurationMinutes;
  final int afterAdhanAzkarStartOffsetMinutes;
  final int azkarDurationMinutes;
  final int exitDuaDurationMinutes;
  final int uiScalePercent;
  final int sleepBrightnessPercent;
  final bool screenLockModeEnabled;
  final bool showNextPrayerFooter;
  final bool keepScreenAlwaysOn;
  final OffModeTypeOption offModeType;
  final bool autoScreenControlEnabled;
  final bool entryDuaEnabled;
  final bool afterPrayerAzkarEnabled;
  final bool exitDuaEnabled;
  final bool manualOverrideMode;
  final double autoScrollSpeedMultiplier;

  int manualAdjustmentFor(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return fajrAdjustmentMinutes;
      case PrayerName.dhuhr:
        return dhuhrAdjustmentMinutes;
      case PrayerName.asr:
        return asrAdjustmentMinutes;
      case PrayerName.maghrib:
        return maghribAdjustmentMinutes;
      case PrayerName.isha:
        return ishaAdjustmentMinutes;
    }
  }

  AppSettings copyWith({
    TvScreenProfile? screenProfile,
    String? cityId,
    PrayerMethodOption? prayerMethod,
    bool? useDaylightSavingTime,
    int? fajrAdjustmentMinutes,
    int? dhuhrAdjustmentMinutes,
    int? asrAdjustmentMinutes,
    int? maghribAdjustmentMinutes,
    int? ishaAdjustmentMinutes,
    int? hijriOffset,
    DisplayFontSizeOption? displayFontSize,
    DisplayFontWeightOption? displayFontWeight,
    ArabicFontStyleOption? arabicFontStyle,
    int? prePrayerWindowMinutes,
    int? entryDuaDurationMinutes,
    int? afterAdhanAzkarStartOffsetMinutes,
    int? azkarDurationMinutes,
    int? exitDuaDurationMinutes,
    int? uiScalePercent,
    int? sleepBrightnessPercent,
    bool? screenLockModeEnabled,
    bool? showNextPrayerFooter,
    bool? keepScreenAlwaysOn,
    OffModeTypeOption? offModeType,
    bool? autoScreenControlEnabled,
    bool? entryDuaEnabled,
    bool? afterPrayerAzkarEnabled,
    bool? exitDuaEnabled,
    bool? manualOverrideMode,
    double? autoScrollSpeedMultiplier,
  }) {
    return AppSettings(
      screenProfile: screenProfile ?? this.screenProfile,
      cityId: cityId ?? this.cityId,
      prayerMethod: prayerMethod ?? this.prayerMethod,
      useDaylightSavingTime:
          useDaylightSavingTime ?? this.useDaylightSavingTime,
      fajrAdjustmentMinutes:
          fajrAdjustmentMinutes ?? this.fajrAdjustmentMinutes,
      dhuhrAdjustmentMinutes:
          dhuhrAdjustmentMinutes ?? this.dhuhrAdjustmentMinutes,
      asrAdjustmentMinutes: asrAdjustmentMinutes ?? this.asrAdjustmentMinutes,
      maghribAdjustmentMinutes:
          maghribAdjustmentMinutes ?? this.maghribAdjustmentMinutes,
      ishaAdjustmentMinutes:
          ishaAdjustmentMinutes ?? this.ishaAdjustmentMinutes,
      hijriOffset: hijriOffset ?? this.hijriOffset,
      displayFontSize: displayFontSize ?? this.displayFontSize,
      displayFontWeight: displayFontWeight ?? this.displayFontWeight,
      arabicFontStyle: arabicFontStyle ?? this.arabicFontStyle,
      prePrayerWindowMinutes:
          prePrayerWindowMinutes ?? this.prePrayerWindowMinutes,
      entryDuaDurationMinutes:
          entryDuaDurationMinutes ?? this.entryDuaDurationMinutes,
      afterAdhanAzkarStartOffsetMinutes: afterAdhanAzkarStartOffsetMinutes ??
          this.afterAdhanAzkarStartOffsetMinutes,
      azkarDurationMinutes: azkarDurationMinutes ?? this.azkarDurationMinutes,
      exitDuaDurationMinutes:
          exitDuaDurationMinutes ?? this.exitDuaDurationMinutes,
      uiScalePercent: uiScalePercent ?? this.uiScalePercent,
      sleepBrightnessPercent:
          sleepBrightnessPercent ?? this.sleepBrightnessPercent,
      screenLockModeEnabled:
          screenLockModeEnabled ?? this.screenLockModeEnabled,
      showNextPrayerFooter: showNextPrayerFooter ?? this.showNextPrayerFooter,
      keepScreenAlwaysOn: keepScreenAlwaysOn ?? this.keepScreenAlwaysOn,
      offModeType: offModeType ?? this.offModeType,
      autoScreenControlEnabled:
          autoScreenControlEnabled ?? this.autoScreenControlEnabled,
      entryDuaEnabled: entryDuaEnabled ?? this.entryDuaEnabled,
      afterPrayerAzkarEnabled:
          afterPrayerAzkarEnabled ?? this.afterPrayerAzkarEnabled,
      exitDuaEnabled: exitDuaEnabled ?? this.exitDuaEnabled,
      manualOverrideMode: manualOverrideMode ?? this.manualOverrideMode,
      autoScrollSpeedMultiplier:
          autoScrollSpeedMultiplier ?? this.autoScrollSpeedMultiplier,
    );
  }

  static String dayKeyFrom(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
