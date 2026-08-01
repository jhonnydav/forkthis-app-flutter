import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/fixtures.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/primitives.dart';

/// Ported from `../app/src/screens/RestaurantDetail.tsx`.
class RestaurantDetailScreen extends StatelessWidget {
  final String id;
  const RestaurantDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final r = restaurantById(id);
    if (r == null) {
      return AppShell(
        header: ScreenHeader(title: 'Not found', onBack: () => context.go('/eat-out')),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('That place is not in the sample data.', style: AppText.body(color: AppColors.mutedForeground)),
        ),
      );
    }
    final hacks = hacksByRestaurant(id);

    return AppShell(
      header: ScreenHeader(title: r.name, onBack: () => context.pop()),
      child: ListView(
        children: [
          Stack(
            children: [
              SizedBox(
                height: 288,
                width: double.infinity,
                child: Image.asset(
                  hacks.isNotEmpty ? hacks.first.image : 'assets/images/recipe-exemplars/02-grilled-chicken-grain-bowl.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppColors.foreground.withValues(alpha: 0.7)],
                      stops: const [0.24, 1],
                    ),
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
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg)),
                  child: Text(r.mark, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.category, style: AppText.eyebrow(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(r.name, style: const TextStyle(fontSize: 34, height: 36 / 34, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 8),
                    Row(children: [
                      if (r.distanceMi != null) ...[
                        const Icon(Icons.place_rounded, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('${r.distanceMi} mi away · ', style: AppText.bodySm(color: Colors.white70).copyWith(fontWeight: FontWeight.w600)),
                      ],
                      Text('${r.hackCount} orders that work', style: AppText.bodySm(color: Colors.white70).copyWith(fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          if (hacks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('START WITH THE OUTCOME', style: AppText.eyebrow(color: AppColors.primary)),
                        const SizedBox(height: 2),
                        Text('Orders that work', style: AppText.h2()),
                      ],
                    ),
                  ),
                  Text('Swipe', style: AppText.caption()),
                ],
              ),
            ),
            SizedBox(
              height: 268,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: hacks.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final hack = hacks[index];
                  final tone = index.isEven ? AppColors.secondary : AppColors.warmSurface;
                  return GestureDetector(
                    onTap: () => context.push('/hack/${hack.id}'),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.78,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(AppRadius.xxl)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 160, width: double.infinity, child: Image.asset(hack.image, fit: BoxFit.cover)),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GoalFitBadge(goal: hack.goals.first),
                                const SizedBox(height: 12),
                                Text(hack.title, style: const TextStyle(fontSize: 21, height: 25 / 21, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.only(top: 12),
                                  decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.foreground.withValues(alpha: 0.1)))),
                                  child: Row(children: [
                                    Text('${hack.calories} cal', style: AppText.label()),
                                    const SizedBox(width: 10),
                                    Text('${hack.protein}g protein', style: AppText.caption()),
                                    const Spacer(),
                                    const Icon(Icons.arrow_forward_rounded, size: 20),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('No orders here yet.', style: AppText.h2()),
                const SizedBox(height: 8),
                Text('We add places every week. In the meantime, the ones we do have are one tap back.',
                    style: AppText.body(color: AppColors.mutedForeground)),
              ]),
            ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const DisclaimerNote(),
              const SizedBox(height: 8),
              Text('Sample data — invented chains, illustrative figures.', style: AppText.caption()),
            ]),
          ),
        ],
      ),
    );
  }
}
