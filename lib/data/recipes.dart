/// Ported from `../app/src/data/recipes.ts`, then extended with the tag
/// vocabulary FR-22/FR-24 filter on. Tags live on the record rather than being
/// inferred at render time so the filter sheet and the admin content model
/// agree on one source of truth.
library;

import 'fixtures.dart';

class Recipe {
  final String id;
  final String title;
  final String time;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String serving;
  final String image;
  final List<String> ingredients;
  final List<String> steps;

  /// Meal slots this recipe suits. A recipe can belong to several.
  final List<String> meals;

  /// Goals this recipe fits, reusing the same [Goal] vocabulary as fast hacks
  /// so a filter means the same thing in Cook and in Eat Out.
  final List<Goal> goals;

  /// Condition tags (PCOS-friendly, GLP-1-friendly, post-op…). FR-24 requires
  /// the vocabulary to be data, not hardcoded UI.
  final List<Condition> conditions;

  /// Whether the image is real photography. `false` marks the AI-generated
  /// path (FR-25 / S-24), which the detail screen discloses rather than hides.
  final bool photoIsReal;

  const Recipe({
    required this.id,
    required this.title,
    required this.time,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.serving,
    required this.image,
    required this.ingredients,
    required this.steps,
    this.meals = const ['Dinner'],
    this.goals = const [Goal.maintain],
    this.conditions = const [],
    this.photoIsReal = true,
  });

  int get minutes => int.tryParse(time.split(' ').first) ?? 0;
}

const List<Recipe> recipes = [
  Recipe(
    id: 'chicken-sweet-potato',
    title: 'Baked chicken and sweet potato',
    time: '30 min',
    calories: 510,
    protein: 44,
    carbs: 48,
    fat: 16,
    serving: '1 plate',
    image: 'assets/images/recipe-exemplars/10-baked-chicken-sweet-potato.jpg',
    ingredients: [
      '5 oz chicken breast',
      '1 medium sweet potato',
      '2 cups green vegetables',
      '1 tsp olive oil',
      'Paprika, garlic, salt and pepper',
    ],
    steps: [
      'Heat the oven to 425°F.',
      'Cube the sweet potato and toss with half the oil and seasoning.',
      'Add the chicken and vegetables to the pan, then roast for 22–25 minutes.',
      'Rest the chicken for 5 minutes before slicing.',
    ],
    meals: ['Dinner'],
    goals: [Goal.lose, Goal.gain],
    conditions: [Condition.highProtein],
  ),
  Recipe(
    id: 'lemon-salmon',
    title: 'Lemon herb salmon',
    time: '25 min',
    calories: 470,
    protein: 39,
    carbs: 31,
    fat: 21,
    serving: '1 plate',
    image: 'assets/images/recipe-exemplars/01-lemon-herb-salmon.jpg',
    ingredients: [
      '5 oz salmon fillet',
      '2 cups vegetables',
      '1/2 cup cooked quinoa',
      'Lemon, dill and black pepper',
    ],
    steps: [
      'Heat the oven to 400°F.',
      'Season salmon with lemon, dill and pepper.',
      'Bake for 12–15 minutes and serve with warm quinoa and vegetables.',
    ],
    meals: ['Dinner'],
    goals: [Goal.lose, Goal.maintain],
    conditions: [Condition.highProtein, Condition.lowCarb],
  ),
  Recipe(
    id: 'lentil-soup',
    title: 'Red lentil soup',
    time: '35 min',
    calories: 360,
    protein: 21,
    carbs: 52,
    fat: 8,
    serving: '2 cups',
    image: 'assets/images/recipe-exemplars/05-red-lentil-soup.jpg',
    ingredients: [
      '1 cup red lentils',
      '4 cups low-sodium broth',
      'Carrot, onion and celery',
      'Cumin, turmeric and lemon',
    ],
    steps: [
      'Soften the vegetables in a large pot.',
      'Add lentils, broth and spices.',
      'Simmer for 22 minutes, then finish with lemon.',
    ],
    meals: ['Lunch', 'Dinner'],
    goals: [Goal.maintain],
    conditions: [Condition.pcos, Condition.postOp],
    photoIsReal: false,
  ),
  Recipe(
    id: 'spinach-eggs',
    title: 'Spinach eggs on toast',
    time: '12 min',
    calories: 390,
    protein: 27,
    carbs: 29,
    fat: 17,
    serving: '1 plate',
    image: 'assets/images/recipe-exemplars/07-spinach-eggs-toast.jpg',
    ingredients: [
      '2 eggs plus 2 egg whites',
      '2 cups spinach',
      '1 slice whole-grain toast',
      '1 tbsp feta',
    ],
    steps: [
      'Wilt the spinach in a skillet.',
      'Add the eggs and stir gently until set.',
      'Serve over toast with feta and black pepper.',
    ],
    meals: ['Breakfast'],
    goals: [Goal.lose, Goal.maintain],
    conditions: [Condition.glp1, Condition.lowCarb, Condition.postOp],
  ),
];

Recipe? recipeById(String id) => recipes.where((r) => r.id == id).firstOrNull;

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
