import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_cities.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/layout/tv_screen_profile.dart';
import '../../../core/layout/tv_viewport_frame.dart';
import '../../../core/widgets/ensure_visible_on_focus.dart';
import '../../../core/widgets/responsive_screen_header.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/tv_action_button.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../../nawawi/presentation/nawawi_library_screen.dart';
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

  static const List<int> _windowMinuteOptions = <int>[
    5,
    10,
    15,
    20,
    25,
    30,
    35,
    40,
    45,
    50,
    55,
    60,
  ];

  static const List<int> _hijriOffsetOptions = <int>[-2, -1, 0, 1, 2];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);
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
    final now = dashboardState.now;
    final effectiveContentMode = settings.effectiveContentSelectionMode(now);
    final selectedContentTitle =
        settings.activeSelectedContentTitle(now) ?? 'لا يوجد محتوى محدد';
    final hasStoredSelection = settings.hasStoredContentSelection;

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
                              'إعدادات المدينة، الحساب، العرض التلفازي، الخط، التمرير، ونوافذ المحتوى حول الصلاة.',
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
                            title: 'التحكم في المحتوى المعروض',
                            children: [
                              _SettingsValueRow(
                                label: 'الوضع الحالي',
                                value: effectiveContentMode.labelArabic,
                              ),
                              SizedBox(height: fieldGap),
                              _SettingsValueRow(
                                label: 'المحتوى المحدد',
                                value: selectedContentTitle,
                              ),
                              SizedBox(height: fieldGap),
                              Text(
                                'يمكنك اختيار حديث أو ذكر من المكتبة لعرضه اليوم فقط أو تثبيته على الشاشة حتى تغييره.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: AppLayout.fluid(
                                    context,
                                    min: 20,
                                    max: 24,
                                  ),
                                ),
                              ),
                              SizedBox(height: fieldGap),
                              Wrap(
                                spacing: fieldGap,
                                runSpacing: fieldGap,
                                children: [
                                  FilledButton.icon(
                                    onPressed:
                                        dashboardState.libraryItems.isEmpty
                                            ? null
                                            : () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        NawawiLibraryScreen(
                                                      items: dashboardState
                                                          .libraryItems,
                                                    ),
                                                  ),
                                                );
                                              },
                                    icon: const Icon(Icons.menu_book_rounded),
                                    label: const Text('اختيار من المكتبة'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: effectiveContentMode ==
                                            ContentSelectionMode.auto
                                        ? null
                                        : () {
                                            ref
                                                .read(
                                                  settingsControllerProvider
                                                      .notifier,
                                                )
                                                .clearManualContentSelection();
                                          },
                                    icon:
                                        const Icon(Icons.auto_awesome_rounded),
                                    label: const Text('الوضع التلقائي'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: hasStoredSelection
                                        ? () {
                                            ref
                                                .read(
                                                  settingsControllerProvider
                                                      .notifier,
                                                )
                                                .clearManualContentSelection();
                                          }
                                        : null,
                                    icon: const Icon(Icons.close_rounded),
                                    label: const Text('مسح التحديد'),
                                  ),
                                ],
                              ),
                            ],
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
                                  if (value != null) {
                                    ref
                                        .read(
                                          settingsControllerProvider.notifier,
                                        )
                                        .updateCity(value);
                                  }
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
                                  if (value != null) {
                                    ref
                                        .read(
                                          settingsControllerProvider.notifier,
                                        )
                                        .updatePrayerMethod(value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        _focusAware(
                          _SettingsSection(
                            title: 'ملف شاشة التلفاز',
                            children: [
                              _FieldLabel(text: 'مقاس الشاشة المستهدف'),
                              SizedBox(height: fieldGap),
                              _SettingsDropdown<TvScreenProfile>(
                                value: settings.tvScreenProfile,
                                items: TvScreenProfile.values
                                    .map(
                                      (profile) =>
                                          DropdownMenuItem<TvScreenProfile>(
                                        value: profile,
                                        child: Text(profile.labelArabic),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    ref
                                        .read(
                                          settingsControllerProvider.notifier,
                                        )
                                        .updateTvScreenProfile(value);
                                  }
                                },
                              ),
                              SizedBox(height: fieldGap),
                              _SettingsValueRow(
                                label: 'الملف الحالي',
                                value: settings.tvScreenProfile.previewLabel,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        _focusAware(
                          _SettingsSection(
                            title: 'الخط والقراءة',
                            children: [
                              _FieldLabel(text: 'حجم الخط'),
                              SizedBox(height: fieldGap),
                              _SettingsDropdown<DisplayFontSizeOption>(
                                value: settings.displayFontSize,
                                items: DisplayFontSizeOption.values
                                    .map(
                                      (option) => DropdownMenuItem<
                                          DisplayFontSizeOption>(
                                        value: option,
                                        child: Text(option.labelArabic),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    ref
                                        .read(
                                          settingsControllerProvider.notifier,
                                        )
                                        .updateDisplayFontSize(value);
                                  }
                                },
                              ),
                              SizedBox(height: sectionGap),
                              _FieldLabel(text: 'سماكة الخط'),
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
                                  if (value != null) {
                                    ref
                                        .read(
                                          settingsControllerProvider.notifier,
                                        )
                                        .updateDisplayFontWeight(value);
                                  }
                                },
                              ),
                              SizedBox(height: sectionGap),
                              _FieldLabel(text: 'سرعة تمرير النص'),
                              SizedBox(height: fieldGap),
                              _SettingsDropdown<AutoScrollSpeedOption>(
                                value: settings.autoScrollSpeed,
                                items: AutoScrollSpeedOption.values
                                    .map(
                                      (option) => DropdownMenuItem<
                                          AutoScrollSpeedOption>(
                                        value: option,
                                        child: Text(option.labelArabic),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    ref
                                        .read(
                                          settingsControllerProvider.notifier,
                                        )
                                        .updateAutoScrollSpeed(value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        _focusAware(
                          _SettingsSection(
                            title: 'نوافذ محتوى الصلاة',
                            children: [
                              _FieldLabel(text: 'نافذة ما قبل الصلاة'),
                              SizedBox(height: fieldGap),
                              _SettingsDropdown<int>(
                                value: settings.prePrayerWindowMinutes,
                                items: _windowMinuteOptions
                                    .map(
                                      (minutes) => DropdownMenuItem<int>(
                                        value: minutes,
                                        child: Text('$minutes دقيقة'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    ref
                                        .read(
                                          settingsControllerProvider.notifier,
                                        )
                                        .updatePrePrayerWindowMinutes(value);
                                  }
                                },
                              ),
                              SizedBox(height: sectionGap),
                              _FieldLabel(text: 'نافذة ما بعد الصلاة'),
                              SizedBox(height: fieldGap),
                              _SettingsDropdown<int>(
                                value: settings.postPrayerWindowMinutes,
                                items: _windowMinuteOptions
                                    .map(
                                      (minutes) => DropdownMenuItem<int>(
                                        value: minutes,
                                        child: Text('$minutes دقيقة'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    ref
                                        .read(
                                          settingsControllerProvider.notifier,
                                        )
                                        .updatePostPrayerWindowMinutes(value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        _focusAware(
                          _SettingsSection(
                            title: 'التاريخ والمحتوى',
                            children: [
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
                                  if (value != null) {
                                    ref
                                        .read(
                                          settingsControllerProvider.notifier,
                                        )
                                        .updateHijriOffset(value);
                                  }
                                },
                              ),
                              SizedBox(height: fieldGap),
                              Text(
                                'خارج نوافذ الصلاة يعرض التطبيق الحديث اليومي، بينما يعرض يوم الجمعة محتوى الجمعة كل ثلاثين دقيقة.',
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
                                'تعمل الشاشة دون اتصال كامل. عند توفر الإنترنت يمكن مزامنة التاريخ الهجري ومحاولة جلب أي حزمة محتوى بعيدة مفعلة.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: AppLayout.fluid(
                                    context,
                                    min: 20,
                                    max: 24,
                                  ),
                                ),
                              ),
                              SizedBox(height: fieldGap),
                              Text(
                                'يفضل أن تكون منطقة الجهاز الزمنية مطابقة للمدينة المختارة لضمان دقة المواقيت.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: AppLayout.fluid(
                                    context,
                                    min: 18,
                                    max: 22,
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

class _SettingsValueRow extends StatelessWidget {
  const _SettingsValueRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

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
          horizontal: AppLayout.cardPadding(context) * 0.72,
          vertical: AppLayout.cardPadding(context) * 0.58,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: AppLayout.fluid(context, min: 20, max: 24),
                    ),
              ),
            ),
            SizedBox(
                width: AppLayout.gap(context,
                    compact: 10, medium: 12, expanded: 14)),
            Flexible(
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: AppLayout.fluid(context, min: 22, max: 26),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
