import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_cities.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/layout/tv_viewport_frame.dart';
import '../../../core/widgets/ensure_visible_on_focus.dart';
import '../../../core/widgets/responsive_screen_header.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/tv_action_button.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../application/settings_controller.dart';
import '../domain/app_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _syncing = false;
  final ScrollController _scrollController = ScrollController();

  static const List<int> _hijriOffsetOptions = <int>[-2, -1, 0, 1, 2];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final theme = Theme.of(context);
    final pagePadding = AppLayout.pagePadding(context);
    final sectionGap = AppLayout.gap(
      context,
      compact: 16,
      medium: 18,
      expanded: 22,
    );
    final fieldGap = AppLayout.gap(
      context,
      compact: 10,
      medium: 12,
      expanded: 14,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF081116),
                  Color(0xFF102C36),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: TvViewportFrame(
                child: Padding(
                  padding: EdgeInsets.all(pagePadding),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: ListView(
                      controller: _scrollController,
                      padding: EdgeInsets.only(bottom: pagePadding * 1.6),
                      children: [
                        ResponsiveScreenHeader(
                          title: 'الإعدادات',
                          description:
                              'ضبط مواقيت الصلاة، مراحل العرض، حجم الخط، وتدرج الواجهة.',
                          trailing: TvActionButton(
                            label: 'عودة',
                            icon: Icons.arrow_back_rounded,
                            autofocus: true,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        _focusAware(
                          _SettingsSection(
                            title: 'الموقع وحساب الصلاة',
                            children: [
                              _FieldLabel(text: 'المدينة'),
                              SizedBox(height: fieldGap),
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
                                  if (value == null) {
                                    return;
                                  }
                                  ref
                                      .read(settingsControllerProvider.notifier)
                                      .updateCity(value);
                                },
                              ),
                              SizedBox(height: sectionGap),
                              _FieldLabel(text: 'طريقة الحساب'),
                              SizedBox(height: fieldGap),
                              _SettingsDropdown<PrayerMethodOption>(
                                value: settings.prayerMethod,
                                items: PrayerMethodOption.values
                                    .map(
                                      (method) =>
                                          DropdownMenuItem<PrayerMethodOption>(
                                        value: method,
                                        child: Text(method.labelArabic),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  ref
                                      .read(settingsControllerProvider.notifier)
                                      .updatePrayerMethod(value);
                                },
                              ),
                              SizedBox(height: sectionGap),
                              _FieldLabel(text: 'إزاحة التاريخ الهجري'),
                              SizedBox(height: fieldGap),
                              _SettingsDropdown<int>(
                                value: settings.hijriOffset,
                                items: _hijriOffsetOptions
                                    .map(
                                      (offset) => DropdownMenuItem<int>(
                                        value: offset,
                                        child: Text(
                                          offset == 0
                                              ? 'بدون إزاحة'
                                              : '$offset يوم',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  ref
                                      .read(settingsControllerProvider.notifier)
                                      .updateHijriOffset(value);
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        _focusAware(
                          _SettingsSection(
                            title: 'توقيت المراحل',
                            children: [
                              _SettingsAdjustRow(
                                label: 'تشغيل الشاشة قبل الأذان',
                                value:
                                    '${settings.prePrayerWindowMinutes} دقيقة',
                                onDecrease: () => _updatePrePrayer(-1),
                                onIncrease: () => _updatePrePrayer(1),
                              ),
                              SizedBox(height: fieldGap),
                              _SettingsAdjustRow(
                                label: 'مدة دعاء الدخول',
                                value:
                                    '${settings.entryDuaDurationMinutes} دقيقة',
                                onDecrease: () => _updateEntryDuration(-1),
                                onIncrease: () => _updateEntryDuration(1),
                              ),
                              SizedBox(height: fieldGap),
                              _SettingsAdjustRow(
                                label: 'مدة أذكار بعد الصلاة',
                                value: '${settings.azkarDurationMinutes} دقيقة',
                                onDecrease: () => _updateAzkarDuration(-1),
                                onIncrease: () => _updateAzkarDuration(1),
                              ),
                              SizedBox(height: fieldGap),
                              _SettingsAdjustRow(
                                label: 'مدة دعاء الخروج',
                                value:
                                    '${settings.exitDuaDurationMinutes} دقيقة',
                                onDecrease: () => _updateExitDuration(-1),
                                onIncrease: () => _updateExitDuration(1),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        _focusAware(
                          _SettingsSection(
                            title: 'العرض والقراءة',
                            children: [
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
                              SizedBox(height: fieldGap),
                              _SettingsAdjustRow(
                                label: 'تدرج الواجهة',
                                value: '${settings.uiScalePercent}%',
                                onDecrease: () => _updateUiScale(-5),
                                onIncrease: () => _updateUiScale(5),
                              ),
                              SizedBox(height: fieldGap),
                              _SettingsAdjustRow(
                                label: 'تكبير نص الذكر',
                                value: '${settings.zikrTextScalePercent}%',
                                onDecrease: () => _updateZikrScale(-5),
                                onIncrease: () => _updateZikrScale(5),
                              ),
                              SizedBox(height: fieldGap),
                              _SettingsAdjustRow(
                                label: 'سطوع وضع السكون',
                                value: '${settings.sleepBrightnessPercent}%',
                                onDecrease: () => _updateSleepBrightness(-5),
                                onIncrease: () => _updateSleepBrightness(5),
                              ),
                              SizedBox(height: fieldGap),
                              _SettingsDropdown<DisplayFontWeightOption>(
                                value: settings.displayFontWeight,
                                items: DisplayFontWeightOption.values
                                    .map(
                                      (option) => DropdownMenuItem<
                                          DisplayFontWeightOption>(
                                        value: option,
                                        child: Text(option.labelArabic),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  ref
                                      .read(settingsControllerProvider.notifier)
                                      .updateDisplayFontWeight(value);
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        _focusAware(
                          _SettingsSection(
                            title: 'سلوك التشغيل',
                            children: [
                              _SettingsSwitchRow(
                                label: 'تشغيل وإطفاء الشاشة تلقائيًا',
                                value: settings.autoScreenControlEnabled,
                                onChanged: (value) {
                                  ref
                                      .read(settingsControllerProvider.notifier)
                                      .updateAutoScreenControlEnabled(value);
                                },
                              ),
                              SizedBox(height: fieldGap),
                              _SettingsSwitchRow(
                                label: 'تفعيل دعاء الدخول',
                                value: settings.entryDuaEnabled,
                                onChanged: (value) {
                                  ref
                                      .read(settingsControllerProvider.notifier)
                                      .updateEntryDuaEnabled(value);
                                },
                              ),
                              SizedBox(height: fieldGap),
                              _SettingsSwitchRow(
                                label: 'تفعيل أذكار بعد الصلاة',
                                value: settings.afterPrayerAzkarEnabled,
                                onChanged: (value) {
                                  ref
                                      .read(settingsControllerProvider.notifier)
                                      .updateAfterPrayerAzkarEnabled(value);
                                },
                              ),
                              SizedBox(height: fieldGap),
                              _SettingsSwitchRow(
                                label: 'تفعيل دعاء الخروج',
                                value: settings.exitDuaEnabled,
                                onChanged: (value) {
                                  ref
                                      .read(settingsControllerProvider.notifier)
                                      .updateExitDuaEnabled(value);
                                },
                              ),
                              SizedBox(height: fieldGap),
                              _SettingsSwitchRow(
                                label: 'وضع التحكم اليدوي',
                                value: settings.manualOverrideMode,
                                onChanged: (value) {
                                  ref
                                      .read(settingsControllerProvider.notifier)
                                      .updateManualOverrideMode(value);
                                },
                              ),
                              SizedBox(height: fieldGap),
                              Text(
                                'عند تفعيل التحكم اليدوي يتوقف الانتقال التلقائي حتى تعيده من هذه الصفحة.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: AppLayout.fluid(
                                    context,
                                    min: 20,
                                    max: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        _focusAware(
                          _SettingsSection(
                            title: 'المزامنة',
                            children: [
                              Text(
                                'يجلب التطبيق مواقيت الصلاة من الشبكة ويحتفظ بنسخة محلية للعمل دون اتصال.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: AppLayout.fluid(
                                    context,
                                    min: 20,
                                    max: 24,
                                  ),
                                ),
                              ),
                              SizedBox(height: sectionGap),
                              FilledButton.icon(
                                onPressed: _syncing ? null : _runSync,
                                icon: _syncing
                                    ? SizedBox(
                                        width: AppLayout.fluid(
                                          context,
                                          min: 18,
                                          max: 22,
                                        ),
                                        height: AppLayout.fluid(
                                          context,
                                          min: 18,
                                          max: 22,
                                        ),
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.sync_rounded),
                                label: Text(
                                  _syncing ? 'جار المزامنة' : 'مزامنة الآن',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
      alignment: 0.14,
      child: child,
    );
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

  void _updateZikrScale(int delta) {
    final settings = ref.read(settingsControllerProvider);
    ref
        .read(settingsControllerProvider.notifier)
        .updateZikrTextScalePercent(settings.zikrTextScalePercent + delta);
  }

  void _updateSleepBrightness(int delta) {
    final settings = ref.read(settingsControllerProvider);
    ref.read(settingsControllerProvider.notifier).updateSleepBrightnessPercent(
          settings.sleepBrightnessPercent + delta,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: AppLayout.fluid(context, min: 28, max: 34),
                ),
          ),
          SizedBox(
            height: AppLayout.gap(
              context,
              compact: 16,
              medium: 18,
              expanded: 20,
            ),
          ),
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
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: AppLayout.fluid(context, min: 22, max: 26),
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
      value: value,
      dropdownColor: const Color(0xFF173E46),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: AppLayout.fluid(context, min: 22, max: 26),
          ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppLayout.cardPadding(context) * 0.78,
          vertical: AppLayout.cardPadding(context) * 0.62,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.62),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.62),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.62),
          borderSide: const BorderSide(
            color: Color(0xFFD8BE74),
            width: 2,
          ),
        ),
      ),
      items: items,
      onChanged: onChanged,
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
    final gap = AppLayout.gap(context, compact: 10, medium: 12, expanded: 14);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.56),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.cardPadding(context) * 0.58,
          vertical: AppLayout.cardPadding(context) * 0.42,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: AppLayout.fluid(context, min: 21, max: 26),
                    ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: AppLayout.fluid(context, min: 22, max: 28),
                    color: const Color(0xFFD8BE74),
                  ),
            ),
            SizedBox(width: gap),
            _AdjustButton(
              icon: Icons.remove_rounded,
              onPressed: onDecrease,
            ),
            SizedBox(width: gap * 0.6),
            _AdjustButton(
              icon: Icons.add_rounded,
              onPressed: onIncrease,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustButton extends StatelessWidget {
  const _AdjustButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final size = AppLayout.fluid(context, min: 42, max: 50);

    return SizedBox.square(
      dimension: size,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: AppLayout.fluid(context, min: 24, max: 30),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.08),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppLayout.radius(context) * 0.44,
            ),
          ),
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.56),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.cardPadding(context) * 0.58,
          vertical: AppLayout.cardPadding(context) * 0.36,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: AppLayout.fluid(context, min: 21, max: 26),
                    ),
              ),
            ),
            Switch(
              value: value,
              activeColor: const Color(0xFFD8BE74),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
