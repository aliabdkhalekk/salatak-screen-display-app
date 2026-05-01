class HijriDate {
  const HijriDate({
    required this.day,
    required this.month,
    required this.year,
    required this.weekdayArabic,
    this.synced = false,
  });

  final int day;
  final int month;
  final int year;
  final String weekdayArabic;
  final bool synced;

  static const List<String> _monthsArabic = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  String get monthArabic => _monthsArabic[month - 1];

  String get formatted => '$weekdayArabic $day $monthArabic $year هـ';
}

class HijriSyncSnapshot {
  const HijriSyncSnapshot({
    required this.gregorianIsoDate,
    required this.day,
    required this.month,
    required this.year,
  });

  factory HijriSyncSnapshot.fromJson(Map<String, dynamic> json) {
    return HijriSyncSnapshot(
      gregorianIsoDate: json['gregorianIsoDate'] as String,
      day: json['day'] as int,
      month: json['month'] as int,
      year: json['year'] as int,
    );
  }

  final String gregorianIsoDate;
  final int day;
  final int month;
  final int year;

  Map<String, dynamic> toJson() {
    return {
      'gregorianIsoDate': gregorianIsoDate,
      'day': day,
      'month': month,
      'year': year,
    };
  }
}
