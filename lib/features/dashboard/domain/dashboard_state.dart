import '../../automation/domain/prayer_flow_models.dart';
import '../../hijri/domain/hijri_date.dart';
import '../../prayer/domain/prayer_models.dart';

class DashboardState {
  const DashboardState({
    required this.isLoading,
    required this.now,
    this.hijriDate,
    this.prayerDay,
    this.automation = const PrayerFlowSnapshot(
      mode: DisplayStateMode.blackScreen,
      prayer: null,
      stageStartedAt: null,
      stageEndsAt: null,
      nextTransitionAt: null,
      entryDua: null,
      exitDua: null,
      azkarItems: [],
    ),
    this.errorMessage,
  });

  factory DashboardState.loading({
    DateTime? now,
  }) {
    return DashboardState(
      isLoading: true,
      now: now ?? DateTime.now(),
    );
  }

  final bool isLoading;
  final DateTime now;
  final HijriDate? hijriDate;
  final PrayerDayInfo? prayerDay;
  final PrayerFlowSnapshot automation;
  final String? errorMessage;

  DashboardState copyWith({
    bool? isLoading,
    DateTime? now,
    HijriDate? hijriDate,
    PrayerDayInfo? prayerDay,
    PrayerFlowSnapshot? automation,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      now: now ?? this.now,
      hijriDate: hijriDate ?? this.hijriDate,
      prayerDay: prayerDay ?? this.prayerDay,
      automation: automation ?? this.automation,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
