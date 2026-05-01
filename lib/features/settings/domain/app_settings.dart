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

class AppSettings {
  const AppSettings({
    required this.cityId,
    required this.prayerMethod,
    required this.hijriOffset,
    required this.displayFontSize,
    required this.displayFontWeight,
    required this.prePrayerWindowMinutes,
    required this.entryDuaDurationMinutes,
    required this.azkarDurationMinutes,
    required this.exitDuaDurationMinutes,
    required this.uiScalePercent,
    required this.zikrTextScalePercent,
    required this.sleepBrightnessPercent,
    required this.autoScreenControlEnabled,
    required this.entryDuaEnabled,
    required this.afterPrayerAzkarEnabled,
    required this.exitDuaEnabled,
    required this.manualOverrideMode,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      cityId: 'cairo',
      prayerMethod: PrayerMethodOption.egyptian,
      hijriOffset: 0,
      displayFontSize: DisplayFontSizeOption.medium,
      displayFontWeight: DisplayFontWeightOption.normal,
      prePrayerWindowMinutes: 10,
      entryDuaDurationMinutes: 10,
      azkarDurationMinutes: 20,
      exitDuaDurationMinutes: 20,
      uiScalePercent: 100,
      zikrTextScalePercent: 100,
      sleepBrightnessPercent: 5,
      autoScreenControlEnabled: true,
      entryDuaEnabled: true,
      afterPrayerAzkarEnabled: true,
      exitDuaEnabled: true,
      manualOverrideMode: false,
    );
  }

  final String cityId;
  final PrayerMethodOption prayerMethod;
  final int hijriOffset;
  final DisplayFontSizeOption displayFontSize;
  final DisplayFontWeightOption displayFontWeight;
  final int prePrayerWindowMinutes;
  final int entryDuaDurationMinutes;
  final int azkarDurationMinutes;
  final int exitDuaDurationMinutes;
  final int uiScalePercent;
  final int zikrTextScalePercent;
  final int sleepBrightnessPercent;
  final bool autoScreenControlEnabled;
  final bool entryDuaEnabled;
  final bool afterPrayerAzkarEnabled;
  final bool exitDuaEnabled;
  final bool manualOverrideMode;

  int get azkarItemSeconds => 12;

  AppSettings copyWith({
    String? cityId,
    PrayerMethodOption? prayerMethod,
    int? hijriOffset,
    DisplayFontSizeOption? displayFontSize,
    DisplayFontWeightOption? displayFontWeight,
    int? prePrayerWindowMinutes,
    int? entryDuaDurationMinutes,
    int? azkarDurationMinutes,
    int? exitDuaDurationMinutes,
    int? uiScalePercent,
    int? zikrTextScalePercent,
    int? sleepBrightnessPercent,
    bool? autoScreenControlEnabled,
    bool? entryDuaEnabled,
    bool? afterPrayerAzkarEnabled,
    bool? exitDuaEnabled,
    bool? manualOverrideMode,
  }) {
    return AppSettings(
      cityId: cityId ?? this.cityId,
      prayerMethod: prayerMethod ?? this.prayerMethod,
      hijriOffset: hijriOffset ?? this.hijriOffset,
      displayFontSize: displayFontSize ?? this.displayFontSize,
      displayFontWeight: displayFontWeight ?? this.displayFontWeight,
      prePrayerWindowMinutes:
          prePrayerWindowMinutes ?? this.prePrayerWindowMinutes,
      entryDuaDurationMinutes:
          entryDuaDurationMinutes ?? this.entryDuaDurationMinutes,
      azkarDurationMinutes: azkarDurationMinutes ?? this.azkarDurationMinutes,
      exitDuaDurationMinutes:
          exitDuaDurationMinutes ?? this.exitDuaDurationMinutes,
      uiScalePercent: uiScalePercent ?? this.uiScalePercent,
      zikrTextScalePercent: zikrTextScalePercent ?? this.zikrTextScalePercent,
      sleepBrightnessPercent:
          sleepBrightnessPercent ?? this.sleepBrightnessPercent,
      autoScreenControlEnabled:
          autoScreenControlEnabled ?? this.autoScreenControlEnabled,
      entryDuaEnabled: entryDuaEnabled ?? this.entryDuaEnabled,
      afterPrayerAzkarEnabled:
          afterPrayerAzkarEnabled ?? this.afterPrayerAzkarEnabled,
      exitDuaEnabled: exitDuaEnabled ?? this.exitDuaEnabled,
      manualOverrideMode: manualOverrideMode ?? this.manualOverrideMode,
    );
  }

  static String dayKeyFrom(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
