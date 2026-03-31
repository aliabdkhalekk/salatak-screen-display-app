import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/layout/tv_viewport_frame.dart';
import '../../nawawi/presentation/nawawi_library_screen.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/dashboard_controller.dart';
import '../domain/dashboard_state.dart';
import 'widgets/content_panel.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/prayer_times_panel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final settings = ref.watch(settingsControllerProvider);

    return FocusTraversalGroup(
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF081116),
                Color(0xFF102C36),
                Color(0xFF173E46),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -120,
                left: -60,
                child: _GlowOrb(
                  color: const Color(0xFFD8BE74).withOpacity(0.12),
                  size: 340,
                ),
              ),
              Positioned(
                bottom: -100,
                right: -80,
                child: _GlowOrb(
                  color: const Color(0xFF58A890).withOpacity(0.18),
                  size: 300,
                ),
              ),
              TvViewportFrame(
                child: Builder(
                  builder: (context) {
                    final pagePadding = AppLayout.pagePadding(context);
                    final panelGap = AppLayout.gap(
                      context,
                      compact: 16,
                      medium: 20,
                      expanded: 24,
                    );
                    final headerGap = AppLayout.gap(
                      context,
                      compact: 8,
                      medium: 10,
                      expanded: 12,
                    );
                    final theme = Theme.of(context);
                    final textScaleFactor = AppLayout.textDesignScale(context);

                    return Theme(
                      data: theme.copyWith(
                        textTheme: theme.textTheme.apply(
                          fontSizeFactor: textScaleFactor,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(pagePadding),
                        child: Column(
                          children: [
                            DashboardHeader(
                              state: dashboardState,
                              settings: settings,
                              onOpenSettings: () {
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                              onOpenNawawi: () {
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => NawawiLibraryScreen(
                                      items: dashboardState.libraryItems,
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: headerGap),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return _DashboardPanels(
                                    state: dashboardState,
                                    gap: panelGap,
                                    maxWidth: constraints.maxWidth,
                                    maxHeight: constraints.maxHeight,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardPanels extends StatelessWidget {
  const _DashboardPanels({
    required this.state,
    required this.gap,
    required this.maxWidth,
    required this.maxHeight,
  });

  final DashboardState state;
  final double gap;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final stackedLayout = maxWidth < 960 || (maxWidth < 1160 && maxHeight < 760);
    final prayerFlex = AppLayout.sidePanelFlex(context) + 1;
    final contentFlex = AppLayout.contentPanelFlex(context) + 1;
    final viewportScale = AppLayout.visualScale(context);

    if (stackedLayout) {
      final compact = maxWidth < 560;
      final prayersHeight = (compact ? 460.0 : 520.0) * viewportScale;
      final contentHeight = (compact ? 560.0 : 660.0) * viewportScale;

      return ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          SizedBox(
            height: prayersHeight,
            child: PrayerTimesPanel(state: state),
          ),
          SizedBox(height: gap),
          SizedBox(
            height: contentHeight,
            child: ContentPanel(state: state),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      textDirection: TextDirection.ltr,
      children: [
        Expanded(
          flex: prayerFlex,
          child: PrayerTimesPanel(state: state),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: contentFlex,
          child: ContentPanel(state: state),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
