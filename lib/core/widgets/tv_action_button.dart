import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../layout/app_layout.dart';

class TvActionButton extends StatefulWidget {
  const TvActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.autofocus = false,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool autofocus;
  final bool compact;

  @override
  State<TvActionButton> createState() => _TvActionButtonState();
}

class _TvActionButtonState extends State<TvActionButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = AppLayout.radius(context) * 0.72;
    final densityFactor = widget.compact ? 0.9 : 1;
    final horizontalPadding =
        AppLayout.buttonHorizontalPadding(context) * densityFactor;
    final verticalPadding =
        AppLayout.buttonVerticalPadding(context) * densityFactor;
    final iconSize = AppLayout.buttonIconSize(context) * densityFactor;
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      fontSize: AppLayout.fluid(
        context,
        min: widget.compact ? 16 : 18,
        max: widget.compact ? 20 : 22,
      ),
    );

    return FocusableActionDetector(
      autofocus: widget.autofocus,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            widget.onPressed();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: _focused ? 1.04 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: _focused
                    ? theme.colorScheme.primary.withOpacity(0.20)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: _focused
                      ? theme.colorScheme.primary
                      : Colors.white.withOpacity(0.10),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: iconSize),
                  SizedBox(
                    width: AppLayout.gap(
                      context,
                      compact: 8,
                      medium: 10,
                      expanded: 12,
                    ),
                  ),
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
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
