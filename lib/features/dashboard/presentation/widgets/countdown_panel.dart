import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../prayer/domain/prayer_models.dart';
import '../../domain/dashboard_state.dart';

class CountdownPanel extends StatelessWidget {
  const CountdownPanel({
    super.key,
    required this.state,
  });

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final prayerDay = state.prayerDay;
    final theme = Theme.of(context);

    return SectionCard(
      child: prayerDay == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final sectionGap = AppLayout.gap(
                  context,
                  compact: 10,
                  medium: 12,
                  expanded: 16,
                );
                final titleStyle = theme.textTheme.titleLarge?.copyWith(
                  fontSize: AppLayout.readableFluid(
                    context,
                    min: 30,
                    max: 36,
                    readableMin: 30,
                  ),
                );
                final prayerStyle = theme.textTheme.displayMedium?.copyWith(
                  fontSize: AppLayout.readableFluid(
                    context,
                    min: 36,
                    max: 48,
                    readableMin: 36,
                  ),
                );
                final timeStyle = theme.textTheme.titleLarge?.copyWith(
                  fontSize: AppLayout.fluid(context, min: 24, max: 30),
                  color: const Color(0xFFD8BE74),
                );
                final countdownStyle = theme.textTheme.displayLarge?.copyWith(
                  fontSize: AppLayout.readableFluid(
                    context,
                    min: 46,
                    max: 60,
                    readableMin: 46,
                  ),
                  height: 1.05,
                );
                final helperStyle = theme.textTheme.bodyLarge?.copyWith(
                  fontSize: AppLayout.fluid(context, min: 20, max: 24),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الصلاة القادمة',
                      style: titleStyle,
                    ),
                    SizedBox(height: sectionGap),
                    Text(
                      prayerDay.nextPrayer.name.arabicLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: prayerStyle,
                    ),
                    SizedBox(height: sectionGap * 0.65),
                    Text(
                      _formatPrayerClock(prayerDay.nextPrayer.time),
                      style: timeStyle,
                    ),
                    SizedBox(height: sectionGap),
                    Text(
                      _formatDuration(prayerDay.timeUntilNextPrayer),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: countdownStyle,
                    ),
                    const Spacer(),
                    Text(
                      'الوقت المتبقي حتى ${prayerDay.nextPrayer.name.arabicLabel}',
                      maxLines: constraints.maxWidth < 340 ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: helperStyle,
                    ),
                  ],
                );
              },
            ),
    );
  }

  String _formatPrayerClock(DateTime time) {
    return DateFormat('h:mm', 'ar').format(time);
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 999999) as int;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
