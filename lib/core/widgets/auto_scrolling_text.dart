import 'dart:async';

import 'package:flutter/material.dart';

class AutoScrollingText extends StatefulWidget {
  const AutoScrollingText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.padding = EdgeInsets.zero,
    this.centerWhenNotScrollable = true,
    this.startDelay = const Duration(seconds: 2),
    this.endPause = const Duration(seconds: 2),
    this.restartDelay = const Duration(milliseconds: 700),
    this.pixelsPerSecond = 18,
    this.speedMultiplier = 1.0,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final EdgeInsetsGeometry padding;
  final bool centerWhenNotScrollable;
  final Duration startDelay;
  final Duration endPause;
  final Duration restartDelay;
  final double pixelsPerSecond;
  final double speedMultiplier;

  @override
  State<AutoScrollingText> createState() => _AutoScrollingTextState();
}

class _AutoScrollingTextState extends State<AutoScrollingText> {
  final ScrollController _controller = ScrollController();
  int _sessionId = 0;

  @override
  void initState() {
    super.initState();
    _scheduleLoop(resetToTop: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleLoop(resetToTop: false);
  }

  @override
  void didUpdateWidget(covariant AutoScrollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldRestart = oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.textAlign != widget.textAlign ||
        oldWidget.startDelay != widget.startDelay ||
        oldWidget.endPause != widget.endPause ||
        oldWidget.restartDelay != widget.restartDelay ||
        oldWidget.pixelsPerSecond != widget.pixelsPerSecond ||
        oldWidget.speedMultiplier != widget.speedMultiplier ||
        oldWidget.padding != widget.padding ||
        oldWidget.centerWhenNotScrollable != widget.centerWhenNotScrollable;
    if (shouldRestart) {
      _scheduleLoop(resetToTop: true);
    }
  }

  @override
  void dispose() {
    _sessionId += 1;
    _controller.dispose();
    super.dispose();
  }

  void _scheduleLoop({required bool resetToTop}) {
    final sessionId = ++_sessionId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runAutoScroll(sessionId, resetToTop: resetToTop));
    });
  }

  Future<void> _runAutoScroll(
    int sessionId, {
    required bool resetToTop,
  }) async {
    if (!mounted) {
      return;
    }

    if (resetToTop && _controller.hasClients) {
      _controller.jumpTo(0);
    }

    await Future<void>.delayed(widget.startDelay);

    while (mounted && sessionId == _sessionId) {
      if (!_controller.hasClients) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        continue;
      }

      final maxScroll = _controller.position.maxScrollExtent;
      if (maxScroll <= 1) {
        return;
      }

      if (_controller.offset != 0) {
        _controller.jumpTo(0);
      }

      final effectivePixelsPerSecond =
          (widget.pixelsPerSecond * widget.speedMultiplier).clamp(1.0, 300.0);
      final duration = Duration(
        milliseconds: ((maxScroll / effectivePixelsPerSecond) * 1000).round(),
      );

      try {
        await _controller.animateTo(
          maxScroll,
          duration: duration,
          curve: Curves.linear,
        );
      } catch (_) {
        return;
      }

      if (!mounted || sessionId != _sessionId) {
        return;
      }

      await Future<void>.delayed(widget.endPause);

      if (!mounted || sessionId != _sessionId || !_controller.hasClients) {
        return;
      }

      final returnDuration = Duration(
        milliseconds:
            ((((maxScroll / (effectivePixelsPerSecond * 2.6)) * 1000).round())
                .clamp(900, 2200)),
      );

      try {
        await _controller.animateTo(
          0,
          duration: returnDuration,
          curve: Curves.easeInOut,
        );
      } catch (_) {
        return;
      }

      if (!mounted || sessionId != _sessionId) {
        return;
      }

      await Future<void>.delayed(widget.restartDelay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      widget.text,
      textAlign: widget.textAlign,
      style: widget.style,
    );

    return ScrollConfiguration(
      behavior: const _NoGlowScrollBehavior(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final resolvedPadding =
              widget.padding.resolve(Directionality.of(context));
          final availableWidth =
              (constraints.maxWidth - resolvedPadding.horizontal)
                  .clamp(0.0, double.infinity);
          final textPainter = TextPainter(
            text: TextSpan(text: widget.text, style: widget.style),
            textAlign: widget.textAlign,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: availableWidth);

          final textFits = widget.centerWhenNotScrollable &&
              (textPainter.height + resolvedPadding.vertical) <=
                  constraints.maxHeight;

          if (textFits) {
            return Center(
              child: Padding(
                padding: widget.padding,
                child: textWidget,
              ),
            );
          }

          return SingleChildScrollView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: widget.padding,
              child: textWidget,
            ),
          );
        },
      ),
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
