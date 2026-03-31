import 'package:flutter_riverpod/flutter_riverpod.dart';

final fridayModeServiceProvider = Provider<FridayModeService>(
  (ref) => FridayModeService(),
);

class FridayModeService {
  bool isFriday(DateTime now) => now.weekday == DateTime.friday;

  int daySeed(DateTime now) {
    final normalized = DateTime.utc(now.year, now.month, now.day);
    return normalized.difference(DateTime.utc(2024, 1, 1)).inDays.abs();
  }

  int halfHourSlot(DateTime now) {
    final minutesSinceMidnight = (now.hour * 60) + now.minute;
    return minutesSinceMidnight ~/ 30;
  }
}
