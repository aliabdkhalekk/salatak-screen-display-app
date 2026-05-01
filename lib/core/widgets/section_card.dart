import 'package:flutter/material.dart';

import '../layout/app_layout.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radius = AppLayout.radius(context);
    final viewportScale = AppLayout.designScale(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24 * viewportScale,
            offset: Offset(0, 10 * viewportScale),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(AppLayout.cardPadding(context)),
        child: child,
      ),
    );
  }
}
