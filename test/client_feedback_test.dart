import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_platform/data/fixtures.dart';
import 'package:nutrition_platform/data/recipes.dart';

void main() {
  test('restaurant browse scale fixture covers 30 plus entries', () {
    expect(restaurantsDense.length, greaterThanOrEqualTo(30));
    expect(
      restaurantsDense.map((item) => item.id).toSet(),
      hasLength(restaurantsDense.length),
    );
  });

  test(
    'every restaurant order has complete nutrition and presentation data',
    () {
      for (final hack in fastHacks) {
        expect(hack.restaurantId, isNotEmpty, reason: hack.id);
        expect(restaurantById(hack.restaurantId), isNotNull, reason: hack.id);
        expect(hack.image, isNotEmpty, reason: hack.id);
        expect(hack.orderScript, isNotEmpty, reason: hack.id);
        expect(hack.calories, greaterThan(0), reason: hack.id);
        expect(hack.protein, greaterThan(0), reason: hack.id);
        expect(hack.carbs, greaterThanOrEqualTo(0), reason: hack.id);
        expect(hack.fat, greaterThanOrEqualTo(0), reason: hack.id);
      }
    },
  );

  test('every recipe has a photo, serving, and complete macros', () {
    for (final recipe in recipes) {
      expect(recipe.image, isNotEmpty, reason: recipe.id);
      expect(recipe.serving, isNotEmpty, reason: recipe.id);
      expect(recipe.calories, greaterThan(0), reason: recipe.id);
      expect(recipe.protein, greaterThan(0), reason: recipe.id);
      expect(recipe.carbs, greaterThanOrEqualTo(0), reason: recipe.id);
      expect(recipe.fat, greaterThanOrEqualTo(0), reason: recipe.id);
    }
  });

  test('approved content fixtures avoid shame-based food language', () {
    final content = [
      for (final hack in fastHacks)
        [
          hack.title,
          ...hack.orderScript,
          ...hack.swaps,
          hack.portionNote,
          hack.why,
          ?hack.caveat,
        ].join(' '),
      for (final recipe in recipes)
        [recipe.title, ...recipe.ingredients, ...recipe.steps].join(' '),
    ].join(' ').toLowerCase();

    for (final phrase in [
      'cheat meal',
      'bad food',
      'earn it',
      'burn it off',
      'sinful',
      'clean eating',
      'before/after',
    ]) {
      expect(content, isNot(contains(phrase)), reason: phrase);
    }
  });
}
