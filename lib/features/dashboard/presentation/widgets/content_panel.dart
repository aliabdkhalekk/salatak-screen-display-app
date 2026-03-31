import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/widgets/auto_scrolling_text.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../content_engine/domain/content_item.dart';
import '../../../content_engine/domain/content_phase.dart';
import '../../../settings/application/settings_controller.dart';
import '../../../settings/domain/app_settings.dart';
import '../../domain/dashboard_state.dart';

class ContentPanel extends ConsumerWidget {
  const ContentPanel({
    super.key,
    required this.state,
  });

  final DashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = state.activeContent;
    final settings = ref.watch(settingsControllerProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: FractionallySizedBox(
            widthFactor: constraints.maxWidth < 920 ? 0.98 : 0.95,
            heightFactor: 0.98,
            child: SectionCard(
              child: content == null
                  ? const _ContentEmptyState()
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      child: _ContentBody(
                        key: ValueKey(content.id),
                        content: content,
                        phaseLabel: state.phase.labelArabic,
                        pixelsPerSecond: settings.autoScrollSpeed.pixelsPerSecond,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _ContentBody extends StatelessWidget {
  const _ContentBody({
    super.key,
    required this.content,
    required this.phaseLabel,
    required this.pixelsPerSecond,
  });

  final ContentItem content;
  final String phaseLabel;
  final double pixelsPerSecond;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = AppLayout.gap(context, compact: 12, medium: 18, expanded: 22);
    final categoryLabel = content.category?.trim();
    final titleStyle = theme.textTheme.displayMedium?.copyWith(
      fontSize: AppLayout.readableFluid(
        context,
        min: 38,
        max: 52,
        readableMin: 38,
      ),
      height: 1.22,
      shadows: _textShadows,
    );
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: AppLayout.readableFluid(
        context,
        min: 28,
        max: 36,
        readableMin: 28,
      ),
      height: 1.72,
      shadows: _textShadows,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.86),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF16323D).withOpacity(0.94),
            const Color(0xFF0A171D).withOpacity(0.98),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppLayout.cardPadding(context) * 1.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing:
                  AppLayout.gap(context, compact: 10, medium: 12, expanded: 14),
              runSpacing:
                  AppLayout.gap(context, compact: 10, medium: 12, expanded: 14),
              children: [
                _Badge(text: content.type.labelArabic),
                _Badge(text: phaseLabel, secondary: true),
                if (content.hadithNumber != null)
                  _Badge(text: 'رقم ${content.hadithNumber}', secondary: true),
                if (categoryLabel != null &&
                    categoryLabel.isNotEmpty &&
                    categoryLabel != phaseLabel)
                  _Badge(text: categoryLabel, secondary: true),
              ],
            ),
            SizedBox(height: gap),
            Text(
              content.title,
              style: titleStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: gap),
            Expanded(
              child: _AutoScrollTextFrame(
                child: AutoScrollingText(
                  text: content.text.trim(),
                  style: bodyStyle,
                  textAlign: TextAlign.start,
                  startDelay: const Duration(seconds: 3),
                  endPause: const Duration(seconds: 3),
                  restartDelay: const Duration(milliseconds: 1400),
                  pixelsPerSecond: pixelsPerSecond,
                ),
              ),
            ),
            SizedBox(height: gap),
            _SourcePanel(source: content.source),
          ],
        ),
      ),
    );
  }
}

class _AutoScrollTextFrame extends StatelessWidget {
  const _AutoScrollTextFrame({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = AppLayout.radius(context) * 0.72;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0C1D24).withOpacity(0.84),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(AppLayout.cardPadding(context) * 0.9),
              child: child,
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TextFadeEdge(top: true),
            ),
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _TextFadeEdge(top: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextFadeEdge extends StatelessWidget {
  const _TextFadeEdge({
    required this.top,
  });

  final bool top;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: AppLayout.gap(context, compact: 24, medium: 28, expanded: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: top ? Alignment.topCenter : Alignment.bottomCenter,
            end: top ? Alignment.bottomCenter : Alignment.topCenter,
            colors: const [
              Color(0xFF102730),
              Color(0x00102730),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourcePanel extends StatelessWidget {
  const _SourcePanel({
    required this.source,
  });

  final String source;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: AppLayout.fluid(context, min: 22, max: 28),
          shadows: _textShadows,
        );
    final sourceStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: AppLayout.fluid(context, min: 22, max: 28),
          shadows: _textShadows,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFD8BE74).withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.68),
        border: Border.all(
          color: const Color(0xFFD8BE74).withOpacity(0.28),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.cardPadding(context) * 0.82,
          vertical: AppLayout.cardPadding(context) * 0.58,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المصدر',
              style: titleStyle,
            ),
            SizedBox(
              width: AppLayout.gap(
                context,
                compact: 10,
                medium: 12,
                expanded: 14,
              ),
            ),
            Expanded(
              child: Text(
                source,
                style: sourceStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    this.secondary = false,
  });

  final String text;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final background = secondary
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFD8BE74);
    final foreground = secondary ? Colors.white : const Color(0xFF091318);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.56),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.gap(
            context,
            compact: 10,
            medium: 12,
            expanded: 14,
          ),
          vertical: AppLayout.gap(
            context,
            compact: 6,
            medium: 7,
            expanded: 8,
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: AppLayout.fluid(context, min: 18, max: 20),
                color: foreground,
              ),
        ),
      ),
    );
  }
}

class _ContentEmptyState extends StatelessWidget {
  const _ContentEmptyState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.86),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF16323D).withOpacity(0.92),
            const Color(0xFF0A171D).withOpacity(0.98),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppLayout.cardPadding(context) * 1.2),
          child: Text(
            'جارِ تحميل المحتوى المعروض...',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: AppLayout.readableFluid(
                    context,
                    min: 30,
                    max: 38,
                    readableMin: 30,
                  ),
                  shadows: _textShadows,
                ),
          ),
        ),
      ),
    );
  }
}

const List<Shadow> _textShadows = <Shadow>[
  Shadow(
    color: Color(0xAA000000),
    blurRadius: 10,
    offset: Offset(0, 2),
  ),
];
