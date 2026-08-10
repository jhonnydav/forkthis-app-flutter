import 'dart:convert';
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

  test(
    'local demo account sign-in persists without storing a password',
    () async {
      final state = AppState();
      await waitUntilLoaded(state);

      state.createEmailAccount(name: 'Sam', email: 'SAM@example.com');
      await Future<void>.delayed(const Duration(milliseconds: 40));

      final restored = AppState();
      await waitUntilLoaded(restored);
      expect(restored.signedIn, isTrue);
      expect(restored.authProvider, 'email');
      expect(restored.accountEmail, 'sam@example.com');
      expect(restored.profile.name, 'Sam');
      expect(restored.exportJson(), isNot(contains('password')));
    },
  );

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

  test('guided tour completion survives relaunch', () async {
    final state = AppState();
    await waitUntilLoaded(state);

    state.completeOnboarding();
    expect(state.guidedTourCompleted, isFalse);
    state.completeGuidedTour();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    final restored = AppState();
    await waitUntilLoaded(restored);
    expect(restored.guidedTourCompleted, isTrue);
  });

  test('reminder opt-out removes and blocks reminder notifications', () async {
    final state = AppState();
    await waitUntilLoaded(state);

    state.addReminderNotification(title: 'Come back');
    expect(state.notifications.any((item) => item.kind == 'reminder'), isTrue);

    state.setReminderNotifications(false);
    state.addReminderNotification(title: 'Blocked reminder');

    expect(state.profile.notifications, isFalse);
    expect(state.notifications.any((item) => item.kind == 'reminder'), isFalse);
  });

  test('a three-day gap creates one supportive return state', () async {
    SharedPreferences.setMockInitialValues({
      'nutrition-platform-state-v1': jsonEncode({
        'profile': {'notifications': true},
        'onboardingCompleted': true,
        'onboardingStep': 9,
        'guidedTourCompleted': true,
        'lastOpenedAt': DateTime.now()
            .subtract(const Duration(days: 4))
            .toIso8601String(),
      }),
    });

    final state = AppState();
    await waitUntilLoaded(state);
    expect(state.welcomeBackPending, isTrue);

    state.dismissWelcomeBack();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final restored = AppState();
    await waitUntilLoaded(restored);
    expect(restored.welcomeBackPending, isFalse);
    expect(restored.earnedBadgeIds, contains('back-at-it'));
  });

  test(
    'saving and logging award momentum without duplicate save points',
    () async {
      final state = AppState();
      await waitUntilLoaded(state);
      final hack = fastHacks.first;

      state.toggleSavedHack(hack.id);
      state.toggleSavedHack(hack.id);
      state.toggleSavedHack(hack.id);
      state.logItem(
        sourceId: hack.id,
        type: 'order',
        title: hack.title,
        calories: hack.calories,
        protein: hack.protein,
        image: hack.image,
      );

      expect(state.momentumPoints, 20);
      expect(state.earnedBadgeIds, contains('first-forkthis-pick'));
      expect(state.earnedBadgeIds, contains('protein-helper'));

      await Future<void>.delayed(const Duration(milliseconds: 40));
      final restored = AppState();
      await waitUntilLoaded(restored);
      expect(restored.momentumPoints, 20);
      expect(restored.earnedBadgeIds, contains('first-forkthis-pick'));
      expect(restored.streakDays, 1);
    },
  );

  test('gamification queues streak and badge celebrations', () async {
    SharedPreferences.setMockInitialValues({
      'nutrition-platform-state-v1': jsonEncode({
        'lastStreakActionDate': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String()
            .substring(0, 10),
        'streakDays': 2,
        'longestStreakDays': 2,
      }),
    });
    final state = AppState();
    await waitUntilLoaded(state);

    state.recordForkThisMoment('fast-restart');

    expect(state.streakDays, 3);
    expect(state.longestStreakDays, 3);
    expect(state.pendingStreakDays, 3);
    expect(state.earnedBadgeIds, contains('three-day-streak'));
    expect(state.pendingBadgeIds, contains('three-day-streak'));

    state.consumePendingStreak();
    state.consumePendingBadge('three-day-streak');
    expect(state.pendingStreakDays, 0);
    expect(state.pendingBadgeIds, isNot(contains('three-day-streak')));
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
      expect(state.profile.surgical, 'prefer_not');
      expect(state.momentumPoints, 0);
      expect(state.earnedBadgeIds, isEmpty);
    },
  );

  test(
    'demo restart returns to onboarding without deleting demo activity',
    () async {
      final state = AppState();
      await waitUntilLoaded(state);
      state.completeOnboarding();
      state.completeGuidedTour();
      state.updateProfile(name: 'Demo User', goal: Goal.lose);
      state.toggleSavedHack(fastHacks.first.id);

      state.restartDemoFromOnboarding();

      expect(state.onboardingCompleted, isFalse);
      expect(state.onboardingStep, 0);
      expect(state.guidedTourCompleted, isFalse);
      expect(state.profile.name, isEmpty);
      expect(state.profile.goal, Goal.maintain);
      expect(state.savedHackIds, contains(fastHacks.first.id));
    },
  );
}
