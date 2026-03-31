import '../../content_engine/domain/content_item.dart';
import '../../content_engine/domain/content_phase.dart';
import '../../hijri/domain/hijri_date.dart';
import '../../prayer/domain/prayer_models.dart';

class ContentSequenceStep {
  const ContentSequenceStep({
    required this.label,
    required this.item,
  });

  final String label;
  final ContentItem item;
}

class DashboardState {
  const DashboardState({
    required this.isLoading,
    required this.now,
    this.hijriDate,
    this.prayerDay,
    this.activeContent,
    this.phase = ContentPhase.loading,
    this.isFriday = false,
    this.sequenceSteps = const <ContentSequenceStep>[],
    this.activeSequenceIndex = 0,
    this.nawawiItems = const <ContentItem>[],
    this.libraryItems = const <ContentItem>[],
  });

  final bool isLoading;
  final DateTime now;
  final HijriDate? hijriDate;
  final PrayerDayInfo? prayerDay;
  final ContentItem? activeContent;
  final ContentPhase phase;
  final bool isFriday;
  final List<ContentSequenceStep> sequenceSteps;
  final int activeSequenceIndex;
  final List<ContentItem> nawawiItems;
  final List<ContentItem> libraryItems;

  factory DashboardState.loading({
    DateTime? now,
  }) {
    return DashboardState(
      isLoading: true,
      now: now ?? DateTime.now(),
    );
  }

  bool get isPostPrayerSequence => sequenceSteps.isNotEmpty;

  ContentSequenceStep? get currentSequenceStep {
    if (sequenceSteps.isEmpty || activeSequenceIndex >= sequenceSteps.length) {
      return null;
    }
    return sequenceSteps[activeSequenceIndex];
  }

  DashboardState copyWith({
    bool? isLoading,
    DateTime? now,
    HijriDate? hijriDate,
    PrayerDayInfo? prayerDay,
    ContentItem? activeContent,
    ContentPhase? phase,
    bool? isFriday,
    List<ContentSequenceStep>? sequenceSteps,
    int? activeSequenceIndex,
    List<ContentItem>? nawawiItems,
    List<ContentItem>? libraryItems,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      now: now ?? this.now,
      hijriDate: hijriDate ?? this.hijriDate,
      prayerDay: prayerDay ?? this.prayerDay,
      activeContent: activeContent ?? this.activeContent,
      phase: phase ?? this.phase,
      isFriday: isFriday ?? this.isFriday,
      sequenceSteps: sequenceSteps ?? this.sequenceSteps,
      activeSequenceIndex: activeSequenceIndex ?? this.activeSequenceIndex,
      nawawiItems: nawawiItems ?? this.nawawiItems,
      libraryItems: libraryItems ?? this.libraryItems,
    );
  }
}
