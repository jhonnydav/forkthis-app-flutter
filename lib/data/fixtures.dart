/// Prototype fixture data — ported verbatim from `../app/src/data/fixtures.ts`.
/// Chains are invented and figures are illustrative; the real restaurant list is
/// unconfirmed (PRD Q-16). Keep this file byte-for-byte in sync with the TS source
/// when either changes — there is no shared generation step yet.
library;

enum Goal { lose, gain, maintain }

enum Condition { pcos, glp1, postOp, highProtein, lowCarb }

const Map<Goal, String> goalLabel = {
  Goal.lose: 'Losing weight',
  Goal.gain: 'Building muscle',
  Goal.maintain: 'Maintaining',
};

const Map<Condition, String> conditionLabel = {
  Condition.pcos: 'PCOS-friendly',
  Condition.glp1: 'GLP-1 friendly',
  Condition.postOp: 'Post-op stage 3',
  Condition.highProtein: 'High protein',
  Condition.lowCarb: 'Lower carb',
};

class Restaurant {
  final String id;
  final String name;
  final String mark;
  final String category;
  final int hackCount;
  final double? distanceMi;

  const Restaurant({
    required this.id,
    required this.name,
    required this.mark,
    required this.category,
    required this.hackCount,
    this.distanceMi,
  });
}

class FastHack {
  final String id;
  final String restaurantId;
  final String title;
  final String image;
  final List<String> orderScript;
  final List<String> swaps;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String portionNote;
  final List<Goal> goals;
  final List<Condition> conditions;
  final String why;
  final String? caveat;

  const FastHack({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.image,
    required this.orderScript,
    required this.swaps,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.portionNote,
    required this.goals,
    required this.conditions,
    required this.why,
    this.caveat,
  });
}

const List<Restaurant> restaurants = [
  Restaurant(
    id: 'pollo-perch',
    name: 'Pollo Perch',
    mark: 'PP',
    category: 'Chicken',
    hackCount: 6,
    distanceMi: 0.4,
  ),
  Restaurant(
    id: 'burger-union',
    name: 'Burger Union',
    mark: 'BU',
    category: 'Burgers',
    hackCount: 5,
    distanceMi: 0.9,
  ),
  Restaurant(
    id: 'sub-society',
    name: 'Sub Society',
    mark: 'SS',
    category: 'Sandwiches',
    hackCount: 7,
    distanceMi: 1.2,
  ),
  Restaurant(
    id: 'taco-junction',
    name: 'Taco Junction',
    mark: 'TJ',
    category: 'Mexican',
    hackCount: 4,
    distanceMi: 1.8,
  ),
  Restaurant(
    id: 'bean-barrel',
    name: 'Bean & Barrel',
    mark: 'BB',
    category: 'Coffee',
    hackCount: 5,
    distanceMi: 0.2,
  ),
  Restaurant(
    id: 'noodle-post',
    name: 'Noodle Post',
    mark: 'NP',
    category: 'Asian',
    hackCount: 3,
    distanceMi: 2.4,
  ),
];

/// The "dense" fixture — FR-17 requires the browse to hold up at 10x launch scale.
const List<Restaurant> restaurantsDense = [
  ...restaurants,
  Restaurant(
    id: 'grill-yard',
    name: 'Grill Yard',
    mark: 'GY',
    category: 'Burgers',
    hackCount: 4,
  ),
  Restaurant(
    id: 'wrap-district',
    name: 'Wrap District',
    mark: 'WD',
    category: 'Sandwiches',
    hackCount: 6,
  ),
  Restaurant(
    id: 'salad-society',
    name: 'Salad Society',
    mark: 'SA',
    category: 'Salads',
    hackCount: 8,
  ),
  Restaurant(
    id: 'pita-point',
    name: 'Pita Point',
    mark: 'PT',
    category: 'Mediterranean',
    hackCount: 5,
  ),
  Restaurant(
    id: 'deli-dock',
    name: 'Deli Dock',
    mark: 'DD',
    category: 'Sandwiches',
    hackCount: 4,
  ),
  Restaurant(
    id: 'roast-house',
    name: 'Roast House',
    mark: 'RH',
    category: 'Coffee',
    hackCount: 3,
  ),
  Restaurant(
    id: 'smoothie-stop',
    name: 'Smoothie Stop',
    mark: 'SM',
    category: 'Drinks',
    hackCount: 7,
  ),
  Restaurant(
    id: 'bao-bar',
    name: 'Bao Bar',
    mark: 'BO',
    category: 'Asian',
    hackCount: 3,
  ),
  Restaurant(
    id: 'crust-co',
    name: 'Crust Co.',
    mark: 'CC',
    category: 'Pizza',
    hackCount: 4,
  ),
  Restaurant(
    id: 'fry-street',
    name: 'Fry Street',
    mark: 'FS',
    category: 'Chicken',
    hackCount: 5,
  ),
  Restaurant(
    id: 'green-counter',
    name: 'Green Counter',
    mark: 'GC',
    category: 'Salads',
    hackCount: 6,
  ),
  Restaurant(
    id: 'morning-mile',
    name: 'Morning Mile',
    mark: 'MM',
    category: 'Breakfast',
    hackCount: 5,
  ),
  Restaurant(
    id: 'bowl-block',
    name: 'Bowl Block',
    mark: 'BL',
    category: 'Mexican',
    hackCount: 4,
  ),
  Restaurant(
    id: 'steam-kettle',
    name: 'Steam & Kettle',
    mark: 'SK',
    category: 'Soup',
    hackCount: 3,
  ),
  Restaurant(
    id: 'firebird-kitchen',
    name: 'Firebird Kitchen',
    mark: 'FK',
    category: 'Chicken',
    hackCount: 0,
  ),
  Restaurant(
    id: 'market-bowl',
    name: 'Market Bowl',
    mark: 'MB',
    category: 'Salads',
    hackCount: 0,
  ),
  Restaurant(
    id: 'corner-taco',
    name: 'Corner Taco',
    mark: 'CT',
    category: 'Mexican',
    hackCount: 0,
  ),
  Restaurant(
    id: 'daily-grind',
    name: 'Daily Grind',
    mark: 'DG',
    category: 'Coffee',
    hackCount: 0,
  ),
  Restaurant(
    id: 'olive-pita',
    name: 'Olive & Pita',
    mark: 'OP',
    category: 'Mediterranean',
    hackCount: 0,
  ),
  Restaurant(
    id: 'rice-table',
    name: 'Rice Table',
    mark: 'RT',
    category: 'Asian',
    hackCount: 0,
  ),
  Restaurant(
    id: 'sunrise-counter',
    name: 'Sunrise Counter',
    mark: 'SC',
    category: 'Breakfast',
    hackCount: 0,
  ),
  Restaurant(
    id: 'slice-market',
    name: 'Slice Market',
    mark: 'SL',
    category: 'Pizza',
    hackCount: 0,
  ),
  Restaurant(
    id: 'garden-wrap',
    name: 'Garden Wrap',
    mark: 'GW',
    category: 'Sandwiches',
    hackCount: 0,
  ),
  Restaurant(
    id: 'broth-house',
    name: 'Broth House',
    mark: 'BH',
    category: 'Soup',
    hackCount: 0,
  ),
  Restaurant(
    id: 'blend-room',
    name: 'Blend Room',
    mark: 'BR',
    category: 'Drinks',
    hackCount: 0,
  ),
  Restaurant(
    id: 'stacked-grill',
    name: 'Stacked Grill',
    mark: 'SG',
    category: 'Burgers',
    hackCount: 0,
  ),
];

const List<FastHack> fastHacks = [
  FastHack(
    id: 'pp-kale-strips',
    restaurantId: 'pollo-perch',
    title: 'Kale salad + grilled strips',
    image: 'assets/images/recipe-exemplars/02-grilled-chicken-grain-bowl.jpg',
    orderScript: [
      'Ask for the Side Kale Crunch — no dressing on it yet.',
      'Add a 3-piece Grilled Strips on the side.',
      'Ask for one packet of the honey-hot sauce, not the avocado ranch.',
    ],
    swaps: [
      'Grilled instead of breaded',
      'Honey-hot instead of ranch (saves ~140 cal)',
    ],
    calories: 340,
    protein: 32,
    carbs: 24,
    fat: 13,
    portionNote:
        'About one salad bowl. Roughly a fist of greens, palm of chicken.',
    goals: [Goal.lose, Goal.maintain],
    conditions: [Condition.highProtein, Condition.pcos],
    why:
        'Grilled protein and a raw base keep this filling for the calories. The sauce packet is where most of the sugar hides, so it is the one thing worth swapping.',
  ),
  FastHack(
    id: 'pp-wrap',
    restaurantId: 'pollo-perch',
    title: 'Grilled wrap, sauce on the side',
    image: 'assets/images/recipe-exemplars/04-turkey-avocado-wrap.jpg',
    orderScript: [
      'Order the Grilled Perch Wrap.',
      'Ask for the sauce on the side.',
      'Skip the tortilla chips it comes with.',
    ],
    swaps: ['Sauce on the side — you will use about half'],
    calories: 410,
    protein: 37,
    carbs: 38,
    fat: 12,
    portionNote:
        'One wrap. If you are post-op, half now and half later is normal.',
    goals: [Goal.lose, Goal.gain, Goal.maintain],
    conditions: [Condition.highProtein, Condition.glp1],
    why:
        'Sauce on the side is the single highest-leverage swap on this menu — you get the flavour and skip roughly half the fat.',
    caveat:
        'Wraps vary by location. Check the tortilla size if you are tracking closely.',
  ),
  FastHack(
    id: 'bu-double-no-bun',
    restaurantId: 'burger-union',
    title: 'Double patty, half the bun',
    image: 'assets/images/recipe-exemplars/12-lean-beef-rice-bowl.jpg',
    orderScript: [
      'Order the Union Double.',
      'Ask for no mayo, extra pickles and mustard.',
      'Take the top bun off and eat it open-faced.',
    ],
    swaps: [
      'Mustard instead of mayo (saves ~90 cal)',
      'Open-faced (saves ~80 cal)',
    ],
    calories: 430,
    protein: 34,
    carbs: 22,
    fat: 24,
    portionNote:
        'Roughly two palms of beef. Filling — most people do not need fries with this.',
    goals: [Goal.lose, Goal.gain],
    conditions: [Condition.highProtein, Condition.lowCarb],
    why:
        'Two patties give you the protein that makes a burger actually hold you. Dropping the top bun and the mayo is where the savings are.',
  ),
  FastHack(
    id: 'bb-cold-brew',
    restaurantId: 'bean-barrel',
    title: 'Protein cold brew, unsweetened',
    image: 'assets/images/recipe-exemplars/03-greek-yogurt-berries.jpg',
    orderScript: [
      'Order a large Cold Brew.',
      'Ask for a scoop of the vanilla protein cold foam.',
      'Say "no classic syrup" — it goes in by default.',
    ],
    swaps: ['No classic syrup (saves ~80 cal of sugar)'],
    calories: 150,
    protein: 15,
    carbs: 9,
    fat: 4,
    portionNote: 'One large cup. Counts toward fluids, which matters post-op.',
    goals: [Goal.lose, Goal.maintain],
    conditions: [Condition.pcos, Condition.glp1, Condition.postOp],
    why:
        'The default pour has syrup in it whether you ask or not. Saying "no classic" is the whole hack.',
  ),
  FastHack(
    id: 'ss-turkey-flat',
    restaurantId: 'sub-society',
    title: 'Turkey on flatbread, loaded',
    image: 'assets/images/recipe-exemplars/09-chickpea-cucumber-salad.jpg',
    orderScript: [
      'Six-inch Turkey on flatbread.',
      'Every vegetable they will give you.',
      'Red wine vinegar and pepper, no oil, no mayo.',
    ],
    swaps: [
      'Vinegar instead of oil (saves ~110 cal)',
      'Flatbread instead of Italian herb',
    ],
    calories: 290,
    protein: 24,
    carbs: 34,
    fat: 5,
    portionNote:
        'Half a footlong. A full one is a reasonable dinner if you are building.',
    goals: [Goal.lose, Goal.maintain],
    conditions: [Condition.highProtein, Condition.pcos],
    why:
        'Loading vegetables is free volume. Oil is the highest-calorie thing on the line and nobody notices when it is gone.',
  ),
  FastHack(
    id: 'tj-bowl',
    restaurantId: 'taco-junction',
    title: 'Burrito bowl, double protein',
    image: 'assets/images/recipe-exemplars/08-shrimp-cabbage-tacos.jpg',
    orderScript: [
      'Bowl, not burrito.',
      'Double chicken.',
      'Black beans, fajita veg, pico, lettuce. Skip rice, cheese and sour cream.',
    ],
    swaps: [
      'Bowl instead of tortilla (saves ~300 cal)',
      'Pico instead of queso',
    ],
    calories: 460,
    protein: 48,
    carbs: 31,
    fat: 15,
    portionNote:
        'A full bowl. If you are post-op this is comfortably two meals.',
    goals: [Goal.gain, Goal.lose],
    conditions: [Condition.highProtein, Condition.lowCarb, Condition.glp1],
    why:
        'The tortilla alone is around 300 calories before anything goes in it. Double protein costs a little and changes how long this holds you.',
  ),
];

List<FastHack> hacksByRestaurant(String id) =>
    fastHacks.where((h) => h.restaurantId == id).toList();
Restaurant? restaurantById(String id) =>
    restaurantsDense.where((r) => r.id == id).firstOrNull;
FastHack? hackById(String id) => fastHacks.where((h) => h.id == id).firstOrNull;

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
