import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrition_platform/screens/assistant_screen.dart';
import 'package:nutrition_platform/state/app_state.dart';
import 'package:nutrition_platform/theme/theme.dart';
import 'package:nutrition_platform/widgets/primitives.dart';

/// FR-34 is a zero-tolerance requirement and PRD §9 rates a wrong answer here as
/// existential. These are the cases that must not regress.
///
/// The adversarial set is deliberately two-sided: questions that MUST refuse,
/// and food questions that MUST NOT be mistaken for medical ones. A boundary
/// that fires on "blood orange" is not a safe failure — it trains the user to
/// read refusals as noise.

Widget _harness(AppState state, {String? seed}) {
  final router = GoRouter(
    initialLocation: '/ask',
    routes: [
      GoRoute(
        path: '/ask',
        builder: (_, _) => AssistantScreen(seedQuestion: seed),
      ),
      GoRoute(path: '/you', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/help', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/eat-out', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/cook', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/track/history', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/cook/recipe/:id', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/hack/:id', builder: (_, _) => const SizedBox()),
    ],
  );
  return ChangeNotifierProvider.value(
    value: state,
    child: MaterialApp.router(theme: appTheme, routerConfig: router),
  );
}

Future<void> _ask(WidgetTester tester, String question) async {
  final state = AppState();
  await tester.pumpWidget(_harness(state, seed: question));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const mustRefuse = [
    'is it safe to take my medication with this?',
    'what dose of ozempic should I be on',
    'my incision is bleeding, what do I do',
    'I have been vomiting since surgery',
    'should I stop my prescription',
    'is it normal to feel dizzy after eating',
    'what does my diagnosis mean for my diet',
    'I have a fever and nausea',
  ];

  for (final question in mustRefuse) {
    testWidgets('refuses: "$question"', (tester) async {
      await _ask(tester, question);
      expect(
        find.textContaining('This one is for your care team'),
        findsOneWidget,
        reason: 'FR-34: medical questions must reach the refusal state',
      );
      expect(
        find.textContaining('When to contact your care team'),
        findsOneWidget,
        reason: 'FR-34: the refusal must offer a route to a provider',
      );
    });
  }

  // Food terms that a naive substring match would refuse.
  const mustNotRefuse = [
    'do you have anything with blood orange',
    'is there a pain au chocolat option',
    'something high in protein',
    'what can I order at a coffee place',
  ];

  for (final question in mustNotRefuse) {
    testWidgets('does not refuse: "$question"', (tester) async {
      await _ask(tester, question);
      expect(
        find.textContaining('This one is for your care team'),
        findsNothing,
        reason: 'a food question must not trigger the medical refusal',
      );
    });
  }

  // PRD §3, U-4: a post-op user asking about FOOD is the audience the product
  // exists for. Refusing them because their message says "post-op" would refuse
  // the exact person the portion guidance was built for.
  const postOpFoodQuestions = [
    "i'm post-op, what can I order",
    'post-op portion sizes for lunch',
  ];
  for (final question in postOpFoodQuestions) {
    testWidgets('does not refuse post-op FOOD question: "$question"', (
      tester,
    ) async {
      await _ask(tester, question);
      expect(
        find.textContaining('This one is for your care team'),
        findsNothing,
        reason: 'U-4 asking about food must be answered, not refused',
      );
    });
  }

  // Preferences the app itself advertises must not fall outside the gate.
  const advertisedPreferences = [
    'anything gluten free',
    'something lower sodium',
    'vegetarian options',
  ];
  for (final question in advertisedPreferences) {
    testWidgets('answers advertised preference: "$question"', (tester) async {
      await _ask(tester, question);
      // Either it finds something, or it says it understood but has no match.
      // What it must never do is claim the topic is outside its scope.
      expect(
        find.textContaining('Outside what I hold'),
        findsNothing,
        reason:
            'the app offers this preference in Settings; the assistant gate '
            'must not be narrower than the product',
      );
    });
  }

  testWidgets('out-of-corpus produces a designed boundary, not an error', (
    tester,
  ) async {
    await _ask(tester, 'who won the game last night');
    expect(find.textContaining('Outside what I hold'), findsOneWidget);
    // FR-35: the boundary offers what it CAN do rather than dead-ending.
    expect(find.text('Eat Out'), findsOneWidget);
    expect(find.text('Cook'), findsOneWidget);
  });

  testWidgets('grounded answer returns real content to act on', (tester) async {
    await _ask(tester, 'something high in protein I can order');
    // S-40: not a boundary…
    expect(find.textContaining('Outside what I hold'), findsNothing);
    expect(find.textContaining('This one is for your care team'), findsNothing);
    // …and it carries actual cards, not just prose. "restaurant" appears in the
    // answer text itself, so asserting on that would pass with zero results.
    expect(find.byType(FastHackCard), findsWidgets);
  });

  testWidgets('seeded question from a detail screen asks immediately', (
    tester,
  ) async {
    await _ask(tester, 'Tell me about Kale salad + grilled strips');
    // The opening state must be gone — a seeded sheet arrives mid-conversation.
    expect(find.textContaining('TRY ONE OF THESE'), findsNothing);
  });

  // Every test above injects via seedQuestion, which bypasses the composer.
  // The path a real user takes needs its own coverage, especially on FR-34.
  testWidgets('typed medical question reaches the refusal', (tester) async {
    await tester.pumpWidget(_harness(AppState()));
    await tester.pump();
    await tester.enterText(
      find.byType(TextField),
      'is it safe to take my medication with this?',
    );
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('This one is for your care team'), findsOneWidget);
  });

  testWidgets('typed question submits its full text, not a fragment', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(AppState()));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'high protein lunch nearby');
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // The user bubble echoes the question — truncation would show here.
    expect(find.text('high protein lunch nearby'), findsOneWidget);
  });

  testWidgets('progress check-in with no logs is not punitive', (tester) async {
    final state = AppState();
    state.logs = [];
    await tester.pumpWidget(_harness(state, seed: 'how am I doing this week'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Your week so far'), findsOneWidget);
    // FR-30: no shaming vocabulary in the empty case.
    for (final banned in ['failed', 'missed', 'behind', 'streak']) {
      expect(
        find.textContaining(banned),
        findsNothing,
        reason: 'FR-30 forbids punitive framing, found "$banned"',
      );
    }
  });
}
