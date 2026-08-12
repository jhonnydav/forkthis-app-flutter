import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../data/fixtures.dart';
import '../product.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/figma_components.dart';
import '../widgets/guided_experience.dart';

/// Restyled against Figma node 790:18213 ("4.1 Home – Dashboard"),
/// `figma.com/design/LjDp489aFZaYiDx88MvvkQ`, pulled 2026-08-11 (the file's
/// sections were renumbered since this was last synced — was node 321:473
/// / "2.1 Home – Dashboard"). Layout order and copy follow that node; app
/// data (fast hacks, AppState) is unchanged — only presentation moved.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _experienceScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.watch<AppState>();
    if (_experienceScheduled || !state.loaded || !state.onboardingCompleted) {
      return;
    }
    if (state.guidedTourCompleted && !state.welcomeBackPending) return;
    _experienceScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!state.guidedTourCompleted) await showGuidedTour(context);
      if (!mounted) return;
      if (state.welcomeBackPending) await showWelcomeBackExperience(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final protein = state.logs.fold<int>(0, (sum, item) => sum + item.protein);
    final name = state.profile.name.trim();
    final firstName = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
    final featured = fastHacks.first;
    // Figma's "Pick an order" rail — real hacks, cycling a few badge labels
    // the way the design does ("BEST FOR TODAY" / "CUSTOMER FAVORITE" / …).
    // One hack per restaurant, for a varied rail rather than the same
    // restaurant appearing twice back to back.
    final seenRestaurants = <String>{};
    final rail = fastHacks
        .where((h) => seenRestaurants.add(h.restaurantId))
        .take(4)
        .toList();
    const railBadges = [
      'BEST FOR TODAY',
      'CUSTOMER FAVORITE',
      'HIGH PROTEIN',
      'QUICK ORDER',
    ];

    const pagePadding = EdgeInsets.symmetric(horizontal: 20);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AppShell(
        scrollTitle: 'Home',
        scrollEyebrow: 'READY WHEN YOU ARE',
        child: Stack(
          children: [
            ColoredBox(
              color: AppColors.highlight,
              child: SafeArea(
                bottom: false,
                // Padding.zero on the ListView itself — the rail section below
                // needs to scroll edge-to-edge, so every other section carries its
                // own [pagePadding] instead of the list carrying it uniformly.
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: pagePadding,
                      child: _Header(
                        firstName: firstName,
                        onSearch: () => context.push('/search'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: pagePadding,
                      child: _ForkThisHero(
                        points: state.momentumPoints,
                        protein: protein,
                        onExactOrder: () =>
                            context.push('/hack/${featured.id}'),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Padding(
                      padding: pagePadding,
                      child: Text(
                        'What do you need?',
                        style: AppText.headline(32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: pagePadding,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ImageLinkTile(
                              label: 'Cook',
                              subtitle: 'Choose a fast recipe',
                              image: 'assets/images/figma/home/cook-tile.png',
                              background: AppColors.secondary,
                              foreground: AppColors.cream,
                              onTap: () => context.go('/cook'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ImageLinkTile(
                              label: 'Eat out',
                              subtitle: 'Find an exact order',
                              image: 'assets/images/figma/home/eatout-tile.png',
                              background: AppColors.accent,
                              foreground: AppColors.textPrimary,
                              onTap: () => context.go('/eat-out'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: pagePadding.copyWith(top: 8),
                      child: _TrackTile(onTap: () => context.go('/track')),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: pagePadding,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const HugeIcon(
                                      icon: HugeIcons.strokeRoundedLocation01,
                                      size: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Ashburn, Virginia',
                                      style: AppText.caption(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pick an order',
                                  style: AppText.headline(32),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/eat-out'),
                            child: const Text('See all'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Sized by content via IntrinsicHeight rather than a guessed
                    // fixed number — the footer's text grows with the system text
                    // scale (NFR-2 asks for 200%), so a hardcoded SizedBox height
                    // either clips it or overflows at larger scales.
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final (index, hack) in rail.indexed) ...[
                              if (index > 0) const SizedBox(width: 12),
                              RailCard(
                                image: hack.image,
                                badge: railBadges[index % railBadges.length],
                                eyebrow:
                                    restaurantById(hack.restaurantId)?.name ??
                                    '',
                                title: hack.title,
                                meta:
                                    '${hack.calories} cal · ${hack.protein}g protein',
                                onTap: () => context.push('/hack/${hack.id}'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: pagePadding,
                      child: CtaBannerCard(
                        icon: HugeIcons.strokeRoundedNotification03,
                        title: 'You can come back any day.',
                        subtitle:
                            'Missed a few days? $productName will give you one easy order or recipe to restart momentum.',
                        onTap: () => context.go('/track'),
                      ),
                    ),
                    SizedBox(height: 32 + MediaQuery.paddingOf(context).bottom),
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

class _Header extends StatelessWidget {
  final String firstName;
  final VoidCallback onSearch;

  const _Header({required this.firstName, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'READY WHEN YOU ARE',
                style: AppText.caption(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                firstName.isEmpty ? 'Welcome' : 'Hi, $firstName',
                style: AppText.greeting(),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onSearch,
          tooltip: 'Search meals and restaurants',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.muted,
            foregroundColor: AppColors.primary,
            fixedSize: const Size(48, 48),
            shape: const CircleBorder(),
          ),
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _ForkThisHero extends StatelessWidget {
  final int points;
  final int protein;
  final VoidCallback onExactOrder;

  const _ForkThisHero({
    required this.points,
    required this.protein,
    required this.onExactOrder,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    // A fixed (not just minimum) height lets the CTA anchor to the card's
    // bottom edge via Spacer below, instead of the badge-to-headline gap
    // carrying a large hardcoded empty span. The scale term keeps the same
    // NFR-2 text-scaling headroom the old minHeight formula provided.
    final height = 332 + ((textScale - 1).clamp(0, 1).toDouble() * 220);
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WarmRedHalftonePainter(),
              child: const SizedBox.expand(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'FORKTHIS! MOMENT',
                    style: AppText.kicker(color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'What would make this meal easier?',
                  style: AppText.headline(
                    36,
                    height: 38,
                    color: AppColors.primaryForeground,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pick the real-life situation first. We will narrow it to one order, recipe, or next step.',
                  style: AppText.bodySm(
                    color: AppColors.primaryForeground.withValues(alpha: 0.82),
                  ).copyWith(height: 1.34),
                ),
                const Spacer(),
                Row(
                  children: [
                    _HeroMetric(value: '$points', label: 'points'),
                    const SizedBox(width: 8),
                    _HeroMetric(value: '${protein}g', label: 'protein'),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: _HeroOrderButton(onTap: onExactOrder),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarmRedHalftonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = AppColors.primary;
    canvas.drawRect(Offset.zero & size, base);

    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.55, -0.7),
        radius: 1.1,
        colors: [
          AppColors.secondary.withValues(alpha: 0.58),
          AppColors.primary.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);

    final dot = Paint()..color = AppColors.accent.withValues(alpha: 0.12);
    const spacing = 6.0;
    for (double y = -20; y < size.height + 20; y += spacing) {
      for (double x = -20; x < size.width + 20; x += spacing) {
        final dx = (x / size.width) - 0.72;
        final dy = (y / size.height) - 0.2;
        final distance = (dx * dx + dy * dy).clamp(0, 1).toDouble();
        final radius = 0.36 + ((1 - distance) * 1.12);
        canvas.drawCircle(Offset(x, y), radius, dot);
      }
    }

    final shade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.02),
          AppColors.maroon.withValues(alpha: 0.62),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, shade);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The hero's single CTA (Figma 4.1 Home – Dashboard, node 790:18213: "See
/// today's order →") — replaces what used to be a split "Start" pill next to
/// a separate "See today's exact order" text link below the card.
class _HeroOrderButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HeroOrderButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                "See today's order",
                style: AppText.button(color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 16,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String value;
  final String label;

  const _HeroMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryForeground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.primaryForeground.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppText.label(color: AppColors.primaryForeground),
                maxLines: 1,
              ),
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppText.caption(
                  color: AppColors.primaryForeground.withValues(alpha: 0.75),
                ).copyWith(fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Home's third "What do you need?" tile — plain card (no photo), icon +
/// title + subtitle. Figma node 321:550.
class _TrackTile extends StatelessWidget {
  final VoidCallback onTap;
  const _TrackTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedNotebook01,
              size: 20,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Track',
                    style: AppText.label(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text('Log your day', style: AppText.caption()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
