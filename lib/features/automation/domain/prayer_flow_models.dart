import '../../prayer/domain/prayer_models.dart';
import 'zikr_content.dart';

enum DisplayStateMode {
  blackScreen,
  duaEntry,
  prayerTime,
  postPrayerAzkar,
  duaExit,
}

extension DisplayStateModeX on DisplayStateMode {
  String get labelArabic {
    switch (this) {
      case DisplayStateMode.blackScreen:
        return 'شاشة سوداء';
      case DisplayStateMode.duaEntry:
        return 'دعاء دخول المسجد';
      case DisplayStateMode.prayerTime:
        return 'وقت الصلاة';
      case DisplayStateMode.postPrayerAzkar:
        return 'أذكار بعد الصلاة';
      case DisplayStateMode.duaExit:
        return 'دعاء الخروج من المسجد';
    }
  }

  bool get keepsScreenAwake => this != DisplayStateMode.blackScreen;
}

class PrayerFlowSnapshot {
  const PrayerFlowSnapshot({
    required this.mode,
    required this.prayer,
    required this.stageStartedAt,
    required this.stageEndsAt,
    required this.nextTransitionAt,
    required this.entryDua,
    required this.exitDua,
    required this.azkarItems,
  });

  factory PrayerFlowSnapshot.black({
    DateTime? nextTransitionAt,
  }) {
    return PrayerFlowSnapshot(
      mode: DisplayStateMode.blackScreen,
      prayer: null,
      stageStartedAt: null,
      stageEndsAt: null,
      nextTransitionAt: nextTransitionAt,
      entryDua: null,
      exitDua: null,
      azkarItems: const <ZikrContent>[],
    );
  }

  final DisplayStateMode mode;
  final PrayerName? prayer;
  final DateTime? stageStartedAt;
  final DateTime? stageEndsAt;
  final DateTime? nextTransitionAt;
  final ZikrContent? entryDua;
  final ZikrContent? exitDua;
  final List<ZikrContent> azkarItems;

  ZikrContent? get primaryItem {
    switch (mode) {
      case DisplayStateMode.duaEntry:
        return entryDua;
      case DisplayStateMode.duaExit:
        return exitDua;
      case DisplayStateMode.blackScreen:
      case DisplayStateMode.prayerTime:
      case DisplayStateMode.postPrayerAzkar:
        return null;
    }
  }

  Duration? remainingFrom(DateTime now) {
    final end = stageEndsAt;
    if (end == null) {
      return null;
    }
    final remaining = end.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String get sideEffectKey {
    final prayerKey = prayer?.name ?? 'none';
    final startKey = stageStartedAt?.millisecondsSinceEpoch ?? 0;
    return '${mode.name}_${prayerKey}_$startKey';
  }
}
