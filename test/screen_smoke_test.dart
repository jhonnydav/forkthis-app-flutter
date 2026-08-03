import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrition_platform/screens/cook_screen.dart';
import 'package:nutrition_platform/screens/eat_out_screen.dart';
import 'package:nutrition_platform/screens/hack_detail_screen.dart';
import 'package:nutrition_platform/screens/home_screen.dart';
import 'package:nutrition_platform/screens/restaurant_detail_screen.dart';
import 'package:nutrition_platform/screens/search_screen.dart';
import 'package:nutrition_platform/screens/track_screen.dart';
import 'package:nutrition_platform/screens/you_screen.dart';
import 'package:nutrition_platform/state/app_state.dart';
import 'package:nutrition_platform/theme/theme.dart';

Widget testApp(String initialLocation, AppState state) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/eat-out', builder: (_, _) => const EatOutScreen()),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(path: '/cook', builder: (_, _) => const CookScreen()),
      GoRoute(path: '/track', builder: (_, _) => const TrackScreen()),
      GoRoute(path: '/you', builder: (_, _) => const YouScreen()),
      GoRoute(
        path: '/restaurant/:id',
        builder: (_, route) =>
            RestaurantDetailScreen(id: route.pathParameters['id']!),
      ),
      GoRoute(
        path: '/hack/:id',
        builder: (_, route) =>
            HackDetailScreen(id: route.pathParameters['id']!),
      ),
      GoRoute(
        path: '/cook/recipe/:id',
        builder: (_, route) =>
            RecipeDetailScreen(id: route.pathParameters['id']!),
      ),
    ],
  );
  return ChangeNotifierProvider.value(
    value: state,
    child: MaterialApp.router(theme: appTheme, routerConfig: router),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  final routes = {
    '/home': 'Today feels manageable.',
    '/eat-out': 'A better order,',
    '/search': 'What would make today easier?',
    '/cook': 'What fits tonight?',
    '/track': 'A record, not a report card',
    '/you': 'What shapes your recommendations',
    '/restaurant/pollo-perch': 'The useful choices first',
    '/hack/pp-kale-strips': 'Kale salad + grilled strips',
    '/cook/recipe/chicken-sweet-potato': 'Baked chicken and sweet potato',
  };

  for (final entry in routes.entries) {
    testWidgets('${entry.key} renders at a large text setting', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.35;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final state = AppState();
      await tester.pumpWidget(testApp(entry.key, state));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining(entry.value), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
