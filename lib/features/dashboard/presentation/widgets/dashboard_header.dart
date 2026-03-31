import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/constants/app_cities.dart';
import '../../../../core/layout/app_layout.dart';
import '../../../../core/layout/tv_screen_profile.dart';
import '../../../../core/widgets/mosque_logo_badge.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/tv_action_button.dart';
import '../../../prayer/domain/prayer_models.dart';
import '../../../settings/domain/app_settings.dart';
import '../../domain/dashboard_state.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.state,
    required this.settings,
    required this.onOpenSettings,
    required this.onOpenNawawi,
  });

  final DashboardState state;
  final AppSettings settings;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenNawawi;

  @override
  Widget build(BuildContext context) {
    final city = appCityById(settings.cityId);
    final cardPadding = AppLayout.cardPadding(context);

    return SectionCard(
      padding: EdgeInsets.symmetric(
        horizontal: cardPadding,
        vertical: cardPadding * 0.44,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 1320;
          final sectionGap = AppLayout.gap(
            context,
            compact: 10,
            medium: 12,
            expanded: 16,
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LeftHeaderSection(
                  settings: settings,
                  onOpenSettings: onOpenSettings,
                  onOpenNawawi: onOpenNawawi,
                ),
                SizedBox(height: sectionGap),
                _RightHeaderSection(
                  state: state,
                  settings: settings,
                  cityName: city.arabicName,
                  stacked: true,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.ltr,
            children: [
              SizedBox(
                width: AppLayout.fluid(context, min: 300, max: 360),
                child: _LeftHeaderSection(
                  settings: settings,
                  onOpenSettings: onOpenSettings,
                  onOpenNawawi: onOpenNawawi,
                ),
              ),
              SizedBox(width: sectionGap),
              Expanded(
                child: _RightHeaderSection(
                  state: state,
                  settings: settings,
                  cityName: city.arabicName,
                  stacked: false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LeftHeaderSection extends StatelessWidget {
  const _LeftHeaderSection({
    required this.settings,
    required this.onOpenSettings,
    required this.onOpenNawawi,
  });

  final AppSettings settings;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenNawawi;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BrandBlock(settings: settings),
        SizedBox(
          height: AppLayout.gap(
            context,
            compact: 12,
            medium: 14,
            expanded: 18,
          ),
        ),
        _ActionStrip(
          onOpenSettings: onOpenSettings,
          onOpenNawawi: onOpenNawawi,
        ),
      ],
    );
  }
}

class _RightHeaderSection extends StatelessWidget {
  const _RightHeaderSection({
    required this.state,
    required this.settings,
    required this.cityName,
    required this.stacked,
  });

  final DashboardState state;
  final AppSettings settings;
  final String cityName;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final gap = AppLayout.gap(context, compact: 10, medium: 12, expanded: 16);

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ClockBlock(state: state),
          SizedBox(height: gap),
          _NextPrayerBlock(state: state),
          SizedBox(height: gap),
          _MetaRow(
            cityName: cityName,
            settings: settings,
            isFriday: state.isFriday,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _ClockBlock(state: state),
            ),
            SizedBox(width: gap),
            Expanded(
              flex: 4,
              child: _NextPrayerBlock(state: state),
            ),
          ],
        ),
        SizedBox(height: gap),
        _MetaRow(
          cityName: cityName,
          settings: settings,
          isFriday: state.isFriday,
        ),
      ],
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({
    required this.settings,
  });

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metaGap = AppLayout.gap(context, compact: 2, medium: 3, expanded: 4);

    return Row(
      textDirection: TextDirection.ltr,
      children: [
        MosqueLogoBadge(
          size: AppLayout.fluid(context, min: 76, max: 94),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'صلاتك',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: AppLayout.fluid(context, min: 30, max: 40),
                ),
              ),
              SizedBox(height: metaGap),
              Text(
                'لوحة عرض المسجد الذكية',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: AppLayout.fluid(context, min: 15, max: 18),
                ),
              ),
              SizedBox(height: metaGap),
              Text(
                settings.tvScreenProfile.previewLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: AppLayout.fluid(context, min: 16, max: 20),
                  color: const Color(0xFFD8BE74),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClockBlock extends StatelessWidget {
  const _ClockBlock({
    required this.state,
  });

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatArabicClock(state.now);
    final theme = Theme.of(context);
    final metaGap = AppLayout.gap(context, compact: 2, medium: 3, expanded: 4);
    final wrapGap = AppLayout.gap(context, compact: 8, medium: 10, expanded: 12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: wrapGap,
          runSpacing: metaGap,
          children: [
            Text(
              formattedTime.time,
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: AppLayout.readableFluid(
                  context,
                  min: 64,
                  max: 96,
                  readableMin: 64,
                ),
                height: 1,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: metaGap * 1.5),
              child: Text(
                formattedTime.periodLabel,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: AppLayout.fluid(context, min: 20, max: 26),
                  color: const Color(0xFFD8BE74),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: metaGap),
        Text(
          DateFormat('EEEE، d MMMM y', 'ar').format(state.now),
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: AppLayout.fluid(context, min: 22, max: 30),
          ),
        ),
        SizedBox(height: metaGap),
        Text(
          state.hijriDate?.formatted ?? 'التاريخ الهجري قيد التحميل',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: AppLayout.fluid(context, min: 18, max: 24),
          ),
        ),
      ],
    );
  }
}

class _NextPrayerBlock extends StatelessWidget {
  const _NextPrayerBlock({
    required this.state,
  });

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final prayerDay = state.prayerDay;
    final theme = Theme.of(context);
    final gap = AppLayout.gap(context, compact: 8, medium: 10, expanded: 12);

    if (prayerDay == null) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFD8BE74).withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.62),
        border: Border.all(
          color: const Color(0xFFD8BE74).withOpacity(0.22),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.cardPadding(context) * 0.82,
          vertical: AppLayout.cardPadding(context) * 0.62,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الصلاة القادمة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: AppLayout.fluid(context, min: 18, max: 22),
              ),
            ),
            SizedBox(height: gap * 0.5),
            Text(
              prayerDay.nextPrayer.name.arabicLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.displayMedium?.copyWith(
                fontSize: AppLayout.readableFluid(
                  context,
                  min: 38,
                  max: 50,
                  readableMin: 38,
                ),
              ),
            ),
            SizedBox(height: gap * 0.35),
            Text(
              DateFormat('h:mm', 'ar').format(prayerDay.nextPrayer.time),
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: AppLayout.fluid(context, min: 24, max: 30),
                color: const Color(0xFFD8BE74),
              ),
            ),
            SizedBox(height: gap * 0.7),
            Text(
              _formatDuration(prayerDay.timeUntilNextPrayer),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: AppLayout.readableFluid(
                  context,
                  min: 44,
                  max: 58,
                  readableMin: 44,
                ),
                height: 1,
              ),
            ),
            SizedBox(height: gap * 0.35),
            Text(
              'المتبقي حتى ${prayerDay.nextPrayer.name.arabicLabel}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppLayout.fluid(context, min: 17, max: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({
    required this.onOpenSettings,
    required this.onOpenNawawi,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onOpenNawawi;

  @override
  Widget build(BuildContext context) {
    final gap = AppLayout.gap(context, compact: 8, medium: 10, expanded: 12);
    final buttonWidth = AppLayout.fluid(context, min: 156, max: 184);

    return Align(
      alignment: AlignmentDirectional.topEnd,
      child: SizedBox(
        width: buttonWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TvActionButton(
              label: 'الإعدادات',
              icon: Icons.settings_rounded,
              autofocus: true,
              compact: true,
              onPressed: onOpenSettings,
            ),
            SizedBox(height: gap),
            TvActionButton(
              label: 'المكتبة',
              icon: Icons.menu_book_rounded,
              compact: true,
              onPressed: onOpenNawawi,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.cityName,
    required this.settings,
    required this.isFriday,
  });

  final String cityName;
  final AppSettings settings;
  final bool isFriday;

  @override
  Widget build(BuildContext context) {
    final gap = AppLayout.gap(context, compact: 8, medium: 10, expanded: 12);

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        _InfoChip(label: 'المدينة', value: cityName),
        _InfoChip(
          label: 'طريقة الحساب',
          value: settings.prayerMethod.labelArabic,
        ),
        _InfoChip(
          label: 'مقاس الشاشة',
          value: settings.tvScreenProfile.labelArabic,
        ),
        if (isFriday) const _InfoChip(label: 'الوضع', value: 'الجمعة'),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.56),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: AppLayout.fluid(context, min: 15, max: 18),
                ),
            children: [
              TextSpan(text: '$label: '),
              TextSpan(
                text: value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: AppLayout.fluid(context, min: 16, max: 20),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArabicClockFormat {
  const _ArabicClockFormat({
    required this.time,
    required this.periodLabel,
  });

  final String time;
  final String periodLabel;
}

_ArabicClockFormat _formatArabicClock(DateTime now) {
  final time = DateFormat('h:mm', 'ar').format(now);
  final periodLabel = now.hour < 12 ? 'صباحًا' : 'مساءً';
  return _ArabicClockFormat(
    time: time,
    periodLabel: periodLabel,
  );
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
