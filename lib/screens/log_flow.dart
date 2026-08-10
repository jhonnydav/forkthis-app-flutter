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
import '../widgets/app_toast.dart';
import '../widgets/primitives.dart';
import '../widgets/states.dart';

/// S-27 (pick) and S-28 (confirm portion) — the two screens between "I ate
/// something" and a logged entry. Before this, `/track/log` went straight to a
/// blank manual form, which meant re-typing an order you had already read on a
/// detail screen ten seconds earlier. FR-26 wants a saved or recent item logged
/// in three taps; this is where those three taps live.
///
/// Order of the sections is deliberate and matches how often each is right:
/// recents (you eat the same things), saved (you meant to eat these), then
/// search across everything, then manual as the escape hatch.

class LogPickerScreen extends StatefulWidget {
  const LogPickerScreen({super.key});

  @override
  State<LogPickerScreen> createState() => _LogPickerScreenState();
}

class _LogPickerScreenState extends State<LogPickerScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final query = _query.trim().toLowerCase();
    final searching = query.isNotEmpty;

    final hackResults = searching
        ? fastHacks
              .where(
                (h) =>
                    h.title.toLowerCase().contains(query) ||
                    (restaurantById(h.restaurantId)?.name ?? '')
                        .toLowerCase()
                        .contains(query),
              )
              .toList()
        : <FastHack>[];
    final recipeResults = searching
        ? recipes.where((r) => r.title.toLowerCase().contains(query)).toList()
        : <Recipe>[];

    final recents = state.recentDistinctLogs(limit: 5);
    final savedHacks = state.savedHackIds
        .map(hackById)
        .whereType<FastHack>()
        .toList();
    final savedRecipes = state.savedRecipeIds
        .map(recipeById)
        .whereType<Recipe>()
        .toList();

    return AppShell(
      tabBar: false,
      header: ScreenHeader(
        title: 'Add to today',
        eyebrow: 'TRACK',
        onBack: () => context.go('/track'),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextField(
              controller: _controller,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search orders and recipes',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    size: 20,
                    color: AppColors.mutedForeground,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
                suffixIcon: searching
                    ? IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          size: 18,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppSpace.xl),

            if (searching) ...[
              if (hackResults.isEmpty && recipeResults.isEmpty)
                StateSurface.noResults(
                  title: 'No match for that',
                  body:
                      'Try a restaurant name or a dish. If it is something you made or bought elsewhere, add it by hand — that counts the same.',
                  primaryLabel: 'Add it by hand',
                  onPrimary: () => context.go('/track/log'),
                  secondaryLabel: 'Clear search',
                  onSecondary: () {
                    _controller.clear();
                    setState(() => _query = '');
                  },
                )
              else ...[
                if (hackResults.isNotEmpty) ...[
                  _Label('RESTAURANT ORDERS'),
                  for (final hack in hackResults.take(8))
                    _PickRow.hack(context, hack),
                ],
                if (recipeResults.isNotEmpty) ...[
                  if (hackResults.isNotEmpty)
                    const SizedBox(height: AppSpace.lg),
                  _Label('RECIPES'),
                  for (final recipe in recipeResults.take(8))
                    _PickRow.recipe(context, recipe),
                ],
              ],
            ] else ...[
              if (recents.isNotEmpty) ...[
                _Label('LOG AGAIN'),
                for (final item in recents)
                  _PickRow(
                    image: item.image,
                    title: item.title,
                    subtitle: '${item.calories} cal · ${item.protein}g protein',
                    onTap: () => openPortionSheet(
                      context,
                      title: item.title,
                      image: item.image,
                      calories: item.calories,
                      protein: item.protein,
                      sourceId: item.sourceId,
                      type: item.type,
                    ),
                  ),
                const SizedBox(height: AppSpace.lg),
              ],
              if (savedHacks.isNotEmpty || savedRecipes.isNotEmpty) ...[
                _Label('FROM YOUR SAVED'),
                for (final hack in savedHacks.take(4))
                  _PickRow.hack(context, hack),
                for (final recipe in savedRecipes.take(4))
                  _PickRow.recipe(context, recipe),
                const SizedBox(height: AppSpace.lg),
              ],
              if (recents.isEmpty && savedHacks.isEmpty && savedRecipes.isEmpty)
                StateSurface.empty(
                  icon: HugeIcons.strokeRoundedNotebook01,
                  title: 'Nothing to reuse yet',
                  body:
                      'Once you have logged or saved a few things, they show up here so a repeat meal is two taps. Until then, search or add one by hand.',
                  primaryLabel: 'Browse Eat Out',
                  onPrimary: () => context.go('/eat-out'),
                  secondaryLabel: 'Add by hand',
                  onSecondary: () => context.go('/track/log'),
                )
              else
                Container(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ate something that is not here?',
                          style: AppText.bodySm(),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/track/log'),
                        child: const Text('Add by hand'),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: AppSpace.xl),
            const DisclaimerNote(),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: AppText.eyebrow(color: AppColors.primary)),
  );
}

class _PickRow extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickRow({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  factory _PickRow.hack(BuildContext context, FastHack hack) => _PickRow(
    image: hack.image,
    title: hack.title,
    subtitle:
        '${restaurantById(hack.restaurantId)?.name ?? 'Restaurant'} · ${hack.calories} cal · ${hack.protein}g protein',
    onTap: () => openPortionSheet(
      context,
      title: hack.title,
      image: hack.image,
      calories: hack.calories,
      protein: hack.protein,
      sourceId: hack.id,
      type: 'order',
    ),
  );

  factory _PickRow.recipe(BuildContext context, Recipe recipe) => _PickRow(
    image: recipe.image,
    title: recipe.title,
    subtitle:
        '${recipe.time} · ${recipe.calories} cal · ${recipe.protein}g protein',
    onTap: () => openPortionSheet(
      context,
      title: recipe.title,
      image: recipe.image,
      calories: recipe.calories,
      protein: recipe.protein,
      sourceId: recipe.id,
      type: 'recipe',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
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
                  image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.h3(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: AppText.caption()),
                  ],
                ),
              ),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedAddCircle,
                size: 22,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// S-28 — confirm the portion. Portion is a first-class field, not a footnote:
/// PRD §3/U-4 is explicit that a post-bariatric user whose capacity is 4–6oz
/// finds a calories-only log meaningless. Choosing "half" here rescales the
/// numbers rather than logging a full serving and hoping the user remembers.
Future<void> openPortionSheet(
  BuildContext context, {
  required String title,
  required String image,
  required int calories,
  required int protein,
  required String sourceId,
  required String type,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _PortionSheet(
      title: title,
      image: image,
      calories: calories,
      protein: protein,
      sourceId: sourceId,
      type: type,
    ),
  );
}

const _portions = <String, double>{
  'A few bites': 0.25,
  'Half': 0.5,
  'Most of it': 0.75,
  '1 serving': 1,
  'Second helping': 2,
};

class _PortionSheet extends StatefulWidget {
  final String title;
  final String image;
  final int calories;
  final int protein;
  final String sourceId;
  final String type;

  const _PortionSheet({
    required this.title,
    required this.image,
    required this.calories,
    required this.protein,
    required this.sourceId,
    required this.type,
  });

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  String _portion = '1 serving';
  late String _meal = _mealForNow();

  static String _mealForNow() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Breakfast';
    if (hour < 15) return 'Lunch';
    if (hour < 21) return 'Dinner';
    return 'Snack';
  }

  double get _factor => _portions[_portion] ?? 1;
  int get _calories => (widget.calories * _factor).round();
  int get _protein => (widget.protein * _factor).round();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Image.asset(
                        widget.image,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppText.h3(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xl),
                Text('How much of it?', style: AppText.label()),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: _portions.keys
                      .map(
                        (option) => ChoiceChip(
                          label: Text(option),
                          selected: _portion == option,
                          onSelected: (_) => setState(() => _portion = option),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpace.lg),
                Text('Which meal?', style: AppText.label()),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: const ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                      .map(
                        (option) => ChoiceChip(
                          label: Text(option),
                          selected: _meal == option,
                          onSelected: (_) => setState(() => _meal = option),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpace.xl),
                NutritionRow(
                  calories: _calories,
                  protein: _protein,
                  portionNote: _portion == '1 serving'
                      ? null
                      : 'Adjusted for $_portion.',
                ),
                const SizedBox(height: AppSpace.xl),
                ElevatedButton(
                  onPressed: () {
                    context.read<AppState>().logItem(
                      sourceId: widget.sourceId,
                      type: widget.type,
                      title: widget.title,
                      calories: _calories,
                      protein: _protein,
                      image: widget.image,
                      meal: _meal,
                      portion: _portion,
                    );
                    Navigator.of(context).pop();
                    context.go('/track');
                    showAppToast(
                      context,
                      'Added to $_meal',
                      description:
                          '+10 momentum points · $_calories cal · ${_protein}g protein',
                    );
                  },
                  child: const Text('Add to today'),
                ),
                const SizedBox(height: AppSpace.md),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
