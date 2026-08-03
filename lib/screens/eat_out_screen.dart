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

String _restaurantImage(Restaurant restaurant) {
  final hacks = fastHacks.where((item) => item.restaurantId == restaurant.id);
  return _categoryImages[restaurant.category] ??
      (hacks.isEmpty
          ? 'assets/images/recipe-exemplars/02-grilled-chicken-grain-bowl.jpg'
          : hacks.first.image);
}

class EatOutScreen extends StatefulWidget {
  final String view;
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
    if (oldWidget.view != widget.view && widget.view != 'nearby') {
      _locationPromptShown = false;
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _setView(String view) {
    context.go(
      Uri(
        path: '/eat-out',
        queryParameters: {'view': view, if (widget.dense) 'data': 'dense'},
      ).toString(),
    );
  }

  void _setCategory(String category) {
    context.go(
      Uri(
        path: '/eat-out',
        queryParameters: {
          'view': 'restaurant',
          if (widget.dense) 'data': 'dense',
          if (category != 'All') 'category': category,
        },
      ).toString(),
    );
  }

  void _scheduleLocationPrompt() {
    if (widget.view != 'nearby' || _locationPromptShown) return;
    _locationPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showLocationSheet(context, () {});
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleLocationPrompt();
    final state = context.watch<AppState>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AppShell(
        scrollTitle: 'Eat out',
        scrollEyebrow: 'SMART ORDERS',
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _EatOutHero(onSearch: () => context.push('/search')),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: _ViewControl(view: widget.view, onChanged: _setView),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.02, 0.02),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(widget.view),
                child: switch (widget.view) {
                  'goal' => _GoalView(goal: state.profile.goal),
                  'nearby' => const _NearbyView(),
                  _ => _ForYouView(
                    dense: widget.dense,
                    category: widget.category,
                    query: _query,
                    onCategoryChanged: _setCategory,
                    onQueryChanged: () => setState(() {}),
                  ),
                },
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

class _EatOutHero extends StatelessWidget {
  final VoidCallback onSearch;
  const _EatOutHero({required this.onSearch});

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
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedLocation01,
                    size: 15,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'ASHBURN, VIRGINIA',
                      style: AppText.eyebrow(color: AppColors.accent),
                    ),
                  ),
                  IconButton(
                    onPressed: onSearch,
                    tooltip: 'Search meals and restaurants',
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'A better order,\nwithout the homework.',
                style: AppText.h1(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'Use the restaurant you already chose. We will show the useful swaps and what to say at the counter.',
                style: AppText.bodySm(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: onSearch,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Restaurant, dish, or craving',
                          style: AppText.bodySm(color: Colors.white70),
                        ),
                      ),
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 17,
                        color: AppColors.accent,
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

class _ViewControl extends StatelessWidget {
  final String view;
  final ValueChanged<String> onChanged;
  const _ViewControl({required this.view, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          _ModeButton(
            label: 'For you',
            active: view == 'restaurant',
            onTap: () => onChanged('restaurant'),
          ),
          _ModeButton(
            label: 'By goal',
            active: view == 'goal',
            onTap: () => onChanged('goal'),
          ),
          _ModeButton(
            label: 'Nearest',
            active: view == 'nearby',
            onTap: () => onChanged('nearby'),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
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

class _ForYouView extends StatelessWidget {
  final bool dense;
  final String category;
  final TextEditingController query;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onQueryChanged;

  const _ForYouView({
    required this.dense,
    required this.category,
    required this.query,
    required this.onCategoryChanged,
    required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final source = dense ? restaurantsDense : restaurants;
    final search = query.text.trim().toLowerCase();
    final filtered = source.where((restaurant) {
      final matchesCategory =
          category == 'All' || restaurant.category == category;
      final matchesQuery =
          search.isEmpty ||
          '${restaurant.name} ${restaurant.category}'.toLowerCase().contains(
            search,
          );
      return matchesCategory && matchesQuery;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MATCHED TO TODAY',
                style: AppText.eyebrow(color: AppColors.success),
              ),
              const SizedBox(height: 3),
              Text('Start with the easiest win', style: AppText.h2()),
            ],
          ),
        ),
        SizedBox(
          height: 304,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _HackFeature(hack: fastHacks[index], index: index),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 34, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BROWSE PLACES',
                style: AppText.eyebrow(color: AppColors.primary),
              ),
              const SizedBox(height: 3),
              Text('Use the menu you already have', style: AppText.h2()),
              const SizedBox(height: 14),
              TextField(
                controller: query,
                onChanged: (_) => onQueryChanged(),
                decoration: const InputDecoration(
                  hintText: 'Filter restaurants',
                  prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _quickCategories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = _quickCategories[index];
              final active = item == category;
              return ChoiceChip(
                selected: active,
                label: Text(item),
                onSelected: (_) => onCategoryChanged(item),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.card,
                side: BorderSide(
                  color: active ? AppColors.primary : AppColors.border,
                ),
                labelStyle: AppText.label(
                  color: active ? Colors.white : AppColors.foreground,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const _EmptyRestaurants()
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (final restaurant in filtered)
                  _RestaurantRow(restaurant: restaurant),
              ],
            ),
          ),
      ],
    );
  }
}

class _HackFeature extends StatelessWidget {
  final FastHack hack;
  final int index;
  const _HackFeature({required this.hack, required this.index});

  @override
  Widget build(BuildContext context) {
    final restaurant = restaurantById(hack.restaurantId);
    final labels = ['BEST MATCH', 'EASY SWAP', 'HIGH PROTEIN'];
    return SizedBox(
      width: 270,
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
                height: 148,
                width: double.infinity,
                child: Image.asset(hack.image, fit: BoxFit.cover),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labels[index],
                        style: AppText.eyebrow(color: AppColors.success),
                      ),
                      const SizedBox(height: 4),
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

class _GoalView extends StatelessWidget {
  final Goal goal;
  const _GoalView({required this.goal});

  @override
  Widget build(BuildContext context) {
    final matches = fastHacks
        .where((hack) => hack.goals.contains(goal))
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR CURRENT GOAL',
                  style: AppText.eyebrow(color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                GoalFitBadge(goal: goal),
                const SizedBox(height: 12),
                Text(
                  '${matches.length} orders fit your plan',
                  style: AppText.h2(),
                ),
                const SizedBox(height: 6),
                Text(
                  'Calories, protein, and the useful menu changes stay visible before you open anything.',
                  style: AppText.bodySm(color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (final hack in matches)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FastHackCard(
                hack: hack,
                restaurant: restaurantById(hack.restaurantId),
              ),
            ),
        ],
      ),
    );
  }
}

class _NearbyView extends StatelessWidget {
  const _NearbyView();

  @override
  Widget build(BuildContext context) {
    final nearby =
        restaurants
            .where((restaurant) => restaurant.distanceMi != null)
            .toList()
          ..sort((a, b) => a.distanceMi!.compareTo(b.distanceMi!));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedLocation01,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CLOSEST FIRST',
                      style: AppText.eyebrow(color: AppColors.primary),
                    ),
                    Text('Near Ashburn, Virginia', style: AppText.h2()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Distance is approximate and only used to sort this list.',
            style: AppText.bodySm(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 20),
          for (final restaurant in nearby)
            _RestaurantRow(restaurant: restaurant),
        ],
      ),
    );
  }
}

class _RestaurantRow extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantRow({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final availableGuides = hacksByRestaurant(restaurant.id).length;
    return InkWell(
      onTap: () => context.push('/restaurant/${restaurant.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Image.asset(
                _restaurantImage(restaurant),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 3),
                  Text(
                    availableGuides == 0
                        ? '${restaurant.category}  ·  Menu review pending'
                        : '${restaurant.category}  ·  $availableGuides ${availableGuides == 1 ? "guide" : "guides"} available',
                    style: AppText.caption(),
                  ),
                  if (restaurant.distanceMi != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${restaurant.distanceMi} mi away',
                      style: AppText.caption(color: AppColors.success),
                    ),
                  ],
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
    );
  }
}

class _EmptyRestaurants extends StatelessWidget {
  const _EmptyRestaurants();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No places match that search.', style: AppText.h2()),
          const SizedBox(height: 6),
          Text(
            'Try a restaurant name or switch the category back to All.',
            style: AppText.bodySm(color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

void showLocationSheet(BuildContext context, VoidCallback onDone) {
  final pageContext = context;
  showProductSheet(
    context,
    title: 'Show places near you?',
    description:
        'Location is used once to sort nearby places and is not stored.',
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedLocation01,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Everything still works if you choose not to share it. The default area remains available.',
            style: AppText.body(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                showAppToast(pageContext, 'Nearby places sorted');
                onDone();
              },
              child: const Text('Use my location'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
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
