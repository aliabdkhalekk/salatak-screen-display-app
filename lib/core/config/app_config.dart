abstract final class AppConfig {
  static const int beforePrayerGeneralWindowMinutes = 60;
  static const int beforePrayerSpecificWindowMinutes = 20;
  static const int postPrayerSequenceWindowMinutes = 15;
  static const int postPrayerStepSeconds = 12;
  static const int defaultRotationSeconds = 16;

  /// Keep empty by default. When a bundle URL is provided, the app will fetch
  /// a JSON payload with keys matching the local content files.
  static const String remoteContentBundleUrl = '';
}

