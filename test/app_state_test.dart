import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrition_platform/data/fixtures.dart';
import 'package:nutrition_platform/state/app_state.dart';

Future<void> waitUntilLoaded(AppState state) async {
  for (var i = 0; i < 50 && !state.loaded; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(state.loaded, isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'onboarding progress and collected context survive a relaunch',
    () async {
      final state = AppState();
      await waitUntilLoaded(state);

      state.updateProfile(
        goal: Goal.lose,
        birthDate: '1994-10-12T00:00:00.000',
        heightCm: 178,
        weightKg: 84,
        surgical: 'recover',
        activity: 'moderately',
      );
      state.markOnboardingStep(8);
      state.completeOnboarding();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final restored = AppState();
      await waitUntilLoaded(restored);
      expect(restored.onboardingCompleted, isTrue);
      expect(restored.onboardingStep, 9);
      expect(restored.profile.goal, Goal.lose);
      expect(restored.profile.birthDate, startsWith('1994-10-12'));
      expect(restored.profile.heightCm, 178);
      expect(restored.profile.weightKg, 84);
      expect(restored.profile.surgical, 'recover');
      expect(restored.profile.activity, 'moderately');
    },
  );

  test('partial onboarding step is persisted for resume', () async {
    final state = AppState();
    await waitUntilLoaded(state);
    state.updateProfile(goal: Goal.gain);
    state.markOnboardingStep(6);
    await Future<void>.delayed(const Duration(milliseconds: 40));

    final restored = AppState();
    await waitUntilLoaded(restored);
    expect(restored.onboardingCompleted, isFalse);
    expect(restored.onboardingStep, 6);
    expect(restored.profile.goal, Goal.gain);
  });

  test('daily counters clamp and notifications stay bounded', () async {
    final state = AppState();
    await waitUntilLoaded(state);

    state.adjustWater(-100);
    state.addMovement(1000);
    for (var i = 0; i < 40; i++) {
      state.addNotification(title: 'Notice $i');
    }

    expect(state.waterCups, 0);
    expect(state.movementMinutes, 300);
    expect(state.notifications, hasLength(30));
  });

  test(
    'clearing local data restarts onboarding and resets private state',
    () async {
      final state = AppState();
      await waitUntilLoaded(state);
      state.completeOnboarding();
      state.toggleSavedHack(fastHacks.first.id);
      state.clearLocalData();

      expect(state.onboardingCompleted, isFalse);
      expect(state.onboardingStep, 0);
      expect(state.savedHackIds, isEmpty);
      expect(state.notifications, isEmpty);
      expect(state.profile.email, isEmpty);
    },
  );
}
