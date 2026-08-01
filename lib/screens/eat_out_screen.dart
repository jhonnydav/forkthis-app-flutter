import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/fixtures.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_toast.dart';
import '../widgets/primitives.dart';
import '../widgets/product_sheet.dart';

const _categoryImages = <String, String>{
  'Chicken': 'assets/images/eat-out/category-chicken-transparent-v3.png',
  'Burgers': 'assets/images/eat-out/category-burgers-transparent-v3.png',
  'Sandwiches': 'assets/images/recipe-exemplars/04-turkey-avocado-wrap.jpg',
  'Mexican': 'assets/images/eat-out/category-mexican-transparent-v3.png',
  'Coffee': 'assets/images/eat-out/category-coffee-transparent-v3.png',
  'Asian': 'assets/images/recipe-exemplars/06-tofu-vegetable-stir-fry.jpg',
  'Salads': 'assets/images/recipe-exemplars/09-chickpea-cucumber-salad.jpg',
  'Mediterranean': 'assets/images/recipe-exemplars/01-lemon-herb-salmon.jpg',
  'Drinks': 'assets/images/recipe-exemplars/11-overnight-oats-apple.jpg',
  'Pizza': 'assets/images/recipe-exemplars/10-baked-chicken-sweet-potato.jpg',
  'Breakfast': 'assets/images/recipe-exemplars/07-spinach-eggs-toast.jpg',
  'Soup': 'assets/images/recipe-exemplars/05-red-lentil-soup.jpg',
};
const _quickCategories = ['All', 'Chicken', 'Coffee', 'Mexican', 'Burgers'];

String _restaurantImage(Restaurant r) =>
    _categoryImages[r.category] ??
    fastHacks.where((h) => h.restaurantId == r.id).firstOrNull?.image ??
    'assets/images/recipe-exemplars/02-grilled-chicken-grain-bowl.jpg';

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Ported from `../app/src/screens/EatOut.tsx`.
class EatOutScreen extends StatefulWidget {
  final String view; // restaurant | goal | nearby
  final bool dense;
  final String category;
  const EatOutScreen({
    super.key,
    this.view = 'restaurant',
    this.dense = false,
    this.category = 'All',
  });

  @override
  State<EatOutScreen> createState() => _EatOutScreenState();
}

class _EatOutScreenState extends State<EatOutScreen> {
  final _query = TextEditingController();
  bool _locationPromptShown = false;

  @override
  void didUpdateWidget(covariant EatOutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.view != 'nearby') _locationPromptShown = false;
  }

  void _maybeShowLocationPrompt() {
    if (widget.view != 'nearby' || _locationPromptShown) return;
    _locationPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showLocationSheet(context, () {});
    });
  }

  void _setView(String view) {
    final params = {'view': view, if (widget.dense) 'data': 'dense'};
    context.go(Uri(path: '/eat-out', queryParameters: params).toString());
  }

  void _setCategory(String category) {
    final params = {
      'view': 'restaurant',
      if (widget.dense) 'data': 'dense',
      if (category != 'All') 'category': category,
    };
    context.go(Uri(path: '/eat-out', queryParameters: params).toString());
  }

  @override
  Widget build(BuildContext context) {
    _maybeShowLocationPrompt();
    final source = widget.dense ? restaurantsDense : restaurants;
    final visibleCount = source
        .where((r) => widget.category == 'All' || r.category == widget.category)
        .length;

    return AppShell(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: AppColors.primary),
              // Background bleeds full-bleed under the status bar; SafeArea sits
              // inside it so only the content respects the top inset (same pattern
              // as home_screen.dart's gradient header — see the note there).
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
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
                                      style: AppText.eyebrow(
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Eat well, wherever you are.',
                                  style: AppText.display(
                                    color: Colors.white,
                                  ).copyWith(fontSize: 34, height: 36 / 34),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: IconButton(
                              onPressed: () => context.push('/search'),
                              icon: const Icon(
                                Icons.search_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 330),
                        child: Text(
                          'Smart orders matched to your goals, health context, and real life.',
                          style: AppText.bodySm(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      InkWell(
                        onTap: () => context.push('/search'),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Restaurant, dish, or craving',
                                style: AppText.bodySm(
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  children: [
                    _ViewTab(
                      label: 'For you',
                      active: widget.view == 'restaurant',
                      onTap: () => _setView('restaurant'),
                    ),
                    _ViewTab(
                      label: 'By goal',
                      active: widget.view == 'goal',
                      onTap: () => _setView('goal'),
                    ),
                    _ViewTab(
                      label: 'Nearest',
                      active: widget.view == 'nearby',
                      onTap: () => _setView('nearby'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.view == 'goal')
            _goalView()
          else if (widget.view == 'nearby')
            _nearbyView(context)
          else ...[
            if (widget.category == 'All') _recommendationRail(),
            _categoryRail(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AROUND YOU',
                            style: AppText.eyebrow(color: AppColors.primary),
                          ),
                          const SizedBox(height: 2),
                          Text('Places worth opening', style: AppText.h2()),
                        ],
                      ),
                    ),
                    Text('$visibleCount places', style: AppText.caption()),
                  ],
                ),
              ),
            ),
            _restaurantList(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DisclaimerNote(),
                    const SizedBox(height: 8),
                    Wrap(
                      children: [
                        Text(
                          'Sample data — invented chains, illustrative figures. Showing the ${widget.dense ? "dense (20 places)" : "launch-scale (6 places)"} state. ',
                          style: AppText.caption(),
                        ),
                        GestureDetector(
                          onTap: () {
                            final params = {
                              'view': 'restaurant',
                              if (!widget.dense) 'data': 'dense',
                            };
                            context.go(
                              Uri(
                                path: '/eat-out',
                                queryParameters: params,
                              ).toString(),
                            );
                          },
                          child: Text(
                            'View ${widget.dense ? "launch scale" : "dense scale"}.',
                            style: AppText.caption(
                              color: AppColors.primary,
                            ).copyWith(decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _recommendationRail() {
    final images = [
      'assets/images/figma/home-kale.jpg',
      'assets/images/figma/home-wrap.jpg',
      'assets/images/figma/home-burger.jpg',
    ];
    final labels = ['BEST MATCH', 'EASY SWAP', 'HIGH PROTEIN'];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 32, bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MATCHED TO TODAY',
                          style: AppText.eyebrow(
                            color: const Color(0xFF6F8A00),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('Lunch, narrowed down', style: AppText.h2()),
                      ],
                    ),
                  ),
                  Text('Swipe', style: AppText.caption()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              // 176 image + 32 padding + ~24 restaurant row + up to 2 title
              // lines (48) + gaps + ~36 chip row overflowed the old 300pt box
              // by up to ~38pt on a wrapped title — verified on-device via the
              // debug overflow banner, not assumed.
              height: 344,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final hack = fastHacks[index];
                  final restaurant = restaurantById(hack.restaurantId);
                  return GestureDetector(
                    onTap: () => context.push('/hack/${hack.id}'),
                    child: Container(
                      width: 300,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              SizedBox(
                                height: 176,
                                width: double.infinity,
                                child: Image.asset(
                                  images[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                left: 12,
                                top: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    labels[index],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (restaurant != null)
                                      Container(
                                        width: 24,
                                        height: 24,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          restaurant.mark,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        restaurant?.name ?? '',
                                        style: AppText.caption().copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  hack.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.h2(
                                    color: AppColors.primary,
                                  ).copyWith(fontSize: 20, height: 24 / 20),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.mint,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                      ),
                                      child: Text(
                                        '${hack.calories} cal',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.warmSurface,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                      ),
                                      child: Text(
                                        '${hack.protein}g protein',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.warmForeground,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 16,
                                        color: Colors.white,
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryRail() {
    return SliverToBoxAdapter(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.eatOutCraveBg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BROWSE YOUR WAY',
                      style: AppText.eyebrow(color: const Color(0xFF6F8A00)),
                    ),
                    const SizedBox(height: 2),
                    Text('What are you craving?', style: AppText.h2()),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 96,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _quickCategories.map((category) {
                    final active = widget.category == category;
                    final image = category == 'All'
                        ? 'assets/images/eat-out/category-all-transparent-v3.png'
                        : _categoryImages[category]!;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        onTap: () => _setCategory(category),
                        child: Container(
                          width: 72,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: Image.asset(image, fit: BoxFit.contain),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                category,
                                style: AppText.caption(
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.mutedForeground,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _restaurantList() {
    final source = widget.dense ? restaurantsDense : restaurants;
    final categoryFiltered = widget.category == 'All'
        ? source
        : source.where((r) => r.category == widget.category).toList();
    final q = _query.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? categoryFiltered
        : categoryFiltered
              .where((r) => '${r.name} ${r.category}'.toLowerCase().contains(q))
              .toList();

    if (widget.dense) {
      final byCategory = <String, List<Restaurant>>{};
      for (final r in filtered) {
        (byCategory[r.category] ??= []).add(r);
      }
      return SliverList.list(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search 20 places',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No places match that search.', style: AppText.h2()),
                  const SizedBox(height: 8),
                  Text(
                    'Try a restaurant name or food category.',
                    style: AppText.bodySm(color: AppColors.mutedForeground),
                  ),
                ],
              ),
            ),
          for (final entry in byCategory.entries) ...[
            Container(
              width: double.infinity,
              color: AppColors.muted,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(entry.key, style: AppText.eyebrow()),
            ),
            for (final r in entry.value) _RestaurantRow(restaurant: r),
          ],
        ],
      );
    }

    final nearest = widget.category == 'All' && filtered.isNotEmpty
        ? filtered.first
        : null;
    final rest = nearest != null ? filtered.skip(1).toList() : filtered;
    return SliverList.list(
      children: [
        if (nearest != null) _RestaurantFeature(restaurant: nearest),
        for (final r in rest) _RestaurantRow(restaurant: r),
      ],
    );
  }

  Widget _goalView() {
    const goals = [Goal.lose, Goal.gain, Goal.maintain];
    return SliverList.list(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR HEALTH CONTEXT',
                style: AppText.eyebrow(color: AppColors.primary),
              ),
              const SizedBox(height: 2),
              Text('Browse by outcome', style: AppText.h2()),
              const SizedBox(height: 8),
              Text(
                'Protein and portion context stay visible for every order.',
                style: AppText.bodySm(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
        for (final goal in goals) ...[
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      GoalFitBadge(goal: goal),
                      const SizedBox(width: 8),
                      Text(
                        '${fastHacks.where((h) => h.goals.contains(goal)).length} orders',
                        style: AppText.caption(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final hack in fastHacks.where(
                        (h) => h.goals.contains(goal),
                      ))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FastHackCard(
                            hack: hack,
                            restaurant: restaurantById(hack.restaurantId),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _nearbyView(BuildContext context) {
    final nearby = restaurants.where((r) => r.distanceMi != null).toList()
      ..sort((a, b) => a.distanceMi!.compareTo(b.distanceMi!));
    return SliverList.list(
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFFEEF3F0)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ASHBURN, VIRGINIA',
                      style: AppText.eyebrow(color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Closest places first', style: AppText.h2()),
                const SizedBox(height: 8),
                Text(
                  'Distance is approximate and only used for sorting.',
                  style: AppText.bodySm(color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
        ),
        for (final r in nearby) _RestaurantRow(restaurant: r),
      ],
    );
  }
}

/// Location permission pre-prompt — shown once when Nearest is opened (S-20).
void showLocationSheet(BuildContext context, VoidCallback onDone) {
  showProductSheet(
    context,
    title: 'Show places near you?',
    description:
        'Location is used once to order nearby places and is not stored.',
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(Icons.place_rounded, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            'We use your location only to sort this list. Everything still works if you choose not to share it.',
            style: AppText.body(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                showAppToast(context, 'Sorted by your location');
                onDone();
              },
              child: const Text('Use my location'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDone();
              },
              child: const Text('Use default area'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ViewTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ViewTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppText.label(
              color: active ? AppColors.primary : AppColors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

class _RestaurantRow extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantRow({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/restaurant/${restaurant.id}'),
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  _restaurantImage(restaurant),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: AppText.h3(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${restaurant.category} · ${restaurant.hackCount} smart orders${restaurant.distanceMi != null ? " · ${restaurant.distanceMi} mi" : ""}',
                    style: AppText.caption(),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantFeature extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantFeature({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        onTap: () => context.push('/restaurant/${restaurant.id}'),
        child: Container(
          clipBehavior: Clip.antiAlias,
          constraints: const BoxConstraints(minHeight: 192),
          decoration: BoxDecoration(
            color: AppColors.foreground,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: 8,
                bottom: 8,
                width: 220,
                child: Image.asset(
                  _restaurantImage(restaurant),
                  fit: BoxFit.contain,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.foreground,
                      AppColors.foreground.withValues(alpha: 0.88),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 150),
                      Text(
                        'CLOSEST TO YOU',
                        style: AppText.eyebrow(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        restaurant.name,
                        style: AppText.h2(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${restaurant.distanceMi} mi · ${restaurant.hackCount} smart orders',
                        style: AppText.bodySm(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See what works',
                            style: AppText.label(color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
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
