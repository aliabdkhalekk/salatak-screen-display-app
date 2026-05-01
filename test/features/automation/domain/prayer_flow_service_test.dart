import 'package:flutter_test/flutter_test.dart';

import 'package:salatak_smart_display/features/automation/domain/prayer_flow_models.dart';
import 'package:salatak_smart_display/features/automation/domain/prayer_scheduler_service.dart';
import 'package:salatak_smart_display/features/prayer/domain/prayer_models.dart';
import 'package:salatak_smart_display/features/settings/domain/app_settings.dart';

void main() {
  const service = PrayerSchedulerService();
  final settings = AppSettings.defaults();

  test('enters pre-prayer before the next prayer', () {
    final now = DateTime(2026, 4, 9, 11, 55);
    final snapshot = service.resolve(
      now: now,
      prayerDay: _prayerDay(now),
      settings: settings,
    );

    expect(snapshot.mode, DisplayStateMode.duaEntry);
    expect(snapshot.prayer, PrayerName.dhuhr);
    expect(snapshot.primaryItem?.id, 'entry_dua');
  });

  test('shows prayer time at adhan', () {
    final now = DateTime(2026, 4, 9, 12);
    final snapshot = service.resolve(
      now: now,
      prayerDay: _prayerDay(now),
      settings: settings,
    );

    expect(snapshot.mode, DisplayStateMode.prayerTime);
    expect(snapshot.prayer, PrayerName.dhuhr);
  });

  test('moves through azkar, exit dua, and sleep after prayer', () {
    final azkar = service.resolve(
      now: DateTime(2026, 4, 9, 12, 31),
      prayerDay: _prayerDay(DateTime(2026, 4, 9, 12, 31)),
      settings: settings,
    );
    final exit = service.resolve(
      now: DateTime(2026, 4, 9, 12, 55),
      prayerDay: _prayerDay(DateTime(2026, 4, 9, 12, 55)),
      settings: settings,
    );
    final sleep = service.resolve(
      now: DateTime(2026, 4, 9, 13, 15),
      prayerDay: _prayerDay(DateTime(2026, 4, 9, 13, 15)),
      settings: settings,
    );

    expect(azkar.mode, DisplayStateMode.postPrayerAzkar);
    expect(azkar.azkarItems, isNotEmpty);
    expect(exit.mode, DisplayStateMode.duaExit);
    expect(exit.primaryItem?.id, 'exit_dua');
    expect(sleep.mode, DisplayStateMode.blackScreen);
  });

  test('manual override disables automation', () {
    final now = DateTime(2026, 4, 9, 11, 55);
    final snapshot = service.resolve(
      now: now,
      prayerDay: _prayerDay(now),
      settings: settings.copyWith(manualOverrideMode: true),
    );

    expect(snapshot.mode, DisplayStateMode.blackScreen);
  });

  test('skips disabled phases', () {
    final now = DateTime(2026, 4, 9, 12, 31);
    final snapshot = service.resolve(
      now: now,
      prayerDay: _prayerDay(now),
      settings: settings.copyWith(
        afterPrayerAzkarEnabled: false,
        exitDuaEnabled: true,
      ),
    );

    expect(snapshot.mode, DisplayStateMode.duaExit);
  });
}

PrayerDayInfo _prayerDay(DateTime now) {
  final entries = <PrayerTimeEntry>[
    PrayerTimeEntry(
      name: PrayerName.fajr,
      time: DateTime(2026, 4, 9, 5),
    ),
    PrayerTimeEntry(
      name: PrayerName.dhuhr,
      time: DateTime(2026, 4, 9, 12),
    ),
    PrayerTimeEntry(
      name: PrayerName.asr,
      time: DateTime(2026, 4, 9, 15),
    ),
    PrayerTimeEntry(
      name: PrayerName.maghrib,
      time: DateTime(2026, 4, 9, 18),
    ),
    PrayerTimeEntry(
      name: PrayerName.isha,
      time: DateTime(2026, 4, 9, 20),
    ),
  ];
  final nextPrayer = entries.firstWhere((entry) => entry.time.isAfter(now));
  final lastPrayer =
      entries.where((entry) => !entry.time.isAfter(now)).lastOrNull ??
          entries.first;

  return PrayerDayInfo(
    todayEntries: entries,
    nextPrayer: nextPrayer,
    lastPrayer: lastPrayer,
    timeUntilNextPrayer: nextPrayer.time.difference(now),
  );
}

extension _LastOrNullX<T> on Iterable<T> {
  T? get lastOrNull => this.isEmpty ? null : last;
}
