class AppCity {
  const AppCity({
    required this.id,
    required this.arabicName,
    required this.englishName,
    required this.latitude,
    required this.longitude,
    required this.timeZoneId,
  });

  final String id;
  final String arabicName;
  final String englishName;
  final double latitude;
  final double longitude;
  final String timeZoneId;
}

const List<AppCity> appCities = [
  AppCity(
    id: 'cairo',
    arabicName: 'القاهرة',
    englishName: 'Cairo',
    latitude: 30.0444,
    longitude: 31.2357,
    timeZoneId: 'Africa/Cairo',
  ),
  AppCity(
    id: 'giza',
    arabicName: 'الجيزة',
    englishName: 'Giza',
    latitude: 30.0131,
    longitude: 31.2089,
    timeZoneId: 'Africa/Cairo',
  ),
  AppCity(
    id: 'alexandria',
    arabicName: 'الإسكندرية',
    englishName: 'Alexandria',
    latitude: 31.2001,
    longitude: 29.9187,
    timeZoneId: 'Africa/Cairo',
  ),
  AppCity(
    id: 'mansoura',
    arabicName: 'المنصورة',
    englishName: 'Mansoura',
    latitude: 31.0409,
    longitude: 31.3785,
    timeZoneId: 'Africa/Cairo',
  ),
  AppCity(
    id: 'tanta',
    arabicName: 'طنطا',
    englishName: 'Tanta',
    latitude: 30.7865,
    longitude: 31.0004,
    timeZoneId: 'Africa/Cairo',
  ),
  AppCity(
    id: 'ismailia',
    arabicName: 'الإسماعيلية',
    englishName: 'Ismailia',
    latitude: 30.5965,
    longitude: 32.2715,
    timeZoneId: 'Africa/Cairo',
  ),
  AppCity(
    id: 'luxor',
    arabicName: 'الأقصر',
    englishName: 'Luxor',
    latitude: 25.6872,
    longitude: 32.6396,
    timeZoneId: 'Africa/Cairo',
  ),
  AppCity(
    id: 'aswan',
    arabicName: 'أسوان',
    englishName: 'Aswan',
    latitude: 24.0889,
    longitude: 32.8998,
    timeZoneId: 'Africa/Cairo',
  ),
];

AppCity appCityById(String id) {
  return appCities.firstWhere(
    (city) => city.id == id,
    orElse: () => appCities.first,
  );
}
