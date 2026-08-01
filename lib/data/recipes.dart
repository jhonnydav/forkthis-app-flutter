/// Ported verbatim from `../app/src/data/recipes.ts`.
library;

class Recipe {
  final String id;
  final String title;
  final String time;
  final int calories;
  final int protein;
  final String image;
  final List<String> ingredients;
  final List<String> steps;

  const Recipe({
    required this.id,
    required this.title,
    required this.time,
    required this.calories,
    required this.protein,
    required this.image,
    required this.ingredients,
    required this.steps,
  });
}

const List<Recipe> recipes = [
  Recipe(
    id: 'chicken-sweet-potato',
    title: 'Baked chicken and sweet potato',
    time: '30 min',
    calories: 510,
    protein: 44,
    image: 'assets/images/recipe-exemplars/10-baked-chicken-sweet-potato.jpg',
    ingredients: ['5 oz chicken breast', '1 medium sweet potato', '2 cups green vegetables', '1 tsp olive oil', 'Paprika, garlic, salt and pepper'],
    steps: ['Heat the oven to 425°F.', 'Cube the sweet potato and toss with half the oil and seasoning.', 'Add the chicken and vegetables to the pan, then roast for 22–25 minutes.', 'Rest the chicken for 5 minutes before slicing.'],
  ),
  Recipe(
    id: 'lemon-salmon',
    title: 'Lemon herb salmon',
    time: '25 min',
    calories: 470,
    protein: 39,
    image: 'assets/images/recipe-exemplars/01-lemon-herb-salmon.jpg',
    ingredients: ['5 oz salmon fillet', '2 cups vegetables', '1/2 cup cooked quinoa', 'Lemon, dill and black pepper'],
    steps: ['Heat the oven to 400°F.', 'Season salmon with lemon, dill and pepper.', 'Bake for 12–15 minutes and serve with warm quinoa and vegetables.'],
  ),
  Recipe(
    id: 'lentil-soup',
    title: 'Red lentil soup',
    time: '35 min',
    calories: 360,
    protein: 21,
    image: 'assets/images/recipe-exemplars/05-red-lentil-soup.jpg',
    ingredients: ['1 cup red lentils', '4 cups low-sodium broth', 'Carrot, onion and celery', 'Cumin, turmeric and lemon'],
    steps: ['Soften the vegetables in a large pot.', 'Add lentils, broth and spices.', 'Simmer for 22 minutes, then finish with lemon.'],
  ),
  Recipe(
    id: 'spinach-eggs',
    title: 'Spinach eggs on toast',
    time: '12 min',
    calories: 390,
    protein: 27,
    image: 'assets/images/recipe-exemplars/07-spinach-eggs-toast.jpg',
    ingredients: ['2 eggs plus 2 egg whites', '2 cups spinach', '1 slice whole-grain toast', '1 tbsp feta'],
    steps: ['Wilt the spinach in a skillet.', 'Add the eggs and stir gently until set.', 'Serve over toast with feta and black pepper.'],
  ),
];

Recipe? recipeById(String id) => recipes.where((r) => r.id == id).firstOrNull;

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
