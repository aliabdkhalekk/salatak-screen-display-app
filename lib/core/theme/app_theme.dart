import 'package:flutter/material.dart';

import '../layout/tv_screen_profile.dart';
import 'tv_display_scale.dart';

abstract final class AppTheme {
  static ThemeData build({
    required TvScreenProfile profile,
    required double uiScale,
    required double fontScale,
    required bool boldText,
  }) {
    const ivory = Color(0xFFF5ECD2);
    const gold = Color(0xFFD8BE74);
    const teal = Color(0xFF173E46);
    const emerald = Color(0xFF1D6B5A);
    const navy = Color(0xFF091318);
    final scale =
        TvDisplayScale.fromProfile(profile).scaled(uiScale).withFontScale(
              fontScale,
            );

    final displayWeight = boldText ? FontWeight.w800 : FontWeight.w700;
    final titleWeight = boldText ? FontWeight.w700 : FontWeight.w600;
    final bodyWeight = boldText ? FontWeight.w600 : FontWeight.w400;
    final labelWeight = boldText ? FontWeight.w700 : FontWeight.w600;

    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: navy,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: emerald,
        surface: teal,
        onPrimary: Color(0xFF091318),
        onSecondary: ivory,
        onSurface: ivory,
      ),
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        scale,
      ],
      textTheme: base.textTheme.copyWith(
        displayLarge: TextStyle(
          fontSize: scale.displayLarge,
          fontWeight: displayWeight,
          color: ivory,
          height: 1.15,
        ),
        displayMedium: TextStyle(
          fontSize: scale.displayMedium,
          fontWeight: displayWeight,
          color: ivory,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: scale.headlineMedium,
          fontWeight: displayWeight,
          color: ivory,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: scale.titleLarge,
          fontWeight: titleWeight,
          color: ivory,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: scale.titleMedium,
          fontWeight: titleWeight,
          color: ivory,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          fontSize: scale.bodyLarge,
          fontWeight: bodyWeight,
          color: ivory,
          height: 1.7,
        ),
        bodyMedium: TextStyle(
          fontSize: scale.bodyMedium,
          fontWeight: bodyWeight,
          color: const Color(0xFFE8DDB6),
          height: 1.6,
        ),
        labelLarge: TextStyle(
          fontSize: scale.labelLarge,
          fontWeight: labelWeight,
          color: ivory,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(scale.radius),
        ),
      ),
    );
  }
}
