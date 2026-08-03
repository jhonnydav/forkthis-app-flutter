# Nutrition Platform Product Flow Audit

Date: 2026-08-02

## Scope

This audit covers the native Flutter app from first launch through onboarding,
results generation, Home, Eat Out, order detail, local saving and logging, Cook,
Track, profile/settings, notifications, search, persistence, error recovery, and
large-text behavior. The primary device was an iPhone 17 Pro simulator on iOS
26.5 at 393 x 852 logical pixels. Widget coverage also runs every primary route
at a 1.35 text scale.

This is a local-first prototype. It has no production API, user account system,
clinical rules service, restaurant data feed, analytics service, or OS-level
notification scheduler.

## Evidence

- `audit-evidence/onboarding-after.png`: first-launch welcome with bottom actions
  and truthful local-storage information.
- `audit-evidence/home-after.png`: returning-user launch after onboarding,
  including persisted logging totals.
- `audit-evidence/profile-after.png`: profile context with persisted height,
  weight, goal, activity, and surgical context.
- Automated route evidence: `test/screen_smoke_test.dart` renders all nine
  primary/detail routes at 393 x 852 with 1.35 text scaling.

## Flow Results

### 1. First launch and onboarding: Pass after fixes

1. Splash routes a new install to the welcome screen.
2. Intro steps advance with a fixed bottom action and spaced progress rail.
3. Questionnaire answers are saved after every step.
4. Date of birth, unit preference, height, weight, goal, surgical context, and
   activity are persisted to the local profile.
5. An interrupted questionnaire resumes at the actual last saved step.
6. Starting over resets the draft to step zero.
7. The staged results screen now takes several seconds and communicates each
   analysis phase before routing to Home.
8. A completed user skips onboarding on subsequent launches.

The former prototype email/password prompts were removed. Collecting credentials
without a secure backend created a misleading and unsafe account flow. The app
now explains that data is stored locally and allows saved orders without an
account gate.

### 2. Home and primary navigation: Pass

1. Home reflects calories, protein, water, and movement from shared state.
2. Quick actions route to Eat Out and Cook.
3. The bottom navigation reaches Home, Eat Out, Cook, Track, and You.
4. Scroll-aware top navigation is supplied by the shared app shell.
5. Returning-user startup lands on Home with prior local activity intact.

### 3. Eat Out and order detail: Pass for bundled data

1. Restaurant, goal, nearby, dense-data, and category views remain routable.
2. Restaurant guide counts now use the actual bundled guide count; restaurants
   without a guide say `Menu review pending` instead of overpromising content.
3. Order detail keeps `Log this` fixed above bottom navigation.
4. Logging updates totals, displays confirmation, and appears in Track.
5. Saving works directly on this device and no longer opens a fake sign-up flow.

### 4. Search: Pass for local guide search

Search now scores real bundled order data by title, restaurant, details, health
goals, conditions, protein intent, coffee intent, sugar intent, and calorie
limits. Unknown queries return an honest empty state. Copy clearly labels this
as on-device guide search rather than implying a live AI or restaurant search.

### 5. Cook and recipe detail: Pass

1. Filters return real subsets of the bundled recipe catalog.
2. Recipe detail, ingredient checklist, steps, saving, and logging are connected.
3. Fixed horizontal metadata and section headers now wrap at larger text sizes.

### 6. Track: Pass for local daily state

1. Logged orders and recipes update daily calories and protein.
2. Water and movement counters clamp to safe non-negative bounds.
3. Quick logging, custom meals, removal, empty state, and success feedback work.
4. Daily totals and quick actions reflow vertically at larger text sizes.

### 7. Profile, settings, and notifications: Pass locally

1. Profile displays onboarding context and actual saved measurements.
2. Profile editing and local reminder preference updates persist.
3. In-app toasts can also add bounded inbox notifications.
4. Clearing local data resets profile, logs, saved items, notifications, and
   onboarding state, then returns to first-run onboarding.
5. Unknown routes show a recovery screen instead of a dead end.

## Accessibility Review

- Primary routes pass widget rendering at 1.35 text scale without overflow.
- Buttons use semantic Material controls, tooltips, and touch-sized targets.
- Reduced-motion handling exists for page and loading animation behavior.
- Important confirmations are visible in-app rather than relying on color alone.

Not yet verified: a full VoiceOver rotor/order audit, TalkBack, switch control,
keyboard-only navigation, 200% text scale, Android font metrics, and contrast
measurement against every image state.

## Remaining Product Requirements

### P0 before production or clinical claims

1. Replace local-only profiles with a secure authentication and encrypted sync
   architecture, including account recovery, deletion, export, and session
   revocation. Do not restore password fields until this exists.
2. Establish clinician-approved recommendation rules, content governance,
   contraindication review, versioning, disclaimers, and escalation boundaries.
3. Add privacy policy, terms, informed consent, health-data classification,
   retention rules, and jurisdiction-specific compliance review.
4. Replace bundled restaurant/menu fixtures with a validated, timestamped data
   source and clear availability/freshness states.
5. Add production crash reporting and privacy-safe observability without logging
   health details, credentials, or free-form meal data.

### P1 for a complete consumer product

1. Real OS notifications with explicit permission education, configurable
   schedules, timezone handling, deep links, and a system-settings recovery path.
2. A goal engine that calculates and explains targets from stored measurements
   under reviewed clinical rules; the current 1,850-calorie guide is static.
3. Meal history by date, edit/undo, duplicate protection, serving sizes, barcode
   scanning, photo/manual entry, and export.
4. Restaurant availability, location permission handling, favorites, recent
   searches, dietary exclusions, allergens, and menu-last-reviewed timestamps.
5. Offline-first sync conflict handling once accounts and backend storage exist.

### P2 quality and growth

1. Formal VoiceOver/TalkBack and 200% text-scale certification on iOS/Android.
2. Localization, regional units, dynamic timezone/day boundaries, and RTL review.
3. Privacy-safe funnel analytics and opt-in research feedback.
4. Expanded automated interaction tests for sheets, forms, destructive actions,
   deep links, interrupted writes, and corrupted local state.

## Verification Matrix

| Scenario | Result |
| --- | --- |
| New-user onboarding to Home | Pass on iOS simulator |
| Interrupted onboarding state | Pass in state tests |
| Returning-user relaunch | Pass on iOS simulator |
| Order log to Track continuity | Pass on iOS simulator |
| Profile measurement continuity | Pass on iOS simulator |
| Search intents and empty result | Pass in unit tests |
| Nine routes at 1.35 text scale | Pass in widget tests |
| Static analysis | Pass |
| Android runtime | Not run; no configured JDK |
| VoiceOver and TalkBack | Requires dedicated manual pass |

## Release Position

The local prototype flow is coherent and testable end to end. It should not be
described as production-ready, clinically validated, cloud-synced, or capable of
real push reminders until the P0/P1 systems above are implemented and reviewed.
