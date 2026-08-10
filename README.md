# ForkThis! — Flutter (native mobile)

Shared Flutter implementation for iOS, Android, and the browser demo. The parallel
React web app lives at [`../app-react/`](../app-react/) — maintained separately, not superseded.
Built 2026-07-31, superseding the earlier Expo + React Native Reusables plan in
[`../docs/ENGINEERING-PLAN.md`](../docs/ENGINEERING-PLAN.md) §3.1 — Flutter is now the mobile stack
decision.

```bash
flutter pub get
flutter run                 # any connected simulator/device
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3213
flutter build web
flutter analyze             # 0 issues as of this writing
```

Runs at native size on the iOS Simulator (verified on iPhone 17 Pro, iOS 26.5) and
as a responsive browser demo. No Android verification has been done yet.

---

## What this is, and isn't

This is a **faithful visual and interactive port** of the web prototype's product screens — same
copy, same fixture data, same layout language, same interaction rules (guest-first, no shame states,
save-prompt-inside-the-sheet, etc.) — rebuilt as real Flutter widgets. It is not a WebView wrapper and
shares no code with `../app/`; it shares **token values**, kept in sync by hand (see below).

**Ported:** onboarding (welcome → 3 intro slides → age/goal/stats/surgical-context/activity
questionnaire → loading → resume prompt), Home, Eat Out (For you / By goal / Nearest, sparse + dense
restaurant browse, location pre-prompt), Search, Restaurant detail, Fast-hack detail (incl. save/sign-up
sheet), Cook (incl. recipe drawer), Track (incl. quick-log drawer), You (incl. profile/saved/settings
drawers and the clear-data confirmation).

**Not ported, deliberately:** `Foundations` and the AI-imagery reference page (`../app/src/screens/
Foundations.tsx`, `ImageryReference.tsx`) and the `ScreenIndex` review surface — these are internal
design-system documentation for reviewing the *web* build, not product screens, and porting them
wouldn't serve "a native app users actually use." If a Dart-side equivalent design-system doc page
becomes useful later, build it fresh rather than transliterating the web one.

---

## 2026-08-02 — flow polish, notifications, and scroll navigation

- Onboarding and questionnaire actions now live in safe-area-aware fixed footers, while the question
  content remains independently scrollable. Progress indicators use the real device top inset plus
  deliberate breathing room instead of a fixed status-bar spacer.
- The results builder now runs as a seven-second staged sequence with synchronized progress, orbit,
  pulse, changing glyphs, task completion, and a short ready state before entering Home.
- `AppShell` supports an optional fixed action above the tab bar and a compact top bar that animates in
  after vertical scrolling. The order-detail `Log this` action uses the fixed region; Home, Eat Out,
  Cook, Track, and You use the scroll-aware header.
- Action feedback is now an animated top popup and is also recorded in a local, persistent in-app
  notification inbox. The inbox is available from the bell in every scroll-aware top bar, supports
  unread counts, individual read state, and mark-all-read.
- All `go_router` destinations use a shared fade-and-slide page transition. Onboarding keeps its own
  keyed in-place transition for query-driven steps.

## 2026-08-02 — Profile, Cook, and Track redesign

- Added a branded, reduced-motion-aware splash route before onboarding and matched the native iOS and
  Android launch backgrounds to it so there is no white frame between launch and Flutter rendering.
- Rebuilt You as a detailed profile: editable identity, units and activity, visible goal/health
  context, computed daily rhythm, saved library, reminders, privacy controls, and validated local
  profile editing.
- Rebuilt Cook around functional pace filters and scannable nutrition-first recipe rows. Recipe taps
  now open dedicated route-backed pages with save state, interactive ingredient and step checklists,
  and a fixed meal logging action.
- Rebuilt Track with a daily guide, quick actions, reversible water and movement controls, manual meal
  entry with validation, detailed log sheets, removal, and direct routes into recipes or restaurant
  orders.

## 2026-08-02 — Home and Eat Out redesign

- Rebuilt Home around the persisted daily state: calorie progress, protein, water and movement context,
  quick actions, personalized next choices, recent logs, and the existing scroll-triggered navigation.
- Rebuilt Eat Out into three focused modes for personalized orders, goal-matched choices, and nearby
  places. Search, category filtering, location consent, empty states, restaurant routes, and smart-order
  routes remain functional.
- Reworked restaurant detail into a vertically scannable, nutrition-first list and removed the fixed-height
  horizontal card layout that overflowed on smaller simulator widths. Smart-order detail now uses the
  actual order image, shared typography, and the shared nutrition summary.

---

## Tokens: shared values, not a shared file

`lib/theme/tokens.dart` mirrors `../app/src/index.css`'s `:root` block by **value**. There is no build
step that generates one from the other — Flutter cannot consume a Tailwind CSS file. If the web app's
palette, type ramp, radius, or spacing changes, **this file needs the matching hand-edit**, or the two
apps will visibly drift. Engineering Plan §3.1 adds a CI token-parity check to the backlog for exactly
this reason; it does not exist yet.

### Known accessibility findings, ported as-is

The current web palette (`#f8fafe` / `#0f3a27` / `#f27424` etc.) was audited by computing real
OKLCH→sRGB→WCAG contrast ratios, not estimating them. Two real failures exist in the **live palette**
and were ported faithfully rather than silently corrected (this is a port, not an unrequested redesign):

- `warm-foreground` on `warm` (#5c2b06 on #f27424): **4.05:1** — fails the 4.5:1 body-text floor, clears
  3:1 for large/bold text. Currently used only on bold caption-weight badge text; do not use `warm` as a
  plain body-text color.
- `coral-foreground` on `coral` (#fdfcf8 on #e96e50): **2.99:1** — fails even the 3:1 non-text UI floor.
  `coral` is used as an icon/accent fill only (Track screen's protein flame icon); do not use it as a
  text or interactive-control color without revisiting the value.
- `input` now equals `border` (both `#dbdee6`, ~1.3:1 against background) — it no longer functions as a
  distinct ≥3:1 control-boundary token the way the design brief's original override list called for.
  `border-strong` (#838691, verified ≥3:1) is the token that actually clears the non-text UI floor.

Flag these to design before shipping; don't silently tighten them here without a matching web-side fix.

---

## Flutter-specific de-defaulting (the web app's DESIGN-BRIEF §5, ported to different knobs)

Material's defaults need the same corrections shadcn's did — different framework, same complaint
(decorative elevation, undersized touch targets, animated skeletons read as "generic" and "unpolished").
Applied in `lib/theme/theme.dart` and `lib/widgets/skeleton.dart`:

- **No decorative elevation.** `elevation: 0` on `CardTheme`, `AppBarTheme`, both button themes. The only
  two places elevation/shadow appears are true overlays (`BottomSheetThemeData.modalElevation`,
  `DialogTheme.elevation`) and the floating tab bar (`widgets/app_shell.dart`'s `AppTabBar`, which draws
  its own manual `BoxShadow` rather than using Material elevation, to match the web app's shadow values).
- **44px floor on every control.** `minimumSize` set explicitly on `ElevatedButton`/`OutlinedButton`/
  `TextButton`/`IconButton` styles and on `InputDecorationTheme`'s `constraints`. Material's own defaults
  range 36–48px depending on widget and do not guarantee this.
- **Static skeletons.** `widgets/skeleton.dart` is a plain `Container`, no shimmer package, no animation.
- **No Dart-side equivalent of `design-qa.mjs` exists yet.** The web app enforces its overrides with a
  script that scans component source for violations; port that idea here (a widget test asserting theme
  elevation is 0 and button `minimumSize` ≥44) before this file grows past what one person can eyeball on
  review.

---

## The safe-area bug class — read this before adding a new full-bleed screen

Flutter has no equivalent of CSS's `env(safe-area-inset-top)` pattern applied automatically — a
`Scaffold` body does **not** get safe-area padding unless something adds it. This bit twice during the
initial port:

1. **Home and Eat Out** both use a full-bleed background (gradient on Home, solid `primary` on Eat Out)
   with content that should be inset from the notch/status bar but a background that shouldn't be. The
   fix in both: put `SafeArea(bottom: false, ...)` **inside** the `DecoratedBox`, wrapping only the
   content — not outside it, which would inset the background too and lose the full-bleed look.
2. **Cook, Track, You** have no full-bleed concern (plain background), so they just wrap their `ListView`
   in `SafeArea(bottom: false, ...)` directly.

Before this fix, "Good afternoon Steven" rendered directly under the status bar clock, illegible. It was
caught by screenshotting the actual running app, not by code review — the bug is invisible in the
widget tree and only shows up rendered. Screenshot every new full-bleed screen at launch.

A second real bug caught the same way: the Eat Out recommendation carousel's cards overflowed their
fixed height by up to ~38pt on a two-line title, visible on-device as Flutter's yellow/black debug
overflow banner. Fixed by sizing the card container to the actual worst-case content height (176 image +
padding + up to two title lines + chip row = 344pt, not the original 300) and capping the title to
`maxLines: 2` so it can never grow further. **Both bugs were invisible in `flutter analyze` and in a
successful `xcodebuild` — analysis and compilation catch syntax and type errors, not layout overflow or
missing safe-area insets. Only a rendered screenshot catches those.**

---

## 2026-08-03 — warm food palette implementation (superseded below)

Implemented the supplied six-color reference across the native Flutter app. The
shared theme now uses off-white (`#F7F5F0`) for the page canvas, cream (`#F6E1C4`)
for soft surfaces, orange (`#FF8C00`) for promotional emphasis, red-orange
(`#DA4928`) for active states, yellow (`#FEC12C`) for appetite highlights, and dark
brown (`#492219`) for type and icons. Compact filled controls and control boundaries
use darker derivatives where the exact source accents do not meet WCAG 2.2 AA.

Typography is now bundled locally as Archivo Black for campaign-scale display
headlines and Manrope for UI, body copy, labels, and numeric data. The implementation
also reduces card/button radii, keeps shadows limited to true overlays, and carries
the color roles through splash, onboarding, Home, Eat Out, Cook, Track, profile,
detail screens, notifications, search, and bottom navigation.

## 2026-08-03 — client discovery feedback completion

Reconciled the completed discovery CSV into an acceptance matrix at
`docs/client-feedback-implementation-2026-08-03.md`. Added the missing three-step
guided tour that starts after onboarding and can be replayed from Settings, a
designed return-after-lapse experience after a three-day gap, and reminder opt-out
behavior that removes and blocks reminder-class inbox items without hiding normal
activity confirmations.

Sensitive surgical context now defaults to `Prefer not to say`, separates that from
`No surgical context`, and explains its educational-only local use. Profile now
contains a neutral mission page without committing unapproved founder identities.
Recipe details include calories, protein, carbs, fat, serving, and photography; the
dense restaurant fixture now verifies the restaurant-first browse at 32 entries.
Tentative gender, name, and founder answers remain pending rather than being presented
as approved product decisions.

## 2026-08-03 — citrus palette and image direction (superseded below)

Replaced the earlier brown/orange palette with colors sampled directly from the
client's citrus reference: Cosmic Latte (`#FFF4E0`), Spring Green (`#007531`),
Yellow (`#FFE53A`), Sky Blue (`#07C1F2`), Yellow Green (`#AAE044`), and supporting
Orange (`#F47B20`). Dark ink green (`#063D22`) and pale derivatives are used only
where body-text or control-boundary contrast requires them.

Brand and campaign surfaces now use flat citrus, leaf, peel-ribbon, and broad
organic-shape illustration. Splash and the Home hero use custom assets in that
direction. Restaurant orders and recipes keep bright real-food photography because
those surfaces help users inspect and choose an actual meal.

## 2026-08-03 — warm fruit-poster palette and image direction

Rebalanced the visual system around the client's latest reference. The dominant
brand colors are Margarine Yellow (`#F5D630`), Neon Orange (`#FF551D`), and Lava
Red (`#CF161A`). Rose Bonbon (`#FE51A4`) and Lavender Indigo (`#9E5AFD`) are
available only as limited accents. A warm cream canvas and dark auburn ink keep
body copy and controls readable.

Primary actions, selected navigation, focus states, and high-emphasis labels use
Lava Red. Promotional surfaces use Neon Orange, while Margarine Yellow carries
small highlights and status emphasis. The Splash and Home hero illustrations now
use the reference's saturated retro fruit-poster direction with flat geometric food
forms and subtle screen-print texture. Green is limited to natural leaf and success
signals rather than acting as a brand-dominant field.

## 2026-08-05 — React demo audit parity pass

Synced the newer React demo completion work into the Flutter route graph. Track now
has route-backed history and manual-log pages. You now has route-backed saved
library, profile edit, settings, help, ask, privacy, and terms pages instead of
requiring modal-only access. Logs now persist date, meal, and portion metadata so
today and history can be separated, and profile settings include reminder time,
dietary preferences, and location sorting preference.

Verified with `flutter analyze`, `flutter test`, `flutter build web`, and a served
web artifact at `http://127.0.0.1:3215/`.

## 2026-08-03 — image-first onboarding and half-height Home hero

The three onboarding introduction steps now use distinct 4:3 poster illustrations
for restaurant ordering, personalized nutrition, and clinically grounded empathy.
Each step keeps its action fixed at the bottom and uses a segmented red-on-neutral
progress indicator. Standard screen canvases continue to use the shared off-white
background token.

Home now opens with a dedicated illustration sized to half of the usable viewport.
The greeting, search action, value proposition, and restaurant-order actions sit in
off-white bands above and below the image so the opening remains legible and gives
the rest of the product room to enter the first scroll. Shared elevated, filled,
outlined, and text buttons now use fully rounded stadium shapes; icon buttons use
circles. Their 48–60 px touch targets remain borderless.

---

## 2026-08-01 (2) — onboarding redesign + animations

Redesigned the full onboarding flow (`lib/screens/onboarding/onboarding_screen.dart`,
909 lines) — Welcome, 3 intro slides, the 5-question questionnaire, and the loading
screen. The user asked for "Framer Motion and Lenis"-quality animation; those are
JS-only libraries with no Flutter equivalent, so this uses Flutter's own animation
system to the same end (confirmed with the user before starting — scope is the
Flutter app, not the web prototype).

## 2026-08-06 — ForkThis! moments and momentum

Client direction now positions the product around real-life "ForkThis!" moments:
eating out, cravings, low time, calories left, and returning after a lapse. The
Flutter prototype includes a shared moment picker, branded `ForkThis!` copy,
positive-only momentum points, behavior badges, and a celebratory comeback flow.
Missed days do not reset progress or create broken-streak messaging.

**The load-bearing fix**: every one of the 9 onboarding sub-steps used to build its
own `AppShell`/`Scaffold`, and `go_router` rebuilds the same `/onboarding` route in
place rather than pushing a new one — so no page-transition animation ever fired,
full stop, regardless of what was added. Fixed by hoisting a single `AppShell` to
`OnboardingScreen` and wrapping the step content in `AnimatedSwitcher`, keyed on the
numeric step (`KeyedSubtree(key: ValueKey(step))`) so it fires even between two
steps of the same widget type (e.g. intro slide 1→2, which share `_IntroContent`).

**New dependency**: [`flutter_animate`](https://pub.dev/packages/flutter_animate)
`^4.5.2` — declarative `.animate().fadeIn().slideY()` chains for staggered entrance
animations, added specifically for this redesign.

**What's animated**: step-to-step transitions (fade + slide, 340ms); staggered
entrance of each step's title/body/CTA; a large tinted `HugeIcon` glyph added to
Welcome and each intro slide (previously pure text — the app's icon-forward language
carried into a flow that had none); press-scale + animated checkmark on selectable
cards (`_GoalOption`, `_SelectOption`, driven off `InkWell.onHighlightChanged`, not a
second gesture recognizer, so it can't compete with the tap itself); animated
progress-segment fill; animated crossfade between the imperial/metric stat inputs.
The loading-plan ring, percentage, and status-dot states are all derived from **one**
`TweenAnimationBuilder<double>` (0→0.85 over the same 2200ms as the
`Future.delayed` that navigates to `/home`) rather than a separate
`AnimationController` — deliberately, so the ring, the count-up text, and the dots
can never drift out of sync, and there is no controller to remember to `dispose()`.

**Token-hygiene fix found along the way**: several onboarding widgets used bare
`TextStyle(fontSize: ..., fontWeight: ...)` instead of `AppText.*`, which meant they
could drift from the shared type system. They now use the same named text styles as
the rest of the app. Also swapped `Colors.white` for `AppColors.card` (identical
value, `0xFFFFFFFF`) for consistency with the rest of the app's token usage.

**Verified**: `flutter analyze` clean throughout. On-device, walked Welcome → all 3
intro slides → Age → Goal (including tapping between goal cards to confirm the
selection/checkmark animation) → Stats, all rendering correctly with no exceptions.
The loading screen's `TweenAnimationBuilder` + delayed navigation completes cleanly
(landed on Home with no crash). Did not walk Surgical/Activity individually — both
reuse `_SelectOption`/`_QuestionFrameContent`, already verified elsewhere in the same
session.

---

## 2026-08-01 redesign — nav, icons, font, three screens, prod-readiness pass

Five changes landed together, verified in this order (font/nav → icons → screen
redesigns → prod-readiness) to keep each change bisectable:

- **Nav bar**: `widgets/app_shell.dart`'s `AppTabBar` changed from a floating,
  inset, rounded-pill bar to a bar fixed flush to the screen's bottom edge
  (full-width, top border + soft shadow, `SafeArea` *inside* the decoration so the
  background still runs to the true bottom under the home indicator — same
  full-bleed-background pattern as Home/Eat Out). Added **Home** as a fifth tab
  destination (`/home` existed as a route already but wasn't reachable from the tab
  bar). `AppShell` computes its bottom content padding from `AppTabBar.totalHeight()`
  so the two can't drift apart.
- **Icons**: swapped every `Icons.*` (Material) reference for `hugeicons` v1.1.7
  (`HugeIcon(icon: HugeIcons.strokeRoundedXxx, ...)` — the free tier ships
  stroke-rounded style only). Constant names were pulled from the installed
  package's `lib/styles/stroke_rounded.dart`, not guessed. Any widget that took an
  `IconData` field (`_TabDef`, `_GoalOption`, `_Metric`, `_MenuRow`,
  `_QuickLogRow`, `_StatCell`) had its field type changed to
  `List<List<dynamic>>` (`HugeIcon` takes JSON icon data, not `IconData`).
- **Font (superseded 2026-08-03)**: this pass originally bundled Satoshi. The current
  fresh fast-food direction replaces it with locally bundled Archivo Black for
  display headlines and Manrope for all UI and body text; see the entry above.
- **Redesigned Cook, Track, You**: kept each screen's state/data logic, refreshed
  the visual layer — tinted-circle icon badges (matching `FastHackCard`'s
  language), a nutrition-first "choose by mood" rail on Cook, a snapshot stat strip
  on You (saved / calories today / water), arrow-in-circle affordance on menu rows.
  One real bug found and fixed along the way: Cook's featured-recipe hero used
  `Container(constraints: BoxConstraints(minHeight: 288))` wrapping
  `Stack(fit: StackFit.expand)` inside a vertical `ListView` — `ListView` gives
  unbounded main-axis height, so a `minHeight`-only constraint let the `Stack` try
  to expand to infinity, which aborted layout for the *entire* `ListView` (blank
  white screen, no error printed, tab bar still fine). This predates the redesign —
  Cook was never individually re-screenshotted after the original safe-area fix
  (see the entry below). Fixed by giving the hero a definite `height: 288` instead
  of a bare `minHeight`. Worth remembering: an unbounded-height crash inside a
  scrollable can look identical to "nothing rendered," with zero console output.
- **Prod-readiness** (scoped to client-shell build/ship readiness, not backend,
  tests, CI, or store submission — there's no backend yet): global error handlers
  (`FlutterError.onError`, `PlatformDispatcher.onError`, `runZonedGuarded`) added
  in `main.dart` so an uncaught exception logs instead of failing silently; Android
  launcher label changed from the raw package name `nutrition_platform` to
  `Nutrition Platform`; verified an **iOS release build succeeds**
  (`xcodebuild ... -configuration Release -sdk iphoneos CODE_SIGNING_ALLOWED=NO`).
  **Android release build could not be verified** — this machine has no local JDK,
  so `flutter build apk --release` fails before touching any app code
  (`Unable to locate a Java Runtime`). Excluded from this pass: app icon (still the
  Flutter default — no real brand mark exists yet per the brand-direction open
  question in the project wiki), native splash screen, Android verification of any
  kind, automated tests, CI.

---

## Verified 2026-07-31

Walked on-device (iPhone 17 Pro simulator, iOS 26.5) end-to-end through: Welcome → 3 intro slides → age
question (native `showDatePicker`, live 13+ validation) → goal → body stats → surgical context →
activity → loading (auto-advances) → Home → Eat Out (For you view, post-fix) → Track (real computed
state: 750/1850 cal ring, starter log entries with bundled images, delete action). Cook and You share the
same `ProductSheet`/list patterns and got the same safe-area fix, but were not individually
re-screenshotted after that fix — worth a pass before calling this done.

Not yet verified: Android (no emulator run yet), dark mode (not attempted — the web prototype's dark
mode is dev-only and never exposed to real users either, per `feedback_coded_design_prototypes` decision
history), 200% text scaling / Dynamic Type, VoiceOver/TalkBack, and the full Cook/You interactive flows
(recipe drawer, profile edit, clear-data dialog) beyond confirming they compile and the screen loads.

---

## Build/run notes specific to this session

- `flutter run --release` **fails on iOS Simulator** — release mode isn't supported there. Use
  `flutter run` (debug) or `flutter run --profile`.
- If `flutter run` reports `Xcode build done` followed immediately by `Could not build the application
  for the simulator` / `Exited with status code 255` with no further detail, a raw `xcodebuild build`
  from `ios/` against the same destination usually succeeds and gives a real error if there is one —
  this happened once during the initial port and turned out to be resource contention from a second,
  orphaned `flutter run` process, not a real build failure.
- **`xcodebuild build` alone does not install the app onto the simulator.** After rebuilding outside
  `flutter run` (e.g. via raw `xcodebuild`), you must `xcrun simctl install <device> <path-to-.app>`
  before `xcrun simctl launch` — otherwise you're relaunching the previous build and any fix you just
  made won't appear. This cost real time during the safe-area fix verification (the first "post-fix"
  screenshot was actually the pre-fix binary).
