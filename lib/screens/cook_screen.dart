import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../data/recipes.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_toast.dart';

class CookScreen extends StatefulWidget {
  final String? recipeId;
  const CookScreen({super.key, this.recipeId});

  @override
  State<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends State<CookScreen> {
  String _filter = 'All';

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
    return switch (_filter) {
      'Under 20 min' =>
        recipes.where((recipe) => _minutes(recipe.time) <= 20).toList(),
      'High protein' =>
        recipes.where((recipe) => recipe.protein >= 35).toList(),
      'Gentle' => recipes.where((recipe) => recipe.calories <= 400).toList(),
      _ => recipes,
    };
  }

  int _minutes(String value) => int.tryParse(value.split(' ').first) ?? 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final featured = recipes.first;
    final visible = _visibleRecipes;

    return AppShell(
      scrollTitle: 'Cook',
      scrollEyebrow: 'YOUR KITCHEN',
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
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              child: const HugeIcon(
                                icon: HugeIcons.strokeRoundedChefHat,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'YOUR KITCHEN',
                              style: AppText.eyebrow(color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('What fits tonight?', style: AppText.h1()),
                        const SizedBox(height: 8),
                        Text(
                          'Choose by energy, not aspiration. Every option keeps protein and recovery in view.',
                          style: AppText.bodySm(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: const [
                  'All',
                  'Under 20 min',
                  'High protein',
                  'Gentle',
                ].length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final label = const [
                    'All',
                    'Under 20 min',
                    'High protein',
                    'Gentle',
                  ][index];
                  final selected = _filter == label;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = label),
                    showCheckmark: false,
                    labelStyle: AppText.label(
                      color: selected ? Colors.white : AppColors.primary,
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.card,
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _FeaturedRecipe(
                recipe: featured,
                saved: state.savedRecipeIds.contains(featured.id),
                onTap: () => context.push('/cook/recipe/${featured.id}'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _filter == 'All'
                        ? 'FOR REAL EVENINGS'
                        : _filter.toUpperCase(),
                    style: AppText.eyebrow(color: AppColors.primary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _filter == 'All'
                        ? 'More ways to make dinner work'
                        : '${visible.length} recipes that fit',
                    style: AppText.h2(),
                  ),
                  const SizedBox(height: 4),
                  Text('${visible.length} options', style: AppText.caption()),
                ],
              ),
            ),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Text(
                    'Nothing matches this pace yet. Try another filter.',
                    style: AppText.bodySm(color: AppColors.primary),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (final recipe in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RecipeRow(
                          recipe: recipe,
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
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
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
                            Text('No cooking tonight?', style: AppText.h3()),
                            Text(
                              'Find an order that still fits',
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
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: Container(
        height: 318,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(recipe.image, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.foreground.withValues(alpha: 0.16),
                    AppColors.foreground.withValues(alpha: 0.94),
                  ],
                  stops: const [0.25, 0.52, 1],
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
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'BEST MATCH TONIGHT',
                  style: AppText.eyebrow(color: AppColors.primary),
                ),
              ),
            ),
            if (saved)
              const Positioned(
                right: 16,
                top: 16,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedBookmark02,
                  color: Colors.white,
                ),
              ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title, style: AppText.h2(color: Colors.white)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _HeroMetric(
                        icon: HugeIcons.strokeRoundedClock01,
                        label: recipe.time,
                      ),
                      _HeroMetric(
                        icon: HugeIcons.strokeRoundedFire,
                        label: '${recipe.calories} cal',
                      ),
                      _HeroMetric(
                        icon: HugeIcons.strokeRoundedBodyPartMuscle,
                        label: '${recipe.protein}g',
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
  }
}

class _HeroMetric extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  const _HeroMetric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HugeIcon(icon: icon, size: 14, color: AppColors.accent),
        const SizedBox(width: 5),
        Text(label, style: AppText.caption(color: Colors.white)),
      ],
    );
  }
}

class _RecipeRow extends StatelessWidget {
  final Recipe recipe;
  final bool saved;
  final VoidCallback onTap;
  const _RecipeRow({
    required this.recipe,
    required this.saved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Image.asset(
                recipe.image,
                width: 94,
                height: 94,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: AppText.h3(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${recipe.time} · ${recipe.calories} cal',
                    style: AppText.caption(),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${recipe.protein}g protein',
                          style: AppText.caption(color: AppColors.primary),
                        ),
                      ),
                      if (saved) ...[
                        const SizedBox(width: 8),
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedBookmark02,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
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
          child: Text(
            'This recipe is no longer available.',
            style: AppText.body(),
          ),
        ),
      );
    }
    final state = context.watch<AppState>();
    final saved = state.savedRecipeIds.contains(recipe.id);
    return AppShell(
      header: ScreenHeader(
        eyebrow: 'RECIPE',
        title: recipe.title,
        onBack: () => context.pop(),
        trailing: IconButton(
          onPressed: () {
            state.toggleSavedRecipe(recipe.id);
            showAppToast(
              context,
              saved ? 'Removed from saved recipes' : 'Recipe saved',
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
          onPressed: () {
            state.logItem(
              sourceId: recipe.id,
              type: 'recipe',
              title: recipe.title,
              calories: recipe.calories,
              protein: recipe.protein,
              image: recipe.image,
            );
            showAppToast(
              context,
              'Meal logged',
              description:
                  '${recipe.calories} cal · ${recipe.protein}g protein',
            );
          },
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
          label: const Text('Log this meal'),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.asset(recipe.image, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.title, style: AppText.h1(color: AppColors.primary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DetailMetric(label: 'Time', value: recipe.time),
                    ),
                    Expanded(
                      child: _DetailMetric(
                        label: 'Energy',
                        value: '${recipe.calories} cal',
                      ),
                    ),
                    Expanded(
                      child: _DetailMetric(
                        label: 'Protein',
                        value: '${recipe.protein}g',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'WHAT YOU NEED',
                  style: AppText.eyebrow(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text('Ingredients', style: AppText.h2()),
                const SizedBox(height: 14),
                for (final (index, ingredient) in recipe.ingredients.indexed)
                  _ChecklistRow(
                    label: ingredient,
                    checked: _ingredientsChecked.contains(index),
                    onTap: () => setState(() {
                      _ingredientsChecked.contains(index)
                          ? _ingredientsChecked.remove(index)
                          : _ingredientsChecked.add(index);
                    }),
                  ),
                const SizedBox(height: 28),
                Text(
                  'MAKE IT',
                  style: AppText.eyebrow(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text('Step by step', style: AppText.h2()),
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
                    color: AppColors.mint,
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
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final String label;
  final String value;
  const _DetailMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppText.eyebrow()),
        const SizedBox(height: 4),
        Text(value, style: AppText.numericSm()),
      ],
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
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked ? AppColors.primary : AppColors.borderStrong,
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
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: checked ? AppColors.secondary : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: checked ? AppColors.homeHeroBorder : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: checked
                  ? const HugeIcon(
                      icon: HugeIcons.strokeRoundedTick01,
                      size: 16,
                      color: Colors.white,
                    )
                  : Text(
                      '$number',
                      style: AppText.label(color: AppColors.primary),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppText.bodySm())),
          ],
        ),
      ),
    );
  }
}
