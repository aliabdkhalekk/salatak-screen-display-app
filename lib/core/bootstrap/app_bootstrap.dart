import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../storage/hive_boxes.dart';

abstract final class AppBootstrap {
  static Future<void> ensureInitialized() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('ar');
    tz_data.initializeTimeZones();
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(HiveBoxes.settings);
    await Hive.openBox<String>(HiveBoxes.cache);

    if (_supportsImmersiveLandscape()) {
      await SystemChrome.setPreferredOrientations(
        const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
      );
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIChangeCallback((overlaysVisible) async {
        if (overlaysVisible) {
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.immersiveSticky,
          );
        }
      });
    }
  }

  static bool _supportsImmersiveLandscape() {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}
