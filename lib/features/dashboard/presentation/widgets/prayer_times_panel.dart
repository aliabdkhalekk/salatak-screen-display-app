import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/layout/app_layout.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../prayer/domain/prayer_models.dart';
import '../../domain/dashboard_state.dart';

class PrayerTimesPanel extends StatelessWidget {
  const PrayerTimesPanel({
    super.key,
    required this.state,
  });

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final prayerDay = state.prayerDay;
    final theme = Theme.of(context);
    final gap = AppLayout.gap(context, compact: 14, medium: 18, expanded: 22);

    return SectionCard(
      child: prayerDay == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مواقيت الصلاة',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontSize: AppLayout.readableFluid(
                      context,
                      min: 36,
                      max: 46,
                      readableMin: 36,
                    ),
                  ),
                ),
                SizedBox(height: gap),
                Expanded(
                  child: Column(
                    children: List<Widget>.generate(
                      prayerDay.todayEntries.length * 2 - 1,
                      (index) {
                        if (index.isOdd) {
                          return SizedBox(height: gap * 0.55);
                        }

                        final prayer = prayerDay.todayEntries[index ~/ 2];
                        return Expanded(
                          child: _PrayerRow(
                            label: prayer.name.arabicLabel,
                            time: _formatPrayerClock(prayer.time),
                            isNext: prayer.name == prayerDay.nextPrayer.name,
                            isPassed: !prayer.time.isAfter(state.now),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatPrayerClock(DateTime time) {
    return DateFormat('h:mm', 'ar').format(time);
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.label,
    required this.time,
    required this.isNext,
    required this.isPassed,
  });

  final String label;
  final String time;
  final bool isNext;
  final bool isPassed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isNext
        ? const Color(0xFF091318)
        : (isPassed ? Colors.white.withOpacity(0.62) : Colors.white);
    final background = isNext
        ? const Color(0xFFD8BE74)
        : Colors.white.withOpacity(isPassed ? 0.05 : 0.09);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.gap(context, compact: 16, medium: 18, expanded: 20),
        vertical: AppLayout.gap(context, compact: 12, medium: 14, expanded: 16),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.72),
        border: Border.all(
          color: isNext
              ? const Color(0xFFE8DDB6)
              : Colors.white.withOpacity(0.10),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                label,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: AppLayout.readableFluid(
                    context,
                    min: 30,
                    max: 38,
                    readableMin: 30,
                  ),
                  color: foreground,
                ),
              ),
            ),
          ),
          if (isNext) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.gap(
                  context,
                  compact: 8,
                  medium: 10,
                  expanded: 12,
                ),
                vertical: AppLayout.gap(
                  context,
                  compact: 4,
                  medium: 5,
                  expanded: 6,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.10),
                borderRadius: BorderRadius.circular(
                  AppLayout.radius(context) * 0.46,
                ),
              ),
              child: Text(
                'التالي',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: AppLayout.readableFluid(
                    context,
                    min: 18,
                    max: 20,
                    readableMin: 18,
                  ),
                  color: foreground,
                ),
              ),
            ),
            SizedBox(
              width: AppLayout.gap(
                context,
                compact: 10,
                medium: 12,
                expanded: 14,
              ),
            ),
          ],
          Text(
            time,
            style: theme.textTheme.displayMedium?.copyWith(
              fontSize: AppLayout.readableFluid(
                context,
                min: 38,
                max: 46,
                readableMin: 38,
              ),
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
