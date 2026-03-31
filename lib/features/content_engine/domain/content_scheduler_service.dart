import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../friday/domain/friday_mode_service.dart';
import '../../prayer/domain/prayer_models.dart';
import '../../settings/domain/app_settings.dart';
import 'content_catalog.dart';
import 'content_item.dart';
import 'content_phase.dart';

final contentSchedulerServiceProvider = Provider<ContentSchedulerService>(
  (ref) => ContentSchedulerService(
    fridayModeService: ref.read(fridayModeServiceProvider),
  ),
);

class ContentSchedulerService {
  const ContentSchedulerService({
    required FridayModeService fridayModeService,
  }) : _fridayModeService = fridayModeService;

  final FridayModeService _fridayModeService;

  ScheduledContent resolve({
    required DateTime now,
    required PrayerDayInfo prayerDay,
    required ContentCatalog catalog,
    required AppSettings settings,
  }) {
    final manualOverride = _resolveManualOverride(
      now: now,
      catalog: catalog,
      settings: settings,
    );
    if (manualOverride != null) {
      return manualOverride;
    }

    final prePrayerWindow = Duration(
      minutes: settings.prePrayerWindowMinutes,
    );
    final postPrayerWindow = Duration(
      minutes: settings.postPrayerWindowMinutes,
    );
    final timeUntilNextPrayer = prayerDay.nextPrayer.time.difference(now);
    final timeSinceLastPrayer = now.difference(prayerDay.lastPrayer.time);

    if (!timeUntilNextPrayer.isNegative &&
        timeUntilNextPrayer <= prePrayerWindow) {
      return ScheduledContent(
        item: _resolvePrayerWindowItem(
          now: now,
          prayer: prayerDay.nextPrayer.name,
          context: DisplayContext.beforePrayerSpecific,
          requiredTag: 'mosque_entry',
          catalog: catalog,
          fallback: _entranceMasjidDua,
        ),
        phase: ContentPhase.beforePrayerSpecific,
      );
    }

    if (!timeSinceLastPrayer.isNegative &&
        timeSinceLastPrayer <= postPrayerWindow) {
      return ScheduledContent(
        item: _resolvePrayerWindowItem(
          now: now,
          prayer: prayerDay.lastPrayer.name,
          context: DisplayContext.afterPrayer,
          requiredTag: 'mosque_exit',
          catalog: catalog,
          fallback: _exitMasjidDua,
        ),
        phase: ContentPhase.postPrayerSequence,
      );
    }

    if (_fridayModeService.isFriday(now)) {
      return ScheduledContent(
        item: _resolveFridayItem(now, catalog),
        phase: ContentPhase.friday,
      );
    }

    return ScheduledContent(
      item: _resolveDailyNawawi(now, catalog),
      phase: ContentPhase.general,
    );
  }

  ScheduledContent? _resolveManualOverride({
    required DateTime now,
    required ContentCatalog catalog,
    required AppSettings settings,
  }) {
    final mode = settings.effectiveContentSelectionMode(now);
    if (mode == ContentSelectionMode.auto) {
      return null;
    }

    final selectedContentId = settings.activeSelectedContentId(now);
    if (selectedContentId == null) {
      return null;
    }

    final item = catalog.itemById(selectedContentId);
    if (item == null) {
      return null;
    }

    return ScheduledContent(
      item: item,
      phase: mode == ContentSelectionMode.selectedForToday
          ? ContentPhase.manualToday
          : ContentPhase.manualPinned,
    );
  }

  ContentItem _resolvePrayerWindowItem({
    required DateTime now,
    required PrayerName prayer,
    required DisplayContext context,
    required String requiredTag,
    required ContentCatalog catalog,
    required ContentItem fallback,
  }) {
    final windowItems = catalog.filter(
      contexts: {context},
      prayer: prayer,
      tags: {requiredTag},
    );
    if (windowItems.isEmpty) {
      return fallback;
    }

    final slot = _fridayModeService.daySeed(now) + prayer.index;
    return windowItems[slot % windowItems.length];
  }

  ContentItem _resolveFridayItem(DateTime now, ContentCatalog catalog) {
    final fridayItems = catalog.filter(
      contexts: const {DisplayContext.friday},
      types: const {ContentType.friday},
      tags: const {'friday_content'},
    );
    if (fridayItems.isEmpty) {
      return _withTagAndCategory(
        ContentItem.fallback(
          id: 'fallback_friday',
          title: 'فضل يوم الجمعة',
          text:
              'أكثروا من الصلاة على النبي صلى الله عليه وسلم، واقرؤوا سورة الكهف، وتحَرَّوا ساعة الإجابة، وبكِّروا إلى الجمعة.',
          source: 'تذكير الجمعة',
          type: ContentType.friday,
          displayContexts: const [
            DisplayContext.friday,
            DisplayContext.general,
          ],
        ),
        tag: 'friday_content',
        category: 'ركن الجمعة',
      );
    }

    final slot = (_fridayModeService.daySeed(now) * 48) +
        _fridayModeService.halfHourSlot(now);
    final item = fridayItems[slot % fridayItems.length];
    return _withTagAndCategory(
      item,
      tag: 'friday_content',
      category: 'ركن الجمعة',
    );
  }

  ContentItem _resolveDailyNawawi(DateTime now, ContentCatalog catalog) {
    final nawawiItems = catalog.nawawiItems;
    if (nawawiItems.isEmpty) {
      return _withTagAndCategory(
        ContentItem.fallback(
          id: 'fallback_daily_hadith',
          title: 'حديث اليوم',
          text:
              'احرص على ذكر الله تعالى، والمحافظة على الصلاة في وقتها، وتعظيم شعائر الله في يومك كله.',
          source: 'محتوى محلي',
          type: ContentType.hadith,
          displayContexts: const [
            DisplayContext.general,
            DisplayContext.betweenPrayers,
          ],
        ),
        tag: 'nawawi_daily',
        category: 'الحديث اليومي',
      );
    }

    final daySeed = _fridayModeService.daySeed(now);
    return _withTagAndCategory(
      nawawiItems[daySeed % nawawiItems.length],
      tag: 'nawawi_daily',
      category: 'الحديث اليومي',
    );
  }
}

class ScheduledContent {
  const ScheduledContent({
    required this.item,
    required this.phase,
  });

  final ContentItem item;
  final ContentPhase phase;
}

final ContentItem _entranceMasjidDua = ContentItem(
  id: 'dua_masjid_entry',
  title: 'دعاء دخول المسجد',
  text:
      'بِسْمِ اللَّهِ، وَالصَّلَاةُ وَالسَّلَامُ عَلَى رَسُولِ اللَّهِ، اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ.',
  source: 'رواه مسلم',
  tags: <String>['mosque_entry', 'prayer_window'],
  priority: 100,
  displayContexts: <DisplayContext>[
    DisplayContext.beforePrayerSpecific,
  ],
  type: ContentType.adhkar,
  category: 'دخول المسجد',
);

final ContentItem _exitMasjidDua = ContentItem(
  id: 'dua_masjid_exit',
  title: 'دعاء الخروج من المسجد',
  text:
      'بِسْمِ اللَّهِ، وَالصَّلَاةُ وَالسَّلَامُ عَلَى رَسُولِ اللَّهِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ.',
  source: 'رواه مسلم',
  tags: <String>['mosque_exit', 'prayer_window'],
  priority: 100,
  displayContexts: <DisplayContext>[
    DisplayContext.afterPrayer,
  ],
  type: ContentType.adhkar,
  category: 'الخروج من المسجد',
);

ContentItem _withTagAndCategory(
  ContentItem item, {
  required String tag,
  required String category,
}) {
  final tags = item.tags.contains(tag)
      ? item.tags
      : <String>[...item.tags, tag];
  return item.copyWith(
    tags: tags,
    category: item.category?.trim().isNotEmpty == true ? item.category : category,
  );
}
