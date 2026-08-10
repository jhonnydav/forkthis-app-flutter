import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../data/fixtures.dart';
import '../data/order_search.dart';
import '../data/recipes.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/primitives.dart';

/// S-39 … S-43. The assistant is the one surface where a wrong answer is an
/// existential risk (PRD §9: Dr. Michaels' licence), so its *limits* are the
/// designed part, not an afterthought:
///
/// * S-39 opening — states scope before the first question. App Flow §3.5:
///   doing this well means most boundary responses never need to fire, which
///   is what makes the limits read as intentional rather than broken (FR-35).
/// * S-40 conversation — grounded answers always carry a route into the actual
///   content they came from. An answer with no way to act on it is a dead end.
/// * S-41 out-of-corpus — a designed state offering what it *can* do, never an
///   error toast and never an apology spiral.
/// * S-42 medical refusal — the zero-tolerance path (FR-34). Fires on symptom,
///   dosing, diagnosis, and post-op medical questions, and always offers the
///   "talk to your provider" route.
/// * S-43 progress check-in — answers over the user's own tracked data.
///
/// Retrieval is over the on-device fixture corpus only (A-8: no open-web
/// fallback). If nothing matches, that is S-41, not an invented answer.

enum _Kind { user, grounded, boundary, medical, progress }

class _Turn {
  final _Kind kind;
  final String text;
  final List<FastHack> hacks;
  final List<Recipe> recipes;

  /// Overrides the kind's default heading. Two boundary turns share a kind but
  /// say different things, and the heading is most of what the user reads.
  final String? title;

  const _Turn(
    this.kind,
    this.text, {
    this.hacks = const [],
    this.recipes = const [],
    this.title,
  });
}

/// Words that mean the question is medical. Matched on **word boundaries**, not
/// as substrings: this is a food app, and a naive `contains` refuses to discuss
/// "pain au chocolat" and "blood orange" (both real menu items) as though they
/// were symptoms. A false refusal is not a safe failure — it teaches the user
/// that the boundary is broken rather than deliberate (FR-35), which makes the
/// real refusals easier to dismiss.
const _medicalWords = {
  'dose',
  'doses',
  'dosage',
  'medication',
  'medications',
  'medicine',
  'meds',
  'prescription',
  'ozempic',
  'wegovy',
  'mounjaro',
  'symptom',
  'symptoms',
  'diagnosis',
  'diagnose',
  'diagnosed',
  'bleeding',
  'infection',
  'infected',
  'vomiting',
  'nauseous',
  'nausea',
  'stitches',
  'incision',
  'complication',
  'complications',
  'dizzy',
  'dizziness',
  'fever',
  'cramping',
};

/// Multi-word medical intents — phrases that ask the app to exercise clinical
/// judgement. Matched as phrases, so "is it safe to" fires but "safe" alone
/// does not.
///
/// Deliberately absent: "post-op", "after my surgery", and similar. Those are
/// how PRD §3's U-4 audience *describes themselves*, not medical questions —
/// "I'm post-op, what can I order?" is a food question from the exact person
/// the portion guidance was built for. Refusing it would refuse the user the
/// product exists to serve. The genuinely medical post-op cases are caught by
/// [_medicalWords] instead (incision, bleeding, vomiting, complication…).
const _medicalPhrases = [
  'is it safe',
  'should i take',
  'should i stop',
  'is it normal',
  'my surgeon said',
  'my doctor said',
  'what does my',
];

/// Terms that contain a medical word but are food. Checked first.
const _foodExceptions = ['blood orange', 'pain au chocolat', 'pain perdu'];

bool _isMedical(String lowercased) {
  var q = lowercased;
  for (final food in _foodExceptions) {
    q = q.replaceAll(food, ' ');
  }
  if (_medicalPhrases.any(q.contains)) return true;
  final words = q.split(RegExp(r"[^a-z']+")).where((w) => w.isNotEmpty);
  return words.any(_medicalWords.contains);
}

/// Words that mark a question as being about food at all. Retrieval is gated on
/// this because the underlying search scores loose substring hits: "who won the
/// game last night" matched a hack whose copy contained "tonight", so a plainly
/// out-of-corpus question came back with lunch suggestions.
///
/// FR-33 requires out-of-corpus questions to reach the boundary state. Without a
/// gate the boundary almost never fires, and a bounded assistant that answers
/// everything is indistinguishable from an unbounded one.
const _foodSignals = {
  'eat', 'eating', 'ate', 'food', 'meal', 'meals', 'lunch', 'dinner',
  'breakfast', 'snack', 'order', 'ordering', 'restaurant', 'restaurants',
  'menu', 'takeout', 'takeaway', 'drive', 'coffee', 'drink', 'protein',
  'calories', 'calorie', 'carbs', 'macros', 'recipe', 'recipes', 'cook',
  'cooking', 'make', 'dish', 'hungry', 'craving', 'portion', 'grab',
  'nearby', 'close', 'healthy', 'swap', 'swaps', 'salad', 'chicken',
  'wrap', 'bowl', 'sandwich', 'burger', 'fries', 'smoothie', 'shake',
  'vegetarian', 'sugar', 'low', 'high', 'quick', 'fast', 'tonight',
  // Every preference the app advertises in Settings must clear this gate —
  // the assistant must not be narrower than the product it speaks for.
  'gluten', 'sodium', 'dairy', 'vegan', 'carb', 'free', 'option', 'options',
  'size', 'sizes', 'serving', 'servings', 'light', 'lighter',
};

bool _looksFoodRelated(String lowercased, Iterable<String> extraTerms) {
  final words = lowercased
      .split(RegExp(r"[^a-z0-9']+"))
      .where((w) => w.isNotEmpty)
      .toSet();
  if (words.any(_foodSignals.contains)) return true;
  // A named restaurant or dish counts even when no generic food word appears.
  return extraTerms.any(
    (term) => term
        .split(RegExp(r'\s+'))
        .any((t) => t.length > 3 && words.contains(t)),
  );
}

const _openers = [
  'What can I order that is high in protein?',
  'Something quick I can cook tonight',
  'How am I doing this week?',
  'What should I get at a coffee place?',
];

/// The assistant as a full route (`/ask`), for deep links and for the entries
/// inside the You tab. The conversation itself lives in [AssistantView] so the
/// sheet and the page cannot drift apart.
class AssistantScreen extends StatelessWidget {
  final String? seedQuestion;
  const AssistantScreen({super.key, this.seedQuestion});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      tabBar: false,
      header: ScreenHeader(
        title: 'Ask',
        eyebrow: 'HELP',
        onBack: () => context.go('/you'),
      ),
      child: SafeArea(
        bottom: false,
        child: AssistantView(seedQuestion: seedQuestion),
      ),
    );
  }
}

/// App Flow §1.3 — "Opens as a sheet on mobile". The assistant is deliberately
/// *not* a fifth tab: making it one would overclaim a capability that is bounded
/// to approved content (FR-33). A sheet keeps the user where they were, which
/// matters when the question is about the screen behind it.
Future<void> showAssistantSheet(BuildContext context, {String? seedQuestion}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.92,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASK',
                        style: AppText.eyebrow(color: AppColors.primary),
                      ),
                      Text('Food, orders, recipes', style: AppText.h3()),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  // The sheet's own context, not the caller's — popping the
                  // caller's route would close the wrong thing if anything is
                  // ever pushed above the sheet.
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: AssistantView(seedQuestion: seedQuestion)),
        ],
      ),
    ),
  );
}

class AssistantView extends StatefulWidget {
  /// Pre-fills and immediately asks, so "Ask about this order" arrives with the
  /// question already posed rather than an empty box and a blinking cursor.
  final String? seedQuestion;

  const AssistantView({super.key, this.seedQuestion});

  @override
  State<AssistantView> createState() => _AssistantViewState();
}

class _AssistantViewState extends State<AssistantView> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Turn> _turns = [];
  bool _thinking = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.seedQuestion;
    if (seed != null && seed.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ask(seed);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            children: [
              if (_turns.isEmpty && !_thinking)
                _opening()
              else ...[
                for (final turn in _turns) _bubble(turn),
                if (_thinking)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Looking through the guides…',
                      style: AppText.caption(),
                    ),
                  ),
              ],
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (_turns.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(_turns.clear),
                    child: const Text('Clear'),
                  ),
                Expanded(
                  child: _Composer(
                    controller: _controller,
                    enabled: !_thinking,
                    onSubmit: _ask,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// S-39 — scope stated up front, in plain terms, before anything is asked.
  Widget _opening() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ask about food, not medicine', style: AppText.h1()),
        const SizedBox(height: AppSpace.md),
        Text(
          'This answers only from the restaurant orders, recipes, and guidance inside this app. It does not search the web and does not know anything about your medical care.',
          style: AppText.body(color: AppColors.mutedForeground),
        ),
        const SizedBox(height: AppSpace.xxl),
        _ScopeCard(
          tone: AppColors.mint,
          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
          title: 'It can help with',
          lines: const [
            'What to order at a place we cover',
            'Recipes that fit your goal or your evening',
            'How your week has been going, from what you logged',
            'How a part of the app works',
          ],
        ),
        const SizedBox(height: AppSpace.md),
        _ScopeCard(
          tone: AppColors.coralSurface,
          icon: HugeIcons.strokeRoundedAlert02,
          title: 'It will not answer',
          lines: const [
            'Symptoms, pain, or anything that feels wrong',
            'Medication, dosing, or whether something is safe for you',
            'Diagnoses, or what your results mean',
            'Post-operative instructions from your surgeon',
          ],
        ),
        const SizedBox(height: AppSpace.xxl),
        Text(
          'TRY ONE OF THESE',
          style: AppText.eyebrow(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpace.md),
        for (final opener in _openers)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: InkWell(
              onTap: () => _ask(opener),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpace.lg),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(opener, style: AppText.bodySm())),
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpace.lg),
        const DisclaimerNote(),
      ],
    );
  }

  Widget _bubble(_Turn turn) {
    if (turn.kind == _Kind.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpace.md, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.action,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
          ),
          child: Text(
            turn.text,
            style: AppText.bodySm(color: AppColors.actionForeground),
          ),
        ),
      );
    }

    final (bg, defaultTitle, icon) = switch (turn.kind) {
      _Kind.medical => (
        AppColors.coralSurface,
        'This one is for your care team',
        HugeIcons.strokeRoundedStethoscope,
      ),
      _Kind.boundary => (
        AppColors.warmSurface,
        'Outside what I hold',
        HugeIcons.strokeRoundedInformationCircle,
      ),
      _Kind.progress => (
        AppColors.mint,
        'Your week so far',
        HugeIcons.strokeRoundedChartLineData01,
      ),
      _ => (AppColors.card, '', HugeIcons.strokeRoundedSparkles),
    };
    final title = turn.title ?? defaultTitle;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.lg, right: 24),
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Row(
              children: [
                HugeIcon(icon: icon, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Text(title, style: AppText.h3())),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
          ],
          Text(turn.text, style: AppText.bodySm()),

          // Every answer ends somewhere the user can act. A boundary that
          // leaves you staring at a wall is the failure FR-35 describes.
          if (turn.hacks.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            for (final hack in turn.hacks.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: FastHackCard(
                  hack: hack,
                  restaurant: restaurantById(hack.restaurantId),
                ),
              ),
          ],
          if (turn.recipes.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            for (final recipe in turn.recipes.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: OutlinedButton(
                  onPressed: () => context.push('/cook/recipe/${recipe.id}'),
                  child: Text('Open ${recipe.title}'),
                ),
              ),
          ],
          if (turn.kind == _Kind.medical) ...[
            const SizedBox(height: AppSpace.lg),
            OutlinedButton.icon(
              onPressed: () => context.go('/help'),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedHelpCircle,
                size: 18,
                color: AppColors.primary,
              ),
              label: const Text('When to contact your care team'),
            ),
          ],
          if (turn.kind == _Kind.boundary) ...[
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/eat-out'),
                    child: const Text('Eat Out'),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/cook'),
                    child: const Text('Cook'),
                  ),
                ),
              ],
            ),
          ],
          if (turn.kind == _Kind.progress) ...[
            const SizedBox(height: AppSpace.lg),
            OutlinedButton(
              onPressed: () => context.go('/track/history'),
              child: const Text('Open history'),
            ),
          ],
        ],
      ),
    );
  }

  void _ask(String raw) {
    final question = raw.trim();
    if (question.isEmpty) return;
    _controller.clear();
    setState(() {
      _turns.add(_Turn(_Kind.user, question));
      _thinking = true;
    });

    // A beat, so an answer reads as considered rather than pre-baked. Real
    // retrieval would stream here (NFR-6: first token ≤1.5s).
    Future.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _turns.add(_answerFor(question));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
        }
      });
    });
  }

  _Turn _answerFor(String question) {
    final q = question.toLowerCase();

    // S-42 first, always. Anything that smells medical is refused before any
    // retrieval runs — a match here can never be overridden by a food match.
    if (_isMedical(q)) {
      return const _Turn(
        _Kind.medical,
        'I can\'t help with symptoms, medication, dosing, or anything about your recovery or diagnosis — not because of a rule I am working around, but because getting it wrong matters too much. Your surgeon or care team can answer this properly, and it is worth asking them today rather than waiting.',
      );
    }

    // S-43 — over the user's own logged data.
    if (q.contains('how am i') ||
        q.contains('this week') ||
        q.contains('my progress') ||
        q.contains('how have i')) {
      final state = context.read<AppState>();
      final since = DateTime.now().subtract(const Duration(days: 7));
      final week = state.logs.where((l) => l.loggedAt.isAfter(since)).toList();
      if (week.isEmpty) {
        return const _Turn(
          _Kind.progress,
          'Nothing logged in the last week, so there is not much for me to read yet — and that is genuinely fine. When you log a few things, I can tell you what your days have looked like. There is no catching up to do first.',
        );
      }
      final days = week.map((l) => l.loggedAt.day).toSet().length;
      final protein = week.fold<int>(0, (sum, l) => sum + l.protein);
      final avgProtein = (protein / days).round();
      return _Turn(
        _Kind.progress,
        'You logged ${week.length} ${week.length == 1 ? 'item' : 'items'} across $days ${days == 1 ? 'day' : 'days'} this week, averaging about ${avgProtein}g of protein on the days you tracked. That is a record, not a grade — the days you did not log are not missing data, they are just days.',
      );
    }

    // S-40 — grounded retrieval over the on-device corpus, but only once the
    // question looks like it is about food at all.
    final corpusTerms = [
      for (final h in fastHacks) h.title.toLowerCase(),
      for (final r in restaurants) r.name.toLowerCase(),
      for (final r in recipes) r.title.toLowerCase(),
    ];
    final foodRelated = _looksFoodRelated(q, corpusTerms);
    if (!foodRelated &&
        !q.contains('track') &&
        !q.contains('log') &&
        !q.contains('how do i')) {
      return _offTopic;
    }

    final hackHits = searchFastHacks(question);
    final recipeHits = recipes.where((r) {
      final hay = '${r.title} ${r.ingredients.join(' ')} ${r.meals.join(' ')}'
          .toLowerCase();
      if (q.contains('protein') && r.protein >= 30) return true;
      if ((q.contains('quick') ||
              q.contains('fast') ||
              q.contains('tonight')) &&
          r.minutes <= 30) {
        return true;
      }
      return q
          .split(RegExp(r'[^a-z0-9]+'))
          .where((t) => t.length > 3)
          .any(hay.contains);
    }).toList();

    if (hackHits.isNotEmpty || recipeHits.isNotEmpty) {
      final parts = <String>[];
      if (hackHits.isNotEmpty) {
        parts.add(
          'There are ${hackHits.length} restaurant ${hackHits.length == 1 ? 'order' : 'orders'} in the guides that fit',
        );
      }
      if (recipeHits.isNotEmpty) {
        parts.add(
          '${recipeHits.length} ${recipeHits.length == 1 ? 'recipe' : 'recipes'} you could cook',
        );
      }
      return _Turn(
        _Kind.grounded,
        '${parts.join(' and ')}. Here are the closest ones — each shows the order script or the steps, plus what it comes to.',
        hacks: hackHits,
        recipes: recipeHits,
      );
    }

    if (q.contains('track') || q.contains('log') || q.contains('how do i')) {
      return const _Turn(
        _Kind.grounded,
        'Track is a light record, not a scoreboard. Add something from the plus button, pick how much of it you actually ate, and earn momentum for useful actions. Missing days costs you nothing.',
      );
    }

    // S-41, second shape. The question was about food and we understood it —
    // the corpus simply has nothing matching. Saying "that is outside what I
    // hold" here would be a lie about comprehension, and it teaches the user the
    // assistant is dumber than it is. Say what is actually true instead.
    if (foodRelated) return _nothingMatching;

    return _offTopic;
  }
}

/// S-41a — the question was not about food. The limit is the *topic*.
const _offTopic = _Turn(
  _Kind.boundary,
  'That is outside what I hold. I only know the restaurant orders, recipes, and guidance inside this app — I do not search the web, so I would rather say so than guess. If you tell me what you are in the mood for, or where you are eating, I can probably help with that.',
);

/// S-41b — the question was about food and understood; the corpus has no match.
/// A different sentence, because a different thing is true.
const _nothingMatching = _Turn(
  _Kind.boundary,
  'I understood that one — there is just nothing matching it in the guides yet. More restaurants and recipes are being added. Browsing directly is often faster than rephrasing, so here are the two places to look.',
  title: 'Nothing matching yet',
);

class _ScopeCard extends StatelessWidget {
  final Color tone;
  final List<List<dynamic>> icon;
  final String title;
  final List<String> lines;

  const _ScopeCard({
    required this.tone,
    required this.icon,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HugeIcon(icon: icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpace.sm),
              // Expanded, not bare: at 200% text scaling (NFR-2) the title
              // wraps rather than overflowing the card.
              Expanded(child: Text(title, style: AppText.h3())),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('·  ', style: AppText.bodySm()),
                  Expanded(child: Text(line, style: AppText.bodySm())),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSubmit;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.send,
            onSubmitted: onSubmit,
            decoration: const InputDecoration(
              hintText: 'Ask about food, orders, or recipes',
            ),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        SizedBox(
          width: 52,
          height: 52,
          child: ElevatedButton(
            onPressed: enabled ? () => onSubmit(controller.text) : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(52, 52),
              shape: const CircleBorder(),
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedSent,
              size: 20,
              color: AppColors.actionForeground,
            ),
          ),
        ),
      ],
    );
  }
}
