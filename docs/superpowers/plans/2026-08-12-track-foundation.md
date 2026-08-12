# Track Page Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the Track page a real activity data model and an action-first Today view — a summary card showing what's done/left, a quick-actions row that logs meals/water/walks/runs/activities with zero hunting, and a unified timeline — replacing the current vague header + disconnected stat tiles.

**Architecture:** Additive state layer (`ActivityLog` alongside the existing `LoggedItem`), one new widget file for the two activity-logging bottom sheets, and a rebuild of `track_screen.dart`'s top section. No routing changes, no backend — everything is local `AppState` + `SharedPreferences`, matching how meals/water/momentum already work.

**Tech Stack:** Flutter/Dart, `provider` for state, `go_router` for navigation, `hugeicons` for icons, `flutter_test` for unit/widget tests.

## Global Constraints

- Follow the existing codebase's token system exactly: `AppColors`, `AppText`, `AppRadius`, `AppSpace` from `lib/theme/tokens.dart` and `lib/theme/text_styles.dart` — never hardcode colors, font sizes, or radii.
- Icon references must be real `HugeIcons.strokeRounded*` constants from the `hugeicons` package — verified against `hugeicons-1.1.7/lib/hugeicons.dart` in this plan; do not invent names.
- `flutter analyze` must report zero issues after every task.
- Persistence follows the existing pattern in `AppState`: field on the class, entry in `toJson`, entry in `fromJson` with a safe default, entry in the debug/reset `toJson`-adjacent map at line ~810 if present.
- Momentum points/streak/badges are existing systems (`_awardMomentum`) — reuse them, do not build a parallel system.

---

### Task 1: `ActivityLog` model + `AppState` wiring

**Files:**
- Modify: `lib/state/app_state.dart`
- Test: `test/app_state_test.dart`

**Interfaces:**
- Produces: `class ActivityLog { String id; String type; String? label; int minutes; double? miles; DateTime loggedAt; }` with `toJson()`/`fromJson()`
- Produces: `AppState.activityLogs` (`List<ActivityLog>`), `AppState.logActivity({required String type, String? label, required int minutes, double? miles})`, `AppState.deleteActivityLog(String id)`
- Produces: `AppState.dailyActiveMinutesGoal` (int getter), `AppState.waterGoalCups` (int getter, `= 8`), `AppState.mealsGoalCount` (int getter, `= 3`)
- Removes: `AppState.movementMinutes` field and `AppState.addMovement(int)` method (superseded by `activityLogs` — the flat unlogged counter conflicts with the new structured timeline; no other code should reference it after this task)

This task also removes the two `state.movementMinutes` / `state.addMovement(...)` call sites in `lib/screens/track_screen.dart` (lines 242, 245, 364-366 as of this writing) with placeholder no-ops, since Task 3 rebuilds that whole section anyway — for this task, just delete the two `_PlainStatTile`/`_CounterRow` entries that reference movement so the file compiles. Task 3 replaces the surrounding structure properly.

- [ ] **Step 1: Write the failing tests**

Add to `test/app_state_test.dart` (append near the end of `main()`, before the closing `});`):

```dart
  test('logActivity records an entry, derives active minutes, and awards momentum once per day', () async {
    final state = AppState();
    await waitUntilLoaded(state);

    expect(state.activityLogs, isEmpty);
    final before = state.momentumPoints;

    state.logActivity(type: 'walk', minutes: 20, miles: 1.5);
    expect(state.activityLogs, hasLength(1));
    expect(state.activityLogs.first.type, 'walk');
    expect(state.activityLogs.first.minutes, 20);
    expect(state.activityLogs.first.miles, 1.5);
    expect(state.momentumPoints, greaterThan(before));

    state.logActivity(type: 'run', minutes: 15);
    expect(state.activityLogs, hasLength(2));
    expect(state.activityLogs.last.miles, isNull);
  });

  test('deleteActivityLog removes the entry', () async {
    final state = AppState();
    await waitUntilLoaded(state);

    state.logActivity(type: 'yoga', minutes: 30);
    final id = state.activityLogs.first.id;
    state.deleteActivityLog(id);
    expect(state.activityLogs, isEmpty);
  });

  test('dailyActiveMinutesGoal is derived from onboarding activity level', () async {
    final state = AppState();
    await waitUntilLoaded(state);

    state.updateProfile(activity: 'sedentary');
    expect(state.dailyActiveMinutesGoal, 15);
    state.updateProfile(activity: 'lightly');
    expect(state.dailyActiveMinutesGoal, 30);
    state.updateProfile(activity: 'moderately');
    expect(state.dailyActiveMinutesGoal, 45);
    state.updateProfile(activity: 'very');
    expect(state.dailyActiveMinutesGoal, 60);
  });

  test('activity logs survive a relaunch (persistence round-trip)', () async {
    final state = AppState();
    await waitUntilLoaded(state);
    state.logActivity(type: 'run', minutes: 25, miles: 2.1);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final restored = AppState();
    await waitUntilLoaded(restored);
    expect(restored.activityLogs, hasLength(1));
    expect(restored.activityLogs.first.type, 'run');
    expect(restored.activityLogs.first.miles, 2.1);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/app_state_test.dart`
Expected: FAIL — `logActivity`, `deleteActivityLog`, `activityLogs`, `dailyActiveMinutesGoal` are not defined on `AppState`.

- [ ] **Step 3: Add the `ActivityLog` model**

In `lib/state/app_state.dart`, add this class directly after the closing `}` of `LoggedItem` (currently ends at line 63):

```dart
class ActivityLog {
  final String id;
  final String type; // 'walk' | 'run' | 'strength' | 'yoga' | 'cycling' | 'swimming' | 'sports' | 'other'
  final String? label; // free-text, only used when type == 'other'
  final int minutes;
  final double? miles;
  final DateTime loggedAt;

  const ActivityLog({
    required this.id,
    required this.type,
    this.label,
    required this.minutes,
    this.miles,
    required this.loggedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'label': label,
    'minutes': minutes,
    'miles': miles,
    'loggedAt': loggedAt.toIso8601String(),
  };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
    id: json['id'] as String,
    type: json['type'] as String,
    label: json['label'] as String?,
    minutes: json['minutes'] as int,
    miles: (json['miles'] as num?)?.toDouble(),
    loggedAt:
        DateTime.tryParse(json['loggedAt'] as String? ?? '') ?? DateTime.now(),
  );
}
```

- [ ] **Step 4: Remove `movementMinutes` and add `activityLogs`**

Find `int movementMinutes = 18;` (line ~381) and replace with:

```dart
  List<ActivityLog> activityLogs = [];
```

Find the `fromJson` line `movementMinutes = json['movementMinutes'] as int? ?? 18;` (line ~458) and replace with:

```dart
        activityLogs = (json['activityLogs'] as List? ?? [])
            .map((e) => ActivityLog.fromJson(e as Map<String, dynamic>))
            .toList();
```

Find the two `toJson`-map entries `'movementMinutes': movementMinutes,` (lines ~533 and ~810) and replace **both** with:

```dart
        'activityLogs': activityLogs.map((a) => a.toJson()).toList(),
```

Find `movementMinutes = 18;` in the reset method (line ~978) and delete that line entirely (no replacement — reset should leave `activityLogs` as whatever `[]` default the field declaration already gives after re-construction; check the surrounding reset method resets other list fields like `logs = _starterLogs();` — if this reset method is called on an *existing* instance rather than constructing a new one, add `activityLogs = [];` in its place instead of deleting).

Find `movementMinutes = 0;` (line ~1013, in what looks like a sign-out/clear method) and replace with:

```dart
    activityLogs = [];
```

- [ ] **Step 5: Delete the `addMovement` method**

Find and delete the whole method (lines ~920-923):

```dart
  void addMovement(int minutes) {
    movementMinutes = (movementMinutes + minutes).clamp(0, 300);
    _commit();
  }
```

- [ ] **Step 6: Add `logActivity`, `deleteActivityLog`, and the goal getters**

Add directly after the `removeLog` method (which sits right after `addLog`, around line 902):

```dart
  void logActivity({
    required String type,
    String? label,
    required int minutes,
    double? miles,
  }) {
    final now = DateTime.now();
    final entry = ActivityLog(
      id: 'activity-$type-${now.microsecondsSinceEpoch}',
      type: type,
      label: label,
      minutes: minutes,
      miles: miles,
      loggedAt: now,
    );
    activityLogs = [entry, ...activityLogs];
    final dayKey = '${now.year}-${now.month}-${now.day}';
    _awardMomentum(
      eventId: 'activity:$dayKey:${entry.id}',
      points: 10,
      badges: const ['momentum-builder'],
    );
    _commit();
  }

  void deleteActivityLog(String id) {
    activityLogs = activityLogs.where((a) => a.id != id).toList();
    _commit();
  }

  int get dailyActiveMinutesGoal => switch (profile.activity) {
    'sedentary' => 15,
    'lightly' => 30,
    'moderately' => 45,
    'very' => 60,
    _ => 30,
  };

  int get waterGoalCups => 8;

  int get mealsGoalCount => 3;
```

- [ ] **Step 7: Fix the two call sites in `track_screen.dart` so the project compiles**

In `lib/screens/track_screen.dart`, delete the `_PlainStatTile` entry for movement (the `Expanded(child: _PlainStatTile(icon: HugeIcons.strokeRoundedWalking, value: '${state.movementMinutes}', ...))` block, lines ~239-254) and delete the `_CounterRow` entry for movement in `_openQuickLog` (lines ~361-367, the one with `title: 'Movement'`). Leave the surrounding `Row`/`Column` structure intact — Task 3 rebuilds this section fully, so this step only needs to make the file compile again, not look good yet.

- [ ] **Step 8: Run tests to verify they pass**

Run: `flutter test test/app_state_test.dart`
Expected: PASS — all 4 new tests green, plus all pre-existing tests in the file still green.

- [ ] **Step 9: Run the analyzer**

Run: `flutter analyze`
Expected: No issues found (confirms no other file still references `movementMinutes`/`addMovement`).

- [ ] **Step 10: Commit**

```bash
git add lib/state/app_state.dart lib/screens/track_screen.dart test/app_state_test.dart
git commit -m "feat: add ActivityLog model, replace movementMinutes with structured activity logging"
```

---

### Task 2: Activity logging bottom sheets

**Files:**
- Create: `lib/widgets/activity_log_sheet.dart`

**Interfaces:**
- Consumes: `AppState.logActivity({required String type, String? label, required int minutes, double? miles})` (from Task 1)
- Consumes: `showProductSheet<T>(BuildContext, {required String title, String? description, required WidgetBuilder builder})` from `lib/widgets/product_sheet.dart` (existing)
- Produces: `Future<void> showWalkRunLogSheet(BuildContext context, {required String type})` — `type` is `'walk'` or `'run'`
- Produces: `Future<void> showActivityPresetSheet(BuildContext context)` — shows the preset grid, then the same duration/distance form

**Design reference:** the existing manual meal-logging sheet pattern in `lib/screens/track_screen.dart`'s `_openQuickLog` (uses `showProductSheet` + `_CounterRow`-style rows) and the auth screens' bordered `TextField`s. This task does not have meaningful unit-testable logic beyond what Task 1 already tests (`logActivity`) — it is presentation wiring. Verification is a manual build + simulator check at the end of Task 3, once these sheets are wired into the real page.

- [ ] **Step 1: Write the sheet file**

```dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'app_toast.dart';
import 'product_sheet.dart';

const _activityPresets = [
  (type: 'strength', label: 'Strength training', icon: HugeIcons.strokeRoundedDumbbell01),
  (type: 'yoga', label: 'Yoga', icon: HugeIcons.strokeRoundedYoga01),
  (type: 'cycling', label: 'Cycling', icon: HugeIcons.strokeRoundedBicycle01),
  (type: 'swimming', label: 'Swimming', icon: HugeIcons.strokeRoundedSwimming),
  (type: 'sports', label: 'Sports', icon: HugeIcons.strokeRoundedFootballPitch),
  (type: 'other', label: 'Other', icon: HugeIcons.strokeRoundedActivity01),
];

String activityTypeLabel(String type, {String? label}) => switch (type) {
  'walk' => 'Walk',
  'run' => 'Run',
  'strength' => 'Strength training',
  'yoga' => 'Yoga',
  'cycling' => 'Cycling',
  'swimming' => 'Swimming',
  'sports' => 'Sports',
  'other' => (label != null && label.trim().isNotEmpty) ? label.trim() : 'Activity',
  _ => 'Activity',
};

List<List<dynamic>> activityTypeIcon(String type) => switch (type) {
  'walk' => HugeIcons.strokeRoundedWalking,
  'run' => HugeIcons.strokeRoundedRunningShoes,
  'strength' => HugeIcons.strokeRoundedDumbbell01,
  'yoga' => HugeIcons.strokeRoundedYoga01,
  'cycling' => HugeIcons.strokeRoundedBicycle01,
  'swimming' => HugeIcons.strokeRoundedSwimming,
  'sports' => HugeIcons.strokeRoundedFootballPitch,
  _ => HugeIcons.strokeRoundedActivity01,
};

Future<void> showWalkRunLogSheet(BuildContext context, {required String type}) {
  return showProductSheet<void>(
    context,
    title: 'Log a ${type == 'run' ? 'run' : 'walk'}',
    description: 'How long, and how far if you know it.',
    builder: (sheetContext) =>
        _DurationDistanceForm(type: type, showDistance: true),
  );
}

Future<void> showActivityPresetSheet(BuildContext context) {
  return showProductSheet<void>(
    context,
    title: 'Log an activity',
    description: 'What did you do?',
    builder: (sheetContext) => _ActivityPresetGrid(),
  );
}

class _ActivityPresetGrid extends StatelessWidget {
  const _ActivityPresetGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.sm,
        children: [
          for (final preset in _activityPresets)
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.tile),
              onTap: () {
                Navigator.of(context).pop();
                showProductSheet<void>(
                  context,
                  title: 'Log ${preset.label.toLowerCase()}',
                  description: 'How long did it take?',
                  builder: (sheetContext) => _DurationDistanceForm(
                    type: preset.type,
                    showDistance: false,
                    presetLabel: preset.type == 'other' ? preset.label : null,
                  ),
                );
              },
              child: Container(
                width: 104,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                ),
                child: Column(
                  children: [
                    HugeIcon(icon: preset.icon, size: 22, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text(
                      preset.label,
                      textAlign: TextAlign.center,
                      style: AppText.caption(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DurationDistanceForm extends StatefulWidget {
  final String type;
  final bool showDistance;
  final String? presetLabel;

  const _DurationDistanceForm({
    required this.type,
    required this.showDistance,
    this.presetLabel,
  });

  @override
  State<_DurationDistanceForm> createState() => _DurationDistanceFormState();
}

class _DurationDistanceFormState extends State<_DurationDistanceForm> {
  final _minutes = TextEditingController();
  final _miles = TextEditingController();
  final _otherLabel = TextEditingController();

  @override
  void dispose() {
    _minutes.dispose();
    _miles.dispose();
    _otherLabel.dispose();
    super.dispose();
  }

  void _save(BuildContext sheetContext) {
    final minutes = int.tryParse(_minutes.text.trim());
    if (minutes == null || minutes <= 0) return;
    final miles = widget.showDistance ? double.tryParse(_miles.text.trim()) : null;
    final label = widget.type == 'other' ? _otherLabel.text.trim() : widget.presetLabel;

    context.read<AppState>().logActivity(
      type: widget.type,
      label: label?.isNotEmpty == true ? label : null,
      minutes: minutes,
      miles: miles,
    );
    Navigator.of(sheetContext).pop();
    showAppToast(sheetContext, 'Logged ${activityTypeLabel(widget.type, label: label)}');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.type == 'other') ...[
            TextField(
              controller: _otherLabel,
              decoration: const InputDecoration(labelText: 'What did you do?'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _minutes,
            decoration: const InputDecoration(labelText: 'Minutes'),
            keyboardType: TextInputType.number,
            textInputAction: widget.showDistance ? TextInputAction.next : TextInputAction.done,
          ),
          if (widget.showDistance) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _miles,
              decoration: const InputDecoration(labelText: 'Miles (optional)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () => _save(context),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run the analyzer**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/activity_log_sheet.dart
git commit -m "feat: add walk/run/activity logging bottom sheets"
```

---

### Task 3: Rebuild the Track Today page

**Files:**
- Modify: `lib/screens/track_screen.dart`
- Test: `test/screen_smoke_test.dart`, `test/track_today_test.dart` (new)

**Interfaces:**
- Consumes: `AppState.activityLogs`, `AppState.logs`, `AppState.waterCups`, `AppState.dailyActiveMinutesGoal`, `AppState.waterGoalCups`, `AppState.mealsGoalCount` (Task 1)
- Consumes: `showWalkRunLogSheet(context, type: 'walk'|'run')`, `showActivityPresetSheet(context)`, `activityTypeLabel(...)`, `activityTypeIcon(...)` (Task 2)

- [ ] **Step 1: Write the failing widget test**

Create `test/track_today_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrition_platform/screens/track_screen.dart';
import 'package:nutrition_platform/state/app_state.dart';
import 'package:nutrition_platform/theme/theme.dart';

Future<AppState> loadedState() async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState();
  for (var i = 0; i < 50 && !state.loaded; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  return state;
}

Widget wrap(AppState state) {
  final router = GoRouter(
    initialLocation: '/track',
    routes: [GoRoute(path: '/track', builder: (_, _) => const TrackScreen())],
  );
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the zero-logs empty state when nothing is tracked today', (tester) async {
    final state = await loadedState();
    state.logs = [];
    state.activityLogs = [];
    state.waterCups = 0;

    await tester.pumpWidget(wrap(state));
    await tester.pumpAndSettle();

    expect(find.textContaining('Log your first meal'), findsOneWidget);
  });

  testWidgets('quick action row exposes all five log entry points', (tester) async {
    final state = await loadedState();
    await tester.pumpWidget(wrap(state));
    await tester.pumpAndSettle();

    expect(find.text('Meal'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Walk'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
  });

  testWidgets('timeline shows a logged activity alongside meals', (tester) async {
    final state = await loadedState();
    state.logActivity(type: 'walk', minutes: 20, miles: 1.5);

    await tester.pumpWidget(wrap(state));
    await tester.pumpAndSettle();

    expect(find.textContaining('Walk'), findsWidgets);
    expect(find.textContaining('20 min'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/track_today_test.dart`
Expected: FAIL — the empty-state copy, the quick-action labels, and the activity timeline entry don't exist yet in the current page.

- [ ] **Step 3: Replace the Today page content**

In `lib/screens/track_screen.dart`, replace the whole block from the page-header `Padding` (starting `Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 0), child: Row(...` around line 57) through the end of the meals list block (ending at the `Padding` that closes the `else` branch around line 313, right before the `CtaBannerCard` `Padding`) with:

```dart
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TRACK', style: AppText.kicker()),
                  const SizedBox(height: 8),
                  Text("What's today looking like?", style: AppText.h1()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedPills<String>(
                      values: const ['today', 'history'],
                      selected: 'today',
                      labelFor: (v) => v == 'today' ? 'Today' : 'History',
                      onChanged: (v) {
                        if (v == 'history') context.go('/track/history');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const AskPill(),
                ],
              ),
            ),
            // App Flow §3.4 node O — a designed screen, not copy. After a gap
            // this is the first thing on Track, and it names the gap warmly
            // instead of rendering it as a hole in a chart. No red, no streak,
            // no tally of the missed days. Copy is the client's own reference
            // wording (PRD §10.1, Q-11).
            if (state.lapseDays >= 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(AppRadius.hero),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You are back!!', style: AppText.h3()),
                      const SizedBox(height: 6),
                      Text(
                        'Here is a new menu suggestion or recipe to keep your momentum. You are making huge strides toward your goal.',
                        style: AppText.bodySm(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => context.go('/eat-out'),
                              child: const Text('Find an easy order'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.go('/cook'),
                              child: const Text('Quick recipe'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _TodaySummaryCard(
                mealsLogged: todayLogs.length,
                mealsGoal: state.mealsGoalCount,
                waterCups: state.waterCups,
                waterGoal: state.waterGoalCups,
                activeMinutes: todayActivityMinutes,
                activeMinutesGoal: state.dailyActiveMinutesGoal,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _QuickActionsRow(
                onMeal: () => _openQuickLog(context),
                onWater: () {
                  state.adjustWater(1);
                  showAppToast(context, 'Water added', addToInbox: false);
                },
                onWalk: () => showWalkRunLogSheet(context, type: 'walk'),
                onRun: () => showWalkRunLogSheet(context, type: 'run'),
                onActivity: () => showActivityPresetSheet(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Text("TODAY'S TIMELINE", style: AppText.kicker()),
            ),
            const SizedBox(height: 12),
            if (timelineItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _EmptyLog(onAdd: () => _openQuickLog(context)),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: timelineItems),
              ),
```

- [ ] **Step 4: Add the data-derivation variables**

In the `build` method, directly after the existing `todayLogs`/`calories`/`protein` block (right after `final remaining = (guide - calories).clamp(0, guide);`), add:

```dart
    final todayActivity = state.activityLogs
        .where(
          (item) =>
              item.loggedAt.year == today.year &&
              item.loggedAt.month == today.month &&
              item.loggedAt.day == today.day,
        )
        .toList();
    final todayActivityMinutes = todayActivity.fold<int>(
      0,
      (sum, item) => sum + item.minutes,
    );
    final timelineItems = <Widget>[
      for (final item in todayLogs)
        ThumbActionRow(
          image: item.image,
          title: item.title,
          subtitle:
              '${_sourceLabel(item.type)} · ${item.calories} cal · ${item.protein}g protein',
          onTap: () => _openLogDetails(context, item),
          onAction: () {
            state.removeLog(item.id);
            showAppToast(context, 'Removed from today');
          },
        ),
      for (final item in todayActivity)
        _ActivityTimelineRow(
          entry: item,
          onDelete: () {
            state.deleteActivityLog(item.id);
            showAppToast(context, 'Removed from today');
          },
        ),
    ]..sort((a, b) => 0); // placeholder — see Step 5 for real chronological sort
```

- [ ] **Step 5: Sort the timeline chronologically**

The placeholder sort in Step 4 can't compare `Widget`s. Replace the whole `timelineItems` construction in Step 4 with a sort-then-map approach — replace that block with:

```dart
    final timelineEntries = <(DateTime, Widget)>[
      for (final item in todayLogs)
        (
          item.loggedAt,
          ThumbActionRow(
            image: item.image,
            title: item.title,
            subtitle:
                '${_sourceLabel(item.type)} · ${item.calories} cal · ${item.protein}g protein',
            onTap: () => _openLogDetails(context, item),
            onAction: () {
              state.removeLog(item.id);
              showAppToast(context, 'Removed from today');
            },
          ),
        ),
      for (final item in todayActivity)
        (
          item.loggedAt,
          _ActivityTimelineRow(
            entry: item,
            onDelete: () {
              state.deleteActivityLog(item.id);
              showAppToast(context, 'Removed from today');
            },
          ),
        ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    final timelineItems = [for (final entry in timelineEntries) entry.$2];
```

- [ ] **Step 6: Add the three new widgets**

Add these to `lib/screens/track_screen.dart`, after the existing `_PlainStatTile` class:

```dart
class _TodaySummaryCard extends StatelessWidget {
  final int mealsLogged;
  final int mealsGoal;
  final int waterCups;
  final int waterGoal;
  final int activeMinutes;
  final int activeMinutesGoal;

  const _TodaySummaryCard({
    required this.mealsLogged,
    required this.mealsGoal,
    required this.waterCups,
    required this.waterGoal,
    required this.activeMinutes,
    required this.activeMinutesGoal,
  });

  @override
  Widget build(BuildContext context) {
    final nothingLoggedYet = mealsLogged == 0 && waterCups == 0 && activeMinutes == 0;
    final remaining = [
      if (mealsLogged < mealsGoal) 'meals',
      if (waterCups < waterGoal) 'water',
      if (activeMinutes < activeMinutesGoal) 'activity',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nothingLoggedYet)
            Text(
              'Log your first meal, glass of water, or walk to start tracking your day.',
              style: AppText.bodySm(color: AppColors.primaryForeground),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _GoalIndicator(
                    label: 'Meals',
                    value: '$mealsLogged/$mealsGoal',
                    complete: mealsLogged >= mealsGoal,
                  ),
                ),
                Expanded(
                  child: _GoalIndicator(
                    label: 'Water',
                    value: '$waterCups/$waterGoal cups',
                    complete: waterCups >= waterGoal,
                  ),
                ),
                Expanded(
                  child: _GoalIndicator(
                    label: 'Active',
                    value: '$activeMinutes/$activeMinutesGoal min',
                    complete: activeMinutes >= activeMinutesGoal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              remaining.isEmpty
                  ? 'All caught up for today.'
                  : '${remaining.length} thing${remaining.length == 1 ? '' : 's'} left today.',
              style: AppText.bodySm(color: AppColors.primaryForeground),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalIndicator extends StatelessWidget {
  final String label;
  final String value;
  final bool complete;

  const _GoalIndicator({
    required this.label,
    required this.value,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              complete ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: complete ? AppColors.accent : AppColors.primaryForeground,
            ),
            const SizedBox(width: 4),
            Text(label, style: AppText.caption(color: AppColors.primaryForeground)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppText.h3(color: AppColors.primaryForeground),
        ),
      ],
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onMeal;
  final VoidCallback onWater;
  final VoidCallback onWalk;
  final VoidCallback onRun;
  final VoidCallback onActivity;

  const _QuickActionsRow({
    required this.onMeal,
    required this.onWater,
    required this.onWalk,
    required this.onRun,
    required this.onActivity,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickActionChip(icon: HugeIcons.strokeRoundedRestaurant01, label: 'Meal', onTap: onMeal),
          _QuickActionChip(icon: HugeIcons.strokeRoundedDroplet, label: 'Water', onTap: onWater),
          _QuickActionChip(icon: HugeIcons.strokeRoundedWalking, label: 'Walk', onTap: onWalk),
          _QuickActionChip(icon: HugeIcons.strokeRoundedRunningShoes, label: 'Run', onTap: onRun),
          _QuickActionChip(icon: HugeIcons.strokeRoundedActivity01, label: 'Activity', onTap: onActivity),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: Container(
          width: 76,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.tile),
          ),
          child: Column(
            children: [
              HugeIcon(icon: icon, size: 20, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(label, style: AppText.caption()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTimelineRow extends StatelessWidget {
  final ActivityLog entry;
  final VoidCallback onDelete;

  const _ActivityTimelineRow({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final distance = entry.miles != null ? ', ${entry.miles} mi' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.highlight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: HugeIcon(
                icon: activityTypeIcon(entry.type),
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activityTypeLabel(entry.type, label: entry.label),
                    style: AppText.cardTitle(),
                  ),
                  Text(
                    '${entry.minutes} min$distance',
                    style: AppText.caption(),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: 'Remove',
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Add the import**

At the top of `lib/screens/track_screen.dart`, add:

```dart
import '../widgets/activity_log_sheet.dart';
```

- [ ] **Step 8: Run the new test to verify it passes**

Run: `flutter test test/track_today_test.dart`
Expected: PASS — all 3 tests green.

- [ ] **Step 9: Update the smoke test's expected copy**

In `test/screen_smoke_test.dart`, find `'/track': 'Keep your momentum',` and change it to:

```dart
    '/track': "What's today looking like?",
```

- [ ] **Step 10: Run the full test suite**

Run: `flutter test`
Expected: PASS — every test in the suite, including `screen_smoke_test.dart` and `app_state_test.dart`.

- [ ] **Step 11: Run the analyzer**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 12: Manual verification in the simulator**

This is presentation-heavy work that automated tests can't fully validate (visual hierarchy, spacing, whether the empty state actually reads as friendly rather than broken). Build and check by hand:

```bash
flutter build ios --simulator --debug
```

Launch on the booted simulator, navigate to the Track tab, and verify:
1. A fresh/empty-logs state shows the "Log your first meal..." card, not zeros or blank charts
2. Logging a meal, water, a walk, and an activity each show up immediately in the summary card's counts and in the timeline, newest first
3. The quick-action row scrolls smoothly and every one of the 5 actions opens the right sheet
4. Deleting a timeline entry (meal or activity) removes it and doesn't crash

- [ ] **Step 13: Commit**

```bash
git add lib/screens/track_screen.dart test/track_today_test.dart test/screen_smoke_test.dart
git commit -m "feat: rebuild Track Today page — action-first summary, quick actions, unified timeline"
```

---

## Self-Review Notes

**Spec coverage:**
- Data model (walk/run/activity types, minutes, optional distance) → Task 1
- Goals derived from onboarding activity level, fixed water/meal goals → Task 1
- Today summary card (meals/water/active-minutes, "what's left" line) → Task 3, `_TodaySummaryCard`
- Quick actions row, always visible, 5 entry points → Task 3, `_QuickActionsRow`
- Walk/Run form, Activity preset grid with free-text "Other" → Task 2
- Unified chronological timeline (meals + activity) → Task 3, `timelineEntries` sort
- Empty state (no zeros/broken charts, single friendly line) → Task 3, `_TodaySummaryCard.nothingLoggedYet`
- Explicit non-goals (Nutrition/Activity tabs, History beyond meals, charts, AI, walkthrough) → untouched by this plan, confirmed by scope of Tasks 1-3

**Placeholder scan:** none — every step has complete code, no TBD/TODO.

**Type consistency:** `ActivityLog` (Task 1) fields (`id`, `type`, `label`, `minutes`, `miles`, `loggedAt`) match usage in Task 2 (`logActivity` call signature) and Task 3 (`_ActivityTimelineRow`, `activityTypeIcon`, `activityTypeLabel`). `AppState.dailyActiveMinutesGoal`/`waterGoalCups`/`mealsGoalCount` (Task 1) match `_TodaySummaryCard` constructor args (Task 3).
