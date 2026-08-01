import 'package:go_router/go_router.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/eat_out_screen.dart';
import 'screens/search_screen.dart';
import 'screens/restaurant_detail_screen.dart';
import 'screens/hack_detail_screen.dart';
import 'screens/cook_screen.dart';
import 'screens/track_screen.dart';
import 'screens/you_screen.dart';

/// Route paths mirror `../app/src/App.tsx` closely — `/onboarding?step=N`,
/// `/eat-out?view=&data=&category=`, `/hack/:id`, `/search?q=` — so anyone who knows
/// the web app's URLs can find the equivalent Flutter screen without a lookup table.
/// go_router gives every one of these query-param states a real, shareable route,
/// same as the web app's URL-addressable states (though there is no in-app screen
/// index here — see app-flutter/README.md for why).
final GoRouter appRouter = GoRouter(
  initialLocation: '/onboarding?step=0',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) {
        final step = int.tryParse(state.uri.queryParameters['step'] ?? '0') ?? 0;
        return OnboardingScreen(step: step);
      },
    ),
    GoRoute(
      path: '/onboarding/resume',
      builder: (context, state) => const OnboardingResumeScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/eat-out',
      builder: (context, state) => EatOutScreen(
        view: state.uri.queryParameters['view'] ?? 'restaurant',
        dense: state.uri.queryParameters['data'] == 'dense',
        category: state.uri.queryParameters['category'] ?? 'All',
      ),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => SearchScreen(initialQuery: state.uri.queryParameters['q'] ?? ''),
    ),
    GoRoute(
      path: '/restaurant/:id',
      builder: (context, state) => RestaurantDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/hack/:id',
      builder: (context, state) => HackDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/cook',
      builder: (context, state) => CookScreen(recipeId: state.uri.queryParameters['recipe']),
    ),
    GoRoute(path: '/track', builder: (context, state) => const TrackScreen()),
    GoRoute(path: '/you', builder: (context, state) => const YouScreen()),
  ],
);
