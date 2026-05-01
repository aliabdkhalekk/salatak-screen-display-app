import 'dart:math' as math;

import 'package:flutter/material.dart';

@immutable
class TvViewportData {
  const TvViewportData({
    required this.viewportSize,
    required this.frameSize,
    required this.safePadding,
    required this.designScale,
  });

  static const Size designCanvas = Size(1920, 1080);
  static const EdgeInsets designSafePadding = EdgeInsets.symmetric(
    horizontal: 80,
    vertical: 60,
  );

  final Size viewportSize;
  final Size frameSize;
  final EdgeInsets safePadding;
  final double designScale;
}

abstract final class TvViewport {
  static TvViewportData? maybeOf(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_TvViewportInherited>();
    return inherited?.data;
  }
}

class TvViewportFrame extends StatelessWidget {
  const TvViewportFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        if (viewportSize.width <= 0 || viewportSize.height <= 0) {
          return const SizedBox.shrink();
        }

        final safePadding = TvViewportData.designSafePadding;
        final safeFrameSize = Size(
          TvViewportData.designCanvas.width - safePadding.horizontal,
          TvViewportData.designCanvas.height - safePadding.vertical,
        );
        final designAspect = TvViewportData.designCanvas.width /
            TvViewportData.designCanvas.height;
        final designScale = math.min(
          viewportSize.width / TvViewportData.designCanvas.width,
          viewportSize.height / TvViewportData.designCanvas.height,
        );

        return Center(
          child: AspectRatio(
            aspectRatio: designAspect,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              child: SizedBox(
                width: TvViewportData.designCanvas.width,
                height: TvViewportData.designCanvas.height,
                child: _TvViewportInherited(
                  data: TvViewportData(
                    viewportSize: viewportSize,
                    frameSize: safeFrameSize,
                    safePadding: safePadding,
                    designScale: designScale,
                  ),
                  child: Builder(
                    builder: (context) {
                      final mediaQuery = MediaQuery.of(context);
                      return MediaQuery(
                        data: mediaQuery.copyWith(
                          size: safeFrameSize,
                          padding: EdgeInsets.zero,
                          viewPadding: EdgeInsets.zero,
                          viewInsets: EdgeInsets.zero,
                        ),
                        child: Padding(
                          padding: safePadding,
                          child: child,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TvViewportInherited extends InheritedWidget {
  const _TvViewportInherited({
    required this.data,
    required super.child,
  });

  final TvViewportData data;

  @override
  bool updateShouldNotify(_TvViewportInherited oldWidget) {
    return data.viewportSize != oldWidget.data.viewportSize ||
        data.frameSize != oldWidget.data.frameSize ||
        data.safePadding != oldWidget.data.safePadding ||
        data.designScale != oldWidget.data.designScale;
  }
}
