import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/eat_out_screen.dart';
import 'screens/search_screen.dart';
import 'screens/restaurant_detail_screen.dart';
import 'screens/hack_detail_screen.dart';
import 'screens/cook_screen.dart';
import 'screens/track_screen.dart';
import 'screens/you_screen.dart';
import 'screens/app_error_screen.dart';

/// Route paths mirror `../app/src/App.tsx` closely — `/onboarding?step=N`,
/// `/eat-out?view=&data=&category=`, `/hack/:id`, `/search?q=` — so anyone who knows
/// the web app's URLs can find the equivalent Flutter screen without a lookup table.
/// go_router gives every one of these query-param states a real, shareable route,
/// same as the web app's URL-addressable states (though there is no in-app screen
/// index here — see app-flutter/README.md for why).
CustomTransitionPage<void> _page(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.025, 0.015),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    );

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  errorPageBuilder: (context, state) => _page(state, const AppErrorScreen()),
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _page(state, const SplashScreen()),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) {
        final step =
            int.tryParse(state.uri.queryParameters['step'] ?? '0') ?? 0;
        return _page(state, OnboardingScreen(step: step));
      },
    ),
    GoRoute(
      path: '/onboarding/resume',
      pageBuilder: (context, state) =>
          _page(state, const OnboardingResumeScreen()),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _page(state, const HomeScreen()),
    ),
    GoRoute(
      path: '/eat-out',
      pageBuilder: (context, state) => _page(
        state,
        EatOutScreen(
          view: state.uri.queryParameters['view'] ?? 'restaurant',
          dense: state.uri.queryParameters['data'] == 'dense',
          category: state.uri.queryParameters['category'] ?? 'All',
        ),
      ),
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => _page(
        state,
        SearchScreen(initialQuery: state.uri.queryParameters['q'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/restaurant/:id',
      pageBuilder: (context, state) =>
          _page(state, RestaurantDetailScreen(id: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/hack/:id',
      pageBuilder: (context, state) =>
          _page(state, HackDetailScreen(id: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/cook/recipe/:id',
      pageBuilder: (context, state) =>
          _page(state, RecipeDetailScreen(id: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/cook',
      pageBuilder: (context, state) => _page(
        state,
        CookScreen(recipeId: state.uri.queryParameters['recipe']),
      ),
    ),
    GoRoute(
      path: '/track',
      pageBuilder: (context, state) => _page(state, const TrackScreen()),
    ),
    GoRoute(
      path: '/you',
      pageBuilder: (context, state) => _page(state, const YouScreen()),
    ),
  ],
);
