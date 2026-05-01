import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  await AppBootstrap.ensureInitialized();
  runApp(const ProviderScope(child: SalatakSmartDisplayApp()));
}
