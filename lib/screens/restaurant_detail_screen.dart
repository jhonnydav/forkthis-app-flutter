import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../data/fixtures.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/primitives.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final String id;
  const RestaurantDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final restaurant = restaurantById(id);
    if (restaurant == null) {
      return AppShell(
        header: ScreenHeader(
          title: 'Not found',
          onBack: () => context.go('/eat-out'),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'That place is not in the sample data.',
            style: AppText.body(color: AppColors.mutedForeground),
          ),
        ),
      );
    }

    final hacks = hacksByRestaurant(id);
    final image = hacks.isEmpty
        ? 'assets/images/recipe-exemplars/02-grilled-chicken-grain-bowl.jpg'
        : hacks.first.image;

    return AppShell(
      header: ScreenHeader(title: restaurant.name, onBack: () => context.pop()),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SizedBox(
            height: 258,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(image, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.foreground.withValues(alpha: 0.82),
                      ],
                      stops: const [0.28, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.category.toUpperCase(),
                        style: AppText.eyebrow(color: AppColors.accent),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant.name,
                        style: AppText.h1(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (restaurant.distanceMi != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedLocation01,
                                  size: 15,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${restaurant.distanceMi} mi away',
                                  style: AppText.bodySm(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                          Text(
                            hacks.isEmpty
                                ? 'Menu review pending'
                                : '${hacks.length} ${hacks.length == 1 ? "guide" : "guides"} available',
                            style: AppText.bodySm(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORDER WITH CONTEXT',
                  style: AppText.eyebrow(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  hacks.isEmpty
                      ? 'We are still reviewing this menu'
                      : 'The useful choices first',
                  style: AppText.h2(),
                ),
                const SizedBox(height: 6),
                Text(
                  hacks.isEmpty
                      ? 'Try another nearby place while we add verified menu guidance here.'
                      : 'Each option includes exactly what to order, the high-impact swaps, and nutrition estimates.',
                  style: AppText.bodySm(color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          if (hacks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/eat-out'),
                  child: const Text('Browse other places'),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [for (final hack in hacks) _OrderRow(hack: hack)],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: const DisclaimerNote(),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final FastHack hack;
  const _OrderRow({required this.hack});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/hack/${hack.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Image.asset(
                hack.image,
                width: 92,
                height: 92,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hack.title,
                    style: AppText.h3(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${hack.calories} cal  ·  ${hack.protein}g protein',
                    style: AppText.caption(color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  if (hack.goals.isNotEmpty)
                    Text(
                      goalLabel[hack.goals.first]!,
                      style: AppText.caption(color: AppColors.success),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 36),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
