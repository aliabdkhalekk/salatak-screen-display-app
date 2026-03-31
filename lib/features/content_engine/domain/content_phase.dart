enum ContentPhase {
  loading,
  general,
  beforePrayerGeneral,
  beforePrayerSpecific,
  postPrayerSequence,
  friday,
  manualToday,
  manualPinned,
}

extension ContentPhaseX on ContentPhase {
  String get labelArabic {
    switch (this) {
      case ContentPhase.loading:
        return 'جاري التحميل';
      case ContentPhase.general:
        return 'الحديث اليومي';
      case ContentPhase.beforePrayerGeneral:
        return 'تذكير قبل الصلاة';
      case ContentPhase.beforePrayerSpecific:
        return 'دخول المسجد';
      case ContentPhase.postPrayerSequence:
        return 'الخروج من المسجد';
      case ContentPhase.friday:
        return 'ركن الجمعة';
      case ContentPhase.manualToday:
        return 'عرض اليوم';
      case ContentPhase.manualPinned:
        return 'محتوى مثبت';
    }
  }
}
