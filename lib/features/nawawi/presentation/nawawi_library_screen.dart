import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/widgets/ensure_visible_on_focus.dart';
import '../../../core/widgets/responsive_screen_header.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/tv_action_button.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../../content_engine/domain/content_item.dart';
import '../../content_engine/domain/content_library_category.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/domain/app_settings.dart';

class NawawiLibraryScreen extends ConsumerStatefulWidget {
  const NawawiLibraryScreen({
    super.key,
    required this.items,
  });

  final List<ContentItem> items;

  @override
  ConsumerState<NawawiLibraryScreen> createState() =>
      _NawawiLibraryScreenState();
}

class _NawawiLibraryScreenState extends ConsumerState<NawawiLibraryScreen> {
  String? _selectedCategoryId;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pagePadding = AppLayout.pagePadding(context);
    final categories = ContentLibraryCategory.build(widget.items);
    final selectedCategory = _resolveSelectedCategory(categories);

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
              child: Padding(
                padding: EdgeInsets.all(pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveScreenHeader(
                      title: selectedCategory == null
                          ? 'مكتبة المحتوى'
                          : selectedCategory.name,
                      description: selectedCategory == null
                          ? 'تصفح المحتوى حسب التصنيف أو المجموعة، ثم اختر ما تريد عرضه اليوم أو تثبيته على الشاشة.'
                          : (selectedCategory.subtitle ??
                              'تصفح عناصر هذا التصنيف واختر ما تريد عرضه على الشاشة.'),
                      trailing: TvActionButton(
                        label: selectedCategory == null ? 'عودة' : 'التصنيفات',
                        icon: selectedCategory == null
                            ? Icons.arrow_back_rounded
                            : Icons.grid_view_rounded,
                        onPressed: () {
                          if (selectedCategory == null) {
                            Navigator.of(context).pop();
                            return;
                          }
                          setState(() {
                            _selectedCategoryId = null;
                          });
                          _scrollController.jumpTo(0);
                        },
                      ),
                    ),
                    SizedBox(height: AppLayout.gap(context)),
                    Expanded(
                      child: widget.items.isEmpty
                          ? const _EmptyLibraryState()
                          : selectedCategory == null
                              ? _CategoryGrid(
                                  categories: categories,
                                  controller: _scrollController,
                                  onSelectCategory: (category) {
                                    setState(() {
                                      _selectedCategoryId = category.id;
                                    });
                                    _scrollController.jumpTo(0);
                                  },
                                )
                              : _CategoryItemsView(
                                  category: selectedCategory,
                                  controller: _scrollController,
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ContentLibraryCategory? _resolveSelectedCategory(
    List<ContentLibraryCategory> categories,
  ) {
    if (_selectedCategoryId == null) {
      return null;
    }

    for (final category in categories) {
      if (category.id == _selectedCategoryId) {
        return category;
      }
    }

    return null;
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.controller,
    required this.onSelectCategory,
  });

  final List<ContentLibraryCategory> categories;
  final ScrollController controller;
  final ValueChanged<ContentLibraryCategory> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desiredCardWidth =
            constraints.maxWidth < 700 ? constraints.maxWidth : 420.0;
        final crossAxisCount = ((constraints.maxWidth / desiredCardWidth)
            .floor()
            .clamp(1, 4)) as int;

        return Scrollbar(
          controller: controller,
          thumbVisibility: true,
          child: GridView.builder(
            controller: controller,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: constraints.maxWidth < 760 ? 0.98 : 1.12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _CategoryCard(
                category: categories[index],
                autofocus: index == 0,
                onTap: () => onSelectCategory(categories[index]),
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({
    required this.category,
    required this.onTap,
    this.autofocus = false,
  });

  final ContentLibraryCategory category;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent =
        category.isAllItems ? const Color(0xFFD8BE74) : const Color(0xFF58A890);
    final settings = ref.watch(settingsControllerProvider);
    final currentDayKey = ref.watch(
      dashboardControllerProvider.select(
        (state) => AppSettings.dayKeyFrom(state.now),
      ),
    );
    final activeSelectedId = settings.activeSelectedContentIdForDayKey(
      currentDayKey,
    );
    final effectiveMode = settings.effectiveContentSelectionModeForDayKey(
      currentDayKey,
    );
    final containsActiveSelection = activeSelectedId != null &&
        category.items.any((item) => item.id == activeSelectedId);
    final modeLabel = containsActiveSelection
        ? switch (effectiveMode) {
            ContentSelectionMode.pinned => 'مثبت',
            ContentSelectionMode.selectedForToday => 'اليوم',
            ContentSelectionMode.auto => null,
          }
        : null;

    return _LibraryFocusableSurface(
      onPressed: onTap,
      autofocus: autofocus,
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(
                      AppLayout.radius(context) * 0.58,
                    ),
                    border: Border.all(color: accent.withOpacity(0.28)),
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
                    child: Text(
                      '${category.itemCount} عنصر',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: accent,
                          ),
                    ),
                  ),
                ),
                const Spacer(),
                if (modeLabel != null)
                  _ModeChip(
                    label: modeLabel,
                    accent: effectiveMode == ContentSelectionMode.pinned
                        ? const Color(0xFFD8BE74)
                        : const Color(0xFF58A890),
                  ),
              ],
            ),
            SizedBox(
              height: AppLayout.gap(
                context,
                compact: 12,
                medium: 14,
                expanded: 16,
              ),
            ),
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: AppLayout.fluid(context, min: 24, max: 30),
                  ),
            ),
            SizedBox(
              height: AppLayout.gap(
                context,
                compact: 8,
                medium: 10,
                expanded: 12,
              ),
            ),
            if (category.sourceSummary != null)
              Text(
                category.sourceSummary!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withOpacity(0.72),
                    ),
              ),
            SizedBox(
              height: AppLayout.gap(
                context,
                compact: 10,
                medium: 12,
                expanded: 14,
              ),
            ),
            Expanded(
              child: Text(
                category.subtitle ??
                    'تصفح عناصر هذا التصنيف واختر منها ما يناسب الشاشة.',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: AppLayout.fluid(context, min: 18, max: 22),
                    ),
              ),
            ),
            SizedBox(
              height: AppLayout.gap(
                context,
                compact: 10,
                medium: 12,
                expanded: 14,
              ),
            ),
            Row(
              children: [
                Text(
                  category.isAllItems ? 'عرض الجميع' : 'فتح التصنيف',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_back_rounded,
                  size: AppLayout.fluid(context, min: 22, max: 26),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItemsView extends StatelessWidget {
  const _CategoryItemsView({
    required this.category,
    required this.controller,
  });

  final ContentLibraryCategory category;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final sortedItems = _sortLibraryItems(category.items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategorySummary(category: category),
        SizedBox(height: AppLayout.gap(context)),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = _HadithGridMetrics.fromConstraints(
                context,
                constraints,
              );

              return Scrollbar(
                controller: controller,
                thumbVisibility: true,
                child: GridView.builder(
                  controller: controller,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: metrics.crossAxisCount,
                    crossAxisSpacing: metrics.gridSpacing,
                    mainAxisSpacing: metrics.gridSpacing,
                    mainAxisExtent: metrics.cardHeight,
                  ),
                  itemCount: sortedItems.length,
                  itemBuilder: (context, index) {
                    return _LibraryItemCard(
                      item: sortedItems[index],
                      metrics: metrics,
                      autofocus: index == 0,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<ContentItem> _sortLibraryItems(List<ContentItem> items) {
    final sorted = List<ContentItem>.of(items);
    sorted.sort((a, b) {
      final aNumber = a.hadithNumber;
      final bNumber = b.hadithNumber;

      if (aNumber != null && bNumber != null) {
        final numberCompare = aNumber.compareTo(bNumber);
        if (numberCompare != 0) {
          return numberCompare;
        }
      } else if (aNumber != null) {
        return -1;
      } else if (bNumber != null) {
        return 1;
      }

      final orderCompare = a.order.compareTo(b.order);
      if (orderCompare != 0) {
        return orderCompare;
      }

      final titleCompare = a.title.compareTo(b.title);
      if (titleCompare != 0) {
        return titleCompare;
      }

      return a.id.compareTo(b.id);
    });
    return sorted;
  }
}

class _CategorySummary extends StatelessWidget {
  const _CategorySummary({
    required this.category,
  });

  final ContentLibraryCategory category;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppLayout.gap(
              context,
              compact: 10,
              medium: 12,
              expanded: 14,
            ),
            runSpacing: AppLayout.gap(
              context,
              compact: 10,
              medium: 12,
              expanded: 14,
            ),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFD8BE74).withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppLayout.radius(context) * 0.56),
                  border: Border.all(
                    color: const Color(0xFFD8BE74).withOpacity(0.22),
                  ),
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
                  child: Text(
                    '${category.itemCount} عنصر',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFFD8BE74),
                        ),
                  ),
                ),
              ),
              if (category.sourceSummary != null)
                _MetaChip(text: category.sourceSummary!),
            ],
          ),
          SizedBox(
            height: AppLayout.gap(
              context,
              compact: 10,
              medium: 12,
              expanded: 14,
            ),
          ),
          Text(
            category.subtitle ?? 'اختر من هذا التصنيف ما تريد عرضه على الشاشة.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _LibraryItemCard extends ConsumerWidget {
  const _LibraryItemCard({
    required this.item,
    required this.metrics,
    this.autofocus = false,
  });

  final ContentItem item;
  final _HadithGridMetrics metrics;
  final bool autofocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final currentDayKey = ref.watch(
      dashboardControllerProvider.select(
        (state) => AppSettings.dayKeyFrom(state.now),
      ),
    );
    final effectiveMode = settings.effectiveContentSelectionModeForDayKey(
      currentDayKey,
    );
    final isSelected =
        settings.activeSelectedContentIdForDayKey(currentDayKey) == item.id;
    final isPinned = isSelected && effectiveMode == ContentSelectionMode.pinned;
    final isTodayOnly =
        isSelected && effectiveMode == ContentSelectionMode.selectedForToday;

    return _LibraryFocusableSurface(
      onPressed: () => _showItemDialog(context, ref),
      autofocus: autofocus,
      focusedScale: 1,
      child: SectionCard(
        padding: EdgeInsets.all(metrics.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: metrics.titleFontSize,
                          height: 1.28,
                        ),
                  ),
                ),
                SizedBox(width: metrics.inlineGap),
                if (isPinned)
                  const _ModeChip(
                    label: 'مثبت',
                    accent: Color(0xFFD8BE74),
                  )
                else if (isTodayOnly)
                  const _ModeChip(
                    label: 'اليوم',
                    accent: Color(0xFF58A890),
                  ),
              ],
            ),
            SizedBox(height: metrics.sectionGap),
            Text(
              item.collectionName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: metrics.collectionFontSize,
                    color: const Color(0xFFD8BE74),
                  ),
            ),
            SizedBox(height: metrics.metaGap),
            Wrap(
              spacing: metrics.inlineGap,
              runSpacing: metrics.metaGap,
              children: [
                _MetaChip(text: item.type.labelArabic),
                if (item.hadithNumber != null)
                  _MetaChip(text: 'رقم ${item.hadithNumber}'),
              ],
            ),
            SizedBox(height: metrics.sectionGap),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.035),
                  borderRadius: BorderRadius.circular(
                    AppLayout.radius(context) * 0.52,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.cardPadding * 0.72,
                    vertical: metrics.cardPadding * 0.58,
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      item.preview(maxChars: metrics.previewCharacters),
                      maxLines: metrics.previewLines,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.58,
                            fontSize: metrics.previewFontSize,
                            color: Colors.white.withOpacity(0.92),
                          ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: metrics.sectionGap),
            Text(
              item.source,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: metrics.sourceFontSize,
                    color: Colors.white.withOpacity(0.72),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showItemDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFF102C36),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 960,
            maxHeight: MediaQuery.sizeOf(dialogContext).height - 32,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppLayout.cardPadding(dialogContext)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style:
                      Theme.of(dialogContext).textTheme.displayMedium?.copyWith(
                            fontSize: AppLayout.fluid(
                              dialogContext,
                              min: 28,
                              max: 36,
                            ),
                          ),
                ),
                SizedBox(
                  height: AppLayout.gap(
                    dialogContext,
                    compact: 12,
                    medium: 14,
                    expanded: 16,
                  ),
                ),
                Wrap(
                  spacing: AppLayout.gap(
                    dialogContext,
                    compact: 8,
                    medium: 10,
                    expanded: 12,
                  ),
                  runSpacing: AppLayout.gap(
                    dialogContext,
                    compact: 8,
                    medium: 10,
                    expanded: 12,
                  ),
                  children: [
                    _MetaChip(text: item.type.labelArabic),
                    _MetaChip(text: item.collectionName),
                    if (item.hadithNumber != null)
                      _MetaChip(text: 'رقم ${item.hadithNumber}'),
                  ],
                ),
                SizedBox(
                  height: AppLayout.gap(
                    dialogContext,
                    compact: 12,
                    medium: 16,
                    expanded: 18,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      item.text,
                      style:
                          Theme.of(dialogContext).textTheme.bodyLarge?.copyWith(
                                fontSize: AppLayout.fluid(
                                  dialogContext,
                                  min: 20,
                                  max: 26,
                                ),
                              ),
                    ),
                  ),
                ),
                SizedBox(
                  height: AppLayout.gap(
                    dialogContext,
                    compact: 12,
                    medium: 16,
                    expanded: 18,
                  ),
                ),
                Text(
                  item.source,
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                SizedBox(
                  height: AppLayout.gap(
                    dialogContext,
                    compact: 14,
                    medium: 16,
                    expanded: 18,
                  ),
                ),
                Wrap(
                  spacing: AppLayout.gap(
                    dialogContext,
                    compact: 10,
                    medium: 12,
                    expanded: 14,
                  ),
                  runSpacing: AppLayout.gap(
                    dialogContext,
                    compact: 10,
                    medium: 12,
                    expanded: 14,
                  ),
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        await ref
                            .read(settingsControllerProvider.notifier)
                            .selectContentForToday(
                              contentId: item.id,
                              title: item.title,
                              now: ref.read(dashboardControllerProvider).now,
                            );
                        if (!dialogContext.mounted) {
                          return;
                        }
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تحديد المحتوى لعرضه اليوم.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.today_rounded),
                      label: const Text('عرض اليوم'),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        await ref
                            .read(settingsControllerProvider.notifier)
                            .pinContentSelection(
                              contentId: item.id,
                              title: item.title,
                            );
                        if (!dialogContext.mounted) {
                          return;
                        }
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تثبيت المحتوى على الشاشة.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.push_pin_rounded),
                      label: const Text('تثبيت في الشاشة'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(settingsControllerProvider.notifier)
                            .clearManualContentSelection();
                        if (!dialogContext.mounted) {
                          return;
                        }
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تمت العودة إلى الوضع التلقائي.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('الوضع التلقائي'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryFocusableSurface extends StatefulWidget {
  const _LibraryFocusableSurface({
    required this.child,
    required this.onPressed,
    this.autofocus = false,
    this.focusedScale = 1,
  });

  final Widget child;
  final VoidCallback onPressed;
  final bool autofocus;
  final double focusedScale;

  @override
  State<_LibraryFocusableSurface> createState() =>
      _LibraryFocusableSurfaceState();
}

class _LibraryFocusableSurfaceState extends State<_LibraryFocusableSurface> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final radius = AppLayout.radius(context) + 6;
    const focusColor = Color(0xFFD8BE74);

    return EnsureVisibleOnFocus(
      alignment: 0.18,
      child: FocusableActionDetector(
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
          scale: _focused ? widget.focusedScale : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: widget.onPressed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.all(_focused ? 4 : 0),
                decoration: BoxDecoration(
                  color: _focused
                      ? focusColor.withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color:
                        _focused ? focusColor : Colors.white.withOpacity(0.04),
                    width: _focused ? 3 : 1,
                  ),
                  boxShadow: _focused
                      ? [
                          BoxShadow(
                            color: focusColor.withOpacity(0.24),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : const <BoxShadow>[],
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HadithGridMetrics {
  const _HadithGridMetrics({
    required this.crossAxisCount,
    required this.gridSpacing,
    required this.cardHeight,
    required this.cardPadding,
    required this.titleFontSize,
    required this.collectionFontSize,
    required this.previewFontSize,
    required this.sourceFontSize,
    required this.previewLines,
    required this.previewCharacters,
    required this.sectionGap,
    required this.metaGap,
    required this.inlineGap,
  });

  factory _HadithGridMetrics.fromConstraints(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final viewportSize = MediaQuery.sizeOf(context);
    final gridSpacing = AppLayout.gap(
      context,
      compact: 14,
      medium: 18,
      expanded: 22,
    );
    final desiredCardWidth =
        (constraints.maxWidth * 0.28).clamp(320.0, 460.0) as double;
    final crossAxisCount = constraints.maxWidth < 640
        ? 1
        : ((constraints.maxWidth / desiredCardWidth).floor().clamp(2, 4))
            as int;
    final targetRows = constraints.maxHeight >= 520 ? 2 : 1;
    final minCardHeight =
        (viewportSize.height * 0.22).clamp(230.0, 280.0) as double;
    final maxCardHeight =
        (viewportSize.height * 0.34).clamp(300.0, 380.0) as double;
    final availableHeight =
        (constraints.maxHeight - (gridSpacing * (targetRows - 1))) / targetRows;
    final cardHeight =
        availableHeight.clamp(minCardHeight, maxCardHeight) as double;
    final compactCard = cardHeight < 300;

    return _HadithGridMetrics(
      crossAxisCount: crossAxisCount,
      gridSpacing: gridSpacing,
      cardHeight: cardHeight,
      cardPadding: AppLayout.cardPadding(context).clamp(18.0, 28.0) as double,
      titleFontSize: AppLayout.readableFluid(
        context,
        min: 22,
        max: 28,
        readableMin: 24,
      ),
      collectionFontSize: AppLayout.readableFluid(
        context,
        min: 18,
        max: 22,
        readableMin: 19,
      ),
      previewFontSize: AppLayout.readableFluid(
        context,
        min: 18,
        max: 24,
        readableMin: 20,
      ),
      sourceFontSize: AppLayout.readableFluid(
        context,
        min: 16,
        max: 20,
        readableMin: 17,
      ),
      previewLines: compactCard ? 2 : 3,
      previewCharacters: compactCard ? 110 : 150,
      sectionGap: AppLayout.gap(
        context,
        compact: 8,
        medium: 10,
        expanded: 12,
      ),
      metaGap: AppLayout.gap(
        context,
        compact: 6,
        medium: 8,
        expanded: 10,
      ),
      inlineGap: AppLayout.gap(
        context,
        compact: 8,
        medium: 10,
        expanded: 12,
      ),
    );
  }

  final int crossAxisCount;
  final double gridSpacing;
  final double cardHeight;
  final double cardPadding;
  final double titleFontSize;
  final double collectionFontSize;
  final double previewFontSize;
  final double sourceFontSize;
  final int previewLines;
  final int previewCharacters;
  final double sectionGap;
  final double metaGap;
  final double inlineGap;
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Center(
        child: Text(
          'لا يوجد محتوى متاح في المكتبة حاليًا.',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.52),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal:
              AppLayout.gap(context, compact: 8, medium: 10, expanded: 12),
          vertical: AppLayout.gap(context, compact: 4, medium: 5, expanded: 6),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: AppLayout.fluid(context, min: 16, max: 18),
              ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppLayout.radius(context) * 0.5),
        border: Border.all(color: accent.withOpacity(0.4)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal:
              AppLayout.gap(context, compact: 8, medium: 10, expanded: 12),
          vertical: AppLayout.gap(context, compact: 4, medium: 5, expanded: 6),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: accent,
              ),
        ),
      ),
    );
  }
}
