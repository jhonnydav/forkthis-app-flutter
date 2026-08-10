import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_toast.dart';
import '../widgets/figma_components.dart';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// Restyled against Figma node 321:849 ("3.2 Track – History"),
/// `figma.com/design/LjDp489aFZaYiDx88MvvkQ`, pulled 2026-08-06: a 7-day
/// letter/date grid (current week, Monday-first, dot marks a logged day),
/// a "Selected day" header with prev/next arrows, two big stat cards, then
/// the meal list.
class TrackHistoryScreen extends StatefulWidget {
  const TrackHistoryScreen({super.key});

  @override
  State<TrackHistoryScreen> createState() => _TrackHistoryScreenState();
}

class _TrackHistoryScreenState extends State<TrackHistoryScreen> {
  late DateTime _selected = DateTime.now();

  static String _sourceLabel(String type) => switch (type) {
    'order' => 'Restaurant order',
    'recipe' => 'Home-cooked recipe',
    _ => 'Meal',
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final week = List.generate(7, (i) => monday.add(Duration(days: i)));

    final items = state.logs
        .where((item) => _sameDay(item.loggedAt, _selected))
        .toList();
    final calories = items.fold<int>(0, (sum, item) => sum + item.calories);
    final protein = items.fold<int>(0, (sum, item) => sum + item.protein);
    final canGoNext = _selected.isBefore(
      DateTime(today.year, today.month, today.day),
    );

    return AppShell(
      header: ScreenHeader(
        title: 'History',
        onBack: () => context.go('/track'),
        trailing: IconButton(
          onPressed: () => context.go('/track/add'),
          tooltip: 'Log a meal',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 32),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR WEEK', style: AppText.kicker()),
                const SizedBox(height: 8),
                Text(
                  'Look back without keeping score.',
                  style: AppText.h1(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a day to review what helped. Empty days are simply empty days.',
                  style: AppText.bodySm(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.banner),
              ),
              child: Row(
                children: [
                  for (final day in week)
                    Expanded(
                      child: _WeekDayCell(
                        letter: _weekdayLetters[day.weekday - 1],
                        date: day.day,
                        selected: _sameDay(day, _selected),
                        hasLogs: state.logs.any(
                          (l) => _sameDay(l.loggedAt, day),
                        ),
                        onTap: day.isAfter(today)
                            ? null
                            : () => setState(() => _selected = day),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SELECTED DAY', style: AppText.kicker()),
                      const SizedBox(height: 4),
                      Text(_dayLabel(_selected, today), style: AppText.h1()),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous day',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.background,
                      ),
                      onPressed: () => setState(
                        () => _selected = _selected.subtract(
                          const Duration(days: 1),
                        ),
                      ),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Opacity(
                      opacity: canGoNext ? 1 : 0.35,
                      child: IconButton(
                        tooltip: 'Next day',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.background,
                        ),
                        onPressed: canGoNext
                            ? () => setState(
                                () => _selected = _selected.add(
                                  const Duration(days: 1),
                                ),
                              )
                            : null,
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            // IntrinsicHeight rather than CrossAxisAlignment.stretch — inside
            // a ListView item the Row has no bounded height to stretch to,
            // which throws (not just overflows). IntrinsicHeight gives it one
            // so both cards still match the taller card's height.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _BigStat(
                      eyebrow: 'Energy',
                      value: '$calories',
                      label: 'calories logged',
                      background: AppColors.primary,
                      foreground: AppColors.highlight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BigStat(
                      eyebrow: 'Protein',
                      value: '${protein}g',
                      label:
                          'across ${items.length} ${items.length == 1 ? 'item' : 'items'}',
                      background: AppColors.accent,
                      foreground: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: items.isEmpty
                ? _EmptyHistory(onAdd: () => context.go('/track/add'))
                : Column(
                    children: [
                      for (final item in items)
                        ThumbActionRow(
                          image: item.image,
                          title: item.title,
                          subtitle:
                              '${_sourceLabel(item.type)} · ${item.calories} cal · ${item.protein}g protein',
                          onAction: () {
                            state.removeLog(item.id);
                            showAppToast(context, 'Removed from history');
                          },
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime day, DateTime today) {
    if (_sameDay(day, today)) return 'Today';
    if (_sameDay(day, today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[day.month - 1]} ${day.day}';
  }
}

class _WeekDayCell extends StatelessWidget {
  final String letter;
  final int date;
  final bool selected;
  final bool hasLogs;
  final VoidCallback? onTap;

  const _WeekDayCell({
    required this.letter,
    required this.date,
    required this.selected,
    required this.hasLogs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final fg = selected
        ? AppColors.highlight
        : disabled
        ? AppColors.textSecondary.withValues(alpha: 0.4)
        : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(letter, style: AppText.kicker(color: fg)),
            const SizedBox(height: 4),
            Text(
              '$date',
              style: AppText.label(
                color: selected ? AppColors.highlight : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasLogs
                    ? (selected ? AppColors.accent : AppColors.primary)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String eyebrow;
  final String value;
  final String label;
  final Color background;
  final Color foreground;

  const _BigStat({
    required this.eyebrow,
    required this.value,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(), style: AppText.caption(color: foreground)),
          const SizedBox(height: 8),
          Text(value, style: AppText.h2(color: foreground)),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption(color: foreground)),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyHistory({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No entries on this day', style: AppText.h3()),
          const SizedBox(height: 6),
          Text(
            'This can stay empty. Add a note only when it helps you remember a meal.',
            style: AppText.bodySm(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onAdd, child: const Text('Add meal')),
        ],
      ),
    );
  }
}

/// Unchanged from the previous build — no Figma node covers manual entry.
class ManualLogScreen extends StatefulWidget {
  const ManualLogScreen({super.key});

  @override
  State<ManualLogScreen> createState() => _ManualLogScreenState();
}

class _ManualLogScreenState extends State<ManualLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  String _meal = 'Dinner';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _calories.dispose();
    _protein.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      tabBar: false,
      header: ScreenHeader(
        title: 'Manual log',
        eyebrow: 'TRACK',
        onBack: () => context.go('/track'),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text('Add what you know', style: AppText.h1()),
            const SizedBox(height: 8),
            Text(
              'A useful estimate is enough. You can remove it from history later.',
              style: AppText.bodySm(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meal', style: AppText.label()),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                        .map(
                          (meal) => ChoiceChip(
                            label: Text(meal),
                            selected: _meal == meal,
                            onSelected: (_) => setState(() => _meal = meal),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Name', style: AppText.label()),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Homemade chicken bowl',
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Enter a meal name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _NumberField(
                          controller: _calories,
                          label: 'Calories',
                          hint: '520',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NumberField(
                          controller: _protein,
                          label: 'Protein',
                          hint: '42',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving...' : 'Log meal'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final calories = int.parse(_calories.text.trim());
    final protein = int.parse(_protein.text.trim());
    context.read<AppState>().logItem(
      sourceId: 'manual-${DateTime.now().millisecondsSinceEpoch}',
      type: 'manual',
      title: _title.text.trim(),
      calories: calories,
      protein: protein,
      image: 'assets/images/recipe-exemplars/02-grilled-chicken-grain-bowl.jpg',
      meal: _meal,
    );
    showAppToast(
      context,
      'Meal logged',
      description: '$calories cal · ${protein}g protein',
    );
    context.go('/track');
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  const _NumberField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label()),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: hint),
          validator: (value) {
            final parsed = int.tryParse(value?.trim() ?? '');
            if (parsed == null || parsed <= 0) return 'Required';
            if (parsed > 5000) return 'Too high';
            return null;
          },
        ),
      ],
    );
  }
}
