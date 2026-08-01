import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/fixtures.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import '../widgets/app_shell.dart';

const _figmaHomeImages = [
  'assets/images/figma/home-kale.jpg',
  'assets/images/figma/home-wrap.jpg',
  'assets/images/figma/home-burger.jpg',
];

/// Ported from `../app/src/screens/Home.tsx`.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loggedCalories = state.logs.fold<int>(
      0,
      (sum, l) => sum + l.calories,
    );

    return AppShell(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.honey, AppColors.background, Color(0xFFF6F8FC)],
            stops: [0, 0.11, 1],
          ),
        ),
        // Gradient bleeds full-bleed under the status bar/notch (matches the web app's
        // `env(safe-area-inset-top)`-padded content over a full-bleed background);
        // SafeArea sits inside the gradient so only the CONTENT respects the inset.
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: AppText.caption().copyWith(
                                    letterSpacing: 0.2,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Good afternoon '),
                                    TextSpan(
                                      text: state.profile.name,
                                      style: const TextStyle(
                                        color: AppColors.homeGoodAfternoon,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Your day, at a glance',
                                style: TextStyle(fontSize: 17, height: 22 / 17),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(color: AppColors.borderStrong),
                          ),
                          child: IconButton(
                            onPressed: () => context.push('/search'),
                            icon: const Icon(Icons.search_rounded),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                        border: Border.all(color: AppColors.homeHeroBorder),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -96,
                            top: -112,
                            child: Container(
                              width: 320,
                              height: 320,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.homeHeroRing.withValues(
                                    alpha: 0.8,
                                  ),
                                  width: 56,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.place_rounded,
                                      size: 14,
                                      color: AppColors.accent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Ashburn, Virginia',
                                      style: AppText.caption(
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 310,
                                  ),
                                  child: Text(
                                    'A balanced day is already underway.',
                                    style: AppText.h2(
                                      color: Colors.white,
                                    ).copyWith(fontSize: 24, height: 26 / 24),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 320,
                                  ),
                                  child: Text(
                                    'Keep the next choice simple. Lunch is your strongest opportunity.',
                                    style: AppText.bodySm(
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      _Metric(
                                        icon: Icons.restaurant_menu_rounded,
                                        label: 'Next meal',
                                        value: 'Lunch',
                                      ),
                                      _vDivider(),
                                      _Metric(
                                        icon: Icons.water_drop_rounded,
                                        label: 'Water',
                                        value: '${state.waterCups} of 8',
                                      ),
                                      _vDivider(),
                                      _Metric(
                                        icon: Icons.directions_walk_rounded,
                                        label: 'Movement',
                                        value: '${state.movementMinutes} min',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BEST NEXT MOVE',
                                style: AppText.caption(
                                  color: AppColors.eatOutLunchLabel,
                                ),
                              ),
                              const SizedBox(height: 2),
                              RichText(
                                text: TextSpan(
                                  style: AppText.h3(),
                                  children: const [
                                    TextSpan(text: 'Lunch, '),
                                    TextSpan(
                                      text: 'already narrowed down',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/eat-out'),
                          child: Text(
                            'See all',
                            style: AppText.bodySm(
                              color: AppColors.eatOutLunchLabel,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 256,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => _MealCard(index: index),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: const BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => context.go('/eat-out'),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.restaurant_menu_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'EATING AWAY FROM HOME?',
                                    style: AppText.caption(
                                      color: const Color(0xFF4A53DC),
                                    ).copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Find a smart order in seconds',
                                    style: TextStyle(
                                      fontSize: 17,
                                      height: 22 / 17,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Nearby places, useful swaps, plain language.',
                                    style: AppText.caption(),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.mutedForeground,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 36, 20, 32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.warmSurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TONIGHT',
                                style: AppText.caption().copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Keep recovery gentle',
                                style: TextStyle(fontSize: 17, height: 22 / 17),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loggedCalories > 0
                                    ? '$loggedCalories calories logged so far. A short walk or an early wind-down both count.'
                                    : 'A short walk or an early wind-down both count.',
                                style: AppText.bodySm(
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.go('/track'),
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _vDivider() => Container(
    width: 1,
    height: 32,
    color: Colors.white.withValues(alpha: 0.45),
  );
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Metric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppText.caption(
                    color: AppColors.accent,
                  ).copyWith(fontSize: 9),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final int index;
  const _MealCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final hack = fastHacks[index];
    final restaurant = restaurantById(hack.restaurantId);
    return GestureDetector(
      onTap: () => context.push('/hack/${hack.id}'),
      child: Container(
        width: 293,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.foreground,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(_figmaHomeImages[index], fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.foreground,
                    AppColors.foreground.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  index == 0 ? 'BEST FOR TODAY' : '${hack.protein}G PROTEIN',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6F8A00),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (restaurant != null)
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(hack.title, style: AppText.h3(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    '${hack.calories} cal · ${hack.protein}g protein',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
