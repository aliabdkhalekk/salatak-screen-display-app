import 'display_state_service.dart';

export 'display_state_service.dart'
    show DisplayStateService, displayStateServiceProvider;

typedef PrayerSchedulerService = DisplayStateService;

final prayerSchedulerServiceProvider = displayStateServiceProvider;
