import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../data/fixtures.dart';
import '../data/order_search.dart';
import '../data/recipes.dart';
import '../product.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/figma_components.dart';
import '../widgets/forkthis_moments.dart';
import '../widgets/primitives.dart';

const _suggestions = [
  'something high-protein I can grab nearby',
  'what can I order at a coffee place that isn’t sugar',
  'a lunch that won’t wreck my afternoon',
  'I’ve got 400 calories left and I’m out',
];
const _suggestionTones = [
  AppColors.warmSurface,
  AppColors.mint,
  AppColors.blueberrySurface,
  AppColors.coralSurface,
];

/// Ported from `../app/src/screens/Search.tsx`.
class SearchScreen extends StatefulWidget {
  final String initialQuery;

  /// 'all' searches orders and recipes; 'recipes' narrows to Cook. Entering
  /// from Cook's search button pre-narrows so results match the tab the user
  /// came from, but the scope is switchable in-place rather than a dead end.
  final String scope;

  const SearchScreen({super.key, this.initialQuery = '', this.scope = 'all'});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  late String _q = widget.initialQuery;
  late String _scope = widget.scope;

  List<Recipe> _recipeResults(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final tokens = q
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length > 2)
        .toSet();
    return recipes.where((r) {
      final haystack = [
        r.title,
        r.time,
        ...r.ingredients,
        ...r.meals,
      ].join(' ').toLowerCase();
      final tokenHit = tokens.any(haystack.contains);
      final proteinHit = q.contains('protein') && r.protein >= 30;
      final quickHit =
          (q.contains('quick') || q.contains('fast')) && r.minutes <= 20;
      return tokenHit || proteinHit || quickHit;
    }).toList();
  }

  void _setQuery(String q) => setState(() {
    _q = q;
    _controller.text = q;
  });

  String _resultSummary(int orders, int recipeCount) {
    if (orders > 0 && recipeCount > 0) {
      return '$orders orders and $recipeCount recipes';
    }
    if (orders > 0) return '$orders orders worth a look';
    return '$recipeCount ${recipeCount == 1 ? 'recipe' : 'recipes'} worth a look';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _q.trim().isNotEmpty;
    final results = hasQuery && _scope != 'recipes'
        ? searchFastHacks(_q)
        : <FastHack>[];
    final recipeHits = hasQuery && _scope != 'orders'
        ? _recipeResults(_q)
        : <Recipe>[];
    final empty = hasQuery && results.isEmpty && recipeHits.isEmpty;

    final state = context.read<AppState>();

    return AppShell(
      header: ScreenHeader(
        title: 'ForkThis! moments',
        eyebrow: 'DECIDE',
        onBack: () => context.pop(),
      ),
      child: ColoredBox(
        color: AppColors.highlight,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: _SearchHero(
                controller: _controller,
                query: _q,
                scope: _scope,
                onQueryChanged: (v) => setState(() => _q = v),
                onQueryCleared: () => setState(() {
                  _q = '';
                  _controller.clear();
                }),
                onScopeChanged: (v) => setState(() => _scope = v),
              ),
            ),
            if (!hasQuery) ...[
              _SectionHeader(
                eyebrow: productMomentLabel.toUpperCase(),
                title: 'Start where you are',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ForkThisMomentPanel(
                  title: 'Choose the situation',
                  subtitle:
                      'Each moment becomes an order or recipe you can actually use.',
                  onSelected: (moment) {
                    state.recordForkThisMoment(moment.id);
                    _scope = moment.scope;
                    _setQuery(moment.query);
                  },
                ),
              ),
              const _SectionHeader(
                eyebrow: 'PLAIN ENGLISH',
                title: 'Or try a sentence',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    for (final (index, s) in _suggestions.indexed) ...[
                      if (index > 0) const SizedBox(height: 10),
                      _SuggestionCard(
                        text: s,
                        tone: _suggestionTones[index],
                        onTap: () => _setQuery(s),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _BrowseCard(
                  onOrders: () => context.go('/eat-out'),
                  onRecipes: () => context.go('/cook'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: const DisclaimerNote(),
              ),
            ],
            if (empty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: _EmptySearchCard(
                  onOrders: () => context.go('/eat-out'),
                  onRecipes: () => context.go('/cook'),
                ),
              ),
            if (hasQuery && !empty) ...[
              _ResultsHeader(
                title: _resultSummary(results.length, recipeHits.length),
                query: _q,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final h in results)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FastHackCard(
                          hack: h,
                          restaurant: restaurantById(h.restaurantId),
                        ),
                      ),
                    if (recipeHits.isNotEmpty) ...[
                      if (results.isNotEmpty) const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, left: 4),
                        child: Text(
                          'RECIPES TO COOK',
                          style: AppText.eyebrow(color: AppColors.primary),
                        ),
                      ),
                      for (final r in recipeHits)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => context.push('/cook/recipe/${r.id}'),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xl,
                                ),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                    child: Image.asset(
                                      r.image,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(r.title, style: AppText.h3()),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${r.time} · ${r.calories} cal · ${r.protein}g protein',
                                          style: AppText.caption(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: const DisclaimerNote(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchHero extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final String scope;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onQueryCleared;
  final ValueChanged<String> onScopeChanged;
  const _SearchHero({
    required this.controller,
    required this.query,
    required this.scope,
    required this.onQueryChanged,
    required this.onQueryCleared,
    required this.onScopeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedSparkles,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'ASK IN PLAIN ENGLISH',
                  style: AppText.kicker(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'What would make today easier?',
            style: AppText.headline(36, height: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Text(
            'Search order scripts and recipes using the words you would actually say in a ForkThis! moment.',
            style: AppText.bodySm(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'High protein nearby, quick dinner...',
              prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
              suffixIcon: query.trim().isEmpty
                  ? const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: AppColors.primary,
                    )
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: onQueryCleared,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          SegmentedPills<String>(
            values: const ['all', 'orders', 'recipes'],
            selected: scope,
            labelFor: (value) => switch (value) {
              'orders' => 'Orders',
              'recipes' => 'Cook',
              _ => 'All',
            },
            onChanged: onScopeChanged,
            trackColor: AppColors.highlight,
            activeColor: AppColors.primary,
            activeForeground: AppColors.primaryForeground,
            inactiveForeground: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  const _SectionHeader({required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: AppText.kicker(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(title, style: AppText.headline(30)),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String text;
  final Color tone;
  final VoidCallback onTap;
  const _SuggestionCard({
    required this.text,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        constraints: const BoxConstraints(minHeight: 82),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedBubbleChatQuestion,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: AppText.cardTitle(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
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

class _BrowseCard extends StatelessWidget {
  final VoidCallback onOrders;
  final VoidCallback onRecipes;
  const _BrowseCard({required this.onOrders, required this.onRecipes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BROWSE INSTEAD', style: AppText.kicker()),
          const SizedBox(height: 6),
          Text(
            'Start from the shelf that fits the moment.',
            style: AppText.h3(),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onOrders,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.card,
              side: BorderSide.none,
            ),
            child: const Text('Eat out'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRecipes,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.card,
              side: BorderSide.none,
            ),
            child: const Text('Cook'),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchCard extends StatelessWidget {
  final VoidCallback onOrders;
  final VoidCallback onRecipes;
  const _EmptySearchCard({required this.onOrders, required this.onRecipes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nothing matched that one.', style: AppText.h2()),
          const SizedBox(height: 8),
          Text(
            'Try fewer specifics, or browse the places and recipes we cover.',
            style: AppText.bodySm(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: onOrders,
            child: const Text('Browse orders'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onRecipes, child: const Text('Recipes')),
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final String title;
  final String query;
  const _ResultsHeader({required this.title, required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BEST AVAILABLE MATCHES',
            style: AppText.kicker(color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(title, style: AppText.headline(30)),
          const SizedBox(height: 8),
          Text(
            'For "$query"',
            style: AppText.bodySm(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
