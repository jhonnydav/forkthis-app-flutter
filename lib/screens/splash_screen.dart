import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../product.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../widgets/brand_logo.dart';

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
        if (state.signedIn && state.onboardingCompleted) {
          context.go('/loading?mode=returning');
        } else if (!state.signedIn && state.onboardingStep >= 4) {
          // They finished the intro slides but closed the app before
          // finishing account creation — resume right back at that gate
          // instead of dropping them past it or restarting the intro.
          context.go('/signup?resume=${state.onboardingStep}');
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
        backgroundColor: AppColors.paletteLava,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/figma/splash-warm-fruit-frame.jpg',
              fit: BoxFit.cover,
              semanticLabel: 'Citrus and leaf illustration',
            ),
            SafeArea(
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
                          child: BrandLogo(
                            size: 92,
                            borderRadius: BorderRadius.circular(24),
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
                            productName,
                            textAlign: TextAlign.center,
                            style: AppText.h1(
                              color: AppColors.paletteCosmicLatte,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'For the moment that could knock you off track.',
                            textAlign: TextAlign.center,
                            style: AppText.bodySm(
                              color: AppColors.paletteCosmicLatte.withValues(
                                alpha: 0.82,
                              ),
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
                                backgroundColor: AppColors.paletteCosmicLatte
                                    .withValues(alpha: 0.24),
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.paletteMargarine,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Private by design',
                            style: AppText.caption(
                              color: AppColors.paletteCosmicLatte.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                        ],
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
