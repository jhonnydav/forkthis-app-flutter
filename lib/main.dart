import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'state/app_state.dart';
import 'theme/theme.dart';

void main() {
  // Route uncaught errors to a single place instead of letting them surface as
  // silent failures (a bare Flutter exception during build/layout otherwise just
  // logs to the device console, which nobody watches once this ships).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack, library: 'nutrition_platform'),
    );
    return true;
  };

  runZonedGuarded(
    () => runApp(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const NutritionPlatformApp(),
      ),
    ),
    (error, stack) => FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack, library: 'nutrition_platform'),
    ),
  );
}

class NutritionPlatformApp extends StatelessWidget {
  const NutritionPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nutrition Platform',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: appRouter,
    );
  }
}
