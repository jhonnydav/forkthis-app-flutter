import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../data/fixtures.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/product_sheet.dart';

/// Ported step-for-step from `../app/src/screens/Onboarding.tsx`. Step numbers and
/// their meaning match the web app's `?step=N` exactly:
///   0 welcome · 1-3 intro slides · 4 age gate (DOB) · 5 goal · 6 body stats
///   7 surgical context · 8 activity · 9 loading plan → auto-advance to /home
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
  DateTime birthDate = DateTime(1994, 10, 12);
  Goal goal = Goal.lose;
  String units = 'imperial';
  final feet = TextEditingController(text: '5');
  final inches = TextEditingController(text: '10');
  final weightLb = TextEditingController(text: '185');
  final heightCm = TextEditingController(text: '178');
  final weightKg = TextEditingController(text: '84');
  String surgical = 'recover';
  String activity = 'lightly';

  int get age {
    final now = DateTime.now();
    var result = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) result -= 1;
    return result;
  }

  void go(int next) => context.go('/onboarding?step=$next');

  Widget _stepContent(int step) {
    if (step == 0) return _WelcomeContent(onNext: () => go(1));
    if (step >= 1 && step <= 3) return _IntroContent(index: step - 1, onNext: () => go(step + 1));
    if (step == 4) return _AgeStep(state: this);
    if (step == 5) return _GoalStep(state: this);
    if (step == 6) return _StatsStep(state: this);
    if (step == 7) return _SurgicalStep(state: this);
    if (step == 8) return _ActivityStep(state: this);
    return const _LoadingPlanContent();
  }

  static Widget _stepTransition(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step.clamp(0, 9);
    return AppShell(
      tabBar: false,
      child: Column(
        children: [
          const _StatusBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 340),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: _stepTransition,
              child: KeyedSubtree(key: ValueKey(step), child: _stepContent(step)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 44);
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(total, (i) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                height: 6,
                decoration: BoxDecoration(
                  color: i < current ? AppColors.primary : AppColors.secondary,
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
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
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
    body: 'Real life happens. We show you exactly what to order at your favorite restaurants to stay entirely on track, completely guilt-free.',
    accent: true,
    icon: HugeIcons.strokeRoundedRestaurant01,
  ),
  (
    badge: 'Tailored to you',
    title: 'Personalized to your context.',
    body: 'No cookie-cutter templates. Your nutritional plans adapt to your unique body stats, goals, and specific medical or surgical context.',
    accent: false,
    icon: HugeIcons.strokeRoundedTarget01,
  ),
  (
    badge: 'Built by people who get it',
    title: 'Clinical depth, real empathy.',
    body: 'Co-founded by a renowned plastic surgeon and a weight health creator who lived the 260 lb loss journey. Pure support, zero intimidation.',
    accent: true,
    icon: HugeIcons.strokeRoundedFavourite,
  ),
];

/// A single large tinted glyph behind the copy — the app's icon-forward language
/// (already used on Home/Cook/Track/You) carried into onboarding without inventing
/// new photography or illustration for a flow that previously had none at all.
class _HeroGlyph extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color tint;
  const _HeroGlyph({required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(AppRadius.xxl)),
      child: HugeIcon(icon: icon, size: 38, color: AppColors.primary),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomeContent({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroGlyph(icon: HugeIcons.strokeRoundedFavourite, tint: AppColors.accent)
              .animate()
              .fadeIn(duration: 420.ms, curve: Curves.easeOut)
              .slideY(begin: 0.15, end: 0, duration: 420.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Text('Your turning point starts here.', style: AppText.h1(color: AppColors.primary)),
          )
              .animate()
              .fadeIn(delay: 80.ms, duration: 420.ms, curve: Curves.easeOut)
              .slideY(begin: 0.12, end: 0, delay: 80.ms, duration: 420.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Text(
              'A warmer, scientifically credible home for sustainable weight health. No paywalls, no judgment.',
              style: AppText.bodySm(color: AppColors.mutedForeground),
            ),
          )
              .animate()
              .fadeIn(delay: 150.ms, duration: 420.ms, curve: Curves.easeOut)
              .slideY(begin: 0.12, end: 0, delay: 150.ms, duration: 420.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 24),
          _PillButton(label: 'Get Started', onPressed: onNext)
              .animate()
              .fadeIn(delay: 230.ms, duration: 380.ms)
              .slideY(begin: 0.1, end: 0, delay: 230.ms, duration: 380.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showSignIn(context),
              child: const Text('I already have an account'),
            ),
          ).animate().fadeIn(delay: 290.ms, duration: 380.ms),
        ],
      ),
    );
  }

  void _showSignIn(BuildContext context) {
    final email = TextEditingController();
    final password = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showProductSheet(
      context,
      title: 'Welcome back',
      description: 'Sign in to continue with your saved plan on this device.',
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email', style: AppText.label()),
              const SizedBox(height: 8),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),
              Text('Password', style: AppText.label()),
              const SizedBox(height: 8),
              TextFormField(
                controller: password,
                obscureText: true,
                validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters' : null,
              ),
              const SizedBox(height: 20),
              _PillButton(
                label: 'Continue',
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  context.read<AppState>().updateProfile(email: email.text);
                  Navigator.of(context).pop();
                  showAppToast(context, 'Signed in');
                  context.go('/home');
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Prototype sign-in. Credentials remain on this device and are not sent to a server.',
                textAlign: TextAlign.center,
                style: AppText.caption(),
              ),
            ],
          ),
        ),
      ),
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
    return Column(
      children: [
        _Progress(current: index + 1, total: 3),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroGlyph(icon: item.icon, tint: item.accent ? AppColors.accent : AppColors.secondary)
                    .animate(key: ValueKey('glyph$index'))
                    .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.15, end: 0, duration: 380.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.accent ? AppColors.accent : AppColors.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(item.badge.toUpperCase(),
                      style: AppText.caption(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700)),
                ).animate(key: ValueKey('badge$index')).fadeIn(delay: 60.ms, duration: 340.ms),
                const SizedBox(height: 12),
                Text(item.title, style: AppText.h1(color: AppColors.primary))
                    .animate(key: ValueKey('title$index'))
                    .fadeIn(delay: 110.ms, duration: 340.ms)
                    .slideY(begin: 0.1, end: 0, delay: 110.ms, duration: 340.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 12),
                Text(item.body, style: AppText.bodySm(color: AppColors.mutedForeground))
                    .animate(key: ValueKey('body$index'))
                    .fadeIn(delay: 160.ms, duration: 340.ms),
                const SizedBox(height: 24),
                _PillButton(label: index == 2 ? "Let's Begin" : 'Next', onPressed: onNext)
                    .animate(key: ValueKey('cta$index'))
                    .fadeIn(delay: 220.ms, duration: 340.ms),
              ],
            ),
          ),
        ),
      ],
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
            padding: EdgeInsets.fromLTRB(24, compact ? 16 : 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Questionnaire $step of 5',
                        style: AppText.bodySm(color: AppColors.questionnaireLabel).copyWith(fontWeight: FontWeight.w700))
                    .animate(key: ValueKey('label$step'))
                    .fadeIn(duration: 300.ms),
                const SizedBox(height: 8),
                Text(title, style: AppText.h1(color: AppColors.primary))
                    .animate(key: ValueKey('title$step'))
                    .fadeIn(delay: 40.ms, duration: 320.ms)
                    .slideY(begin: 0.08, end: 0, delay: 40.ms, duration: 320.ms, curve: Curves.easeOutCubic),
                if (description != null) ...[
                  const SizedBox(height: 8),
                  Text(description!, style: AppText.body(color: AppColors.mutedForeground))
                      .animate(key: ValueKey('desc$step'))
                      .fadeIn(delay: 90.ms, duration: 320.ms),
                ],
                SizedBox(height: compact ? 16 : 24),
                child.animate(key: ValueKey('body$step')).fadeIn(delay: 140.ms, duration: 320.ms),
                SizedBox(height: compact ? 16 : 24),
                _PillButton(label: actionLabel, onPressed: onAction),
              ],
            ),
          ),
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
  const _GoalOption({required this.title, required this.body, required this.icon, required this.selected, required this.onTap});

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
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 107),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.selected ? AppColors.primary : AppColors.border, width: widget.selected ? 2 : 1),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.selected ? AppColors.accent : AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: HugeIcon(icon: widget.icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: -0.2)),
                    const SizedBox(height: 4),
                    Text(widget.body, style: AppText.bodySm(color: AppColors.mutedForeground)),
                  ],
                ),
              ),
              AnimatedScale(
                scale: widget.selected ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, size: 22, color: AppColors.primary),
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
  const _SelectOption({required this.title, required this.body, required this.selected, required this.onTap, this.compact = false});

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
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(minHeight: widget.compact ? 66 : 74),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: widget.compact ? 12 : 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: widget.selected ? AppColors.primary : AppColors.border, width: widget.selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                    const SizedBox(height: 2),
                    Text(widget.body, style: AppText.caption()),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.selected ? AppColors.primary : AppColors.border, width: 2),
                  color: widget.selected ? AppColors.primary : Colors.transparent,
                ),
                child: AnimatedScale(
                  scale: widget.selected ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutBack,
                  child: const HugeIcon(icon: HugeIcons.strokeRoundedTick01, size: 14, color: Colors.white),
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
    final formatted = '${_month(s.birthDate.month)} ${s.birthDate.day}, ${s.birthDate.year}';
    return _QuestionFrameContent(
      step: 1,
      title: 'How old are you?',
      description: 'To provide personalized clinical insights, we need to verify your age. You must be 13 or older.',
      onAction: valid ? () => s.go(5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
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
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Date of Birth', style: TextStyle(fontSize: 18, color: AppColors.primary, letterSpacing: -0.2)),
                  Row(children: [
                    Text(formatted, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: -0.2)),
                    const SizedBox(width: 8),
                    const HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01, size: 18, color: AppColors.primary),
                  ]),
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
                HugeIcon(icon: HugeIcons.strokeRoundedShield01, size: 16, color: valid ? AppColors.primary : AppColors.destructive),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    valid ? 'Verified (${s.age} years old) · Over 13+ requirement' : 'You must be between 13 and 120 years old.',
                    style: AppText.bodySm(color: valid ? AppColors.mutedForeground : AppColors.destructive),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _month(int m) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
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
      onAction: () => s.go(6),
      child: Column(children: [
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
      ]),
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
    final imperialValid = (double.tryParse(s.feet.text) ?? 0) >= 3 &&
        (double.tryParse(s.feet.text) ?? 0) <= 8 &&
        (double.tryParse(s.inches.text) ?? -1) >= 0 &&
        (double.tryParse(s.inches.text) ?? -1) <= 11 &&
        (double.tryParse(s.weightLb.text) ?? 0) >= 50;
    final metricValid = (double.tryParse(s.heightCm.text) ?? 0) >= 90 &&
        (double.tryParse(s.heightCm.text) ?? 0) <= 245 &&
        (double.tryParse(s.weightKg.text) ?? 0) >= 23;
    final valid = s.units == 'imperial' ? imperialValid : metricValid;

    return _QuestionFrameContent(
      step: 3,
      title: 'What are your stats?',
      onAction: valid ? () => s.go(7) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(AppRadius.xl)),
            child: Row(children: [
              Expanded(child: _UnitToggle(label: 'Imperial (ft, lbs)', active: s.units == 'imperial', onTap: () => setState(() => s.units = 'imperial'))),
              Expanded(child: _UnitToggle(label: 'Metric (cm, kg)', active: s.units == 'metric', onTap: () => setState(() => s.units = 'metric'))),
            ]),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: s.units == 'imperial'
                ? Column(
                    key: const ValueKey('imperial'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Height', style: AppText.label(color: AppColors.primary)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _UnitInput(controller: s.feet, unit: 'ft', onChanged: (_) => setState(() {}))),
                        const SizedBox(width: 12),
                        Expanded(child: _UnitInput(controller: s.inches, unit: 'in', onChanged: (_) => setState(() {}))),
                      ]),
                      const SizedBox(height: 16),
                      Text('Weight', style: AppText.label(color: AppColors.primary)),
                      const SizedBox(height: 8),
                      _UnitInput(controller: s.weightLb, unit: 'lbs', onChanged: (_) => setState(() {})),
                    ],
                  )
                : Row(
                    key: const ValueKey('metric'),
                    children: [
                      Expanded(child: _UnitInput(controller: s.heightCm, unit: 'cm', onChanged: (_) => setState(() {}))),
                      const SizedBox(width: 12),
                      Expanded(child: _UnitInput(controller: s.weightKg, unit: 'kg', onChanged: (_) => setState(() {}))),
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
  const _UnitToggle({required this.label, required this.active, required this.onTap});

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
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text(label, style: AppText.bodySm(color: active ? AppColors.blueberry : AppColors.mutedForeground)),
      ),
    );
  }
}

class _UnitInput extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final ValueChanged<String> onChanged;
  const _UnitInput({required this.controller, required this.unit, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: -0.2),
      decoration: InputDecoration(
        suffixText: unit,
        suffixStyle: AppText.bodySm(color: AppColors.mutedForeground),
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
      description: 'Our clinical founder co-designed this platform to ensure safe nutritional support before or after surgical weight-loss procedures.',
      onAction: () => s.go(8),
      compact: true,
      child: Column(
        children: [
          _SelectOption(compact: true, title: 'Yes, preparing for surgery', body: 'Optimizing my nutritional runway', selected: s.surgical == 'prepare', onTap: () => setState(() => s.surgical = 'prepare')),
          _SelectOption(compact: true, title: 'Yes, recovering from surgery', body: 'Gently supporting tissue healing and repair', selected: s.surgical == 'recover', onTap: () => setState(() => s.surgical = 'recover')),
          _SelectOption(compact: true, title: 'No / prefer not to say', body: 'Standard, healthy lifestyle guidance', selected: s.surgical == 'none', onTap: () => setState(() => s.surgical = 'none')),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.hackWhySurface, borderRadius: BorderRadius.circular(AppRadius.xxl)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedShield01, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your details are kept securely with clinical-grade safety. We never sell your health metrics.',
                    style: AppText.bodySm(color: AppColors.primary).copyWith(fontSize: 13),
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
      description: "This establishes your metabolic baseline so we don't under-nourish your recovery.",
      actionLabel: 'See My Plan',
      onAction: () {
        context.read<AppState>().updateProfile(
              goal: s.goal,
              units: s.units,
              surgical: s.surgical,
              activity: s.activity,
            );
        s.go(9);
      },
      child: Column(
        children: [
          _SelectOption(title: 'Sedentary', body: 'Desk job, gentle short walks', selected: s.activity == 'sedentary', onTap: () => setState(() => s.activity = 'sedentary')),
          _SelectOption(title: 'Lightly active', body: 'Light exercise 1-3 days/week', selected: s.activity == 'lightly', onTap: () => setState(() => s.activity = 'lightly')),
          _SelectOption(title: 'Moderately active', body: 'Moderate workouts 3-5 days/week', selected: s.activity == 'moderately', onTap: () => setState(() => s.activity = 'moderately')),
          _SelectOption(title: 'Very active', body: 'Hard, physical training almost daily', selected: s.activity == 'very', onTap: () => setState(() => s.activity = 'very')),
        ],
      ),
    );
  }
}

const _planDuration = Duration(milliseconds: 2200);
const _planTarget = 0.85;

/// The ring, percentage, and status dots are all driven off ONE `TweenAnimationBuilder`
/// value rather than independent timers/controllers — deliberately, so nothing can
/// drift out of sync and there is no `AnimationController` to forget to dispose (the
/// widget also navigates itself away via `Future.delayed` on the same duration).
class _LoadingPlanContent extends StatefulWidget {
  const _LoadingPlanContent();
  @override
  State<_LoadingPlanContent> createState() => _LoadingPlanContentState();
}

class _LoadingPlanContentState extends State<_LoadingPlanContent> {
  @override
  void initState() {
    super.initState();
    Future.delayed(_planDuration, () {
      if (mounted) context.go('/home');
    });
  }

  static const _statusLabels = [
    'Analyzing metabolic baseline',
    'Mapping restaurant swaps & hacks',
    'Curating high-protein recipes',
    'Structuring recovery metrics',
  ];

  String _statusFor(int index, double value) {
    final thresholds = List.generate(_statusLabels.length, (i) => _planTarget * (i + 1) / _statusLabels.length);
    if (value >= thresholds[index]) return 'done';
    final activeIndex = thresholds.indexWhere((t) => value < t);
    return activeIndex == index ? 'active' : 'waiting';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      child: Column(
        children: [
          Text('Building your plan…', textAlign: TextAlign.center, style: AppText.h1(color: AppColors.primary))
              .animate()
              .fadeIn(duration: 380.ms)
              .slideY(begin: 0.1, end: 0, duration: 380.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 12),
          Text(
            "We're personalizing everything based on your goals, baseline, and dining preferences.",
            textAlign: TextAlign.center,
            style: AppText.bodySm(color: AppColors.mutedForeground),
          ).animate().fadeIn(delay: 80.ms, duration: 380.ms),
          const SizedBox(height: 40),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _planTarget),
            duration: _planDuration,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              final percent = (value * 100).round();
              return Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 224,
                        height: 224,
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 12,
                          backgroundColor: AppColors.secondary,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      Container(
                        width: 160,
                        height: 160,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
                        child: Text('$percent%', style: AppText.display(color: AppColors.primary).copyWith(fontSize: 36)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, label) in _statusLabels.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Builder(builder: (context) {
                            final state = _statusFor(i, value);
                            return Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 14,
                                  height: 14,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: state == 'done' ? AppColors.blueberry : (state == 'active' ? AppColors.accent : Colors.transparent),
                                    border: Border.all(color: state == 'waiting' ? AppColors.border : Colors.transparent),
                                  ),
                                  child: state == 'done'
                                      ? const HugeIcon(icon: HugeIcons.strokeRoundedTick01, size: 10, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Text(label,
                                    style: AppText.bodySm(
                                        color: state == 'waiting' ? AppColors.mutedForeground.withValues(alpha: 0.65) : AppColors.mutedForeground)),
                              ],
                            );
                          }),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.hackWhySurface, borderRadius: BorderRadius.circular(20)),
            child: Text(
              "Almost there! Over 23K active users are currently tracking today's progress.",
              style: AppText.bodySm(color: AppColors.primary).copyWith(fontSize: 13),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 380.ms),
        ],
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
      child: Column(
        children: [
          const _StatusBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WELCOME BACK', style: AppText.bodySm(color: AppColors.questionnaireLabel).copyWith(fontWeight: FontWeight.w700))
                      .animate()
                      .fadeIn(duration: 380.ms),
                  const SizedBox(height: 8),
                  Text('Your setup is still here.', style: AppText.h1(color: AppColors.primary))
                      .animate()
                      .fadeIn(delay: 60.ms, duration: 380.ms)
                      .slideY(begin: 0.1, end: 0, delay: 60.ms, duration: 380.ms, curve: Curves.easeOutCubic),
                  const SizedBox(height: 12),
                  Text('Continue with your body stats or start the short setup again.', style: AppText.bodySm(color: AppColors.mutedForeground))
                      .animate()
                      .fadeIn(delay: 120.ms, duration: 380.ms),
                  const SizedBox(height: 24),
                  _PillButton(label: 'Continue setup', onPressed: () => context.go('/onboarding?step=6'))
                      .animate()
                      .fadeIn(delay: 190.ms, duration: 380.ms),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: OutlinedButton(onPressed: () => context.go('/onboarding?step=0'), child: const Text('Start over')),
                  ).animate().fadeIn(delay: 240.ms, duration: 380.ms),
                  const SizedBox(height: 16),
                  Text('Nutrition Platform keeps partial answers on this device for 30 days.',
                      textAlign: TextAlign.center, style: AppText.caption()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
