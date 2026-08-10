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
import '../widgets/ask_entry.dart';
import '../widgets/app_toast.dart';
import '../widgets/figma_components.dart';
import '../widgets/primitives.dart';
import '../widgets/product_sheet.dart';
import '../widgets/states.dart';

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
    // FR-20 — "without permission the experience degrades to manual browse
    // with no nagging". Once the user has answered, we never ask again from
    // here; the only way back is the explicit control in Settings.
    if (context.read<AppState>().locationPromptSeen) return;
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
      value: SystemUiOverlayStyle.dark,
      child: AppShell(
        scrollTitle: 'Eat out',
        scrollEyebrow: 'SMART ORDERS',
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _EatOutHero(onSearch: () => context.push('/search')),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedPills<String>(
                      values: const ['restaurant', 'goal', 'nearby'],
                      selected: widget.view,
                      labelFor: (v) => switch (v) {
                        'goal' => 'By goal',
                        'nearby' => 'Nearest',
                        _ => 'For you',
                      },
                      onChanged: _setView,
                      trackColor: AppColors.highlight,
                      activeColor: AppColors.card,
                      activeForeground: AppColors.primary,
                      inactiveForeground: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const AskPill(),
                ],
              ),
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

/// Figma node 321:1671 "Header" — shared verbatim by the Browse & Discover
/// and Start with an Order pulls (321:1671, 321:2468 both show identical
/// eyebrow/headline/body copy), so this hero is the header for all three
/// Eat Out tabs, not just "For you".
class _EatOutHero extends StatelessWidget {
  final VoidCallback onSearch;
  const _EatOutHero({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedLocation01,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ASHBURN, VIRGINIA',
                              style: AppText.kicker(color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Eat well, wherever you are.',
                          style: AppText.headline(
                            42,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: onSearch,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.foreground,
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Smart orders matched to your goals, health context, and real life. Organized by restaurant so the choice feels smaller.',
                style: AppText.bodySm(),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: onSearch,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.foreground),
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        size: 16,
                        color: AppColors.foreground,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Restaurant, dish, or craving',
                          style: AppText.bodySm(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 16,
                        color: AppColors.foreground,
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
                'MADE FOR RIGHT NOW',
                style: AppText.kicker(color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text('Start with an order', style: AppText.h2()),
            ],
          ),
        ),
        SizedBox(
          // Matches RailCard's actual content height (207 image + 16/16
          // padding + eyebrow/title/meta text block) instead of the old 380,
          // which left ~50px of dead white space under every card.
          height: 336,
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
          padding: const EdgeInsets.fromLTRB(20, 34, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHOOSE A LANE',
                style: AppText.kicker(color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text('What sounds good?', style: AppText.h3()),
            ],
          ),
        ),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _quickCategories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = _quickCategories[index];
              final active = item == category;
              return _CategoryTile(
                label: item,
                image: _categoryImages[item],
                active: active,
                onTap: () => onCategoryChanged(item),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPLORE RESTAURANTS',
                          style: AppText.kicker(color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text('A good place to start', style: AppText.h3()),
                      ],
                    ),
                  ),
                  Text(
                    '${source.length} tested ${source.length == 1 ? 'place' : 'places'}',
                    style: AppText.caption(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: query,
                onChanged: (_) => onQueryChanged(),
                decoration: const InputDecoration(
                  hintText: 'Search tested places',
                  prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
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

/// Category quick-filter tile — image + label, matching Figma's "Choose a
/// lane" / "What are you craving?" chip grid (node 321:1756). Distinct from a
/// plain [ChoiceChip]: the active state is a tinted card, not just a border.
class _CategoryTile extends StatelessWidget {
  final String label;
  final String? image;
  final bool active;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.image,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 72,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? Colors.white.withValues(alpha: 0.8) : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: active ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 58,
              width: double.infinity,
              child: image == null
                  ? Icon(
                      Icons.restaurant_menu,
                      color: active
                          ? AppColors.primary
                          : AppColors.mutedForeground,
                    )
                  : Image.asset(image!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppText.tagBold(
                color: active ? AppColors.primary : AppColors.mutedForeground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
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
    final badges = ['BEST MATCH', 'EASY SWAP', 'HIGH PROTEIN'];
    return RailCard(
      image: hack.image,
      badge: badges[index % badges.length],
      eyebrow: restaurant?.name ?? 'Smart order',
      title: hack.title,
      meta: '${hack.calories} cal · ${hack.protein}g protein',
      onTap: () => context.push('/hack/${hack.id}'),
      width: 270,
    );
  }
}

/// Figma node 321:2044 "5.3 Eat Out – Browse by Outcome". The profile's own
/// goal opens selected, but every outcome is browsable from here — the pill
/// row (see [CountChip]) is a real switch, not decoration.
class _GoalView extends StatefulWidget {
  final Goal goal;
  const _GoalView({required this.goal});

  @override
  State<_GoalView> createState() => _GoalViewState();
}

class _GoalViewState extends State<_GoalView> {
  late Goal _selected = widget.goal;

  @override
  Widget build(BuildContext context) {
    final matches = fastHacks
        .where((hack) => hack.goals.contains(_selected))
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR HEALTH CONTEXT',
            style: AppText.kicker(color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text('Browse by outcome', style: AppText.h3()),
          const SizedBox(height: 6),
          Text(
            'Protein and portion context stay visible for every order.',
            style: AppText.bodySm(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: Goal.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final g = Goal.values[index];
                final count = fastHacks
                    .where((hack) => hack.goals.contains(g))
                    .length;
                return CountChip(
                  label: goalLabel[g]!,
                  count: count,
                  selected: g == _selected,
                  onTap: () => setState(() => _selected = g),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          for (final hack in matches)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FastHackCard(
                hack: hack,
                restaurant: restaurantById(hack.restaurantId),
              ),
            ),
          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No orders tagged for this outcome yet.',
                style: AppText.bodySm(color: AppColors.mutedForeground),
              ),
            ),
          if (_selected == widget.goal) ...[
            const SizedBox(height: 4),
            Text(
              '${goalLabel[widget.goal]} is your current goal.',
              style: AppText.caption(),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _NearbyView extends StatelessWidget {
  const _NearbyView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // S-20 — the pre-prompt. Asked in the app's own words, before the OS
    // dialog, so the user knows what they are agreeing to and a decline is not
    // a permanent loss.
    if (!state.locationPromptSeen) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
        child: StateSurface.empty(
          icon: HugeIcons.strokeRoundedLocation01,
          title: 'Sort by what is actually close',
          body:
              'With your location, this list starts with the places you can reach now. It is used to sort this screen and nothing else — not stored, not attached to your profile.',
          primaryLabel: 'Use my location',
          onPrimary: () => state.setLocationEnabled(true),
          secondaryLabel: 'Not now',
          onSecondary: () => state.setLocationEnabled(false),
          padding: const EdgeInsets.symmetric(vertical: 24),
        ),
      );
    }

    // Permission-denied variant: full manual browse, one quiet line of
    // explanation, and no repeat ask.
    if (!state.profile.locationEnabled) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ALL PLACES WE COVER',
              style: AppText.kicker(color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text('Browse by name', style: AppText.h2()),
            const SizedBox(height: 12),
            InlineNote(
              icon: HugeIcons.strokeRoundedLocation01,
              text:
                  'Location is off, so this is the full list rather than the closest first. You can turn it on in Settings whenever it would help.',
            ),
            const SizedBox(height: 20),
            for (final restaurant in restaurants)
              _RestaurantRow(restaurant: restaurant),
          ],
        ),
      );
    }

    final nearby =
        restaurants
            .where((restaurant) => restaurant.distanceMi != null)
            .toList()
          ..sort((a, b) => a.distanceMi!.compareTo(b.distanceMi!));

    // Granted but nothing in range — a real state, not an empty column.
    if (nearby.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
        child: StateSurface.noResults(
          title: 'Nothing covered nearby yet',
          body:
              'We do not have guides for anywhere close to you right now. More places are being added — browsing by name still works.',
          primaryLabel: 'Browse all places',
          onPrimary: () => context.go('/eat-out?view=restaurant'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedLocation01,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'ASHBURN, VIRGINIA',
                style: AppText.kicker(color: AppColors.primary),
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
          const SizedBox(height: 20),
          for (final restaurant in nearby)
            _RestaurantRow(restaurant: restaurant),
        ],
      ),
    );
  }
}

/// Restaurant list row — Figma node 321:1901 "5.1 Eat Out – Restaurant List".
/// Close kin of [ThumbListRow] but the thumbnail is a contain-fit square
/// (restaurant marks are transparent PNGs that crop badly under
/// [ThumbListRow]'s circular cover-fit), so this stays its own widget rather
/// than forcing that shared one to fit content it wasn't built for.
class _RestaurantRow extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantRow({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final availableGuides = hacksByRestaurant(restaurant.id).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push('/restaurant/${restaurant.id}'),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: const BoxConstraints(minHeight: 80),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.highlight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Image.asset(
                  _restaurantImage(restaurant),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: AppText.body(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        restaurant.category,
                        availableGuides == 0
                            ? 'Menu review pending'
                            : '$availableGuides ${availableGuides == 1 ? "tested order" : "tested orders"}',
                        if (restaurant.distanceMi != null)
                          '${restaurant.distanceMi} mi',
                      ].join(' · '),
                      style: AppText.caption(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
                color: AppColors.mutedForeground,
              ),
            ],
          ),
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
                // Persist the answer so the pre-prompt never fires twice.
                pageContext.read<AppState>().setLocationEnabled(true);
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
                pageContext.read<AppState>().setLocationEnabled(false);
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
