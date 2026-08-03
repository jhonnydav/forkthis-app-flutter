import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  Timer? _navigationTimer;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    final appState = context.watch<AppState>();
    if (!appState.loaded) return;
    _scheduled = true;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
      _pulse.repeat(reverse: true);
    }
    _navigationTimer = Timer(
      Duration(milliseconds: reduceMotion ? 700 : 2400),
      () {
        if (!mounted) return;
        final state = context.read<AppState>();
        if (state.onboardingCompleted) {
          context.go('/home');
        } else if (state.onboardingStep > 0) {
          context.go('/onboarding/resume');
        } else {
          context.go('/onboarding?step=0');
        }
      },
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entranceCurve = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutCubic,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
            child: Column(
              children: [
                const Spacer(),
                FadeTransition(
                  opacity: entranceCurve,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.82, end: 1).animate(
                      CurvedAnimation(
                        parent: _entrance,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) => Transform.scale(
                        scale: 1 + (_pulse.value * 0.035),
                        child: child,
                      ),
                      child: Container(
                        width: 92,
                        height: 92,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedFavourite,
                          size: 42,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: entranceCurve,
                  child: Column(
                    children: [
                      Text(
                        'Nutrition Platform',
                        textAlign: TextAlign.center,
                        style: AppText.h1(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Weight health, made more human.',
                        textAlign: TextAlign.center,
                        style: AppText.bodySm(
                          color: Colors.white.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                FadeTransition(
                  opacity: entranceCurve,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: SizedBox(
                          width: 84,
                          height: 3,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.16,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Private by design',
                        style: AppText.caption(
                          color: Colors.white.withValues(alpha: 0.54),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
