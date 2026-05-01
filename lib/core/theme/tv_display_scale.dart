import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../layout/tv_screen_profile.dart';

@immutable
class TvDisplayScale extends ThemeExtension<TvDisplayScale> {
  const TvDisplayScale({
    required this.profileScaleMultiplier,
    required this.fontScaleMultiplier,
    required this.pagePadding,
    required this.cardPadding,
    required this.radius,
    required this.compactGap,
    required this.mediumGap,
    required this.expandedGap,
    required this.displayLarge,
    required this.displayMedium,
    required this.headlineMedium,
    required this.titleLarge,
    required this.titleMedium,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.labelLarge,
    required this.buttonHorizontalPadding,
    required this.buttonVerticalPadding,
    required this.buttonIconSize,
    required this.dashboardMaxWidth,
    required this.contentPanelFlex,
    required this.sidePanelFlex,
  });

  final double profileScaleMultiplier;
  final double fontScaleMultiplier;
  final double pagePadding;
  final double cardPadding;
  final double radius;
  final double compactGap;
  final double mediumGap;
  final double expandedGap;
  final double displayLarge;
  final double displayMedium;
  final double headlineMedium;
  final double titleLarge;
  final double titleMedium;
  final double bodyLarge;
  final double bodyMedium;
  final double labelLarge;
  final double buttonHorizontalPadding;
  final double buttonVerticalPadding;
  final double buttonIconSize;
  final double dashboardMaxWidth;
  final int contentPanelFlex;
  final int sidePanelFlex;

  double get textScaleFactor => profileScaleMultiplier * fontScaleMultiplier;

  static const TvDisplayScale _baseline = TvDisplayScale(
    profileScaleMultiplier: 1,
    fontScaleMultiplier: 1,
    pagePadding: 22,
    cardPadding: 20,
    radius: 24,
    compactGap: 12,
    mediumGap: 18,
    expandedGap: 22,
    displayLarge: 68,
    displayMedium: 44,
    headlineMedium: 30,
    titleLarge: 24,
    titleMedium: 20,
    bodyLarge: 22,
    bodyMedium: 18,
    labelLarge: 18,
    buttonHorizontalPadding: 18,
    buttonVerticalPadding: 12,
    buttonIconSize: 22,
    dashboardMaxWidth: 1500,
    contentPanelFlex: 8,
    sidePanelFlex: 5,
  );

  static TvDisplayScale fromProfile(TvScreenProfile profile) {
    return _baseline.scaled(profile.scaleMultiplier);
  }

  TvDisplayScale scaled(double multiplier) {
    return TvDisplayScale(
      profileScaleMultiplier: multiplier,
      fontScaleMultiplier: fontScaleMultiplier,
      pagePadding: pagePadding * multiplier,
      cardPadding: cardPadding * multiplier,
      radius: radius * multiplier,
      compactGap: compactGap * multiplier,
      mediumGap: mediumGap * multiplier,
      expandedGap: expandedGap * multiplier,
      displayLarge: displayLarge * multiplier,
      displayMedium: displayMedium * multiplier,
      headlineMedium: headlineMedium * multiplier,
      titleLarge: titleLarge * multiplier,
      titleMedium: titleMedium * multiplier,
      bodyLarge: bodyLarge * multiplier,
      bodyMedium: bodyMedium * multiplier,
      labelLarge: labelLarge * multiplier,
      buttonHorizontalPadding: buttonHorizontalPadding * multiplier,
      buttonVerticalPadding: buttonVerticalPadding * multiplier,
      buttonIconSize: buttonIconSize * multiplier,
      dashboardMaxWidth: dashboardMaxWidth * multiplier,
      contentPanelFlex: contentPanelFlex,
      sidePanelFlex: sidePanelFlex,
    );
  }

  TvDisplayScale withFontScale(double multiplier) {
    return TvDisplayScale(
      profileScaleMultiplier: profileScaleMultiplier,
      fontScaleMultiplier: multiplier,
      pagePadding: pagePadding,
      cardPadding: cardPadding,
      radius: radius,
      compactGap: compactGap,
      mediumGap: mediumGap,
      expandedGap: expandedGap,
      displayLarge: displayLarge * multiplier,
      displayMedium: displayMedium * multiplier,
      headlineMedium: headlineMedium * multiplier,
      titleLarge: titleLarge * multiplier,
      titleMedium: titleMedium * multiplier,
      bodyLarge: bodyLarge * multiplier,
      bodyMedium: bodyMedium * multiplier,
      labelLarge: labelLarge * multiplier,
      buttonHorizontalPadding: buttonHorizontalPadding,
      buttonVerticalPadding: buttonVerticalPadding,
      buttonIconSize: buttonIconSize,
      dashboardMaxWidth: dashboardMaxWidth,
      contentPanelFlex: contentPanelFlex,
      sidePanelFlex: sidePanelFlex,
    );
  }

  @override
  TvDisplayScale copyWith({
    double? profileScaleMultiplier,
    double? fontScaleMultiplier,
    double? pagePadding,
    double? cardPadding,
    double? radius,
    double? compactGap,
    double? mediumGap,
    double? expandedGap,
    double? displayLarge,
    double? displayMedium,
    double? headlineMedium,
    double? titleLarge,
    double? titleMedium,
    double? bodyLarge,
    double? bodyMedium,
    double? labelLarge,
    double? buttonHorizontalPadding,
    double? buttonVerticalPadding,
    double? buttonIconSize,
    double? dashboardMaxWidth,
    int? contentPanelFlex,
    int? sidePanelFlex,
  }) {
    return TvDisplayScale(
      profileScaleMultiplier:
          profileScaleMultiplier ?? this.profileScaleMultiplier,
      fontScaleMultiplier: fontScaleMultiplier ?? this.fontScaleMultiplier,
      pagePadding: pagePadding ?? this.pagePadding,
      cardPadding: cardPadding ?? this.cardPadding,
      radius: radius ?? this.radius,
      compactGap: compactGap ?? this.compactGap,
      mediumGap: mediumGap ?? this.mediumGap,
      expandedGap: expandedGap ?? this.expandedGap,
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      headlineMedium: headlineMedium ?? this.headlineMedium,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      labelLarge: labelLarge ?? this.labelLarge,
      buttonHorizontalPadding:
          buttonHorizontalPadding ?? this.buttonHorizontalPadding,
      buttonVerticalPadding:
          buttonVerticalPadding ?? this.buttonVerticalPadding,
      buttonIconSize: buttonIconSize ?? this.buttonIconSize,
      dashboardMaxWidth: dashboardMaxWidth ?? this.dashboardMaxWidth,
      contentPanelFlex: contentPanelFlex ?? this.contentPanelFlex,
      sidePanelFlex: sidePanelFlex ?? this.sidePanelFlex,
    );
  }

  @override
  TvDisplayScale lerp(ThemeExtension<TvDisplayScale>? other, double t) {
    if (other is! TvDisplayScale) {
      return this;
    }

    return TvDisplayScale(
      profileScaleMultiplier:
          lerpDouble(profileScaleMultiplier, other.profileScaleMultiplier, t)!,
      fontScaleMultiplier:
          lerpDouble(fontScaleMultiplier, other.fontScaleMultiplier, t)!,
      pagePadding: lerpDouble(pagePadding, other.pagePadding, t)!,
      cardPadding: lerpDouble(cardPadding, other.cardPadding, t)!,
      radius: lerpDouble(radius, other.radius, t)!,
      compactGap: lerpDouble(compactGap, other.compactGap, t)!,
      mediumGap: lerpDouble(mediumGap, other.mediumGap, t)!,
      expandedGap: lerpDouble(expandedGap, other.expandedGap, t)!,
      displayLarge: lerpDouble(displayLarge, other.displayLarge, t)!,
      displayMedium: lerpDouble(displayMedium, other.displayMedium, t)!,
      headlineMedium: lerpDouble(headlineMedium, other.headlineMedium, t)!,
      titleLarge: lerpDouble(titleLarge, other.titleLarge, t)!,
      titleMedium: lerpDouble(titleMedium, other.titleMedium, t)!,
      bodyLarge: lerpDouble(bodyLarge, other.bodyLarge, t)!,
      bodyMedium: lerpDouble(bodyMedium, other.bodyMedium, t)!,
      labelLarge: lerpDouble(labelLarge, other.labelLarge, t)!,
      buttonHorizontalPadding: lerpDouble(
        buttonHorizontalPadding,
        other.buttonHorizontalPadding,
        t,
      )!,
      buttonVerticalPadding:
          lerpDouble(buttonVerticalPadding, other.buttonVerticalPadding, t)!,
      buttonIconSize: lerpDouble(buttonIconSize, other.buttonIconSize, t)!,
      dashboardMaxWidth:
          lerpDouble(dashboardMaxWidth, other.dashboardMaxWidth, t)!,
      contentPanelFlex: t < 0.5 ? contentPanelFlex : other.contentPanelFlex,
      sidePanelFlex: t < 0.5 ? sidePanelFlex : other.sidePanelFlex,
    );
  }
}
