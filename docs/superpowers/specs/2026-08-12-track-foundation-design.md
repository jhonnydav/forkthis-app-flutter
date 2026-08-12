# Track Page — Foundation (Subproject 1 of 4)

## Context

The Track page currently feels like a passive dashboard: a vague "Keep your momentum" header, a wall of stat tiles, and a meal-only log list. Users don't immediately understand what they can log or what to do first.

The full redesign requested is large — activity tracking (which doesn't exist in the app today), an action-first Today view, a new-user walkthrough, a Nutrition/Activity split with history and date ranges, new chart types, and an AI insights engine. These are largely independent subsystems. This spec covers only the first, foundational slice; later slices depend on this one existing first.

**Decomposition (agreed with user):**
1. **Foundation** (this spec) — activity data model + action-first Today redesign
2. Nutrition/Activity split + History views with date ranges + charts
3. AI Insights ("Ask about my progress" + surfaced patterns)
4. New-user walkthrough

## Goal

A user opening Track should immediately understand: what's logged today, what's left, and how to log something new — without hunting through the interface.

## Current data model (unchanged, for reference)

- `LoggedItem` — meal logs: id, sourceId, type, title, calories, protein, image, loggedAt, meal, portion
- `waterCups` — int, 0–16, incremented via `addWaterCup()`/`addWaterCups(n)`
- `momentumPoints`, `streakDays`, `longestStreakDays` — existing gamification, unaffected by this spec
- No activity/exercise data exists anywhere in `AppState` today

## New data model

```dart
class ActivityLog {
  final String id;
  final String type;     // 'walk' | 'run' | 'strength' | 'yoga' | 'cycling' | 'swimming' | 'sports' | 'other'
  final String? label;   // free-text, only used when type == 'other'
  final int minutes;     // active minutes, required
  final double? miles;   // distance, optional — offered for walk/run, hidden for other types
  final DateTime loggedAt;

  Map<String, dynamic> toJson() => {...};
  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(...);
}
```

**AppState additions:**
- `List<ActivityLog> activityLogs = []` — empty by default, no starter fixture data (a fresh user hasn't logged anything; this is what makes the empty state meaningful rather than staged)
- Persisted via the existing `toJson`/`fromJson`/local-storage round-trip, same pattern as `logs`
- `int get dailyActiveMinutesGoal` — derived from `profile.activity`:
  - `sedentary` → 15
  - `lightly` → 30
  - `moderately` → 45
  - `very` → 60
- `int get waterGoalCups` — fixed at 8
- `int get mealsGoalCount` — fixed at 3
- `void logActivity({required String type, String? label, required int minutes, double? miles})` — appends an `ActivityLog`, awards momentum points via the same mechanism `logMeal`/manual logging already uses
- `void deleteActivityLog(String id)` — mirrors `deleteLog`

No changes to `LoggedItem`, existing meal logging, water counter mechanics, or the momentum/streak system — this is additive only.

## Today page layout

Three stacked blocks replace the current header + stat-tile wall. The existing Today/History segmented control at the top of the page is unchanged — History continues to show meals only, unchanged, for this pass.

### 1. Today summary card
Red hero card, visually consistent with Home's existing hero card pattern (not a new visual language). Contains three compact progress indicators side by side:
- Meals — e.g. "2/3" against `mealsGoalCount`
- Water — e.g. "5/8 cups" against `waterGoalCups`
- Active minutes — e.g. "20/30 min" against `dailyActiveMinutesGoal`

Each indicator is tappable and jumps to that category's quick-log action. Below the three indicators, one plain-language line reflecting remaining goals: "2 things left today" or, when all three are met, "All caught up for today." No numeric "momentum score" jargon in this card — that concept stays with the existing `momentumPoints` display elsewhere on the page, unchanged.

**Empty state (zero logs today):** the card shows "Log your first meal, glass of water, or walk to start tracking your day" in place of the three indicators. The quick-action row (below) is unchanged and immediately actionable — the empty state is a single line, not a separate illustrated screen.

### 2. Quick actions row
Five compact chip-buttons, always visible, directly below the summary card: **Log Meal, Log Water, Log Walk, Log Run, Log Activity**. No extra taps or menus to find them (per the core requirement — actions must not require searching the interface).

- **Log Meal** — existing meal-logging flow, unchanged
- **Log Water** — existing water counter increment, unchanged
- **Log Walk / Log Run** — opens a small bottom sheet: minutes (required), miles (optional), Save. Same visual shape as the existing manual meal-log sheet.
- **Log Activity** — opens a preset grid (Strength, Yoga, Cycling, Swimming, Sports, Other); tapping a preset drops into the same minutes/optional-distance form. Selecting "Other" adds a free-text label field.

All three new flows call `logActivity(...)` and award momentum points the same way meal logging does today.

### 3. Today's timeline
Chronological list mixing meal logs and activity logs together, e.g.:
- "7:30 AM — Logged breakfast"
- "12:15 PM — 25 min walk, 1.8 mi"
- "1:00 PM — Logged lunch"

Replaces the current meal-only list for the Today view. Directly answers "what have I done today" at a glance without opening History.

## Explicitly out of scope for this pass

- Nutrition/Activity tab split
- Real Activity History (History still shows meals only, unchanged)
- Date-range switching (7-day / 30-day / custom)
- Charts, trend visualizations, streak/consistency scoring beyond what already exists
- AI insights, "Ask about my progress"
- New-user walkthrough

These are subprojects 2–4, to be spec'd separately once this foundation exists.
