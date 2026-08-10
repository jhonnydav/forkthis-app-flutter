import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/fixtures.dart';
import '../home_widgets.dart';
import '../product.dart';

/// Ported from `../app/src/state/AppState.tsx`. `localStorage` → `SharedPreferences`,
/// React context + useState → ChangeNotifier. Same shape, same starter data, same
/// mutation semantics (toggle-in-place, clamp water/movement, etc).
class LoggedItem {
  final String id;
  final String sourceId;
  final String type; // 'order' | 'recipe' | 'manual'
  final String title;
  final int calories;
  final int protein;
  final String image;
  final DateTime loggedAt;
  final String meal;
  final String portion;

  const LoggedItem({
    required this.id,
    required this.sourceId,
    required this.type,
    required this.title,
    required this.calories,
    required this.protein,
    required this.image,
    required this.loggedAt,
    this.meal = 'Lunch',
    this.portion = '1 serving',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceId': sourceId,
    'type': type,
    'title': title,
    'calories': calories,
    'protein': protein,
    'image': image,
    'loggedAt': loggedAt.toIso8601String(),
    'meal': meal,
    'portion': portion,
  };

  factory LoggedItem.fromJson(Map<String, dynamic> json) => LoggedItem(
    id: json['id'] as String,
    sourceId: json['sourceId'] as String,
    type: json['type'] as String,
    title: json['title'] as String,
    calories: json['calories'] as int,
    protein: json['protein'] as int,
    image: json['image'] as String,
    loggedAt:
        DateTime.tryParse(json['loggedAt'] as String? ?? '') ?? DateTime.now(),
    meal: json['meal'] as String? ?? 'Lunch',
    portion: json['portion'] as String? ?? '1 serving',
  );
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String kind; // 'activity' | 'reminder'

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.kind = 'activity',
  });

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
    kind: kind,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
    'kind': kind,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        read: json['read'] as bool? ?? false,
        kind:
            json['kind'] as String? ??
            ((json['id'] as String? ?? '').contains('reminder')
                ? 'reminder'
                : 'activity'),
      );
}

class UserProfile {
  final String name;
  final String email;
  final Goal goal;
  final String units; // 'imperial' | 'metric'
  final String surgical; // 'prepare' | 'recover' | 'none' | 'prefer_not'
  final String activity; // 'sedentary' | 'lightly' | 'moderately' | 'very'
  final bool notifications;
  final String reminderTime;
  final List<String> dietaryPreferences;
  final bool locationEnabled;
  final String birthDate;
  final double heightCm;
  final double weightKg;

  const UserProfile({
    this.name = 'Steven',
    this.email = '',
    this.goal = Goal.maintain,
    this.units = 'imperial',
    this.surgical = 'prefer_not',
    this.activity = 'lightly',
    this.notifications = true,
    this.reminderTime = '18:30',
    this.dietaryPreferences = const [],
    this.locationEnabled = true,
    this.birthDate = '',
    this.heightCm = 0,
    this.weightKg = 0,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    Goal? goal,
    String? units,
    String? surgical,
    String? activity,
    bool? notifications,
    String? reminderTime,
    List<String>? dietaryPreferences,
    bool? locationEnabled,
    String? birthDate,
    double? heightCm,
    double? weightKg,
  }) => UserProfile(
    name: name ?? this.name,
    email: email ?? this.email,
    goal: goal ?? this.goal,
    units: units ?? this.units,
    surgical: surgical ?? this.surgical,
    activity: activity ?? this.activity,
    notifications: notifications ?? this.notifications,
    reminderTime: reminderTime ?? this.reminderTime,
    dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
    locationEnabled: locationEnabled ?? this.locationEnabled,
    birthDate: birthDate ?? this.birthDate,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'goal': goal.name,
    'units': units,
    'surgical': surgical,
    'activity': activity,
    'notifications': notifications,
    'reminderTime': reminderTime,
    'dietaryPreferences': dietaryPreferences,
    'locationEnabled': locationEnabled,
    'birthDate': birthDate,
    'heightCm': heightCm,
    'weightKg': weightKg,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? 'Steven',
    email: json['email'] as String? ?? '',
    goal: Goal.values.byName(json['goal'] as String? ?? 'maintain'),
    units: json['units'] as String? ?? 'imperial',
    surgical: json['surgical'] as String? ?? 'prefer_not',
    activity: json['activity'] as String? ?? 'lightly',
    notifications: json['notifications'] as bool? ?? true,
    reminderTime: json['reminderTime'] as String? ?? '18:30',
    dietaryPreferences: List<String>.from(
      json['dietaryPreferences'] as List? ?? [],
    ),
    locationEnabled: json['locationEnabled'] as bool? ?? true,
    birthDate: json['birthDate'] as String? ?? '',
    heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
    weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
  );
}

/// A single self-reported weight reading. Kept as a list rather than a scalar so
/// the profile can show movement over time. Progress mechanics live separately
/// as positive momentum and badges; missed days are never rendered as debt.
class WeightEntry {
  final DateTime recordedAt;
  final double weightKg;

  const WeightEntry({required this.recordedAt, required this.weightKg});

  Map<String, dynamic> toJson() => {
    'recordedAt': recordedAt.toIso8601String(),
    'weightKg': weightKg,
  };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    recordedAt:
        DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
        DateTime.now(),
    weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
  );
}

const _storageKey = 'nutrition-platform-state-v1';

class MomentumBadge {
  final String id;
  final String title;
  final String description;
  final String image;
  final String tier;
  final int unlockAt;

  const MomentumBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    this.tier = 'bronze',
    this.unlockAt = 1,
  });
}

const List<MomentumBadge> momentumBadgeCatalog = [
  MomentumBadge(
    id: 'back-at-it',
    title: 'Back At It',
    description: 'Returned after a gap and picked a next step.',
    image: 'assets/images/badges/back-at-it.png',
    tier: 'silver',
  ),
  MomentumBadge(
    id: 'first-forkthis-pick',
    title: 'First ForkThis! Pick',
    description: 'Saved a meal that can help in a real-life moment.',
    image: 'assets/images/badges/first-forkthis-pick.png',
    tier: 'gold',
  ),
  MomentumBadge(
    id: 'protein-helper',
    title: 'Protein Helper',
    description: 'Logged a meal with at least 30g of protein.',
    image: 'assets/images/badges/protein-helper.png',
    tier: 'diamond',
  ),
  MomentumBadge(
    id: 'momentum-builder',
    title: 'Momentum Builder',
    description: 'Took a small action that supports the day.',
    image: 'assets/images/badges/momentum-builder.png',
    tier: 'bronze',
  ),
  MomentumBadge(
    id: 'three-day-streak',
    title: '3 Day Streak',
    description: 'Showed up three different days.',
    image: 'assets/images/badges/momentum-builder.png',
    tier: 'gold',
    unlockAt: 3,
  ),
  MomentumBadge(
    id: 'seven-day-streak',
    title: '7 Day Streak',
    description: 'Kept a full week of helpful choices going.',
    image: 'assets/images/badges/back-at-it.png',
    tier: 'diamond',
    unlockAt: 7,
  ),
];

class GamificationRule {
  final String id;
  final String trigger;
  final int points;
  final List<String> badges;
  final String retentionJob;

  const GamificationRule({
    required this.id,
    required this.trigger,
    required this.points,
    required this.badges,
    required this.retentionJob,
  });
}

const List<GamificationRule> gamificationMatrix = [
  GamificationRule(
    id: 'moment-picked',
    trigger: 'Pick a ForkThis! moment',
    points: 5,
    badges: ['momentum-builder'],
    retentionJob: 'Make the first small action feel acknowledged.',
  ),
  GamificationRule(
    id: 'save-pick',
    trigger: 'Save an order or recipe',
    points: 10,
    badges: ['first-forkthis-pick'],
    retentionJob: 'Turn intent into a reusable fallback plan.',
  ),
  GamificationRule(
    id: 'log-meal',
    trigger: 'Log a meal',
    points: 10,
    badges: ['momentum-builder', 'protein-helper'],
    retentionJob: 'Reward self-monitoring without punishing missed days.',
  ),
  GamificationRule(
    id: 'return-gap',
    trigger: 'Return after a multi-day gap',
    points: 15,
    badges: ['back-at-it', 'momentum-builder'],
    retentionJob: 'Make recovery from lapse feel like progress.',
  ),
];

MomentumBadge? badgeById(String id) {
  for (final badge in momentumBadgeCatalog) {
    if (badge.id == id) return badge;
  }
  return null;
}

List<LoggedItem> _starterLogs() => fastHacks.take(2).map((hack) {
  final index = fastHacks.indexOf(hack);
  return LoggedItem(
    id: 'starter-$index',
    sourceId: hack.id,
    type: 'order',
    title: hack.title,
    calories: hack.calories,
    protein: hack.protein,
    image: hack.image,
    loggedAt: DateTime.now(),
  );
}).toList();

class AppState extends ChangeNotifier {
  Future<void> _writeQueue = Future.value();
  bool signedIn = false;
  String authProvider = '';
  String accountEmail = '';
  String accountName = '';
  UserProfile profile = const UserProfile();
  List<String> savedHackIds = [];
  List<String> savedRecipeIds = [];
  List<LoggedItem> logs = _starterLogs();
  int waterCups = 5;
  int movementMinutes = 18;
  bool onboardingCompleted = false;
  int onboardingStep = 0;
  bool guidedTourCompleted = false;
  bool welcomeBackPending = false;
  DateTime lastOpenedAt = DateTime.now();
  int momentumPoints = 0;
  List<String> earnedBadgeIds = [];
  List<String> momentumEventIds = [];
  int streakDays = 0;
  int longestStreakDays = 0;
  String lastStreakActionDate = '';
  List<String> pendingBadgeIds = [];
  int pendingStreakDays = 0;

  /// Days since the last log before this session opened. 0 when the user logged
  /// today. Drives the return-after-lapse copy (App Flow §3.4 node O) — read as
  /// "how long since we saw you", never rendered as a debt.
  int lapseDays = 0;

  /// Whether the pre-prompt explaining *why* location helps has been shown.
  /// FR-20: without permission the experience degrades to manual browse "with no
  /// nagging", so this is asked at most once.
  bool locationPromptSeen = false;

  List<WeightEntry> weightLog = [];
  List<AppNotification> notifications = [
    AppNotification(
      id: 'welcome-plan',
      title: 'Your plan is ready',
      body: 'Your daily targets and meal ideas are ready to explore.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    AppNotification(
      id: 'water-reminder',
      title: 'A gentle water check-in',
      body: 'One cup is enough to keep the day moving.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      kind: 'reminder',
    ),
  ];

  int get unreadNotificationCount =>
      notifications.where((item) => !item.read).length;
  List<MomentumBadge> get earnedBadges =>
      earnedBadgeIds.map(badgeById).whereType<MomentumBadge>().toList();
  List<MomentumBadge> get pendingBadges =>
      pendingBadgeIds.map(badgeById).whereType<MomentumBadge>().toList();

  bool _loaded = false;
  bool get loaded => _loaded;

  AppState() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        profile = UserProfile.fromJson(
          json['profile'] as Map<String, dynamic>? ?? {},
        );
        signedIn = json['signedIn'] as bool? ?? false;
        authProvider = json['authProvider'] as String? ?? '';
        accountEmail = json['accountEmail'] as String? ?? profile.email;
        accountName = json['accountName'] as String? ?? profile.name;
        savedHackIds = List<String>.from(json['savedHackIds'] as List? ?? []);
        savedRecipeIds = List<String>.from(
          json['savedRecipeIds'] as List? ?? [],
        );
        logs = (json['logs'] as List? ?? [])
            .map((e) => LoggedItem.fromJson(e as Map<String, dynamic>))
            .toList();
        waterCups = json['waterCups'] as int? ?? 5;
        movementMinutes = json['movementMinutes'] as int? ?? 18;
        onboardingCompleted = json['onboardingCompleted'] as bool? ?? false;
        onboardingStep = json['onboardingStep'] as int? ?? 0;
        guidedTourCompleted = json['guidedTourCompleted'] as bool? ?? false;
        locationPromptSeen = json['locationPromptSeen'] as bool? ?? false;
        weightLog = (json['weightLog'] as List? ?? [])
            .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        final previousOpenedAt = DateTime.tryParse(
          json['lastOpenedAt'] as String? ?? '',
        );
        if (onboardingCompleted &&
            previousOpenedAt != null &&
            DateTime.now().difference(previousOpenedAt) >=
                const Duration(days: comebackThresholdDays)) {
          welcomeBackPending = true;
        }
        if (logs.isNotEmpty) {
          final latest = logs
              .map((l) => l.loggedAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);
          lapseDays = _dayGap(latest, DateTime.now());
        }
        final storedNotifications = json['notifications'] as List?;
        if (storedNotifications != null) {
          notifications = storedNotifications
              .map(
                (item) =>
                    AppNotification.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
        if (!profile.notifications) {
          notifications = notifications
              .where((item) => item.kind != 'reminder')
              .toList();
        }
        momentumPoints = json['momentumPoints'] as int? ?? 0;
        earnedBadgeIds = List<String>.from(
          json['earnedBadgeIds'] as List? ?? [],
        );
        momentumEventIds = List<String>.from(
          json['momentumEventIds'] as List? ?? [],
        );
        streakDays = json['streakDays'] as int? ?? 0;
        longestStreakDays = json['longestStreakDays'] as int? ?? streakDays;
        lastStreakActionDate = json['lastStreakActionDate'] as String? ?? '';
        pendingBadgeIds = List<String>.from(
          json['pendingBadgeIds'] as List? ?? [],
        );
        pendingStreakDays = json['pendingStreakDays'] as int? ?? 0;
      } catch (_) {
        // Corrupt or pre-migration data — fall back to defaults, same as the web app's catch block.
      }
    }
    lastOpenedAt = DateTime.now();
    _loaded = true;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'profile': profile.toJson(),
        'signedIn': signedIn,
        'authProvider': authProvider,
        'accountEmail': accountEmail,
        'accountName': accountName,
        'savedHackIds': savedHackIds,
        'savedRecipeIds': savedRecipeIds,
        'logs': logs.map((l) => l.toJson()).toList(),
        'waterCups': waterCups,
        'movementMinutes': movementMinutes,
        'onboardingCompleted': onboardingCompleted,
        'onboardingStep': onboardingStep,
        'guidedTourCompleted': guidedTourCompleted,
        'locationPromptSeen': locationPromptSeen,
        'weightLog': weightLog.map((entry) => entry.toJson()).toList(),
        'lastOpenedAt': lastOpenedAt.toIso8601String(),
        'notifications': notifications.map((item) => item.toJson()).toList(),
        'momentumPoints': momentumPoints,
        'earnedBadgeIds': earnedBadgeIds,
        'momentumEventIds': momentumEventIds,
        'streakDays': streakDays,
        'longestStreakDays': longestStreakDays,
        'lastStreakActionDate': lastStreakActionDate,
        'pendingBadgeIds': pendingBadgeIds,
        'pendingStreakDays': pendingStreakDays,
      }),
    );
    final todayCalories = todayLogs.fold<int>(0, (sum, item) => sum + item.calories);
    final todayProtein = todayLogs.fold<int>(0, (sum, item) => sum + item.protein);
    unawaited(
      syncHomeWidgets(
        momentumPoints: momentumPoints,
        streakDays: streakDays,
        todayCalories: todayCalories,
        todayProtein: todayProtein,
        todayWaterCups: waterCups,
      ),
    );
  }

  static int _dayGap(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  void _commit() {
    notifyListeners();
    _writeQueue = _writeQueue.then((_) => _persist());
  }

  bool _awardMomentum({
    required String eventId,
    required int points,
    List<String> badges = const [],
  }) {
    if (momentumEventIds.contains(eventId)) return false;
    momentumEventIds = [...momentumEventIds, eventId];
    momentumPoints += points;
    _advanceStreak();
    for (final badge in badges) {
      if (!earnedBadgeIds.contains(badge)) {
        earnedBadgeIds = [...earnedBadgeIds, badge];
        pendingBadgeIds = [...pendingBadgeIds, badge];
      }
    }
    return true;
  }

  void _advanceStreak() {
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    if (lastStreakActionDate == todayKey) return;
    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));
    streakDays = lastStreakActionDate == yesterdayKey ? streakDays + 1 : 1;
    longestStreakDays = streakDays > longestStreakDays
        ? streakDays
        : longestStreakDays;
    lastStreakActionDate = todayKey;
    if (const {3, 7, 14, 21, 30}.contains(streakDays)) {
      pendingStreakDays = streakDays;
      final streakBadge = streakDays >= 7
          ? 'seven-day-streak'
          : 'three-day-streak';
      if (!earnedBadgeIds.contains(streakBadge)) {
        earnedBadgeIds = [...earnedBadgeIds, streakBadge];
        pendingBadgeIds = [...pendingBadgeIds, streakBadge];
      }
    }
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void consumePendingBadge(String id) {
    pendingBadgeIds = pendingBadgeIds
        .where((badgeId) => badgeId != id)
        .toList();
    _commit();
  }

  void consumePendingStreak() {
    pendingStreakDays = 0;
    _commit();
  }

  void createEmailAccount({required String name, required String email}) {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    signedIn = true;
    authProvider = 'email';
    accountName = cleanName;
    accountEmail = cleanEmail;
    profile = profile.copyWith(name: cleanName, email: cleanEmail);
    _commit();
  }

  void signInWithEmail(String email) {
    final cleanEmail = email.trim().toLowerCase();
    signedIn = true;
    authProvider = 'email';
    accountEmail = cleanEmail;
    if (profile.email.isEmpty) profile = profile.copyWith(email: cleanEmail);
    if (accountName.isEmpty && profile.name.isNotEmpty) {
      accountName = profile.name;
    }
    _commit();
  }

  void signInWithProvider(String provider) {
    signedIn = true;
    authProvider = provider;
    accountName = profile.name.isEmpty ? 'Demo User' : profile.name;
    accountEmail = profile.email.isEmpty
        ? '${provider.toLowerCase()}@forkthis.demo'
        : profile.email;
    profile = profile.copyWith(name: accountName, email: accountEmail);
    _commit();
  }

  void signOut() {
    signedIn = false;
    authProvider = '';
    _commit();
  }

  void recordForkThisMoment(String momentId) {
    final awarded = _awardMomentum(
      eventId: 'moment:$momentId',
      points: 5,
      badges: const ['momentum-builder'],
    );
    if (awarded) _commit();
  }

  void updateProfile({
    String? name,
    String? email,
    Goal? goal,
    String? units,
    String? surgical,
    String? activity,
    bool? notifications,
    String? reminderTime,
    List<String>? dietaryPreferences,
    bool? locationEnabled,
    String? birthDate,
    double? heightCm,
    double? weightKg,
  }) {
    profile = profile.copyWith(
      name: name,
      email: email,
      goal: goal,
      units: units,
      surgical: surgical,
      activity: activity,
      notifications: notifications,
      reminderTime: reminderTime,
      dietaryPreferences: dietaryPreferences,
      locationEnabled: locationEnabled,
      birthDate: birthDate,
      heightCm: heightCm,
      weightKg: weightKg,
    );
    _commit();
  }

  void markOnboardingStep(int step) {
    onboardingStep = step.clamp(0, 9);
    _commit();
  }

  void completeOnboarding() {
    onboardingCompleted = true;
    onboardingStep = 9;
    guidedTourCompleted = false;
    welcomeBackPending = false;
    _commit();
  }

  void completeGuidedTour() {
    guidedTourCompleted = true;
    _commit();
  }

  /// FR-40 — the tour is replayable from the profile. Replaying is deliberately
  /// the *same* flow as the first run, not a cut-down recap, so a user who was
  /// interrupted the first time gets the whole thing.
  void replayGuidedTour() {
    guidedTourCompleted = false;
    _commit();
  }

  /// Demo control: returns the device to the first onboarding question while
  /// keeping starter content available for the rest of the app.
  void restartDemoFromOnboarding() {
    signedIn = true;
    profile = const UserProfile(name: '');
    onboardingCompleted = false;
    onboardingStep = 0;
    guidedTourCompleted = false;
    welcomeBackPending = false;
    locationPromptSeen = false;
    _commit();
  }

  void markLocationPromptSeen() {
    locationPromptSeen = true;
    _commit();
  }

  void setLocationEnabled(bool enabled) {
    profile = profile.copyWith(locationEnabled: enabled);
    locationPromptSeen = true;
    _commit();
  }

  void recordWeight(double weightKg) {
    if (weightKg <= 0) return;
    final now = DateTime.now();
    // One reading per day — re-recording replaces rather than stacks, so the
    // list stays a trend line instead of a log of second-guessing.
    weightLog = [
      ...weightLog.where((e) => _dayGap(e.recordedAt, now) != 0),
      WeightEntry(recordedAt: now, weightKg: weightKg),
    ]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    profile = profile.copyWith(weightKg: weightKg);
    _commit();
  }

  void removeWeightEntry(DateTime recordedAt) {
    weightLog = weightLog.where((e) => e.recordedAt != recordedAt).toList();
    _commit();
  }

  /// Logs for one calendar day, newest first.
  List<LoggedItem> logsForDay(DateTime day) =>
      logs.where((l) => _dayGap(l.loggedAt, day) == 0).toList()
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

  List<LoggedItem> get todayLogs => logsForDay(DateTime.now());

  /// Distinct recently-logged items, newest first — the "≤3 taps to log a
  /// recent item" path in FR-26.
  List<LoggedItem> recentDistinctLogs({int limit = 8}) {
    final seen = <String>{};
    final out = <LoggedItem>[];
    final sorted = [...logs]..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    for (final log in sorted) {
      if (seen.add('${log.type}:${log.sourceId}:${log.title}')) out.add(log);
      if (out.length >= limit) break;
    }
    return out;
  }

  /// FR-15 — data export. Returned as pretty JSON so what the user copies is
  /// legible, not a blob.
  String exportJson() => const JsonEncoder.withIndent('  ').convert({
    'exportedAt': DateTime.now().toIso8601String(),
    'profile': profile.toJson(),
    'savedHackIds': savedHackIds,
    'savedRecipeIds': savedRecipeIds,
    'logs': logs.map((l) => l.toJson()).toList(),
    'weightLog': weightLog.map((e) => e.toJson()).toList(),
    'waterCups': waterCups,
    'movementMinutes': movementMinutes,
    'momentumPoints': momentumPoints,
    'earnedBadgeIds': earnedBadgeIds,
    'streakDays': streakDays,
    'longestStreakDays': longestStreakDays,
  });

  void dismissWelcomeBack() {
    welcomeBackPending = false;
    _awardMomentum(
      eventId:
          'return:${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}',
      points: 15,
      badges: const ['back-at-it', 'momentum-builder'],
    );
    _commit();
  }

  void setReminderNotifications(bool enabled) {
    profile = profile.copyWith(notifications: enabled);
    if (!enabled) {
      notifications = notifications
          .where((item) => item.kind != 'reminder')
          .toList();
    }
    _commit();
  }

  void toggleSavedHack(String id) {
    final wasSaved = savedHackIds.contains(id);
    savedHackIds = wasSaved
        ? savedHackIds.where((s) => s != id).toList()
        : [...savedHackIds, id];
    if (!wasSaved) {
      _awardMomentum(
        eventId: 'save-hack:$id',
        points: 10,
        badges: const ['first-forkthis-pick'],
      );
    }
    _commit();
  }

  void toggleSavedRecipe(String id) {
    final wasSaved = savedRecipeIds.contains(id);
    savedRecipeIds = wasSaved
        ? savedRecipeIds.where((s) => s != id).toList()
        : [...savedRecipeIds, id];
    if (!wasSaved) {
      _awardMomentum(
        eventId: 'save-recipe:$id',
        points: 10,
        badges: const ['first-forkthis-pick'],
      );
    }
    _commit();
  }

  void logItem({
    required String sourceId,
    required String type,
    required String title,
    required int calories,
    required int protein,
    required String image,
    DateTime? loggedAt,
    String meal = 'Lunch',
    String portion = '1 serving',
  }) {
    final now = DateTime.now();
    final recordedAt = loggedAt ?? now;
    logs = [
      LoggedItem(
        id: '$type-$sourceId-${now.millisecondsSinceEpoch}',
        sourceId: sourceId,
        type: type,
        title: title,
        calories: calories,
        protein: protein,
        image: image,
        loggedAt: recordedAt,
        meal: meal,
        portion: portion,
      ),
      ...logs,
    ];
    final dayKey = '${recordedAt.year}-${recordedAt.month}-${recordedAt.day}';
    _awardMomentum(
      eventId: 'log:$dayKey:$type:$sourceId',
      points: 10,
      badges: ['momentum-builder', if (protein >= 30) 'protein-helper'],
    );
    _commit();
  }

  void removeLog(String id) {
    logs = logs.where((l) => l.id != id).toList();
    _commit();
  }

  void addWater() {
    waterCups = (waterCups + 1).clamp(0, 16);
    _commit();
  }

  void adjustWater(int cups) {
    waterCups = (waterCups + cups).clamp(0, 16);
    _commit();
  }

  void addMovement(int minutes) {
    movementMinutes = (movementMinutes + minutes).clamp(0, 300);
    _commit();
  }

  void addNotification({required String title, String body = ''}) {
    notifications = [
      AppNotification(
        id: 'notification-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        body: body,
        createdAt: DateTime.now(),
        kind: 'activity',
      ),
      ...notifications,
    ].take(30).toList();
    _commit();
  }

  void addReminderNotification({required String title, String body = ''}) {
    if (!profile.notifications) return;
    notifications = [
      AppNotification(
        id: 'reminder-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        body: body,
        createdAt: DateTime.now(),
        kind: 'reminder',
      ),
      ...notifications,
    ].take(30).toList();
    _commit();
  }

  void markNotificationRead(String id) {
    notifications = notifications
        .map((item) => item.id == id ? item.copyWith(read: true) : item)
        .toList();
    _commit();
  }

  void markAllNotificationsRead() {
    notifications = notifications
        .map((item) => item.copyWith(read: true))
        .toList();
    _commit();
  }

  void clearLocalData() {
    signedIn = false;
    authProvider = '';
    accountEmail = '';
    accountName = '';
    profile = const UserProfile();
    savedHackIds = [];
    savedRecipeIds = [];
    logs = _starterLogs();
    waterCups = 5;
    movementMinutes = 18;
    onboardingCompleted = false;
    onboardingStep = 0;
    guidedTourCompleted = false;
    welcomeBackPending = false;
    lastOpenedAt = DateTime.now();
    locationPromptSeen = false;
    weightLog = [];
    lapseDays = 0;
    notifications = [];
    momentumPoints = 0;
    earnedBadgeIds = [];
    momentumEventIds = [];
    streakDays = 0;
    longestStreakDays = 0;
    lastStreakActionDate = '';
    pendingBadgeIds = [];
    pendingStreakDays = 0;
    _commit();
  }

  /// FR-15 — account deletion. Distinct from [clearLocalData] in intent even
  /// though this build has no server: deleting removes everything *including*
  /// the starter content, leaving a genuinely blank device rather than a
  /// freshly-seeded one. Onboarding starts over from zero.
  void deleteEverything() {
    signedIn = false;
    authProvider = '';
    accountEmail = '';
    accountName = '';
    profile = const UserProfile(name: '');
    savedHackIds = [];
    savedRecipeIds = [];
    logs = [];
    waterCups = 0;
    movementMinutes = 0;
    onboardingCompleted = false;
    onboardingStep = 0;
    guidedTourCompleted = false;
    welcomeBackPending = false;
    locationPromptSeen = false;
    weightLog = [];
    lapseDays = 0;
    notifications = [];
    momentumPoints = 0;
    earnedBadgeIds = [];
    momentumEventIds = [];
    streakDays = 0;
    longestStreakDays = 0;
    lastStreakActionDate = '';
    pendingBadgeIds = [];
    pendingStreakDays = 0;
    _commit();
  }
}
