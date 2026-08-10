import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'product.dart';
import 'home_widgets.dart';
import 'state/app_state.dart';
import 'theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initHomeWidgets();
  // Route uncaught errors to a single place instead of letting them surface as
  // silent failures (a bare Flutter exception during build/layout otherwise just
  // logs to the device console, which nobody watches once this ships).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'nutrition_platform',
      ),
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
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'nutrition_platform',
      ),
    ),
  );
}

class NutritionPlatformApp extends StatelessWidget {
  const NutritionPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: productName,
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: appRouter,
      builder: (context, child) => _ResponsiveDemoFrame(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _ResponsiveDemoFrame extends StatelessWidget {
  final Widget child;
  const _ResponsiveDemoFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 600) return child;
        return ColoredBox(
          color: const Color(0xFFF0D8A8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
