import 'package:flutter/material.dart';

import '../layout/app_layout.dart';

class ResponsiveScreenHeader extends StatelessWidget {
  const ResponsiveScreenHeader({
    super.key,
    required this.title,
    required this.description,
    this.trailing,
  });

  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = AppLayout.gap(context, compact: 12, medium: 16, expanded: 20);
    final titleStyle = theme.textTheme.displayMedium?.copyWith(
      fontSize: AppLayout.fluid(context, min: 28, max: 42),
    );
    final descriptionStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: AppLayout.fluid(context, min: 16, max: 22),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;
        final textBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle),
            SizedBox(height: gap * 0.5),
            Text(description, style: descriptionStyle),
          ],
        );

        if (trailing == null) {
          return textBlock;
        }

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textBlock,
              SizedBox(height: gap),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: trailing!,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: textBlock),
            SizedBox(width: gap),
            trailing!,
          ],
        );
      },
    );
  }
}
