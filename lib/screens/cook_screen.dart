import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/recipes.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_toast.dart';
import '../widgets/product_sheet.dart';

/// Ported from the `CookScreen`/`RecipeDrawer` in `../app/src/screens/NotBuilt.tsx`
/// (S-21–S-24 — recipe browse and detail).
class CookScreen extends StatefulWidget {
  final String? recipeId;
  const CookScreen({super.key, this.recipeId});

  @override
  State<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends State<CookScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.recipeId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openRecipe(context, widget.recipeId!),
      );
    }
  }

  void _openRecipe(BuildContext context, String id) {
    final recipe = recipeById(id);
    if (recipe == null) return;
    final state = context.read<AppState>();
    showProductSheet(
      context,
      title: recipe.title,
      description:
          '${recipe.time} · ${recipe.calories} calories · ${recipe.protein}g protein',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.asset(recipe.image, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHAT YOU NEED',
                  style: AppText.eyebrow(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                for (final item in recipe.ingredients)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 8, right: 12),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(child: Text(item, style: AppText.bodySm())),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'MAKE IT',
                  style: AppText.eyebrow(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                for (final (index, step) in recipe.steps.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(step, style: AppText.bodySm()),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Text(
                    'Nutrition is an estimate. Adjust portions for your goals and clinical guidance.',
                    style: AppText.caption(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      footer: Builder(
        builder: (sheetContext) {
          final saved = state.savedRecipeIds.contains(recipe.id);
          return Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      state.toggleSavedRecipe(recipe.id);
                      showAppToast(
                        context,
                        saved ? 'Removed from saved recipes' : 'Recipe saved',
                      );
                    },
                    icon: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                    ),
                    label: Text(saved ? 'Saved' : 'Save'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
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
                      showAppToast(context, 'Recipe logged to today');
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Log meal'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      if (widget.recipeId != null && context.mounted) context.go('/cook');
    });
  }

  @override
  Widget build(BuildContext context) {
    final featured = recipes.first;
    final rest = recipes.skip(1).toList();
    return AppShell(
      child: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AT HOME',
                    style: AppText.eyebrow(color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text('Cook something that fits', style: AppText.h1()),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(
                      'Simple meals built around protein, fiber, and the time you actually have.',
                      style: AppText.bodySm(color: AppColors.mutedForeground),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => _openRecipe(context, featured.id),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 288),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.foreground,
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(featured.image, fit: BoxFit.cover),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.foreground.withValues(alpha: 0.95),
                              AppColors.foreground.withValues(alpha: 0.18),
                              Colors.transparent,
                            ],
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
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "TONIGHT'S EASY WIN",
                                  style: AppText.eyebrow(color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              featured.title,
                              style: AppText.h2(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'One pan · ${featured.time} · High protein',
                              style: AppText.bodySm(
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Open recipe',
                                  style: AppText.label(color: Colors.white),
                                ),
                                const SizedBox(width: 8),
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
                    ],
                  ),
                ),
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
                          'MAKE IT YOURS',
                          style: AppText.eyebrow(color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text('Choose by mood', style: AppText.h2()),
                      ],
                    ),
                  ),
                  Text('Swipe', style: AppText.caption()),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: rest.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final recipe = rest[index];
                  return GestureDetector(
                    onTap: () => _openRecipe(context, recipe.id),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.58,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Image.asset(
                                recipe.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            recipe.title,
                            style: AppText.h3(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(recipe.time, style: AppText.caption()),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: InkWell(
                onTap: () => context.go('/eat-out'),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.mint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.soup_kitchen_rounded,
                        color: AppColors.mintForeground,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.mutedForeground,
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
