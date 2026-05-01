enum PrayerName {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha,
}

extension PrayerNameX on PrayerName {
  String get arabicLabel {
    switch (this) {
      case PrayerName.fajr:
        return 'الفجر';
      case PrayerName.dhuhr:
        return 'الظهر';
      case PrayerName.asr:
        return 'العصر';
      case PrayerName.maghrib:
        return 'المغرب';
      case PrayerName.isha:
        return 'العشاء';
    }
  }

  String get tagKey => 'prayer_$name';

  bool get hasPostPrayerSunnah {
    return this == PrayerName.dhuhr ||
        this == PrayerName.maghrib ||
        this == PrayerName.isha;
  }
}

class PrayerTimeEntry {
  const PrayerTimeEntry({
    required this.name,
    required this.time,
  });

  final PrayerName name;
  final DateTime time;
}

class PrayerDayInfo {
  const PrayerDayInfo({
    required this.todayEntries,
    required this.nextPrayer,
    required this.lastPrayer,
    required this.timeUntilNextPrayer,
  });

  final List<PrayerTimeEntry> todayEntries;
  final PrayerTimeEntry nextPrayer;
  final PrayerTimeEntry lastPrayer;
  final Duration timeUntilNextPrayer;

  DateTime timeFor(PrayerName prayer) {
    return todayEntries.firstWhere((entry) => entry.name == prayer).time;
  }
}
