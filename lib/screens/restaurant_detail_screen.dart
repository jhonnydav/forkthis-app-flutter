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
            height: 288,
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
                        AppColors.foreground.withValues(alpha: 0.85),
                      ],
                      stops: const [0.24, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  top: 20,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      restaurant.mark,
                      style: AppText.caption(
                        color: AppColors.primary,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.category.toUpperCase(),
                        style: AppText.kicker(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant.name,
                        style: AppText.headline(36, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (restaurant.distanceMi != null) ...[
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedLocation01,
                              size: 15,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 5),
                          ],
                          Flexible(
                            child: Text(
                              [
                                if (restaurant.distanceMi != null)
                                  '${restaurant.distanceMi} mi away',
                                hacks.isEmpty
                                    ? 'Menu review pending'
                                    : '${hacks.length} ${hacks.length == 1 ? "tested order" : "tested orders"}',
                              ].join(' · '),
                              style: AppText.label(color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'START WITH THE OUTCOME',
                        style: AppText.kicker(color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hacks.isEmpty
                            ? 'We are still reviewing this menu'
                            : 'Orders that work',
                        style: AppText.headline(36),
                      ),
                    ],
                  ),
                ),
                if (hacks.isNotEmpty) Text('Swipe', style: AppText.caption()),
              ],
            ),
          ),
          if (hacks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Try another nearby place while we add verified menu guidance here.',
                    style: AppText.bodySm(color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/eat-out'),
                      child: const Text('Browse other places'),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 346,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: hacks.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _OrderCard(hack: hacks[index]),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: const DisclaimerNote(),
          ),
        ],
      ),
    );
  }
}

/// Horizontal "start with the outcome" rail — Figma node 321:2729, an orange
/// card per order with a goal-fit chip, dish title, and a cal/protein +
/// arrow footer below a hairline divider.
class _OrderCard extends StatelessWidget {
  final FastHack hack;
  const _OrderCard({required this.hack});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push('/hack/${hack.id}'),
      child: Container(
        width: 309,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Image.asset(hack.image, fit: BoxFit.cover),
            ),
            // Expanded + a scrollable inner column, not a fixed-height
            // Padding — at large text scales (NFR-2) the badge/title/footer
            // stack can exceed the remaining card height, and this rail
            // sits inside a fixed-height horizontal ListView so it cannot
            // just grow taller. Scrolling internally avoids the blank-screen
            // class of bug from an unbounded Row/Column overflow.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hack.goals.isNotEmpty)
                      GoalFitBadge(goal: hack.goals.first),
                    const SizedBox(height: 12),
                    Text(
                      hack.title,
                      style: AppText.h3(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.foreground),
                        ),
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${hack.calories} cal',
                              style: AppText.button(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              '${hack.protein}g protein',
                              style: AppText.caption(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Spacer(),
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowRight01,
                            size: 20,
                            color: AppColors.foreground,
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
