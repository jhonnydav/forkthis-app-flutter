import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../data/fixtures.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_toast.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _dailyCalories = 1850;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final calories = state.logs.fold<int>(
      0,
      (sum, item) => sum + item.calories,
    );
    final protein = state.logs.fold<int>(0, (sum, item) => sum + item.protein);
    final progress = (calories / _dailyCalories).clamp(0.0, 1.0);
    final remaining = (_dailyCalories - calories).clamp(0, _dailyCalories);
    final firstName = state.profile.name.trim().split(RegExp(r'\s+')).first;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AppShell(
        scrollTitle: 'Today',
        scrollEyebrow: 'YOUR PLAN',
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _HomeHero(
              firstName: firstName,
              calories: calories,
              remaining: remaining,
              progress: progress,
              protein: protein,
              water: state.waterCups,
              movement: state.movementMinutes,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK ACTIONS',
                    style: AppText.eyebrow(color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text('Keep the next step small', style: AppText.h2()),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: HugeIcons.strokeRoundedDroplet,
                          label: 'Water',
                          detail: '${state.waterCups}/8 cups',
                          tone: AppColors.blueberrySurface,
                          onTap: () {
                            state.addWater();
                            state.addNotification(
                              title: 'Water added',
                              body:
                                  '${state.waterCups} of 8 cups complete today.',
                            );
                            showAppToast(context, 'Water added');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickAction(
                          icon: HugeIcons.strokeRoundedRestaurant01,
                          label: 'Eat out',
                          detail: 'Find an order',
                          tone: AppColors.warmSurface,
                          onTap: () => context.go('/eat-out'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickAction(
                          icon: HugeIcons.strokeRoundedChefHat,
                          label: 'Cook',
                          detail: 'Pick a recipe',
                          tone: AppColors.secondary,
                          onTap: () => context.go('/cook'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 14),
              child: _SectionHeading(
                eyebrow: 'BEST NEXT MOVE',
                title: 'Lunch, already narrowed down',
                action: 'See all',
                onTap: () => context.go('/eat-out'),
              ),
            ),
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _RecommendationCard(
                  hack: fastHacks[index],
                  label: index == 0
                      ? 'BEST FOR TODAY'
                      : index == 1
                      ? 'EASY SWAP'
                      : 'HIGH PROTEIN',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 14),
              child: _SectionHeading(
                eyebrow: 'TODAY',
                title: 'What you have logged',
                action: 'Open Track',
                onTap: () => context.go('/track'),
              ),
            ),
            if (state.logs.isEmpty)
              const _EmptyLog()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    for (final item in state.logs.take(3)) _LogRow(item: item),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 36),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () => context.go('/track'),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedWalking,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('A gentle finish counts', style: AppText.h3()),
                            const SizedBox(height: 3),
                            Text(
                              '${state.movementMinutes} minutes logged. A short walk or an early wind-down are both useful.',
                              style: AppText.bodySm(
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  final String firstName;
  final int calories;
  final int remaining;
  final double progress;
  final int protein;
  final int water;
  final int movement;

  const _HomeHero({
    required this.firstName,
    required this.calories,
    required this.remaining,
    required this.progress,
    required this.protein,
    required this.water,
    required this.movement,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.primary),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GOOD AFTERNOON, ${firstName.toUpperCase()}',
                          style: AppText.eyebrow(color: AppColors.accent),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Today feels manageable.',
                          style: AppText.h1(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/search'),
                    tooltip: 'Search meals and restaurants',
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$calories',
                    style: AppText.display(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'calories logged · $remaining left in your current guide',
                    style: AppText.bodySm(color: AppColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _HeroMetric(
                      label: 'Protein',
                      value: '${protein}g',
                      icon: HugeIcons.strokeRoundedBodyPartMuscle,
                    ),
                    _HeroMetric(
                      label: 'Water',
                      value: '$water/8',
                      icon: HugeIcons.strokeRoundedDroplet,
                    ),
                    _HeroMetric(
                      label: 'Movement',
                      value: '${movement}m',
                      icon: HugeIcons.strokeRoundedWalking,
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

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final List<List<dynamic>> icon;
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.caption(color: Colors.white60),
                  maxLines: 1,
                ),
                Text(
                  value,
                  style: AppText.label(color: Colors.white),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String detail;
  final Color tone;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.detail,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        height: 164,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
              child: HugeIcon(icon: icon, size: 17, color: AppColors.primary),
            ),
            const Spacer(),
            Text(label, style: AppText.label()),
            Text(
              detail,
              style: AppText.caption(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String action;
  final VoidCallback onTap;
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: AppText.eyebrow(color: AppColors.primary)),
              const SizedBox(height: 3),
              Text(title, style: AppText.h2()),
            ],
          ),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final FastHack hack;
  final String label;
  const _RecommendationCard({required this.hack, required this.label});

  @override
  Widget build(BuildContext context) {
    final restaurant = restaurantById(hack.restaurantId);
    return SizedBox(
      width: 246,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.push('/hack/${hack.id}'),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 132,
                width: double.infinity,
                child: Image.asset(hack.image, fit: BoxFit.cover),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppText.eyebrow(color: AppColors.success),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hack.title,
                        style: AppText.h3(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        '${restaurant?.name ?? 'Smart order'}  ·  ${hack.calories} cal  ·  ${hack.protein}g',
                        style: AppText.caption(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

class _LogRow extends StatelessWidget {
  final LoggedItem item;
  const _LogRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/track'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.asset(
                item.image,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppText.label(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.calories} cal  ·  ${item.protein}g protein',
                    style: AppText.caption(),
                  ),
                ],
              ),
            ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 17,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLog extends StatelessWidget {
  const _EmptyLog();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nothing logged yet. Add the first useful thing, not a perfect day.',
                style: AppText.bodySm(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
