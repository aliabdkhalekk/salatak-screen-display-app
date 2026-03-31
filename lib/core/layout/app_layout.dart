import 'package:flutter/material.dart';

import 'tv_screen_profile.dart';
import 'tv_viewport_frame.dart';
import '../theme/tv_display_scale.dart';

abstract final class AppLayout {
  static Size size(BuildContext context) =>
      TvViewport.maybeOf(context)?.frameSize ?? MediaQuery.sizeOf(context);

  static double width(BuildContext context) => size(context).width;

  static double height(BuildContext context) => size(context).height;

  static bool isCompact(BuildContext context) => width(context) < 700;

  static bool isNarrow(BuildContext context) => width(context) < 900;

  static bool isShort(BuildContext context) => height(context) < 720;

  static TvDisplayScale scale(BuildContext context) =>
      Theme.of(context).extension<TvDisplayScale>() ??
      TvDisplayScale.fromProfile(
        TvScreenProfile.inch55,
      );

  static double designScale(BuildContext context) {
    return TvViewport.maybeOf(context)?.designScale ?? 1;
  }

  static double visualScale(BuildContext context) {
    return designScale(context).clamp(0.92, 1.08) as double;
  }

  static double textDesignScale(BuildContext context) {
    return designScale(context).clamp(1.0, 1.08) as double;
  }

  static double pagePadding(BuildContext context) {
    final profilePadding = scale(context).pagePadding * visualScale(context);
    if (width(context) < 420) {
      return profilePadding - 4;
    }
    if (width(context) < 760) {
      return profilePadding - 2;
    }
    return profilePadding;
  }

  static double cardPadding(BuildContext context) {
    final profilePadding = scale(context).cardPadding * visualScale(context);
    if (width(context) < 420) {
      return profilePadding - 4;
    }
    if (width(context) < 760) {
      return profilePadding - 2;
    }
    return profilePadding;
  }

  static double radius(BuildContext context) {
    final profileRadius = scale(context).radius * visualScale(context);
    if (width(context) < 420) {
      return profileRadius - 4;
    }
    if (width(context) < 760) {
      return profileRadius - 2;
    }
    return profileRadius;
  }

  static double gap(
    BuildContext context, {
    double compact = 12,
    double medium = 18,
    double expanded = 24,
  }) {
    final profile = scale(context);
    final screenWidth = width(context);
    final viewportScale = visualScale(context);
    if (screenWidth < 420) {
      return profile.compactGap * (compact / 12) * viewportScale;
    }
    if (screenWidth < 900) {
      return profile.mediumGap * (medium / 18) * viewportScale;
    }
    return profile.expandedGap * (expanded / 24) * viewportScale;
  }

  static double fluid(
    BuildContext context, {
    required double min,
    required double max,
    double minWidth = 360,
    double maxWidth = 1600,
  }) {
    final screenWidth = width(context);
    final progress =
        ((screenWidth - minWidth) / (maxWidth - minWidth)).clamp(0.0, 1.0)
            as double;
    final fluidValue = min + (max - min) * progress;
    final profileTextScale =
        scale(context).textScaleFactor.clamp(0.78, 1.60) as double;
    return fluidValue * profileTextScale * textDesignScale(context);
  }

  static double readableFluid(
    BuildContext context, {
    required double min,
    required double max,
    required double readableMin,
    double minWidth = 360,
    double maxWidth = 1600,
  }) {
    final value = fluid(
      context,
      min: min,
      max: max,
      minWidth: minWidth,
      maxWidth: maxWidth,
    );
    return value < readableMin ? readableMin : value;
  }

  static double dashboardMaxWidth(BuildContext context) {
    final maxWidth = scale(context).dashboardMaxWidth * visualScale(context);
    if (width(context) < 960) {
      return width(context);
    }
    return maxWidth.clamp(0.0, width(context)) as double;
  }

  static int contentPanelFlex(BuildContext context) {
    return scale(context).contentPanelFlex;
  }

  static int sidePanelFlex(BuildContext context) {
    return scale(context).sidePanelFlex;
  }

  static double buttonHorizontalPadding(BuildContext context) {
    return scale(context).buttonHorizontalPadding * visualScale(context);
  }

  static double buttonVerticalPadding(BuildContext context) {
    return scale(context).buttonVerticalPadding * visualScale(context);
  }

  static double buttonIconSize(BuildContext context) {
    return scale(context).buttonIconSize * textDesignScale(context);
  }
}
