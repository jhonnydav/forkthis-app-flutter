import 'package:flutter/material.dart';
import '../data/fixtures.dart';
import '../data/recipes.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

/// S-22 — the recipe filter sheet. FR-22 names four axes: goal, meal type, prep
/// time, and dietary/condition tags. All four are here, all multi-select except
/// prep time (a ceiling, so one value is the only sensible shape).
///
/// Empty on every axis means "no constraint" rather than "nothing matches" —
/// the default state of the sheet returns the full list, so a user who opens it
/// out of curiosity and closes it has changed nothing.
@immutable
class RecipeFilters {
  final Set<Goal> goals;
  final Set<String> meals;
  final Set<Condition> conditions;

  /// Maximum prep minutes. `null` is no limit.
  final int? maxMinutes;

  const RecipeFilters({
    this.goals = const {},
    this.meals = const {},
    this.conditions = const {},
    this.maxMinutes,
  });

  bool get isActive =>
      goals.isNotEmpty ||
      meals.isNotEmpty ||
      conditions.isNotEmpty ||
      maxMinutes != null;

  int get activeCount =>
      goals.length +
      meals.length +
      conditions.length +
      (maxMinutes == null ? 0 : 1);

  bool matches(Recipe recipe) {
    if (goals.isNotEmpty && !recipe.goals.any(goals.contains)) return false;
    if (meals.isNotEmpty && !recipe.meals.any(meals.contains)) return false;
    if (conditions.isNotEmpty && !recipe.conditions.any(conditions.contains)) {
      return false;
    }
    if (maxMinutes != null && recipe.minutes > maxMinutes!) return false;
    return true;
  }

  RecipeFilters copyWith({
    Set<Goal>? goals,
    Set<String>? meals,
    Set<Condition>? conditions,
    int? maxMinutes,
    bool clearMinutes = false,
  }) => RecipeFilters(
    goals: goals ?? this.goals,
    meals: meals ?? this.meals,
    conditions: conditions ?? this.conditions,
    maxMinutes: clearMinutes ? null : (maxMinutes ?? this.maxMinutes),
  );
}

const _mealOptions = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
const _timeOptions = {'Under 15 min': 15, 'Under 30 min': 30, 'Under 45 min': 45};

Future<RecipeFilters?> showRecipeFilterSheet(
  BuildContext context,
  RecipeFilters current,
) {
  return showModalBottomSheet<RecipeFilters>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FilterSheet(initial: current),
  );
}

class _FilterSheet extends StatefulWidget {
  final RecipeFilters initial;
  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late RecipeFilters _draft = widget.initial;

  int get _resultCount => recipes.where(_draft.matches).length;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
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
                  Expanded(child: Text('Filter recipes', style: AppText.h2())),
                  if (_draft.isActive)
                    TextButton(
                      onPressed: () =>
                          setState(() => _draft = const RecipeFilters()),
                      child: const Text('Clear all'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),

              _Section(
                title: 'Goal',
                child: Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: Goal.values.map((goal) {
                    final on = _draft.goals.contains(goal);
                    return FilterChip(
                      label: Text(goalLabel[goal]!),
                      selected: on,
                      onSelected: (_) => setState(() {
                        final next = {..._draft.goals};
                        on ? next.remove(goal) : next.add(goal);
                        _draft = _draft.copyWith(goals: next);
                      }),
                    );
                  }).toList(),
                ),
              ),

              _Section(
                title: 'Meal',
                child: Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: _mealOptions.map((meal) {
                    final on = _draft.meals.contains(meal);
                    return FilterChip(
                      label: Text(meal),
                      selected: on,
                      onSelected: (_) => setState(() {
                        final next = {..._draft.meals};
                        on ? next.remove(meal) : next.add(meal);
                        _draft = _draft.copyWith(meals: next);
                      }),
                    );
                  }).toList(),
                ),
              ),

              _Section(
                title: 'Time to cook',
                child: Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: _timeOptions.entries.map((entry) {
                    final on = _draft.maxMinutes == entry.value;
                    return FilterChip(
                      label: Text(entry.key),
                      selected: on,
                      onSelected: (_) => setState(() {
                        _draft = on
                            ? _draft.copyWith(clearMinutes: true)
                            : _draft.copyWith(maxMinutes: entry.value);
                      }),
                    );
                  }).toList(),
                ),
              ),

              _Section(
                title: 'Tags',
                note:
                    'Condition tags come from the content itself — they are not a diagnosis or a recommendation.',
                child: Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: Condition.values.map((condition) {
                    final on = _draft.conditions.contains(condition);
                    return FilterChip(
                      label: Text(conditionLabel[condition]!),
                      selected: on,
                      onSelected: (_) => setState(() {
                        final next = {..._draft.conditions};
                        on ? next.remove(condition) : next.add(condition);
                        _draft = _draft.copyWith(conditions: next);
                      }),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppSpace.sm),
              ElevatedButton(
                // Showing the count here means a filter combination that
                // matches nothing is visible *before* it empties the screen.
                onPressed: () => Navigator.of(context).pop(_draft),
                child: Text(
                  _resultCount == 0
                      ? 'No recipes match — show anyway'
                      : 'Show $_resultCount ${_resultCount == 1 ? 'recipe' : 'recipes'}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? note;
  final Widget child;
  const _Section({required this.title, required this.child, this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.label()),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(note!, style: AppText.caption()),
          ],
          const SizedBox(height: AppSpace.sm),
          child,
        ],
      ),
    );
  }
}
