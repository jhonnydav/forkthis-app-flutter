import 'fixtures.dart';

List<FastHack> searchFastHacks(String rawQuery) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) return const [];

  final calorieMatch = RegExp(r'(\d{3,4})\s*(?:cal|calorie)').firstMatch(query);
  final calorieLimit = calorieMatch == null
      ? null
      : int.tryParse(calorieMatch.group(1)!);
  final wantsProtein = query.contains('protein') || query.contains('muscle');
  final wantsCoffee =
      query.contains('coffee') ||
      query.contains('drink') ||
      query.contains('brew');
  final wantsLowerSugar = query.contains('sugar') || query.contains('sweet');
  final broadMealIntent = [
    'lunch',
    'dinner',
    'meal',
    'nearby',
    'grab',
    'order',
    'out',
  ].any(query.contains);
  const ignored = {
    'a',
    'an',
    'and',
    'at',
    'can',
    'for',
    'got',
    'i',
    'im',
    'in',
    'isnt',
    'left',
    'me',
    'my',
    'of',
    'something',
    'that',
    'the',
    'to',
    'what',
    'wont',
  };
  final tokens = query
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .split(RegExp(r'\s+'))
      .where((token) => token.length > 2 && !ignored.contains(token))
      .toSet();

  final scored = <(FastHack, int)>[];
  for (final hack in fastHacks) {
    if (calorieLimit != null && hack.calories > calorieLimit) continue;
    final restaurant = restaurantById(hack.restaurantId);
    if (wantsCoffee && restaurant?.category != 'Coffee') continue;

    final title = hack.title.toLowerCase();
    final restaurantText =
        '${restaurant?.name ?? ''} ${restaurant?.category ?? ''}'.toLowerCase();
    final details = [
      ...hack.orderScript,
      ...hack.swaps,
      ...hack.goals.map((goal) => goalLabel[goal] ?? ''),
      ...hack.conditions.map((condition) => conditionLabel[condition] ?? ''),
      hack.why,
    ].join(' ').toLowerCase();

    var score = 0;
    for (final token in tokens) {
      if (title.contains(token)) score += 4;
      if (restaurantText.contains(token)) score += 3;
      if (details.contains(token)) score += 1;
    }
    if (wantsProtein) score += hack.protein >= 30 ? 4 : 1;
    if (wantsLowerSugar) score += hack.carbs <= 24 ? 3 : 0;
    if (calorieLimit != null) score += 3;
    if (broadMealIntent && restaurant?.category != 'Coffee') score += 1;

    if (score > 0) scored.add((hack, score));
  }

  scored.sort((a, b) {
    final scoreOrder = b.$2.compareTo(a.$2);
    return scoreOrder != 0 ? scoreOrder : b.$1.protein.compareTo(a.$1.protein);
  });
  return scored.map((item) => item.$1).toList();
}
