import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_platform/data/order_search.dart';

void main() {
  test('matches coffee intent to the coffee guide', () {
    final results = searchFastHacks('coffee without too much sugar');
    expect(results, isNotEmpty);
    expect(results.first.id, 'bb-cold-brew');
  });

  test('respects a calorie limit', () {
    final results = searchFastHacks('lunch under 400 calories');
    expect(results, isNotEmpty);
    expect(results.every((item) => item.calories <= 400), isTrue);
  });

  test('ranks high-protein orders using real nutrition data', () {
    final results = searchFastHacks('something high protein nearby');
    expect(results, isNotEmpty);
    expect(results.first.protein, greaterThanOrEqualTo(30));
  });

  test('returns an honest empty state for an unknown query', () {
    expect(searchFastHacks('zzzxxyyqq'), isEmpty);
  });
}
