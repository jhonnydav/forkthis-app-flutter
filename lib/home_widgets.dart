import 'dart:async';
import 'dart:developer' as developer;
import 'package:home_widget/home_widget.dart';
import 'router.dart';

/// Bridges app state to the iOS Home Screen widgets (see `ios/NutritionWidgets`).
/// Shared storage is an App Group `UserDefaults` suite — [appGroupId] here must
/// match the group configured on both the Runner and NutritionWidgets Xcode
/// targets' entitlements.
const appGroupId = 'group.com.nutritionplatform.nutritionPlatform';

/// Widget `kind` identifiers — must match the `kind:` string each `Widget`
/// struct declares in `ios/NutritionWidgets/NutritionWidgetsBundle.swift`.
/// `WidgetCenter.reloadTimelines(ofKind:)` only refreshes the kind it's given,
/// so every kind that reads changed data needs its own reload call.
const _momentumWidgetKind = 'MomentumWidget';
const _todayWidgetKind = 'TodayWidget';
const _forkThisWidgetKind = 'ForkThisMomentWidget';

/// Call once at startup, before the first [AppState] persist. Registers the
/// App Group and starts listening for taps on a widget (the `forkthis://`
/// scheme registered in Info.plist), routing straight to the relevant tab
/// instead of just cold-launching to whatever screen was last open.
Future<void> initHomeWidgets() async {
  await HomeWidget.setAppGroupId(appGroupId);

  void route(Uri? uri) {
    if (uri == null) return;
    switch (uri.host) {
      case 'forkthis-moment':
        appRouter.go('/home');
      case 'track':
        appRouter.go('/track');
      default:
        appRouter.go('/home');
    }
  }

  try {
    route(await HomeWidget.initiallyLaunchedFromHomeWidget());
  } catch (error) {
    developer.log('Home widget initial-launch check failed: $error');
  }
  HomeWidget.widgetClicked.listen(route);
}

/// Pushes the latest snapshot to the widgets' shared storage and asks
/// WidgetKit to redraw every kind. Called from [AppState.persist] — widget
/// sync failures (no App Group entitlement on a plain simulator run, etc.)
/// must never block saving app data, so every call site swallows its errors.
Future<void> syncHomeWidgets({
  required int momentumPoints,
  required int streakDays,
  required int todayCalories,
  required int todayProtein,
  required int todayWaterCups,
}) async {
  try {
    await Future.wait([
      HomeWidget.saveWidgetData<int>('momentum_points', momentumPoints),
      HomeWidget.saveWidgetData<int>('streak_days', streakDays),
      HomeWidget.saveWidgetData<int>('today_calories', todayCalories),
      HomeWidget.saveWidgetData<int>('today_protein', todayProtein),
      HomeWidget.saveWidgetData<int>('today_water', todayWaterCups),
    ]);
    await Future.wait([
      HomeWidget.updateWidget(iOSName: _momentumWidgetKind),
      HomeWidget.updateWidget(iOSName: _todayWidgetKind),
      HomeWidget.updateWidget(iOSName: _forkThisWidgetKind),
    ]);
  } catch (error) {
    developer.log('Home widget sync failed: $error');
  }
}
