import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../prayer/domain/prayer_models.dart';
import '../../settings/domain/app_settings.dart';
import 'prayer_flow_models.dart';
import 'zikr_content.dart';

final displayStateServiceProvider = Provider<DisplayStateService>(
  (ref) => const DisplayStateService(),
);

class DisplayStateService {
  const DisplayStateService();

  static const Duration _prayerTimeDuration = Duration(minutes: 1);

  PrayerFlowSnapshot resolve({
    required DateTime now,
    required PrayerDayInfo prayerDay,
    required AppSettings settings,
  }) {
    final windows = _candidateEntries(prayerDay)
        .map((entry) => _DisplayWindow.from(entry, settings))
        .toList(growable: false);

    if (settings.manualOverrideMode) {
      return PrayerFlowSnapshot.black(
        nextTransitionAt: _nextTransition(now, windows),
      );
    }

    final prayerTime = _firstWhereOrNull(
      windows,
      (window) => window.containsPrayerTime(now),
    );
    if (prayerTime != null) {
      return _snapshot(
        mode: DisplayStateMode.prayerTime,
        prayer: prayerTime.prayer.name,
        start: prayerTime.prayerTimeStart,
        end: prayerTime.prayerTimeEnd,
        nextTransitionAt: prayerTime.prayerTimeEnd,
      );
    }

    final azkar = _firstWhereOrNull(
      windows,
      (window) => window.containsAzkar(now),
    );
    if (azkar != null) {
      return _snapshot(
        mode: DisplayStateMode.postPrayerAzkar,
        prayer: azkar.prayer.name,
        start: azkar.azkarStart,
        end: azkar.azkarEnd,
        nextTransitionAt: azkar.azkarEnd,
        azkarItems: _azkarFor(azkar.prayer.name),
      );
    }

    final entry = _firstWhereOrNull(
      windows,
      (window) => window.containsEntryDua(now),
    );
    if (entry != null) {
      return _snapshot(
        mode: DisplayStateMode.duaEntry,
        prayer: entry.prayer.name,
        start: entry.entryStart,
        end: entry.entryEnd,
        nextTransitionAt: entry.entryEnd,
        entryDua: entryDuaContent,
      );
    }

    final exit = _firstWhereOrNull(
      windows,
      (window) => window.containsExitDua(now),
    );
    if (exit != null) {
      return _snapshot(
        mode: DisplayStateMode.duaExit,
        prayer: exit.prayer.name,
        start: exit.exitStart,
        end: exit.exitEnd,
        nextTransitionAt: exit.exitEnd,
        exitDua: exitDuaContent,
      );
    }

    return PrayerFlowSnapshot.black(
      nextTransitionAt: _nextTransition(now, windows),
    );
  }

  List<PrayerTimeEntry> _candidateEntries(PrayerDayInfo prayerDay) {
    final entries = <PrayerTimeEntry>[
      ...prayerDay.todayEntries,
      prayerDay.lastPrayer,
      prayerDay.nextPrayer,
    ];
    final seen = <String>{};
    final uniqueEntries = <PrayerTimeEntry>[];
    for (final entry in entries) {
      final key = '${entry.name.name}_${entry.time.millisecondsSinceEpoch}';
      if (seen.add(key)) {
        uniqueEntries.add(entry);
      }
    }
    uniqueEntries.sort((a, b) => a.time.compareTo(b.time));
    return uniqueEntries;
  }

  List<ZikrContent> _azkarFor(PrayerName prayer) {
    return afterPrayerAzkarContent
        .where((content) => content.appliesTo(prayer))
        .toList(growable: false);
  }

  PrayerFlowSnapshot _snapshot({
    required DisplayStateMode mode,
    required PrayerName prayer,
    required DateTime start,
    required DateTime end,
    required DateTime nextTransitionAt,
    ZikrContent? entryDua,
    ZikrContent? exitDua,
    List<ZikrContent> azkarItems = const <ZikrContent>[],
  }) {
    return PrayerFlowSnapshot(
      mode: mode,
      prayer: prayer,
      stageStartedAt: start,
      stageEndsAt: end,
      nextTransitionAt: nextTransitionAt,
      entryDua: entryDua,
      exitDua: exitDua,
      azkarItems: azkarItems,
    );
  }

  DateTime? _nextTransition(DateTime now, List<_DisplayWindow> windows) {
    final candidates = <DateTime>[];
    for (final window in windows) {
      candidates.addAll(window.transitionTimes);
    }
    final future = candidates.where((time) => time.isAfter(now)).toList()
      ..sort();
    return future.isEmpty ? null : future.first;
  }
}

class _DisplayWindow {
  const _DisplayWindow({
    required this.prayer,
    required this.entryEnabled,
    required this.azkarEnabled,
    required this.exitEnabled,
    required this.entryStart,
    required this.entryEnd,
    required this.prayerTimeStart,
    required this.prayerTimeEnd,
    required this.azkarStart,
    required this.azkarEnd,
    required this.exitStart,
    required this.exitEnd,
  });

  factory _DisplayWindow.from(PrayerTimeEntry prayer, AppSettings settings) {
    final entryStart = prayer.time.subtract(
      Duration(minutes: settings.prePrayerWindowMinutes),
    );
    final requestedEntryEnd = entryStart.add(
      Duration(minutes: settings.entryDuaDurationMinutes),
    );
    final entryEnd = requestedEntryEnd.isBefore(prayer.time)
        ? requestedEntryEnd
        : prayer.time;
    final prayerTimeStart = prayer.time;
    final prayerTimeEnd =
        prayer.time.add(DisplayStateService._prayerTimeDuration);
    final azkarStart = prayer.time.add(
      Duration(minutes: settings.afterAdhanAzkarStartOffsetMinutes),
    );
    final azkarEnd = azkarStart.add(
      Duration(minutes: settings.azkarDurationMinutes),
    );
    final exitStart = settings.afterPrayerAzkarEnabled ? azkarEnd : azkarStart;
    final exitEnd = exitStart.add(
      Duration(minutes: settings.exitDuaDurationMinutes),
    );

    return _DisplayWindow(
      prayer: prayer,
      entryEnabled: settings.entryDuaEnabled,
      azkarEnabled: settings.afterPrayerAzkarEnabled,
      exitEnabled: settings.exitDuaEnabled,
      entryStart: entryStart,
      entryEnd: entryEnd,
      prayerTimeStart: prayerTimeStart,
      prayerTimeEnd: prayerTimeEnd,
      azkarStart: azkarStart,
      azkarEnd: azkarEnd,
      exitStart: exitStart,
      exitEnd: exitEnd,
    );
  }

  final PrayerTimeEntry prayer;
  final bool entryEnabled;
  final bool azkarEnabled;
  final bool exitEnabled;
  final DateTime entryStart;
  final DateTime entryEnd;
  final DateTime prayerTimeStart;
  final DateTime prayerTimeEnd;
  final DateTime azkarStart;
  final DateTime azkarEnd;
  final DateTime exitStart;
  final DateTime exitEnd;

  List<DateTime> get transitionTimes {
    return <DateTime>[
      if (entryEnabled) ...[entryStart, entryEnd],
      prayerTimeStart,
      prayerTimeEnd,
      if (azkarEnabled) ...[azkarStart, azkarEnd],
      if (exitEnabled) ...[exitStart, exitEnd],
    ];
  }

  bool containsEntryDua(DateTime now) {
    return entryEnabled && _contains(now, entryStart, entryEnd);
  }

  bool containsPrayerTime(DateTime now) {
    return _contains(now, prayerTimeStart, prayerTimeEnd);
  }

  bool containsAzkar(DateTime now) {
    return azkarEnabled && _contains(now, azkarStart, azkarEnd);
  }

  bool containsExitDua(DateTime now) {
    return exitEnabled && _contains(now, exitStart, exitEnd);
  }

  bool _contains(DateTime now, DateTime start, DateTime end) {
    return !now.isBefore(start) && now.isBefore(end);
  }
}

T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T value) test) {
  for (final value in values) {
    if (test(value)) {
      return value;
    }
  }
  return null;
}
