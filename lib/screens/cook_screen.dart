import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../data/fixtures.dart';
import '../data/recipes.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/ask_entry.dart';
import '../widgets/figma_components.dart';
import '../widgets/primitives.dart';
import '../widgets/states.dart';
import 'recipe_filters.dart';
import 'log_flow.dart';
import '../widgets/app_toast.dart';

/// Restyled against the Figma redesign pulled 2026-08-06
/// (`figma.com/design/LjDp489aFZaYiDx88MvvkQ`, nodes 321:1030 "4.1 Cook –
/// Browse Recipes" and 321:1512 "4.2 Cook – Recipe Detail"). Every
/// interaction below predates the restyle and is unchanged: the quick-filter
/// chips and the filter sheet both still drive [_filter]/[_filters], the
/// search affordance still pushes `/search`, the save toggle and portion-sheet
/// logging flow are untouched, and the AI-image disclosure badge and "Ask
/// about this recipe" row are still exactly where FR-25 and App Flow §1.3
/// put them.

/// Best-effort tag for a recipe's colored corner chip and detail-page tag
/// line. Cook's list rows in Figma each carry a one-word vibe tag ("Comfort",
/// "Bright", "Cozy"…) that has no equivalent field on [Recipe] — rather than
/// invent that vocabulary, this derives a real descriptor from the data that
/// already exists: the recipe's first condition tag, falling back to its
/// first goal.
String _recipeTag(Recipe r) {
  if (r.conditions.isNotEmpty) return conditionLabel[r.conditions.first]!;
  return goalLabel[r.goals.first]!;
}

/// A one-line "why this fits" blurb, built only from real [Recipe] fields
/// (tag, ingredient count, serving) — Figma's recipe rows carry hand-written
/// blurbs ("Sheet-pan comfort with crisp edges…") that don't exist in this
/// data model, so this composes an honest equivalent instead of inventing
/// prose.
String _recipeBlurb(Recipe r) {
  final tag = _recipeTag(r).toLowerCase();
  return 'Fits a $tag plan — ${r.ingredients.length} ingredients, ${r.serving}.';
}

Widget _metricPill(
  String text, {
  required Color background,
  required Color foreground,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(text, style: AppText.tagBold(color: foreground)),
  );
}

class CookScreen extends StatefulWidget {
  final String? recipeId;
  const CookScreen({super.key, this.recipeId});

  @override
  State<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends State<CookScreen> {
  // S-22 — filters on the four axes FR-22 names: goal, meal type, prep time,
  // and dietary/condition tags. The chip row stays as the fast path for the one
  // filter people reach for most; everything else lives in the sheet so the
  // browse header does not become a control panel.
  String _filter = 'All';
  RecipeFilters _filters = const RecipeFilters();

  static const _filterLabels = [
    'All',
    'Under 20 min',
    'High protein',
    'Gentle',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.recipeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/cook/recipe/${widget.recipeId}');
      });
    }
  }

  List<Recipe> get _visibleRecipes {
    final quick = switch (_filter) {
      'Under 20 min' => recipes.where((r) => r.minutes <= 20).toList(),
      'High protein' => recipes.where((r) => r.protein >= 35).toList(),
      'Gentle' => recipes.where((r) => r.calories <= 400).toList(),
      _ => recipes.toList(),
    };
    return quick.where(_filters.matches).toList();
  }

  Future<void> _openFilterSheet() async {
    final next = await showRecipeFilterSheet(context, _filters);
    if (next != null && mounted) setState(() => _filters = next);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final featured = recipes.first;
    final visible = _visibleRecipes;
    final quickest = recipes.reduce((a, b) => a.minutes <= b.minutes ? a : b);
    final quickCount = recipes.where((r) => r.minutes <= 20).length;
    final proteinCount = recipes.where((r) => r.protein >= 30).length;

    return AppShell(
      scrollTitle: 'Cook',
      scrollEyebrow: 'COOK',
      child: ColoredBox(
        color: AppColors.highlight,
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COOK',
                            style: AppText.kicker(color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Pick the craving. Get the recipe.',
                            style: AppText.h1(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Search by taste, ingredient, meal type, or goal. Open a recipe for groceries, steps, portions, and macros.',
                            style: AppText.bodySm(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: AskPill(),
                    ),
                  ],
                ),
              ),
              // Search entry — still a route push to /search, not a live text
              // field, restyled as Figma's rounded search bar so it reads as
              // one at a glance. The filter-sheet trigger sits inside it now
              // rather than as a separate button.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: InkWell(
                  onTap: () => context.push('/search?scope=recipes'),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.only(left: 20, right: 6),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.06),
                          offset: const Offset(0, 12),
                          blurRadius: 34,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedSearch01,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Chicken, cozy, bowl...',
                            style: AppText.bodySm(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                        Badge(
                          isLabelVisible: _filters.isActive,
                          label: Text('${_filters.activeCount}'),
                          backgroundColor: AppColors.action,
                          child: IconButton(
                            onPressed: _openFilterSheet,
                            tooltip: 'Filter recipes',
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedFilterHorizontal,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filterLabels.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final label = _filterLabels[index];
                    final selected = _filter == label;
                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = label),
                      showCheckmark: false,
                      labelStyle: AppText.button(
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.background,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StatTileBanner(
                  eyebrow: 'Kitchen flow',
                  heading: 'Recipe help without the scroll hunt.',
                  tiles: [
                    StatTile(value: '${recipes.length}', label: 'recipes'),
                    StatTile(value: '$quickCount', label: 'fast'),
                    StatTile(
                      value: '$proteinCount',
                      label: '30g+',
                      background: AppColors.accent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _FeaturedRecipe(
                  recipe: featured,
                  saved: state.savedRecipeIds.contains(featured.id),
                  onTap: () => context.push('/cook/recipe/${featured.id}'),
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BROWSE LANES',
                      style: AppText.kicker(color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text('Start from a need', style: AppText.h1()),
                  ],
                ),
              ),
              SizedBox(
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    CountChip(
                      label: 'Quick',
                      count: recipes.where((r) => r.minutes <= 20).length,
                      selected: _filter == 'Under 20 min',
                      onTap: () => setState(() => _filter = 'Under 20 min'),
                    ),
                    const SizedBox(width: 6),
                    CountChip(
                      label: 'Protein',
                      count: recipes.where((r) => r.protein >= 35).length,
                      selected: _filter == 'High protein',
                      onTap: () => setState(() => _filter = 'High protein'),
                    ),
                    const SizedBox(width: 6),
                    CountChip(
                      label: 'Gentle',
                      count: recipes.where((r) => r.calories <= 400).length,
                      selected: _filter == 'Gentle',
                      onTap: () => setState(() => _filter = 'Gentle'),
                    ),
                    const SizedBox(width: 6),
                    CountChip(
                      label: 'All',
                      count: recipes.length,
                      selected: _filter == 'All',
                      onTap: () => setState(() => _filter = 'All'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CtaBannerCard(
                  icon: HugeIcons.strokeRoundedClock01,
                  title: quickest.title,
                  subtitle:
                      '${quickest.time} · ${quickest.protein}g protein · ${quickest.meals.first}',
                  plateColor: AppColors.secondary,
                  iconColor: AppColors.textPrimary,
                  background: AppColors.goldLight,
                  showArrow: true,
                  onTap: () => context.push('/cook/recipe/${quickest.id}'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECIPE LIBRARY',
                      style: AppText.kicker(color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text('${visible.length} matches', style: AppText.h1()),
                  ],
                ),
              ),
              if (visible.isEmpty)
                StateSurface.noResults(
                  title: 'Nothing matches that combination',
                  body:
                      'The filters are narrower than the recipes we have right now. Widening one usually brings options back.',
                  primaryLabel: 'Clear filters',
                  onPrimary: () => setState(() {
                    _filter = 'All';
                    _filters = const RecipeFilters();
                  }),
                  secondaryLabel: 'Adjust filters',
                  onSecondary: _openFilterSheet,
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final (index, recipe) in visible.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RecipeRow(
                            recipe: recipe,
                            alternate: index.isOdd,
                            saved: state.savedRecipeIds.contains(recipe.id),
                            onTap: () =>
                                context.push('/cook/recipe/${recipe.id}'),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: InkWell(
                  onTap: () => context.go('/eat-out'),
                  borderRadius: BorderRadius.circular(AppRadius.banner),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(AppRadius.banner),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.card,
                            shape: BoxShape.circle,
                          ),
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedRestaurant01,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Plans changed?', style: AppText.h3()),
                              Text(
                                'Find a nearby order instead',
                                style: AppText.caption(),
                              ),
                            ],
                          ),
                        ),
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
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
      ),
    );
  }
}

class _FeaturedRecipe extends StatelessWidget {
  final Recipe recipe;
  final bool saved;
  final VoidCallback onTap;
  const _FeaturedRecipe({
    required this.recipe,
    required this.saved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.hero),
        ),
        padding: const EdgeInsets.all(12),
        // IntrinsicHeight + stretch, not a bare stretch — the Row sits inside
        // a ListView item where height is otherwise unbounded, and stretch
        // alone there renders a blank screen with no exception. IntrinsicHeight
        // gives the Row a concrete height first, same pattern as
        // FastHackCard in widgets/primitives.dart.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: SizedBox(
                      width: 104,
                      child: Image.asset(recipe.image, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'BEST FIRST',
                        style: AppText.tagBold(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  if (saved)
                    const Positioned(
                      right: 8,
                      top: 8,
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedBookmark02,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'RECOMMENDED',
                      style: AppText.kicker(color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(recipe.title, style: AppText.h2()),
                    const SizedBox(height: 6),
                    Text(
                      _recipeBlurb(recipe),
                      style: AppText.caption(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.highlight,
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _FeaturedMetric(
                              label: 'Time',
                              value: recipe.time,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: AppColors.goldLight,
                          ),
                          Expanded(
                            child: _FeaturedMetric(
                              label: 'Protein',
                              value: '${recipe.protein}g',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: AppColors.goldLight,
                          ),
                          Expanded(
                            child: _FeaturedMetric(
                              label: 'Cal',
                              value: '${recipe.calories}',
                            ),
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
    );
  }
}

class _FeaturedMetric extends StatelessWidget {
  final String label;
  final String value;
  const _FeaturedMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppText.button(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: AppText.kicker()),
      ],
    );
  }
}

class _RecipeRow extends StatelessWidget {
  final Recipe recipe;
  final bool saved;
  final bool alternate;
  final VoidCallback onTap;
  const _RecipeRow({
    required this.recipe,
    required this.saved,
    required this.onTap,
    this.alternate = false,
  });

  @override
  Widget build(BuildContext context) {
    return TaggedThumbRow(
      image: recipe.image,
      tag: _recipeTag(recipe),
      tagBackground: alternate ? AppColors.background : AppColors.goldLight,
      tagForeground: alternate ? AppColors.primary : AppColors.textPrimary,
      meta: '${recipe.time} · ${recipe.meals.first}',
      title: recipe.title,
      subtitle: '${recipe.ingredients.length} ingredients · ${recipe.serving}',
      onTap: onTap,
      pills: [
        _metricPill(
          '${recipe.protein}g protein',
          background: AppColors.accent,
          foreground: AppColors.textPrimary,
        ),
        _metricPill(
          '${recipe.calories} cal',
          background: AppColors.highlight,
          foreground: AppColors.textSecondary,
        ),
        if (saved)
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedBookmark02,
              size: 16,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}

class RecipeDetailScreen extends StatefulWidget {
  final String id;
  const RecipeDetailScreen({super.key, required this.id});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final Set<int> _ingredientsChecked = {};
  final Set<int> _stepsChecked = {};

  @override
  Widget build(BuildContext context) {
    final recipe = recipeById(widget.id);
    if (recipe == null) {
      return AppShell(
        header: ScreenHeader(
          title: 'Recipe not found',
          onBack: () => context.go('/cook'),
        ),
        child: Center(
          child: StateSurface.error(
            title: 'We could not open that recipe',
            body:
                'The link may be out of date, or the recipe may have been replaced. The rest of the kitchen is still here.',
            primaryLabel: 'Back to recipes',
            onPrimary: () => context.go('/cook'),
            secondaryLabel: 'Search',
            onSecondary: () => context.push('/search?scope=recipes'),
          ),
        ),
      );
    }
    final state = context.watch<AppState>();
    final saved = state.savedRecipeIds.contains(recipe.id);
    return AppShell(
      header: ScreenHeader(
        title: 'Recipe',
        onBack: () => context.pop(),
        trailing: IconButton(
          onPressed: () {
            state.toggleSavedRecipe(recipe.id);
            showAppToast(
              context,
              saved ? 'Removed from saved recipes' : 'Recipe saved',
              description: saved ? null : '+10 momentum points',
            );
          },
          tooltip: saved ? 'Remove saved recipe' : 'Save recipe',
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedBookmark02,
            color: saved ? AppColors.primary : AppColors.mutedForeground,
          ),
        ),
      ),
      fixedAction: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          // Goes through the portion sheet rather than logging a full serving
          // outright — one extra tap, and the entry is honest about how much
          // was actually eaten (PRD §3, U-4).
          onPressed: () => openPortionSheet(
            context,
            title: recipe.title,
            image: recipe.image,
            calories: recipe.calories,
            protein: recipe.protein,
            sourceId: recipe.id,
            type: 'recipe',
          ),
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
          label: const Text('Log this meal'),
        ),
      ),
      child: ColoredBox(
        color: AppColors.highlight,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.asset(recipe.image, fit: BoxFit.cover),
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedClock01,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          recipe.time,
                          style: AppText.caption(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                // S-24 / FR-25 — where no photograph exists, the image is
                // generated in the house style and labelled. Disclosure sits on
                // the image itself; burying it in a footer would be the thing
                // the client's own "clear vision" answer (Q-8) rules out.
                if (!recipe.photoIsReal)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.foreground.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedSparkles,
                            size: 13,
                            color: AppColors.background,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Illustration, not a photo',
                            style: AppText.caption(color: AppColors.background),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${recipe.meals.join(', ')} · ${_recipeTag(recipe)}'
                        .toUpperCase(),
                    style: AppText.kicker(color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(recipe.title, style: AppText.h1()),
                  const SizedBox(height: 8),
                  Text(
                    _recipeBlurb(recipe),
                    style: AppText.body(color: AppColors.textSecondary),
                  ),
                  if (recipe.goals.isNotEmpty ||
                      recipe.conditions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final goal in recipe.goals)
                          GoalFitBadge(goal: goal),
                        for (final condition in recipe.conditions)
                          ConditionTag(condition: condition),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DetailMetric(
                            label: 'Time',
                            value: recipe.time,
                          ),
                        ),
                        Expanded(
                          child: _DetailMetric(
                            label: 'Serving',
                            value: recipe.serving,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AskAboutRow(
                    seedQuestion: 'Tell me about ${recipe.title}',
                    label: 'Ask about this recipe',
                  ),
                  const SizedBox(height: 16),
                  Text('NUTRITION PER SERVING', style: AppText.kicker()),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.tile),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DetailMetric(
                            label: 'Calories',
                            value: '${recipe.calories}',
                            divider: true,
                          ),
                        ),
                        Expanded(
                          child: _DetailMetric(
                            label: 'Protein',
                            value: '${recipe.protein}g',
                            divider: true,
                          ),
                        ),
                        Expanded(
                          child: _DetailMetric(
                            label: 'Carbs',
                            value: '${recipe.carbs}g',
                            divider: true,
                          ),
                        ),
                        Expanded(
                          child: _DetailMetric(
                            label: 'Fat',
                            value: '${recipe.fat}g',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WHAT YOU NEED',
                              style: AppText.kicker(color: AppColors.primary),
                            ),
                            const SizedBox(height: 4),
                            Text('Ingredients', style: AppText.h1()),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${_ingredientsChecked.length}/${recipe.ingredients.length}',
                          style: AppText.caption(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (final (index, ingredient) in recipe.ingredients.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ChecklistRow(
                        label: ingredient,
                        checked: _ingredientsChecked.contains(index),
                        onTap: () => setState(() {
                          _ingredientsChecked.contains(index)
                              ? _ingredientsChecked.remove(index)
                              : _ingredientsChecked.add(index);
                        }),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MAKE IT',
                              style: AppText.kicker(color: AppColors.primary),
                            ),
                            const SizedBox(height: 4),
                            Text('Step by step', style: AppText.h1()),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${_stepsChecked.length}/${recipe.steps.length}',
                          style: AppText.caption(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (final (index, step) in recipe.steps.indexed)
                    _StepRow(
                      number: index + 1,
                      label: step,
                      checked: _stepsChecked.contains(index),
                      onTap: () => setState(() {
                        _stepsChecked.contains(index)
                            ? _stepsChecked.remove(index)
                            : _stepsChecked.add(index);
                      }),
                    ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedInformationCircle,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Nutrition is an estimate. Adjust portions to your appetite and care plan.',
                            style: AppText.bodySm(color: AppColors.primary),
                          ),
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
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool divider;
  const _DetailMetric({
    required this.label,
    required this.value,
    this.divider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: divider
          ? const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.goldLight)),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value, style: AppText.numericSm(color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppText.kicker(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;
  const _ChecklistRow({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked ? AppColors.action : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked ? AppColors.action : AppColors.goldLight,
                ),
              ),
              child: checked
                  ? const HugeIcon(
                      icon: HugeIcons.strokeRoundedTick01,
                      size: 15,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style:
                    AppText.bodySm(
                      color: checked
                          ? AppColors.mutedForeground
                          : AppColors.foreground,
                    ).copyWith(
                      decoration: checked ? TextDecoration.lineThrough : null,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String label;
  final bool checked;
  final VoidCallback onTap;
  const _StepRow({
    required this.number,
    required this.label,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.banner),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: checked ? AppColors.success : AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.banner),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: checked
                  ? const HugeIcon(
                      icon: HugeIcons.strokeRoundedTick01,
                      size: 18,
                      color: AppColors.textPrimary,
                    )
                  : Text(
                      '$number',
                      style: AppText.button(color: AppColors.textPrimary),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  label,
                  style: AppText.body(color: Colors.white).copyWith(
                    fontSize: 18,
                    height: 28 / 18,
                    fontWeight: FontWeight.w700,
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
