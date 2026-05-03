import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_cities.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/layout/tv_screen_profile.dart';
import '../../../core/layout/tv_viewport_frame.dart';
import '../../../core/platform/screen_control_service.dart';
import '../../../core/widgets/auto_scrolling_text.dart';
import '../../../core/widgets/ensure_visible_on_focus.dart';
import '../../../core/widgets/section_card.dart';
import '../../automation/domain/prayer_flow_models.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../../mosque_display/application/display_control_controller.dart';
import '../../mosque_display/presentation/mosque_content_screens.dart';
import '../../prayer/domain/prayer_models.dart';
import '../application/settings_controller.dart';
import '../domain/app_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _syncing = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final gap = AppLayout.gap(context, compact: 14, medium: 18, expanded: 22);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF07100D),
                  Color(0xFF173A32),
                  Color(0xFF0A1714),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: TvViewportFrame(
              child: Padding(
                padding: EdgeInsets.all(AppLayout.pagePadding(context)),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      bottom: AppLayout.pagePadding(context),
                    ),
                    children: [
                      _Header(onBack: () => Navigator.of(context).pop()),
                      SizedBox(height: gap),
                      _focusAware(_displaySection(settings)),
                      SizedBox(height: gap),
                      _focusAware(_prayerSection(settings)),
                      SizedBox(height: gap),
                      _focusAware(_manualAdjustmentsSection(settings)),
                      SizedBox(height: gap),
                      _focusAware(_timingSection(settings)),
                      SizedBox(height: gap),
                      _focusAware(_behaviorSection(settings)),
                      SizedBox(height: gap),
                      _focusAware(_previewSection()),
                      SizedBox(height: gap),
                      _focusAware(_syncSection()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _focusAware(Widget child) {
    return EnsureVisibleOnFocus(
      alignment: 0.12,
      child: child,
    );
  }

  Widget _displaySection(AppSettings settings) {
    return _SettingsSection(
      title: 'العرض وحجم الشاشة',
      children: [
        _FieldLabel(text: 'مقاس الشاشة'),
        _SettingsDropdown<TvScreenProfile>(
          value: settings.screenProfile,
          items: TvScreenProfile.values
              .map(
                (profile) => DropdownMenuItem<TvScreenProfile>(
                  value: profile,
                  child: Text(profile.previewLabel),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              ref
                  .read(settingsControllerProvider.notifier)
                  .updateScreenProfile(value);
            }
          },
        ),
        _rowGap(),
        _SettingsAdjustRow(
          label: 'تدرج الواجهة',
          value: '${settings.uiScalePercent}%',
          onDecrease: () => _updateUiScale(-5),
          onIncrease: () => _updateUiScale(5),
        ),
        _rowGap(),
        _SettingsAdjustRow(
          label: 'حجم الخط',
          value: settings.displayFontSize.labelArabic,
          onDecrease: () {
            ref
                .read(settingsControllerProvider.notifier)
                .decreaseDisplayFontSize();
          },
          onIncrease: () {
            ref
                .read(settingsControllerProvider.notifier)
                .increaseDisplayFontSize();
          },
        ),
        _rowGap(),
        _SettingsDropdown<DisplayFontWeightOption>(
          value: settings.displayFontWeight,
          items: DisplayFontWeightOption.values
              .map(
                (option) => DropdownMenuItem<DisplayFontWeightOption>(
                  value: option,
                  child: Text('وزن الخط: ${option.labelArabic}'),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              ref
                  .read(settingsControllerProvider.notifier)
                  .updateDisplayFontWeight(value);
            }
          },
        ),
        _rowGap(),
        _FieldLabel(text: 'Arabic font style / نمط الخط العربي'),
        _SettingsDropdown<ArabicFontStyleOption>(
          value: settings.arabicFontStyle,
          items: ArabicFontStyleOption.values
              .map(
                (option) => DropdownMenuItem<ArabicFontStyleOption>(
                  value: option,
                  child: Text(option.labelArabic),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              ref
                  .read(settingsControllerProvider.notifier)
                  .updateArabicFontStyle(value);
            }
          },
        ),
        _rowGap(),
        _SettingsScrollSpeedRow(
          value: settings.autoScrollSpeedMultiplier,
          autofocus: true,
          onChanged: (value) {
            ref
                .read(settingsControllerProvider.notifier)
                .updateAutoScrollSpeedMultiplier(value);
          },
        ),
        _rowGap(),
        _SettingsScrollSpeedPreview(
          speedMultiplier: settings.autoScrollSpeedMultiplier,
        ),
      ],
    );
  }

  Widget _prayerSection(AppSettings settings) {
    return _SettingsSection(
      title: 'الموقع وحساب الصلاة',
      children: [
        _FieldLabel(text: 'المدينة / الموقع'),
        _SettingsDropdown<String>(
          value: settings.cityId,
          items: appCities
              .map(
                (city) => DropdownMenuItem<String>(
                  value: city.id,
                  child: Text(city.arabicName),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              ref.read(settingsControllerProvider.notifier).updateCity(value);
            }
          },
        ),
        _rowGap(),
        _FieldLabel(text: 'طريقة الحساب'),
        _SettingsDropdown<PrayerMethodOption>(
          value: settings.prayerMethod,
          items: PrayerMethodOption.values
              .map(
                (method) => DropdownMenuItem<PrayerMethodOption>(
                  value: method,
                  child: Text(method.labelArabic),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              ref
                  .read(settingsControllerProvider.notifier)
                  .updatePrayerMethod(value);
            }
          },
        ),
        _rowGap(),
        _SettingsSwitchRow(
          label: 'استخدام التوقيت الصيفي',
          value: settings.useDaylightSavingTime,
          onChanged: (value) {
            ref
                .read(settingsControllerProvider.notifier)
                .updateDaylightSavingTime(value);
          },
        ),
      ],
    );
  }

  Widget _manualAdjustmentsSection(AppSettings settings) {
    return _SettingsSection(
      title: 'التعديل اليدوي لكل صلاة',
      children: PrayerName.values.map((prayer) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppLayout.gap(context, compact: 10)),
          child: _SettingsAdjustRow(
            label: prayer.arabicLabel,
            value: '${settings.manualAdjustmentFor(prayer)} دقيقة',
            onDecrease: () => _updateManualPrayer(prayer, -1),
            onIncrease: () => _updateManualPrayer(prayer, 1),
          ),
        );
      }).toList(),
    );
  }

  Widget _timingSection(AppSettings settings) {
    return _SettingsSection(
      title: 'توقيت مراحل العرض',
      children: [
        _SettingsAdjustRow(
          label: 'بدء المحتوى قبل الأذان',
          value: '${settings.prePrayerWindowMinutes} دقيقة',
          onDecrease: () => _updatePrePrayer(-1),
          onIncrease: () => _updatePrePrayer(1),
        ),
        _rowGap(),
        _SettingsAdjustRow(
          label: 'مدة دعاء دخول المسجد',
          value: '${settings.entryDuaDurationMinutes} دقيقة',
          onDecrease: () => _updateEntryDuration(-1),
          onIncrease: () => _updateEntryDuration(1),
        ),
        _rowGap(),
        _SettingsAdjustRow(
          label: 'بدء الأذكار بعد الأذان',
          value: '${settings.afterAdhanAzkarStartOffsetMinutes} دقيقة',
          onDecrease: () => _updateAzkarStartOffset(-1),
          onIncrease: () => _updateAzkarStartOffset(1),
        ),
        _rowGap(),
        _SettingsAdjustRow(
          label: 'مدة أذكار بعد الصلاة',
          value: '${settings.azkarDurationMinutes} دقيقة',
          onDecrease: () => _updateAzkarDuration(-1),
          onIncrease: () => _updateAzkarDuration(1),
        ),
        _rowGap(),
        _SettingsAdjustRow(
          label: 'مدة دعاء الخروج',
          value: '${settings.exitDuaDurationMinutes} دقيقة',
          onDecrease: () => _updateExitDuration(-1),
          onIncrease: () => _updateExitDuration(1),
        ),
      ],
    );
  }

  Widget _behaviorSection(AppSettings settings) {
    return _SettingsSection(
      title: 'سلوك التشغيل',
      children: [
        _SettingsSwitchRow(
          label: 'التحكم في إيقاظ الشاشة تلقائيًا',
          value: settings.autoScreenControlEnabled,
          onChanged: (value) {
            ref
                .read(settingsControllerProvider.notifier)
                .updateAutoScreenControlEnabled(value);
          },
        ),
        _rowGap(),
        _SettingsSwitchRow(
          label: 'Keep screen always on / إبقاء الشاشة تعمل دائمًا',
          value: settings.keepScreenAlwaysOn,
          onChanged: (value) {
            ref
                .read(settingsControllerProvider.notifier)
                .updateKeepScreenAlwaysOn(value);
          },
        ),
        _rowGap(),
        _FieldLabel(text: 'Off mode type / نوع وضع الإطفاء'),
        _SettingsDropdown<OffModeTypeOption>(
          value: settings.offModeType,
          items: OffModeTypeOption.values
              .map(
                (option) => DropdownMenuItem<OffModeTypeOption>(
                  value: option,
                  child: Text(option.labelArabic),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              ref
                  .read(settingsControllerProvider.notifier)
                  .updateOffModeType(value);
            }
          },
        ),
        _rowGap(),
        FutureBuilder<String>(
          future: ref
              .read(screenControlServiceProvider)
              .realScreenOffSupportStatus(),
          builder: (context, snapshot) {
            final status = snapshot.data ?? 'unknown';
            return _SettingsInfoRow(
              label: 'Real screen off supported / دعم الإطفاء الحقيقي: $status',
              detail:
                  'يعتمد على صلاحيات الجهاز. عند المنع تستخدم الشاشة السوداء النقية.',
            );
          },
        ),
        _rowGap(),
        _SettingsSwitchRow(
          label: 'تفعيل دعاء الدخول',
          value: settings.entryDuaEnabled,
          onChanged: (value) {
            ref
                .read(settingsControllerProvider.notifier)
                .updateEntryDuaEnabled(value);
          },
        ),
        _rowGap(),
        _SettingsSwitchRow(
          label: 'تفعيل أذكار بعد الصلاة',
          value: settings.afterPrayerAzkarEnabled,
          onChanged: (value) {
            ref
                .read(settingsControllerProvider.notifier)
                .updateAfterPrayerAzkarEnabled(value);
          },
        ),
        _rowGap(),
        _SettingsSwitchRow(
          label: 'تفعيل دعاء الخروج',
          value: settings.exitDuaEnabled,
          onChanged: (value) {
            ref
                .read(settingsControllerProvider.notifier)
                .updateExitDuaEnabled(value);
          },
        ),
        _rowGap(),
        _SettingsSwitchRow(
          label: 'وضع التحكم اليدوي',
          value: settings.manualOverrideMode,
          onChanged: (value) {
            ref
                .read(settingsControllerProvider.notifier)
                .updateManualOverrideMode(value);
          },
        ),
        _rowGap(),
        _SettingsSwitchRow(
          label: 'Show next prayer footer / عرض شريط الصلاة القادمة',
          value: settings.showNextPrayerFooter,
          onChanged: (value) {
            ref
                .read(settingsControllerProvider.notifier)
                .updateShowNextPrayerFooter(value);
          },
        ),
        _rowGap(),
        FilledButton.icon(
          onPressed: _lockScreenFromSettings,
          icon: const Icon(Icons.lock_rounded),
          label: const Text('Lock Screen / وضع القفل'),
        ),
        _rowGap(),
        FilledButton.icon(
          onPressed: _blackScreenFromSettings,
          icon: const Icon(Icons.power_settings_new_rounded),
          label: const Text('Black Screen / إطفاء الشاشة'),
        ),
      ],
    );
  }

  Widget _previewSection() {
    return _SettingsSection(
      title: 'المعاينة',
      children: [
        _PreviewButton(
          label: 'معاينة دخول المسجد',
          mode: DisplayStateMode.duaEntry,
          onPressed: _openPreview,
        ),
        _rowGap(),
        _PreviewButton(
          label: 'معاينة أذكار بعد الصلاة',
          mode: DisplayStateMode.postPrayerAzkar,
          onPressed: _openPreview,
        ),
        _rowGap(),
        _PreviewButton(
          label: 'معاينة خروج المسجد',
          mode: DisplayStateMode.duaExit,
          onPressed: _openPreview,
        ),
        _rowGap(),
        _PreviewButton(
          label: 'معاينة الشاشة السوداء',
          mode: DisplayStateMode.blackScreen,
          onPressed: _openPreview,
        ),
      ],
    );
  }

  Widget _syncSection() {
    return _SettingsSection(
      title: 'المزامنة',
      children: [
        FilledButton.icon(
          onPressed: _recalculateScheduleNow,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Recalculate schedule now'),
        ),
        _rowGap(),
        FilledButton.icon(
          onPressed: _syncing ? null : _runSync,
          icon: _syncing
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync_rounded),
          label: Text(_syncing ? 'جار المزامنة' : 'مزامنة المواقيت الآن'),
        ),
      ],
    );
  }

  void _recalculateScheduleNow() {
    ref.read(dashboardControllerProvider.notifier).recalculateNow();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recalculate schedule now')),
    );
  }

  SizedBox _rowGap() {
    return SizedBox(height: AppLayout.gap(context, compact: 10, medium: 12));
  }

  Future<void> _runSync() async {
    setState(() => _syncing = true);
    final message =
        await ref.read(dashboardControllerProvider.notifier).syncNow();
    if (!mounted) {
      return;
    }
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openPreview(DisplayStateMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MosquePreviewScreen(mode: mode),
      ),
    );
  }

  void _updateManualPrayer(PrayerName prayer, int delta) {
    final settings = ref.read(settingsControllerProvider);
    ref.read(settingsControllerProvider.notifier).updateManualPrayerAdjustment(
          prayer,
          settings.manualAdjustmentFor(prayer) + delta,
        );
  }

  void _updatePrePrayer(int delta) {
    final settings = ref.read(settingsControllerProvider);
    ref
        .read(settingsControllerProvider.notifier)
        .updatePrePrayerWindowMinutes(settings.prePrayerWindowMinutes + delta);
  }

  void _updateEntryDuration(int delta) {
    final settings = ref.read(settingsControllerProvider);
    ref.read(settingsControllerProvider.notifier).updateEntryDuaDurationMinutes(
          settings.entryDuaDurationMinutes + delta,
        );
  }

  void _updateAzkarStartOffset(int delta) {
    final settings = ref.read(settingsControllerProvider);
    ref
        .read(settingsControllerProvider.notifier)
        .updateAfterAdhanAzkarStartOffsetMinutes(
          settings.afterAdhanAzkarStartOffsetMinutes + delta,
        );
  }

  void _updateAzkarDuration(int delta) {
    final settings = ref.read(settingsControllerProvider);
    ref.read(settingsControllerProvider.notifier).updateAzkarDurationMinutes(
          settings.azkarDurationMinutes + delta,
        );
  }

  void _updateExitDuration(int delta) {
    final settings = ref.read(settingsControllerProvider);
    ref.read(settingsControllerProvider.notifier).updateExitDuaDurationMinutes(
          settings.exitDuaDurationMinutes + delta,
        );
  }

  void _updateUiScale(int delta) {
    final settings = ref.read(settingsControllerProvider);
    ref
        .read(settingsControllerProvider.notifier)
        .updateUiScalePercent(settings.uiScalePercent + delta);
  }

  void _lockScreenFromSettings() {
    ref
        .read(settingsControllerProvider.notifier)
        .updateScreenLockModeEnabled(true);
    Navigator.of(context).pop();
  }

  void _blackScreenFromSettings() {
    final dashboardState = ref.read(dashboardControllerProvider);
    final settings = ref.read(settingsControllerProvider);
    ref
        .read(settingsControllerProvider.notifier)
        .updateScreenLockModeEnabled(true);
    ref.read(displayControlControllerProvider.notifier).forceBlackUntil(
          dashboardState.automation.nextTransitionAt,
        );
    if (settings.offModeType == OffModeTypeOption.realStandby) {
      unawaited(ref.read(screenControlServiceProvider).enterRealStandby());
    }
    Navigator.of(context).pop();
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton.icon(
          autofocus: false,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('عودة'),
        ),
        Expanded(
          child: Text(
            'إعدادات شاشة المسجد',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: AppLayout.fluid(context, min: 34, max: 48),
                ),
          ),
        ),
        const SizedBox(width: 120),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: AppLayout.fluid(context, min: 26, max: 34),
                  color: const Color(0xFFD8BE74),
                ),
          ),
          SizedBox(height: AppLayout.gap(context, compact: 14, medium: 18)),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: AppLayout.gap(context, compact: 8, medium: 10),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: AppLayout.fluid(context, min: 21, max: 26),
            ),
      ),
    );
  }
}

class _SettingsDropdown<T> extends StatelessWidget {
  const _SettingsDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF173A32),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: AppLayout.fluid(context, min: 21, max: 26),
          ),
      decoration: _fieldDecoration(context),
    );
  }
}

class _SettingsAdjustRow extends StatelessWidget {
  const _SettingsAdjustRow({
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final String value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final buttonSize = AppLayout.fluid(context, min: 42, max: 54);
    return DecoratedBox(
      decoration: _rowDecoration(context),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.cardPadding(context) * 0.6,
          vertical: AppLayout.cardPadding(context) * 0.34,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: AppLayout.fluid(context, min: 20, max: 26),
                    ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: AppLayout.fluid(context, min: 20, max: 28),
                    color: const Color(0xFFD8BE74),
                  ),
            ),
            SizedBox(width: AppLayout.gap(context, compact: 8, medium: 12)),
            SizedBox.square(
              dimension: buttonSize,
              child: IconButton(
                onPressed: onDecrease,
                icon: const Icon(Icons.remove_rounded),
              ),
            ),
            SizedBox.square(
              dimension: buttonSize,
              child: IconButton(
                onPressed: onIncrease,
                icon: const Icon(Icons.add_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _rowDecoration(context),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.cardPadding(context) * 0.6,
          vertical: AppLayout.cardPadding(context) * 0.28,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: AppLayout.fluid(context, min: 20, max: 26),
                    ),
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: const Color(0xFFD8BE74),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  const _SettingsInfoRow({
    required this.label,
    required this.detail,
  });

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _rowDecoration(context),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.cardPadding(context) * 0.6,
          vertical: AppLayout.cardPadding(context) * 0.38,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: AppLayout.fluid(context, min: 20, max: 26),
                    color: const Color(0xFFD8BE74),
                  ),
            ),
            SizedBox(height: AppLayout.gap(context, compact: 6, medium: 8)),
            Text(
              detail,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: AppLayout.fluid(context, min: 17, max: 22),
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsScrollSpeedRow extends StatelessWidget {
  const _SettingsScrollSpeedRow({
    required this.value,
    this.autofocus = false,
    required this.onChanged,
  });

  final double value;
  final bool autofocus;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = normalizeAutoScrollSpeedMultiplier(value);
    final speedText = autoScrollSpeedText(normalizedValue);
    final canDecrease = normalizedValue > kAutoScrollSpeedMultipliers.first;
    final canIncrease = normalizedValue < kAutoScrollSpeedMultipliers.last;

    void decrease() {
      if (!canDecrease) {
        return;
      }
      onChanged(previousAutoScrollSpeedMultiplier(normalizedValue));
    }

    void increase() {
      if (!canIncrease) {
        return;
      }
      onChanged(nextAutoScrollSpeedMultiplier(normalizedValue));
    }

    return DecoratedBox(
      decoration: _rowDecoration(context),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.cardPadding(context) * 0.6,
          vertical: AppLayout.cardPadding(context) * 0.34,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'سرعة نزول الأذكار',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: AppLayout.fluid(context, min: 20, max: 26),
                  ),
            ),
            SizedBox(height: AppLayout.gap(context, compact: 10, medium: 14)),
            Shortcuts(
              shortcuts: const <ShortcutActivator, Intent>{
                SingleActivator(LogicalKeyboardKey.arrowLeft):
                    _AdjustScrollSpeedIntent(increase: false),
                SingleActivator(LogicalKeyboardKey.arrowRight):
                    _AdjustScrollSpeedIntent(increase: true),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  _AdjustScrollSpeedIntent:
                      CallbackAction<_AdjustScrollSpeedIntent>(
                    onInvoke: (intent) {
                      if (intent.increase) {
                        increase();
                      } else {
                        decrease();
                      }
                      return null;
                    },
                  ),
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepperButton(
                      icon: Icons.remove_rounded,
                      autofocus: autofocus,
                      onPressed: decrease,
                    ),
                    SizedBox(
                      width: AppLayout.gap(context, compact: 14, medium: 20),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child:
                              ScaleTransition(scale: animation, child: child),
                        );
                      },
                      child: Text(
                        speedText,
                        key: ValueKey<String>(speedText),
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontSize: AppLayout.fluid(
                                    context,
                                    min: 28,
                                    max: 36,
                                  ),
                                  color: const Color(0xFFD8BE74),
                                ),
                      ),
                    ),
                    SizedBox(
                      width: AppLayout.gap(context, compact: 14, medium: 20),
                    ),
                    _StepperButton(
                      icon: Icons.add_rounded,
                      onPressed: increase,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppLayout.gap(context, compact: 8, medium: 10)),
            Text(
              'بطيء جداً – بطيء – عادي – سريع',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustScrollSpeedIntent extends Intent {
  const _AdjustScrollSpeedIntent({required this.increase});

  final bool increase;
}

class _StepperButton extends StatefulWidget {
  const _StepperButton({
    required this.icon,
    required this.onPressed,
    this.autofocus = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final size = AppLayout.fluid(context, min: 56, max: 72);
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
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _focused ? 1.07 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(size),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              height: size,
              width: size,
              decoration: BoxDecoration(
                color: _focused
                    ? const Color(0xFFD8BE74).withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(size),
                border: Border.all(
                  color: _focused
                      ? const Color(0xFFD8BE74)
                      : Colors.white.withValues(alpha: 0.24),
                  width: 2,
                ),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFFD8BE74).withValues(alpha: 0.40),
                          blurRadius: 18,
                          spreadRadius: 0.8,
                        ),
                      ]
                    : const [],
              ),
              child: Icon(
                widget.icon,
                size: AppLayout.fluid(context, min: 32, max: 40),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsScrollSpeedPreview extends StatelessWidget {
  const _SettingsScrollSpeedPreview({
    required this.speedMultiplier,
  });

  final double speedMultiplier;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _rowDecoration(context),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.cardPadding(context) * 0.6,
          vertical: AppLayout.cardPadding(context) * 0.38,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'معاينة سرعة النزول',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: AppLayout.fluid(context, min: 20, max: 26),
                    color: const Color(0xFFD8BE74),
                  ),
            ),
            SizedBox(height: AppLayout.gap(context, compact: 8, medium: 12)),
            SizedBox(
              height: AppLayout.fluid(context, min: 180, max: 230),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.76,
                      ),
                      child: ClipRect(
                        child: SizedBox.expand(
                          child: AutoScrollingText(
                            text: _scrollPreviewText,
                            textAlign: TextAlign.center,
                            speedMultiplier: speedMultiplier,
                            pixelsPerSecond: 15,
                            startDelay: const Duration(milliseconds: 600),
                            endPause: const Duration(milliseconds: 900),
                            padding: EdgeInsets.symmetric(
                              vertical: AppLayout.gap(context,
                                  compact: 12, medium: 18),
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(height: 1.8),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    required this.label,
    required this.mode,
    required this.onPressed,
  });

  final String label;
  final DisplayStateMode mode;
  final ValueChanged<DisplayStateMode> onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => onPressed(mode),
      icon: const Icon(Icons.visibility_rounded),
      label: Text(label),
    );
  }
}

const String _scrollPreviewText = 'اللهم أعنّي على ذكرك وشكرك وحسن عبادتك. '
    'سبحان الله والحمد لله ولا إله إلا الله والله أكبر.';

InputDecoration _fieldDecoration(BuildContext context) {
  return InputDecoration(
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppLayout.cardPadding(context) * 0.65,
      vertical: AppLayout.cardPadding(context) * 0.48,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.42),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.42),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.42),
      borderSide: const BorderSide(color: Color(0xFFD8BE74), width: 2),
    ),
  );
}

BoxDecoration _rowDecoration(BuildContext context) {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.42),
    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
  );
}
