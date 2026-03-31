enum TvScreenProfile {
  inch21,
  inch24,
  inch27,
  inch32,
  inch40,
  inch42,
  inch50,
  inch55,
  inch65,
  inch75,
  inch85,
}

extension TvScreenProfileX on TvScreenProfile {
  String get storageValue => name;

  int get diagonalInches {
    switch (this) {
      case TvScreenProfile.inch21:
        return 21;
      case TvScreenProfile.inch24:
        return 24;
      case TvScreenProfile.inch27:
        return 27;
      case TvScreenProfile.inch32:
        return 32;
      case TvScreenProfile.inch40:
        return 40;
      case TvScreenProfile.inch42:
        return 42;
      case TvScreenProfile.inch50:
        return 50;
      case TvScreenProfile.inch55:
        return 55;
      case TvScreenProfile.inch65:
        return 65;
      case TvScreenProfile.inch75:
        return 75;
      case TvScreenProfile.inch85:
        return 85;
    }
  }

  String get labelArabic => '$diagonalInches بوصة';

  String get labelEnglish => '$diagonalInches inch';

  double get scaleMultiplier {
    switch (this) {
      case TvScreenProfile.inch21:
        return 0.82;
      case TvScreenProfile.inch24:
        return 0.86;
      case TvScreenProfile.inch27:
        return 0.90;
      case TvScreenProfile.inch32:
        return 0.94;
      case TvScreenProfile.inch40:
        return 0.98;
      case TvScreenProfile.inch42:
        return 1.00;
      case TvScreenProfile.inch50:
        return 1.05;
      case TvScreenProfile.inch55:
        return 1.10;
      case TvScreenProfile.inch65:
        return 1.18;
      case TvScreenProfile.inch75:
        return 1.26;
      case TvScreenProfile.inch85:
        return 1.34;
    }
  }

  String get previewLabel =>
      '$labelArabic • ×${scaleMultiplier.toStringAsFixed(2)}';

  static TvScreenProfile fromStorage(String? value) {
    return TvScreenProfile.values.firstWhere(
      (profile) => profile.storageValue == value,
      orElse: () => TvScreenProfile.inch55,
    );
  }
}
