import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'state/app_state.dart';
import 'theme/theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const NutritionPlatformApp(),
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
