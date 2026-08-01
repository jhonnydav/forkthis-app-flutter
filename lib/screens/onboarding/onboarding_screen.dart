import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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

  @override
  Widget build(BuildContext context) {
    final step = widget.step.clamp(0, 9);
    if (step == 0) return _Welcome(onNext: () => go(1));
    if (step >= 1 && step <= 3) return _Intro(index: step - 1, onNext: () => go(step + 1));
    if (step == 4) return _AgeStep(state: this);
    if (step == 5) return _GoalStep(state: this);
    if (step == 6) return _StatsStep(state: this);
    if (step == 7) return _SurgicalStep(state: this);
    if (step == 8) return _ActivityStep(state: this);
    return const _LoadingPlan();
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 44);
  }
}

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
              height: 6,
              decoration: BoxDecoration(
                color: i < current ? AppColors.primary : AppColors.secondary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
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
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        child: Text(label),
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
  ),
  (
    badge: 'Tailored to you',
    title: 'Personalized to your context.',
    body: 'No cookie-cutter templates. Your nutritional plans adapt to your unique body stats, goals, and specific medical or surgical context.',
    accent: false,
  ),
  (
    badge: 'Built by people who get it',
    title: 'Clinical depth, real empathy.',
    body: 'Co-founded by a renowned plastic surgeon and a weight health creator who lived the 260 lb loss journey. Pure support, zero intimidation.',
    accent: true,
  ),
];

class _Welcome extends StatelessWidget {
  final VoidCallback onNext;
  const _Welcome({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      tabBar: false,
      child: Column(
        children: [
          const _StatusBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: Text('Your turning point starts here.', style: AppText.h1(color: AppColors.primary)),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: Text(
                      'A warmer, scientifically credible home for sustainable weight health. No paywalls, no judgment.',
                      style: AppText.bodySm(color: AppColors.mutedForeground),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _PillButton(label: 'Get Started', onPressed: onNext),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showSignIn(context),
                      child: const Text('I already have an account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
              const Text('Email', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),
              const Text('Password', style: TextStyle(fontWeight: FontWeight.w700)),
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

class _Intro extends StatelessWidget {
  final int index;
  final VoidCallback onNext;
  const _Intro({required this.index, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final item = _introSteps[index];
    return AppShell(
      tabBar: false,
      child: Column(
        children: [
          const _StatusBar(),
          _Progress(current: index + 1, total: 3),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.accent ? AppColors.accent : AppColors.secondary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(item.badge.toUpperCase(),
                        style: AppText.caption(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  Text(item.title, style: AppText.h1(color: AppColors.primary)),
                  const SizedBox(height: 12),
                  Text(item.body, style: AppText.bodySm(color: AppColors.mutedForeground)),
                  const SizedBox(height: 24),
                  _PillButton(label: index == 2 ? "Let's Begin" : 'Next', onPressed: onNext),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionFrame extends StatelessWidget {
  final int step;
  final String title;
  final String? description;
  final Widget child;
  final VoidCallback? onAction;
  final String actionLabel;
  final bool compact;

  const _QuestionFrame({
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
    return AppShell(
      tabBar: false,
      child: Column(
        children: [
          const _StatusBar(),
          _Progress(current: step, total: 5),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, compact ? 16 : 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Questionnaire $step of 5',
                      style: AppText.bodySm(color: AppColors.questionnaireLabel).copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(title, style: AppText.h1(color: AppColors.primary)),
                  if (description != null) ...[
                    const SizedBox(height: 8),
                    Text(description!, style: AppText.body(color: AppColors.mutedForeground)),
                  ],
                  SizedBox(height: compact ? 16 : 24),
                  child,
                  SizedBox(height: compact ? 16 : 24),
                  _PillButton(label: actionLabel, onPressed: onAction),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  final String value;
  final String title;
  final String body;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _GoalOption({required this.value, required this.title, required this.body, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 107),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(body, style: AppText.bodySm(color: AppColors.mutedForeground)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectOption extends StatelessWidget {
  final String title;
  final String body;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;
  const _SelectOption({required this.title, required this.body, required this.selected, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(minHeight: compact ? 66 : 74),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(body, style: AppText.caption()),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 2),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
              child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
          ],
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
    return _QuestionFrame(
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Date of Birth', style: TextStyle(fontSize: 18, color: AppColors.primary)),
                  Row(children: [
                    Text(formatted, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(width: 8),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.verified_user_rounded, size: 16, color: valid ? AppColors.primary : AppColors.destructive),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  valid ? 'Verified (${s.age} years old) · Over 13+ requirement' : 'You must be between 13 and 120 years old.',
                  style: AppText.bodySm(color: valid ? AppColors.mutedForeground : AppColors.destructive),
                ),
              ),
            ],
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
    return _QuestionFrame(
      step: 2,
      title: "What's your main goal?",
      onAction: () => s.go(6),
      child: Column(children: [
        _GoalOption(
          value: 'lose',
          title: 'Lose weight',
          body: 'Sustainable fat loss with muscle preservation',
          icon: Icons.south_east_rounded,
          selected: s.goal == Goal.lose,
          onTap: () => setState(() => s.goal = Goal.lose),
        ),
        const SizedBox(height: 12),
        _GoalOption(
          value: 'gain',
          title: 'Gain muscle',
          body: 'Build physical strength and energetic support',
          icon: Icons.fitness_center_rounded,
          selected: s.goal == Goal.gain,
          onTap: () => setState(() => s.goal = Goal.gain),
        ),
        const SizedBox(height: 12),
        _GoalOption(
          value: 'maintain',
          title: 'Maintain weight',
          body: 'Focus on longevity, metabolism and vitality',
          icon: Icons.favorite_rounded,
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

    return _QuestionFrame(
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
          if (s.units == 'imperial') ...[
            const Text('Height', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _UnitInput(controller: s.feet, unit: 'ft', onChanged: (_) => setState(() {}))),
              const SizedBox(width: 12),
              Expanded(child: _UnitInput(controller: s.inches, unit: 'in', onChanged: (_) => setState(() {}))),
            ]),
            const SizedBox(height: 16),
            const Text('Weight', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 8),
            _UnitInput(controller: s.weightLb, unit: 'lbs', onChanged: (_) => setState(() {})),
          ] else ...[
            Row(children: [
              Expanded(child: _UnitInput(controller: s.heightCm, unit: 'cm', onChanged: (_) => setState(() {}))),
              const SizedBox(width: 12),
              Expanded(child: _UnitInput(controller: s.weightKg, unit: 'kg', onChanged: (_) => setState(() {}))),
            ]),
          ],
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
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
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
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
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
    return _QuestionFrame(
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
                const Icon(Icons.verified_user_rounded, size: 20, color: AppColors.primary),
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
    return _QuestionFrame(
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

class _LoadingPlan extends StatefulWidget {
  const _LoadingPlan();
  @override
  State<_LoadingPlan> createState() => _LoadingPlanState();
}

class _LoadingPlanState extends State<_LoadingPlan> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) context.go('/home');
    });
  }

  static const _statuses = [
    ('Analyzing metabolic baseline', 'done'),
    ('Mapping restaurant swaps & hacks', 'done'),
    ('Curating high-protein recipes', 'active'),
    ('Structuring recovery metrics', 'waiting'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      tabBar: false,
      child: Column(
        children: [
          const _StatusBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                children: [
                  Text('Building your plan…', textAlign: TextAlign.center, style: AppText.h1(color: AppColors.primary)),
                  const SizedBox(height: 12),
                  Text(
                    "We're personalizing everything based on your goals, baseline, and dining preferences.",
                    textAlign: TextAlign.center,
                    style: AppText.bodySm(color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 40),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 224,
                        height: 224,
                        child: CircularProgressIndicator(
                          value: 0.85,
                          strokeWidth: 12,
                          backgroundColor: AppColors.secondary,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      Container(
                        width: 160,
                        height: 160,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Text('85%', style: AppText.display(color: AppColors.primary).copyWith(fontSize: 36)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (label, state) in _statuses)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: state == 'done' ? AppColors.blueberry : (state == 'active' ? AppColors.accent : Colors.transparent),
                                  border: Border.all(color: state == 'waiting' ? AppColors.border : Colors.transparent),
                                ),
                                child: state == 'done' ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 12),
                              Text(label, style: AppText.bodySm(color: state == 'waiting' ? AppColors.mutedForeground.withValues(alpha: 0.65) : AppColors.mutedForeground)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.hackWhySurface, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      "Almost there! Over 23K active users are currently tracking today's progress.",
                      style: AppText.bodySm(color: AppColors.primary).copyWith(fontSize: 13),
                    ),
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
                  Text('WELCOME BACK', style: AppText.bodySm(color: AppColors.questionnaireLabel).copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Your setup is still here.', style: AppText.h1(color: AppColors.primary)),
                  const SizedBox(height: 12),
                  Text('Continue with your body stats or start the short setup again.', style: AppText.bodySm(color: AppColors.mutedForeground)),
                  const SizedBox(height: 24),
                  _PillButton(label: 'Continue setup', onPressed: () => context.go('/onboarding?step=6')),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: OutlinedButton(onPressed: () => context.go('/onboarding?step=0'), child: const Text('Start over')),
                  ),
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
