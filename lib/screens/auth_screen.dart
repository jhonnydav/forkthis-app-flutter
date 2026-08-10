import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../product.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

class LoginScreen extends StatefulWidget {
  final bool afterOnboarding;
  const LoginScreen({super.key, this.afterOnboarding = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _finish() {
    final state = context.read<AppState>();
    if (widget.afterOnboarding) {
      state.completeOnboarding();
      context.go('/loading');
    } else if (state.onboardingCompleted) {
      context.go('/loading?mode=returning');
    } else {
      context.go('/onboarding?step=0');
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AppState>().signInWithEmail(_email.text);
    _finish();
  }

  void _social(String provider) {
    context.read<AppState>().signInWithProvider(provider);
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Welcome back.',
      subtitle:
          'Sign in to keep your ForkThis! moments, saves, and momentum together.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'New here?',
            style: AppText.bodySm(color: AppColors.textSecondary),
          ),
          TextButton(
            onPressed: () => openCreateAccountSheet(
              context,
              afterOnboarding: widget.afterOnboarding,
            ),
            child: const Text('Create account'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProviderButton(
              label: 'Continue with Apple',
              provider: _AuthProvider.apple,
              onTap: () => _social('Apple'),
            ),
            const SizedBox(height: 10),
            _ProviderButton(
              label: 'Continue with Google',
              provider: _AuthProvider.google,
              onTap: () => _social('Google'),
            ),
            const SizedBox(height: 18),
            _DividerLabel(label: 'or use email'),
            const SizedBox(height: 18),
            _AuthField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
            ),
            const SizedBox(height: 12),
            _AuthField(
              controller: _password,
              label: 'Password',
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: _validatePassword,
              suffix: IconButton(
                tooltip: _hidePassword ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: HugeIcon(
                  icon: _hidePassword
                      ? HugeIcons.strokeRoundedView
                      : HugeIcons.strokeRoundedViewOffSlash,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                ),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reached from [LoginScreen]'s "Forgot password?" link. This build has no
/// real backend (see the onboarding welcome sheet's "Private by design"
/// copy — no password is collected), so there is nothing to actually email;
/// the screen still models the full request → confirmation shape so the
/// flow reads as complete rather than a dead end.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: _sent ? 'Check your email.' : 'Reset your password.',
      subtitle: _sent
          ? "If an account exists for ${_email.text}, we've sent a link to reset the password."
          : "Enter the email on your account and we'll send a link to reset your password.",
      footer: TextButton(
        onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
        child: const Text('Back to sign in'),
      ),
      child: _sent
          ? SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: () => setState(() => _sent = false),
                child: const Text('Use a different email'),
              ),
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AuthField(
                    controller: _email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Send reset link'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Reached directly (splash's "resume onboarding" path, and the end of the
/// onboarding flow) as well as from [LoginScreen]'s "Create account" link.
/// Account creation itself is never a full page — it always opens as a modal
/// bottom drawer over this backdrop (or over whatever screen requested it),
/// so this screen's only job is to show the backdrop and immediately raise
/// the drawer once it is first painted.
class SignupScreen extends StatefulWidget {
  final bool afterOnboarding;
  final int? resumeAtStep;
  const SignupScreen({
    super.key,
    this.afterOnboarding = false,
    this.resumeAtStep,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _opened = false;

  void _openSheet() {
    if (_opened) return;
    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        openCreateAccountSheet(
          context,
          afterOnboarding: widget.afterOnboarding,
          resumeAtStep: widget.resumeAtStep,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _openSheet();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const Positioned.fill(child: _AuthBackdrop()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _AuthBrandMark(),
                    const Spacer(),
                    Text(
                      'Create your account.',
                      style: AppText.headline(38, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Just enough to save your progress. Your goals and body context come next.',
                      style: AppText.bodySm(
                        color: AppColors.textSecondary,
                      ).copyWith(height: 1.3),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(
                          widget.afterOnboarding
                              ? '/login?after=onboarding'
                              : '/login',
                        ),
                        child: const Text('Already have one? Sign in'),
                      ),
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

/// Opens account creation as a bottom drawer — the modal-sheet equivalent of
/// [SignupScreen]/[LoginScreen]'s "Create account" action. Callable from
/// anywhere that already has an [AppState] and [GoRouter] in context.
Future<void> openCreateAccountSheet(
  BuildContext context, {
  bool afterOnboarding = false,
  int? resumeAtStep,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => _CreateAccountSheet(
      afterOnboarding: afterOnboarding,
      resumeAtStep: resumeAtStep,
    ),
  );
}

class _CreateAccountSheet extends StatefulWidget {
  final bool afterOnboarding;
  final int? resumeAtStep;
  const _CreateAccountSheet({required this.afterOnboarding, this.resumeAtStep});

  @override
  State<_CreateAccountSheet> createState() => _CreateAccountSheetState();
}

class _CreateAccountSheetState extends State<_CreateAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _finish() {
    final resumeAtStep = widget.resumeAtStep;
    if (resumeAtStep != null) {
      context.read<AppState>().markOnboardingStep(resumeAtStep);
      context.go('/onboarding?step=$resumeAtStep');
    } else if (widget.afterOnboarding) {
      context.read<AppState>().completeOnboarding();
      context.go('/loading');
    } else {
      context.go('/onboarding?step=0');
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AppState>().createEmailAccount(
      name: _name.text,
      email: _email.text,
    );
    Navigator.of(context).pop();
    _finish();
  }

  void _social(String provider) {
    context.read<AppState>().signInWithProvider(provider);
    Navigator.of(context).pop();
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Text(
                'Create your account.',
                style: AppText.h2(color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                'Just enough to save your progress. Your goals and body context come next.',
                style: AppText.bodySm(
                  color: AppColors.textSecondary,
                ).copyWith(height: 1.3),
              ),
              const SizedBox(height: 20),
              _ProviderButton(
                label: 'Sign up with Apple',
                provider: _AuthProvider.apple,
                onTap: () => _social('Apple'),
              ),
              const SizedBox(height: 10),
              _ProviderButton(
                label: 'Sign up with Google',
                provider: _AuthProvider.google,
                onTap: () => _social('Google'),
              ),
              const SizedBox(height: 18),
              _DividerLabel(label: 'or create with email'),
              const SizedBox(height: 18),
              _AuthField(
                controller: _name,
                label: 'First name',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final clean = value?.trim() ?? '';
                  if (clean.isEmpty) return 'Enter your first name.';
                  if (clean.length < 2) return 'Use at least 2 characters.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _AuthField(
                controller: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              _AuthField(
                controller: _password,
                label: 'Password',
                obscureText: _hidePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: _validatePassword,
                suffix: IconButton(
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  icon: HugeIcon(
                    icon: _hidePassword
                        ? HugeIcons.strokeRoundedView
                        : HugeIcons.strokeRoundedViewOffSlash,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Create account'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'By creating an account you agree to our Terms and Privacy Policy.',
                textAlign: TextAlign.center,
                style: AppText.caption(color: AppColors.mutedForeground),
              ),
              const SizedBox(height: 6),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Already have one?',
                      style: AppText.bodySm(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go(
                          widget.afterOnboarding
                              ? '/login?after=onboarding'
                              : '/login',
                        );
                      },
                      child: const Text('Sign in'),
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

class _AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;

  const _AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const Positioned.fill(child: _AuthBackdrop()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // A fixed gap (rather than the old 28%-of-screen-height
                  // spacer) keeps the brand mark, headline, and form a
                  // consistent distance apart on every device instead of
                  // stranding the form far down a tall screen.
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final topGap = textScale > 1.2 ? 16.0 : 32.0;
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _AuthBrandMark(),
                            SizedBox(height: topGap),
                            Text(
                              title,
                              style: AppText.headline(
                                38,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: AppText.bodySm(
                                color: AppColors.textSecondary,
                              ).copyWith(height: 1.3),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xl,
                                ),
                                border: Border.all(color: AppColors.border),
                                boxShadow: AppElevation.floating,
                              ),
                              child: child,
                            ),
                            const SizedBox(height: 16),
                            Center(child: footer),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AuthHeaderPatternPainter());
  }
}

class _AuthBrandMark extends StatelessWidget {
  const _AuthBrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Text(
            'F!',
            style: AppText.h3(color: AppColors.primaryForeground),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                productName,
                style: AppText.h3(color: AppColors.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'One clear choice when meals get messy.',
                style: AppText.caption(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _AuthProvider { apple, google }

class _ProviderButton extends StatelessWidget {
  final String label;
  final _AuthProvider provider;
  final VoidCallback onTap;

  const _ProviderButton({
    required this.label,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final apple = provider == _AuthProvider.apple;
    final background = apple ? Colors.black : AppColors.card;
    final foreground = apple ? Colors.white : const Color(0xFF3C4043);
    final border = apple ? Colors.black : const Color(0xFFDADCE0);

    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: AppText.button(color: foreground),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            apple
                ? const Icon(Icons.apple, size: 22, color: Colors.white)
                : const _GoogleGLogo(size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleGLogo extends StatelessWidget {
  final double size;
  const _GoogleGLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _GoogleGLogoPainter());
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.17;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint logoPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;

    canvas.drawArc(rect, -0.03, 1.22, false, logoPaint(_blue));
    canvas.drawArc(rect, 1.19, 1.42, false, logoPaint(_green));
    canvas.drawArc(rect, 2.61, 0.9, false, logoPaint(_yellow));
    canvas.drawArc(rect, 3.51, 1.55, false, logoPaint(_red));
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(size.width - (stroke * 0.35), center.dy),
      logoPaint(_blue)..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AuthHeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);

    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, -0.78),
        radius: 0.9,
        colors: [
          AppColors.primary.withValues(alpha: 0.18),
          AppColors.accent.withValues(alpha: 0.12),
          AppColors.background.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);

    final dot = Paint()..color = AppColors.primary.withValues(alpha: 0.08);
    for (double y = -10; y < size.height * 0.48; y += 8) {
      for (double x = -10; x < size.width + 10; x += 8) {
        final dx = (x / size.width) - 0.78;
        final dy = (y / size.height) - 0.25;
        final distance = (dx * dx + dy * dy).clamp(0, 1).toDouble();
        canvas.drawCircle(Offset(x, y), 0.45 + ((1 - distance) * 1.25), dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DividerLabel extends StatelessWidget {
  final String label;
  const _DividerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: AppColors.border),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppText.kicker(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(labelText: label, suffixIcon: suffix),
    );
  }
}

String? _validateEmail(String? value) {
  final clean = value?.trim() ?? '';
  if (clean.isEmpty) return 'Enter your email.';
  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailPattern.hasMatch(clean)) return 'Enter a valid email.';
  return null;
}

String? _validatePassword(String? value) {
  final clean = value ?? '';
  if (clean.isEmpty) return 'Enter your password.';
  if (clean.length < 8) return 'Use at least 8 characters.';
  return null;
}
