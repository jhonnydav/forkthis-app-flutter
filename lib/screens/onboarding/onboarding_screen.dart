import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../data/fixtures.dart';
import '../../state/app_state.dart';
import '../../product.dart';
import '../../theme/tokens.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_shell.dart';
import '../auth_screen.dart';

/// Ported step-for-step from `../app/src/screens/Onboarding.tsx`. Step numbers and
/// their meaning match the web app's `?step=N` exactly:
///   0 welcome (Get Started / Sign in) · 1-3 intro slides · 4 age gate (DOB)
///   5 goal · 6 body stats · 7 surgical context · 8 activity, which opens the
///   create-account sheet (with a sign-in option) → /loading → /home.
///
/// Redesigned 2026-08-01: one `AppShell`/`Scaffold` for the whole flow (each step
/// used to wrap its own, which meant no navigation transition ever fired — go_router
/// rebuilds the same `/onboarding` route in place, it doesn't push a new one). Steps
/// now cross-fade+slide via `AnimatedSwitcher`, keyed on the numeric step so it fires
/// even between two steps of the same widget type (e.g. intro slide 1→2).
class OnboardingScreen extends StatefulWidget {
  final int step;
  const OnboardingScreen({super.key, required this.step});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _restoredDraft = false;
  DateTime birthDate = DateTime(1994, 10, 12);
  Goal goal = Goal.lose;
  String units = 'imperial';
  final feet = TextEditingController(text: '5');
  final inches = TextEditingController(text: '10');
  final weightLb = TextEditingController(text: '185');
  final heightCm = TextEditingController(text: '178');
  final weightKg = TextEditingController(text: '84');
  String surgical = 'prefer_not';
  String activity = 'lightly';

  int get age {
    final now = DateTime.now();
    var result = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      result -= 1;
    }
    return result;
  }

  double get heightInCentimeters {
    if (units == 'metric') return double.tryParse(heightCm.text) ?? 0;
    final totalInches =
        (double.tryParse(feet.text) ?? 0) * 12 +
        (double.tryParse(inches.text) ?? 0);
    return totalInches * 2.54;
  }

  double get weightInKilograms {
    if (units == 'metric') return double.tryParse(weightKg.text) ?? 0;
    return (double.tryParse(weightLb.text) ?? 0) * 0.45359237;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restoredDraft) return;
    final state = context.watch<AppState>();
    if (!state.loaded) return;
    _restoredDraft = true;
    if (state.onboardingStep == 0 && !state.onboardingCompleted) return;

    final profile = state.profile;
    goal = profile.goal;
    units = profile.units;
    surgical = profile.surgical;
    activity = profile.activity;
    birthDate = DateTime.tryParse(profile.birthDate) ?? birthDate;
    if (profile.heightCm > 0) {
      heightCm.text = profile.heightCm.round().toString();
      final totalInches = profile.heightCm / 2.54;
      feet.text = (totalInches ~/ 12).toString();
      inches.text = (totalInches - (totalInches ~/ 12) * 12).round().toString();
    }
    if (profile.weightKg > 0) {
      weightKg.text = profile.weightKg.round().toString();
      weightLb.text = (profile.weightKg / 0.45359237).round().toString();
    }
  }

  void go(int next) {
    context.read<AppState>().markOnboardingStep(next);
    context.go('/onboarding?step=$next');
  }

  @override
  void dispose() {
    feet.dispose();
    inches.dispose();
    weightLb.dispose();
    heightCm.dispose();
    weightKg.dispose();
    super.dispose();
  }

  Widget _stepContent(int step) {
    if (step == 0) return _WelcomeContent(onNext: () => go(1));
    if (step >= 1 && step <= 3) {
      return _IntroContent(index: step - 1, onNext: () => go(step + 1));
    }
    if (step == 4) return _AgeStep(state: this);
    if (step == 5) return _GoalStep(state: this);
    if (step == 6) return _StatsStep(state: this);
    if (step == 7) return _SurgicalStep(state: this);
    if (step == 8) return _ActivityStep(state: this);
    return const _LoadingPlanContent();
  }

  static Widget _stepTransition(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step.clamp(0, 9);
    return AppShell(
      tabBar: false,
      child: ColoredBox(
        // Figma's onboarding canvas (node 321:48) sits on Highlight (#FFF4E0),
        // one step warmer than the app's usual Background — distinguishes the
        // flow from the rest of the app while the value-prop slides' full-bleed
        // photos sit on top of it.
        color: AppColors.highlight,
        child: SafeArea(
          // Steps 0-3 (welcome + intro slides) are full-bleed photo screens that
          // already run their own inner SafeArea around their text — consuming
          // the top inset again here paints a solid Highlight rectangle behind
          // the status bar instead of letting the photo run edge-to-edge under
          // it, so those steps skip the outer top inset entirely.
          top: step > 3,
          bottom: false,
          child: SizedBox.expand(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: _stepTransition,
              child: KeyedSubtree(
                key: ValueKey(step),
                child: _stepContent(step),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActionArea extends StatelessWidget {
  final List<Widget> children;
  const _BottomActionArea({required this.children});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.highlight,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

/// Segmented step indicator. Each segment's fill smoothly crossfades rather than
/// snapping, so advancing a step reads as progress rather than a hard cut.
class _Progress extends StatelessWidget {
  final int current;
  final int total;
  const _Progress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: List.generate(total, (i) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 7),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                height: 5,
                decoration: BoxDecoration(
                  color: i < current
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _IntroProgress extends StatelessWidget {
  final int current;
  const _IntroProgress({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final active = index < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: active ? 19 : 18,
          height: 5,
          margin: EdgeInsets.only(right: index == 2 ? 0 : 5),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        );
      }),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _PillButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onPressed == null ? 0.55 : 1,
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

const _introSteps = [
  (
    badge: 'Fast food hacks',
    title: 'Eat smart, anywhere.',
    body:
        'Real life happens. We show you exactly what to order at your favorite restaurants to stay entirely on track, completely guilt-free.',
    accent: true,
    image: 'assets/images/figma/onboarding-fast-order-photo.png',
    visualLabel: 'Opening a grilled chicken order in a white takeaway box',
  ),
  (
    badge: 'Tailored to you',
    title: 'Personalized to your context.',
    body:
        'No cookie-cutter templates. Your nutritional plans adapt to your unique body stats, goals, and specific medical or surgical context.',
    accent: false,
    image: 'assets/images/figma/onboarding-personalized-bowl-photo.png',
    visualLabel: 'Balanced chicken grain bowl with orange and avocado',
  ),
  (
    badge: 'Built by people who get it',
    title: 'Clinical depth, real empathy.',
    body:
        'Co-founded by a renowned plastic surgeon and a weight health creator who lived the 260 lb loss journey. Pure support, zero intimidation.',
    accent: true,
    image: 'assets/images/figma/onboarding-clinical-empathy-photo.png',
    visualLabel: 'Two people sharing a warm chicken and quinoa bowl',
  ),
];

class _WelcomeContent extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomeContent({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/figma/onboarding-forkthis-first-screen-v2.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IntroProgress(current: 0),
                const Spacer(),
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedFavourite,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                      'Your ForkThis! moment starts here.',
                      style: AppText.headline(
                        42,
                        height: 44,
                        color: AppColors.primary,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 420.ms)
                    .slideY(
                      begin: 0.12,
                      end: 0,
                      delay: 80.ms,
                      duration: 420.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 14),
                Text(
                  '$productName helps you choose what to order or cook when real life puts your healthier habits on the spot.',
                  style: AppText.bodySm(
                    color: AppColors.textPrimary,
                  ).copyWith(height: 1.38),
                ),
                const SizedBox(height: 16),
                _PillButton(label: 'Get Started', onPressed: onNext),
                const SizedBox(height: 8),
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/login'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.borderStrong),
                      backgroundColor: AppColors.card.withValues(alpha: 0.86),
                    ),
                    child: const Text('Sign in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}

class _IntroContent extends StatelessWidget {
  final int index;
  final VoidCallback onNext;
  const _IntroContent({required this.index, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final item = _introSteps[index];
    return Semantics(
      button: true,
      label: index == 2 ? "Let's Begin" : 'Next',
      onTap: onNext,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onNext,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              item.image,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              semanticLabel: item.visualLabel,
            ).animate(key: ValueKey('photo$index')).fadeIn(duration: 300.ms),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IntroProgress(current: index + 1),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        item.badge.toUpperCase(),
                        style: AppText.kicker(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                          item.title,
                          style: AppText.headline(
                            39,
                            height: 41,
                            color: AppColors.primary,
                          ),
                        )
                        .animate(key: ValueKey('title$index'))
                        .fadeIn(delay: 70.ms, duration: 280.ms)
                        .slideY(
                          begin: 0.07,
                          end: 0,
                          delay: 70.ms,
                          duration: 280.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 8),
                    Text(
                          item.body,
                          style: AppText.bodySm(
                            color: AppColors.textPrimary,
                          ).copyWith(height: 1.38),
                        )
                        .animate(key: ValueKey('body$index'))
                        .fadeIn(delay: 120.ms, duration: 280.ms),
                    const SizedBox(height: 12),
                    _PillButton(
                      label: index == 2 ? "Let's Begin" : 'Next',
                      onPressed: onNext,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionFrameContent extends StatelessWidget {
  final int step;
  final String title;
  final String? description;
  final Widget child;
  final VoidCallback? onAction;
  final String actionLabel;
  final bool compact;

  const _QuestionFrameContent({
    required this.step,
    required this.title,
    this.description,
    required this.child,
    required this.onAction,
    this.actionLabel = 'Continue',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Progress(current: step, total: 5),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, compact ? 16 : 22, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Question $step of 5'.toUpperCase(),
                    style: AppText.kicker(color: AppColors.primary),
                  ),
                ).animate(key: ValueKey('label$step')).fadeIn(duration: 300.ms),
                const SizedBox(height: 14),
                Text(
                      title,
                      style: AppText.headline(38, color: AppColors.primary),
                    )
                    .animate(key: ValueKey('title$step'))
                    .fadeIn(delay: 40.ms, duration: 320.ms)
                    .slideY(
                      begin: 0.08,
                      end: 0,
                      delay: 40.ms,
                      duration: 320.ms,
                      curve: Curves.easeOutCubic,
                    ),
                if (description != null) ...[
                  const SizedBox(height: 10),
                  Text(
                        description!,
                        style: AppText.bodySm(
                          color: AppColors.mutedForeground,
                        ).copyWith(height: 1.35),
                      )
                      .animate(key: ValueKey('desc$step'))
                      .fadeIn(delay: 90.ms, duration: 320.ms),
                ],
                SizedBox(height: compact ? 18 : 26),
                child
                    .animate(key: ValueKey('body$step'))
                    .fadeIn(delay: 140.ms, duration: 320.ms),
              ],
            ),
          ),
        ),
        _BottomActionArea(
          children: [_PillButton(label: actionLabel, onPressed: onAction)],
        ),
      ],
    );
  }
}

/// Selectable card with a subtle press-scale — pure UI feedback, no gesture
/// recognizer competes with `InkWell`'s own since the scale is driven off
/// `InkWell.onHighlightChanged` rather than a second tap detector.
class _GoalOption extends StatefulWidget {
  final String title;
  final String body;
  final List<List<dynamic>> icon;
  final bool selected;
  final VoidCallback onTap;
  const _GoalOption({
    required this.title,
    required this.body,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_GoalOption> createState() => _GoalOptionState();
}

class _GoalOptionState extends State<_GoalOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 107),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: widget.selected ? AppColors.accent : AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: widget.selected ? AppColors.action : AppColors.border,
              width: widget.selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.selected
                      ? AppColors.primary
                      : AppColors.highlight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: HugeIcon(
                  icon: widget.icon,
                  color: widget.selected
                      ? AppColors.primaryForeground
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 22,
                        height: 27 / 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.body,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 14,
                        height: 15 / 14,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectOption extends StatefulWidget {
  final String title;
  final String body;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;
  const _SelectOption({
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_SelectOption> createState() => _SelectOptionState();
}

class _SelectOptionState extends State<_SelectOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(minHeight: widget.compact ? 74 : 78),
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: widget.compact ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.accent.withValues(alpha: 0.92)
                : AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: widget.selected ? AppColors.action : AppColors.border,
              width: widget.selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: widget.compact ? 18 : 16,
                        height: 24 / (widget.compact ? 18 : 16),
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.body,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 13,
                        height: 18 / 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.selected
                        ? AppColors.action
                        : AppColors.borderStrong,
                    width: 2,
                  ),
                  color: widget.selected
                      ? AppColors.action
                      : Colors.transparent,
                ),
                child: AnimatedScale(
                  scale: widget.selected ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutBack,
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedTick01,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeStep extends StatefulWidget {
  final _OnboardingScreenState state;
  const _AgeStep({required this.state});
  @override
  State<_AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<_AgeStep> {
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final valid = s.age >= 13 && s.age <= 120;
    final formatted =
        '${_month(s.birthDate.month)} ${s.birthDate.day}, ${s.birthDate.year}';
    return _QuestionFrameContent(
      step: 1,
      title: 'How old are you?',
      description:
          'To provide personalized clinical insights, we need to verify your age. You must be 13 or older.',
      onAction: valid
          ? () {
              context.read<AppState>().updateProfile(
                birthDate: s.birthDate.toIso8601String(),
              );
              s.go(5);
            }
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () async {
              HapticFeedback.selectionClick();
              final picked = await showDatePicker(
                context: context,
                initialDate: s.birthDate,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => s.birthDate = picked);
            },
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date of Birth',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 18,
                      height: 28 / 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        formatted,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 18,
                          height: 28 / 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowDown01,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Row(
              key: ValueKey(valid),
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedShield01,
                  size: 16,
                  color: valid ? AppColors.primary : AppColors.destructive,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    valid
                        ? 'Verified (${s.age} years old) · Over 13+ requirement'
                        : 'You must be between 13 and 120 years old.',
                    style: AppText.bodySm(
                      color: valid
                          ? AppColors.mutedForeground
                          : AppColors.destructive,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _month(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];
}

class _GoalStep extends StatefulWidget {
  final _OnboardingScreenState state;
  const _GoalStep({required this.state});
  @override
  State<_GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends State<_GoalStep> {
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return _QuestionFrameContent(
      step: 2,
      title: "What's your main goal?",
      onAction: () {
        context.read<AppState>().updateProfile(goal: s.goal);
        s.go(6);
      },
      child: Column(
        children: [
          _GoalOption(
            title: 'Lose weight',
            body: 'Sustainable fat loss with muscle preservation',
            icon: HugeIcons.strokeRoundedArrowDownRight01,
            selected: s.goal == Goal.lose,
            onTap: () => setState(() => s.goal = Goal.lose),
          ),
          const SizedBox(height: 12),
          _GoalOption(
            title: 'Gain muscle',
            body: 'Build physical strength and energetic support',
            icon: HugeIcons.strokeRoundedDumbbell01,
            selected: s.goal == Goal.gain,
            onTap: () => setState(() => s.goal = Goal.gain),
          ),
          const SizedBox(height: 12),
          _GoalOption(
            title: 'Maintain weight',
            body: 'Focus on longevity, metabolism and vitality',
            icon: HugeIcons.strokeRoundedFavourite,
            selected: s.goal == Goal.maintain,
            onTap: () => setState(() => s.goal = Goal.maintain),
          ),
        ],
      ),
    );
  }
}

class _StatsStep extends StatefulWidget {
  final _OnboardingScreenState state;
  const _StatsStep({required this.state});
  @override
  State<_StatsStep> createState() => _StatsStepState();
}

class _StatsStepState extends State<_StatsStep> {
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final imperialValid =
        (double.tryParse(s.feet.text) ?? 0) >= 3 &&
        (double.tryParse(s.feet.text) ?? 0) <= 8 &&
        (double.tryParse(s.inches.text) ?? -1) >= 0 &&
        (double.tryParse(s.inches.text) ?? -1) <= 11 &&
        (double.tryParse(s.weightLb.text) ?? 0) >= 50;
    final metricValid =
        (double.tryParse(s.heightCm.text) ?? 0) >= 90 &&
        (double.tryParse(s.heightCm.text) ?? 0) <= 245 &&
        (double.tryParse(s.weightKg.text) ?? 0) >= 23;
    final valid = s.units == 'imperial' ? imperialValid : metricValid;

    return _QuestionFrameContent(
      step: 3,
      title: 'What are your stats?',
      description:
          'Use what you know today — you can always update this later.',
      onAction: valid
          ? () {
              context.read<AppState>().updateProfile(
                units: s.units,
                heightCm: s.heightInCentimeters,
                weightKg: s.weightInKilograms,
              );
              s.go(7);
            }
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _UnitToggle(
                    label: 'Imperial (ft, lbs)',
                    active: s.units == 'imperial',
                    onTap: () => setState(() => s.units = 'imperial'),
                  ),
                ),
                Expanded(
                  child: _UnitToggle(
                    label: 'Metric (cm, kg)',
                    active: s.units == 'metric',
                    onTap: () => setState(() => s.units = 'metric'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: s.units == 'imperial'
                ? Column(
                    key: const ValueKey('imperial'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Height',
                        style: AppText.label(color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _UnitInput(
                              controller: s.feet,
                              unit: 'ft',
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _UnitInput(
                              controller: s.inches,
                              unit: 'in',
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Weight',
                        style: AppText.label(color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      _UnitInput(
                        controller: s.weightLb,
                        unit: 'lbs',
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('metric'),
                    children: [
                      Expanded(
                        child: _UnitInput(
                          controller: s.heightCm,
                          unit: 'cm',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _UnitInput(
                          controller: s.weightKg,
                          unit: 'kg',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _UnitToggle({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            color: active ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _UnitInput extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final ValueChanged<String> onChanged;
  const _UnitInput({
    required this.controller,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppText.label(
        color: AppColors.primary,
      ).copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        suffixText: unit,
        suffixStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SurgicalStep extends StatefulWidget {
  final _OnboardingScreenState state;
  const _SurgicalStep({required this.state});
  @override
  State<_SurgicalStep> createState() => _SurgicalStepState();
}

class _SurgicalStepState extends State<_SurgicalStep> {
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return _QuestionFrameContent(
      step: 4,
      title: 'Any surgical context?',
      description:
          'Optional. This only changes the educational context we show before or after surgery, and you can update it later.',
      onAction: () {
        context.read<AppState>().updateProfile(surgical: s.surgical);
        s.go(8);
      },
      compact: true,
      child: Column(
        children: [
          _SelectOption(
            compact: true,
            title: 'Yes, preparing for surgery',
            body: 'Optimizing my nutritional runway',
            selected: s.surgical == 'prepare',
            onTap: () => setState(() => s.surgical = 'prepare'),
          ),
          _SelectOption(
            compact: true,
            title: 'Yes, recovering from surgery',
            body: 'Gently supporting tissue healing and repair',
            selected: s.surgical == 'recover',
            onTap: () => setState(() => s.surgical = 'recover'),
          ),
          _SelectOption(
            compact: true,
            title: 'No surgical context',
            body: 'Standard, healthy lifestyle guidance',
            selected: s.surgical == 'none',
            onTap: () => setState(() => s.surgical = 'none'),
          ),
          _SelectOption(
            compact: true,
            title: 'Prefer not to say',
            body: 'Continue without tailoring this information',
            selected: s.surgical == 'prefer_not',
            onTap: () => setState(() => s.surgical = 'prefer_not'),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              'This answer stays in local app storage in this build. It is used for educational context only, not diagnosis or medical advice. You can change it later.',
              style: AppText.bodySm(
                color: AppColors.primary,
              ).copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityStep extends StatefulWidget {
  final _OnboardingScreenState state;
  const _ActivityStep({required this.state});
  @override
  State<_ActivityStep> createState() => _ActivityStepState();
}

class _ActivityStepState extends State<_ActivityStep> {
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return _QuestionFrameContent(
      step: 5,
      title: 'How active are you right now?',
      description:
          "This establishes your metabolic baseline so we don't under-nourish your recovery.",
      actionLabel: 'See My Plan',
      onAction: () {
        context.read<AppState>().updateProfile(
          goal: s.goal,
          units: s.units,
          surgical: s.surgical,
          activity: s.activity,
          birthDate: s.birthDate.toIso8601String(),
          heightCm: s.heightInCentimeters,
          weightKg: s.weightInKilograms,
        );
        // Account creation comes after the questionnaire, not before it —
        // the new user answers everything first, then is asked to save
        // their progress (with a sign-in option for returning users).
        openCreateAccountSheet(context, afterOnboarding: true);
      },
      child: Column(
        children: [
          _SelectOption(
            title: 'Sedentary',
            body: 'Desk job, gentle short walks',
            selected: s.activity == 'sedentary',
            onTap: () => setState(() => s.activity = 'sedentary'),
          ),
          _SelectOption(
            title: 'Lightly active',
            body: 'Light exercise 1-3 days/week',
            selected: s.activity == 'lightly',
            onTap: () => setState(() => s.activity = 'lightly'),
          ),
          _SelectOption(
            title: 'Moderately active',
            body: 'Moderate workouts 3-5 days/week',
            selected: s.activity == 'moderately',
            onTap: () => setState(() => s.activity = 'moderately'),
          ),
          _SelectOption(
            title: 'Very active',
            body: 'Hard, physical training almost daily',
            selected: s.activity == 'very',
            onTap: () => setState(() => s.activity = 'very'),
          ),
        ],
      ),
    );
  }
}

const _planExitDelay = Duration(milliseconds: 650);

/// S-08 — brief transitional beat between finishing onboarding and landing in the
/// app. Deliberately NOT a multi-second results reveal: client discovery feedback
/// (2026-08-02, raw/universal-perk-discovery-questionnaire-responses.csv) was explicit
/// that a new user should go "straight to the App where it will walk them through
/// important features" — no summary, no first-recommendation screen. This replaces
/// the earlier ~7s orbiting-progress design with the shortest beat that still reads
/// as intentional rather than a hard cut. The guided tour then picks up on Home
/// immediately after this transition.
class _LoadingPlanContent extends StatefulWidget {
  const _LoadingPlanContent();
  @override
  State<_LoadingPlanContent> createState() => _LoadingPlanContentState();
}

class _LoadingPlanContentState extends State<_LoadingPlanContent> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_planExitDelay, () {
      if (mounted) {
        // Account creation already happened right after the intro slides
        // (see `_stepContent`'s step-3 gate), so by the time the
        // questionnaire finishes there is nothing left to sign up for —
        // go straight to the loading beat and then Home's tour.
        final state = context.read<AppState>();
        state.markOnboardingStep(9);
        state.completeOnboarding();
        context.go('/loading');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(AppColors.brandBlue),
            ),
          ).animate().fadeIn(duration: 220.ms),
          const SizedBox(height: 16),
          Text(
            'Setting things up…',
            style: AppText.bodySm(color: AppColors.mutedForeground),
          ).animate().fadeIn(delay: 80.ms, duration: 220.ms),
        ],
      ),
    );
  }
}

class LoadingPlanScreen extends StatefulWidget {
  final bool returning;
  const LoadingPlanScreen({super.key, this.returning = false});

  @override
  State<LoadingPlanScreen> createState() => _LoadingPlanScreenState();
}

class _LoadingPlanScreenState extends State<LoadingPlanScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_planExitDelay, () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      tabBar: false,
      child: ColoredBox(
        color: AppColors.highlight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.returning
                    ? 'Refreshing your next ForkThis! moment...'
                    : 'Building your first set of picks...',
                textAlign: TextAlign.center,
                style: AppText.bodySm(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// S-09 — resume prompt. Branch A of an open client decision (PRD Q-3).
class OnboardingResumeScreen extends StatelessWidget {
  const OnboardingResumeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      tabBar: false,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WELCOME BACK',
                      style: AppText.bodySm(
                        color: AppColors.questionnaireLabel,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ).animate().fadeIn(duration: 380.ms),
                    const SizedBox(height: 8),
                    Text(
                          'Your setup is still here.',
                          style: AppText.h1(color: AppColors.primary),
                        )
                        .animate()
                        .fadeIn(delay: 60.ms, duration: 380.ms)
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          delay: 60.ms,
                          duration: 380.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 12),
                    Text(
                      'Continue with your body stats or start the short setup again.',
                      style: AppText.bodySm(color: AppColors.mutedForeground),
                    ).animate().fadeIn(delay: 120.ms, duration: 380.ms),
                    const SizedBox(height: 16),
                    Text(
                      '$productName keeps partial answers on this device for 30 days.',
                      style: AppText.caption(),
                    ),
                  ],
                ),
              ),
            ),
            _BottomActionArea(
              children: [
                _PillButton(
                  label: 'Continue setup',
                  onPressed: () {
                    final savedStep = context
                        .read<AppState>()
                        .onboardingStep
                        .clamp(1, 8);
                    context.go('/onboarding?step=$savedStep');
                  },
                ).animate().fadeIn(delay: 190.ms, duration: 380.ms),
                const SizedBox(height: 10),
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<AppState>().markOnboardingStep(0);
                      context.go('/onboarding?step=0');
                    },
                    child: const Text('Start over'),
                  ),
                ).animate().fadeIn(delay: 240.ms, duration: 380.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
