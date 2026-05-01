import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/layout/tv_viewport_frame.dart';
import '../../automation/presentation/prayer_flow_overlay.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/dashboard_controller.dart';
import '../domain/dashboard_state.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/prayer_times_panel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    void openSettings() {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => const SettingsScreen(),
        ),
      );
    }

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
                              onOpenSettings: openSettings,
                            ),
                            SizedBox(height: headerGap),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return _DashboardPanels(
                                    state: dashboardState,
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
              PrayerFlowOverlay(
                snapshot: dashboardState.automation,
                settings: settings,
                now: dashboardState.now,
                hijriLabel: dashboardState.hijriDate?.formatted,
                prayerDay: dashboardState.prayerDay,
                onOpenSettings: openSettings,
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
    required this.maxWidth,
    required this.maxHeight,
  });

  final DashboardState state;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final viewportScale = AppLayout.visualScale(context);
    final widthFactor = maxWidth < 900 ? 1.0 : 0.72;
    final maxPanelHeight = maxHeight * 0.98;

    return Center(
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: SizedBox(
          height: maxPanelHeight * viewportScale,
          child: PrayerTimesPanel(state: state),
        ),
      ),
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
