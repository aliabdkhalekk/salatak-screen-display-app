import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/layout/app_layout.dart';
import '../../../core/layout/tv_viewport_frame.dart';
import '../../../core/widgets/auto_scrolling_text.dart';
import '../../automation/domain/prayer_flow_models.dart';
import '../../automation/domain/zikr_content.dart';
import '../../dashboard/domain/dashboard_state.dart';
import '../../prayer/domain/prayer_models.dart';
import '../../settings/domain/app_settings.dart';

class MosqueDisplaySurface extends StatelessWidget {
  const MosqueDisplaySurface({
    super.key,
    required this.state,
    required this.settings,
    required this.onOpenSettings,
    required this.controlsVisible,
  });

  final DashboardState state;
  final AppSettings settings;
  final VoidCallback onOpenSettings;
  final bool controlsVisible;

  @override
  Widget build(BuildContext context) {
    final errorMessage = state.errorMessage;
    if (errorMessage != null) {
      return MosqueErrorScreen(
        message: errorMessage,
        onOpenSettings: onOpenSettings,
        controlsVisible: controlsVisible,
      );
    }

    return MosqueContentScreens.fromSnapshot(
      snapshot: state.automation,
      now: state.now,
      prayerDay: state.prayerDay,
      settings: settings,
      onOpenSettings: onOpenSettings,
      controlsVisible: controlsVisible,
    );
  }
}

abstract final class MosqueContentScreens {
  static Widget fromSnapshot({
    required PrayerFlowSnapshot snapshot,
    required DateTime now,
    required PrayerDayInfo? prayerDay,
    required AppSettings settings,
    required VoidCallback onOpenSettings,
    required bool controlsVisible,
  }) {
    switch (snapshot.mode) {
      case DisplayStateMode.blackScreen:
        return const MosqueBlackScreen();
      case DisplayStateMode.duaEntry:
        return MosqueDuaScreen(
          title: entryDuaContent.title,
          text: entryDuaContent.text,
          now: now,
          prayerDay: prayerDay,
          showFooter: settings.showNextPrayerFooter,
          onOpenSettings: onOpenSettings,
          controlsVisible: controlsVisible,
        );
      case DisplayStateMode.prayerTime:
        return MosquePrayerTimeScreen(
          prayer: snapshot.prayer,
          now: now,
          prayerDay: prayerDay,
          showFooter: settings.showNextPrayerFooter,
          onOpenSettings: onOpenSettings,
          controlsVisible: controlsVisible,
        );
      case DisplayStateMode.postPrayerAzkar:
        return MosqueAzkarScreen(
          text: afterPrayerAzkarContent.first.text,
          autoScrollSpeedMultiplier: settings.autoScrollSpeedMultiplier,
          now: now,
          prayerDay: prayerDay,
          showFooter: settings.showNextPrayerFooter,
          onOpenSettings: onOpenSettings,
          controlsVisible: controlsVisible,
        );
      case DisplayStateMode.duaExit:
        return MosqueDuaScreen(
          title: exitDuaContent.title,
          text: exitDuaContent.text,
          now: now,
          prayerDay: prayerDay,
          showFooter: settings.showNextPrayerFooter,
          onOpenSettings: onOpenSettings,
          controlsVisible: controlsVisible,
        );
    }
  }

  static Widget preview({
    required DisplayStateMode mode,
    required DateTime now,
    required VoidCallback onOpenSettings,
  }) {
    return fromSnapshot(
      snapshot: PrayerFlowSnapshot(
        mode: mode,
        prayer: PrayerName.dhuhr,
        stageStartedAt: now,
        stageEndsAt: now.add(const Duration(minutes: 20)),
        nextTransitionAt: null,
        entryDua: entryDuaContent,
        exitDua: exitDuaContent,
        azkarItems: afterPrayerAzkarContent,
      ),
      now: now,
      prayerDay: null,
      settings: AppSettings.defaults(),
      onOpenSettings: onOpenSettings,
      controlsVisible: true,
    );
  }
}

class MosqueBlackScreen extends StatelessWidget {
  const MosqueBlackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: SizedBox.expand(),
    );
  }
}

class MosqueDuaScreen extends StatelessWidget {
  const MosqueDuaScreen({
    super.key,
    required this.title,
    required this.text,
    required this.now,
    required this.prayerDay,
    required this.showFooter,
    required this.onOpenSettings,
    required this.controlsVisible,
  });

  final String title;
  final String text;
  final DateTime now;
  final PrayerDayInfo? prayerDay;
  final bool showFooter;
  final VoidCallback onOpenSettings;
  final bool controlsVisible;

  @override
  Widget build(BuildContext context) {
    return _MosqueScaffold(
      now: now,
      title: title,
      prayerDay: prayerDay,
      showFooter: showFooter,
      onOpenSettings: onOpenSettings,
      controlsVisible: controlsVisible,
      child: _CenteredContentFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: AppLayout.readableFluid(
                      context,
                      min: 34,
                      max: 54,
                      readableMin: 34,
                    ),
                    color: const Color(0xFFE8DDB6),
                  ),
            ),
            SizedBox(height: AppLayout.gap(context, compact: 28, medium: 36)),
            Text(
              text,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: AppLayout.readableFluid(
                      context,
                      min: 74,
                      max: 126,
                      readableMin: 74,
                    ),
                    height: 1.65,
                    color: Colors.white,
                    shadows: _textShadows,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class MosquePrayerTimeScreen extends StatelessWidget {
  const MosquePrayerTimeScreen({
    super.key,
    required this.prayer,
    required this.now,
    required this.prayerDay,
    required this.showFooter,
    required this.onOpenSettings,
    required this.controlsVisible,
  });

  final PrayerName? prayer;
  final DateTime now;
  final PrayerDayInfo? prayerDay;
  final bool showFooter;
  final VoidCallback onOpenSettings;
  final bool controlsVisible;

  @override
  Widget build(BuildContext context) {
    final prayerLabel = prayer?.arabicLabel ?? 'الصلاة';
    return _MosqueScaffold(
      now: now,
      title: 'وقت الصلاة',
      prayerDay: prayerDay,
      showFooter: showFooter,
      onOpenSettings: onOpenSettings,
      controlsVisible: controlsVisible,
      child: _CenteredContentFrame(
        maxWidthFactor: 0.68,
        child: Text(
          'حان الآن وقت صلاة $prayerLabel',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: AppLayout.readableFluid(
                  context,
                  min: 62,
                  max: 104,
                  readableMin: 62,
                ),
                height: 1.6,
                color: Colors.white,
                shadows: _textShadows,
              ),
        ),
      ),
    );
  }
}

class MosqueAzkarScreen extends StatelessWidget {
  const MosqueAzkarScreen({
    super.key,
    required this.text,
    required this.autoScrollSpeedMultiplier,
    required this.now,
    required this.prayerDay,
    required this.showFooter,
    required this.onOpenSettings,
    required this.controlsVisible,
  });

  final String text;
  final double autoScrollSpeedMultiplier;
  final DateTime now;
  final PrayerDayInfo? prayerDay;
  final bool showFooter;
  final VoidCallback onOpenSettings;
  final bool controlsVisible;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.displayMedium?.copyWith(
          fontSize: AppLayout.readableFluid(
            context,
            min: 35,
            max: 52,
            readableMin: 35,
          ),
          height: 1.8,
          color: Colors.white,
          shadows: _textShadows,
        );

    return _MosqueScaffold(
      now: now,
      title: 'أذكار بعد الصلاة',
      prayerDay: prayerDay,
      showFooter: showFooter,
      onOpenSettings: onOpenSettings,
      controlsVisible: controlsVisible,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.gap(context, compact: 18, medium: 32),
        ),
        child: _CenteredContentFrame(
          maxWidthFactor: 0.76,
          allowInternalScroll: false,
          centerChild: false,
          child: ClipRect(
            child: SizedBox.expand(
              child: AutoScrollingText(
                text: text,
                textAlign: TextAlign.center,
                style: style,
                pixelsPerSecond: 15,
                speedMultiplier: autoScrollSpeedMultiplier,
                startDelay: const Duration(seconds: 3),
                endPause: const Duration(seconds: 4),
                padding: EdgeInsets.symmetric(
                  vertical: AppLayout.gap(context, compact: 24, medium: 38),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MosqueErrorScreen extends StatelessWidget {
  const MosqueErrorScreen({
    super.key,
    required this.message,
    required this.onOpenSettings,
    required this.controlsVisible,
  });

  final String message;
  final VoidCallback onOpenSettings;
  final bool controlsVisible;

  @override
  Widget build(BuildContext context) {
    return _MosqueScaffold(
      now: DateTime.now(),
      title: 'تنبيه',
      prayerDay: null,
      showFooter: false,
      onOpenSettings: onOpenSettings,
      controlsVisible: controlsVisible,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            SizedBox(height: AppLayout.gap(context, compact: 20, medium: 28)),
            FilledButton.icon(
              autofocus: true,
              onPressed: controlsVisible ? onOpenSettings : null,
              icon: const Icon(Icons.settings_rounded),
              label: const Text('فتح الإعدادات'),
            ),
          ],
        ),
      ),
    );
  }
}

class MosquePreviewScreen extends StatelessWidget {
  const MosquePreviewScreen({
    super.key,
    required this.mode,
  });

  final DisplayStateMode mode;

  @override
  Widget build(BuildContext context) {
    return MosqueContentScreens.preview(
      mode: mode,
      now: DateTime.now(),
      onOpenSettings: () => Navigator.of(context).pop(),
    );
  }
}

class _MosqueScaffold extends StatelessWidget {
  const _MosqueScaffold({
    required this.now,
    required this.title,
    required this.prayerDay,
    required this.showFooter,
    required this.onOpenSettings,
    required this.controlsVisible,
    required this.child,
  });

  final DateTime now;
  final String title;
  final PrayerDayInfo? prayerDay;
  final bool showFooter;
  final VoidCallback onOpenSettings;
  final bool controlsVisible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF06100D),
              Color(0xFF12362F),
              Color(0xFF0A1714),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: TvViewportFrame(
          child: Builder(
            builder: (context) {
              final padding = AppLayout.pagePadding(context);
              final topBarHeight = AppLayout.fluid(context, min: 54, max: 72);
              final sectionGap = AppLayout.gap(
                context,
                compact: 12,
                medium: 18,
              );
              final footerBottomInset = AppLayout.fluid(
                context,
                min: 20,
                max: 40,
              );
              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: topBarHeight,
                        child: _MosqueTopBar(
                          title: title,
                          now: now,
                          onOpenSettings: onOpenSettings,
                          controlsVisible: controlsVisible,
                        ),
                      ),
                    ),
                    SizedBox(height: sectionGap),
                    Expanded(
                      child: child,
                    ),
                    if (showFooter && prayerDay != null) ...[
                      SizedBox(height: sectionGap),
                      SafeArea(
                        top: false,
                        minimum: EdgeInsets.only(bottom: footerBottomInset),
                        child: Center(
                          child: _NextPrayerFooter(
                            now: now,
                            prayerDay: prayerDay!,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CenteredContentFrame extends StatelessWidget {
  const _CenteredContentFrame({
    this.maxWidthFactor = 0.70,
    this.allowInternalScroll = true,
    this.centerChild = true,
    required this.child,
  });

  final double maxWidthFactor;
  final bool allowInternalScroll;
  final bool centerChild;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth * maxWidthFactor;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SizedBox(
              height: constraints.maxHeight,
              child: _buildBody(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    final body = allowInternalScroll
        ? SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Center(child: child),
          )
        : child;
    if (!centerChild) {
      return body;
    }
    return Center(child: body);
  }
}

class _NextPrayerFooter extends StatelessWidget {
  const _NextPrayerFooter({
    required this.now,
    required this.prayerDay,
  });

  final DateTime now;
  final PrayerDayInfo prayerDay;

  @override
  Widget build(BuildContext context) {
    final nextPrayer = prayerDay.nextPrayer;
    final remaining = nextPrayer.time.difference(now);
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: AppLayout.fluid(context, min: 13, max: 17),
          color: const Color(0xFFE8DDB6),
        );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: AppLayout.fluid(context, min: 760, max: 1080),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFD8BE74).withValues(alpha: 0.34),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.gap(context, compact: 12, medium: 18),
                vertical: AppLayout.gap(context, compact: 6, medium: 8),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppLayout.gap(context, compact: 10, medium: 14),
                runSpacing: AppLayout.gap(context, compact: 4, medium: 6),
                children: [
                  Text(
                    'باقي على صلاة ${nextPrayer.name.arabicLabel}: '
                    '${_formatDuration(remaining)}',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: textStyle,
                  ),
                  Text(
                    'وقت الصلاة: ${DateFormat('hh:mm a', 'ar').format(nextPrayer.time)}',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: textStyle?.copyWith(
                      color: const Color(0xFFD8BE74),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MosqueTopBar extends StatelessWidget {
  const _MosqueTopBar({
    required this.title,
    required this.now,
    required this.onOpenSettings,
    required this.controlsVisible,
  });

  final String title;
  final DateTime now;
  final VoidCallback onOpenSettings;
  final bool controlsVisible;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: AppLayout.fluid(context, min: 22, max: 34),
          color: const Color(0xFFE8DDB6),
        );

    return Row(
      children: [
        if (controlsVisible)
          IconButton(
            autofocus: true,
            tooltip: 'الإعدادات',
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_rounded),
            iconSize: AppLayout.fluid(context, min: 24, max: 34),
            color: const Color(0xFFD8BE74),
          )
        else
          SizedBox(width: AppLayout.fluid(context, min: 48, max: 58)),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
        Text(
          DateFormat('h:mm a', 'ar').format(now),
          style: style,
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(0, 999999);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

const List<Shadow> _textShadows = <Shadow>[
  Shadow(
    color: Color(0xAA000000),
    blurRadius: 12,
    offset: Offset(0, 3),
  ),
];
