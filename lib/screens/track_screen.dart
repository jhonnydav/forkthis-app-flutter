import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_toast.dart';
import '../widgets/product_sheet.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.2;
    final calories = state.logs.fold<int>(
      0,
      (sum, item) => sum + item.calories,
    );
    final protein = state.logs.fold<int>(0, (sum, item) => sum + item.protein);
    final remaining = (1850 - calories).clamp(0, 1850);
    final progress = (calories / 1850).clamp(0.0, 1.0);

    return AppShell(
      scrollTitle: 'Track',
      scrollEyebrow: 'TODAY',
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TODAY',
                          style: AppText.eyebrow(color: AppColors.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A record, not a report card',
                          style: AppText.h1(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Notice the day as it happens. Nothing here needs to be perfect.',
                          style: AppText.bodySm(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: IconButton(
                      onPressed: () => _openQuickLog(context),
                      tooltip: 'Quick log',
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'DAILY ENERGY',
                            style: AppText.eyebrow(color: AppColors.accent),
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: AppText.label(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Flex(
                      direction: largeText ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: largeText
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$calories',
                          style: AppText.display(color: Colors.white),
                        ),
                        SizedBox(
                          width: largeText ? 0 : 8,
                          height: largeText ? 4 : 0,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'calories logged',
                            style: AppText.bodySm(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      remaining == 0
                          ? 'Daily guide reached'
                          : '$remaining calories remain in your current guide',
                      style: AppText.caption(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: largeText
                  ? Column(
                      children: [
                        _RhythmTile(
                          icon: HugeIcons.strokeRoundedBodyPartMuscle,
                          value: '${protein}g',
                          label: 'Protein',
                          tint: AppColors.coralSurface,
                        ),
                        const SizedBox(height: 10),
                        _RhythmTile(
                          icon: HugeIcons.strokeRoundedDroplet,
                          value: '${state.waterCups}/8',
                          label: 'Water',
                          tint: AppColors.blueberrySurface,
                        ),
                        const SizedBox(height: 10),
                        _RhythmTile(
                          icon: HugeIcons.strokeRoundedWalking,
                          value: '${state.movementMinutes}m',
                          label: 'Movement',
                          tint: AppColors.warmSurface,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _RhythmTile(
                            icon: HugeIcons.strokeRoundedBodyPartMuscle,
                            value: '${protein}g',
                            label: 'Protein',
                            tint: AppColors.coralSurface,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _RhythmTile(
                            icon: HugeIcons.strokeRoundedDroplet,
                            value: '${state.waterCups}/8',
                            label: 'Water',
                            tint: AppColors.blueberrySurface,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _RhythmTile(
                            icon: HugeIcons.strokeRoundedWalking,
                            value: '${state.movementMinutes}m',
                            label: 'Movement',
                            tint: AppColors.warmSurface,
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK ACTIONS',
                    style: AppText.eyebrow(color: AppColors.primary),
                  ),
                  const SizedBox(height: 3),
                  Text('Keep the interruption small', style: AppText.h2()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: HugeIcons.strokeRoundedDroplet,
                      label: 'Water',
                      onTap: () {
                        state.adjustWater(1);
                        showAppToast(context, 'Water added', addToInbox: false);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: HugeIcons.strokeRoundedWalking,
                      label: '+10 min',
                      onTap: () {
                        state.addMovement(10);
                        showAppToast(
                          context,
                          'Movement added',
                          description: '10 minutes',
                          addToInbox: false,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: HugeIcons.strokeRoundedAdd01,
                      label: 'Meal',
                      strong: true,
                      onTap: () => _openCustomMeal(context),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MEALS',
                          style: AppText.eyebrow(color: AppColors.primary),
                        ),
                        const SizedBox(height: 3),
                        Text('Logged today', style: AppText.h2()),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openQuickLog(context),
                    child: const Text('Add item'),
                  ),
                ],
              ),
            ),
            if (state.logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _EmptyLog(onAdd: () => _openQuickLog(context)),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (final item in state.logs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LogRow(
                          item: item,
                          onTap: () => _openLogDetails(context, item),
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

  void _openQuickLog(BuildContext context) {
    final pageContext = context;
    showProductSheet(
      context,
      title: 'Quick log',
      description: 'Update the day without leaving your place in it.',
      builder: (sheetContext) => Consumer<AppState>(
        builder: (context, state, _) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            children: [
              _CounterRow(
                icon: HugeIcons.strokeRoundedDroplet,
                title: 'Water',
                value: '${state.waterCups} cups',
                tint: AppColors.blueberrySurface,
                onDecrease: () => state.adjustWater(-1),
                onIncrease: () => state.adjustWater(1),
              ),
              const SizedBox(height: 10),
              _CounterRow(
                icon: HugeIcons.strokeRoundedWalking,
                title: 'Movement',
                value: '${state.movementMinutes} min',
                tint: AppColors.warmSurface,
                onDecrease: () => state.addMovement(-10),
                onIncrease: () => state.addMovement(10),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _openCustomMeal(pageContext);
                  },
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
                  label: const Text('Add a meal manually'),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        pageContext.go('/cook');
                      },
                      child: const Text('Browse recipes'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        pageContext.go('/eat-out');
                      },
                      child: const Text('Browse orders'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCustomMeal(BuildContext context) {
    showProductSheet(
      context,
      title: 'Add a meal',
      description: 'Use the best estimate you have. You can remove it later.',
      builder: (sheetContext) => _CustomMealForm(
        onSaved: (title, calories, protein) {
          context.read<AppState>().logItem(
            sourceId: 'manual-${DateTime.now().millisecondsSinceEpoch}',
            type: 'manual',
            title: title,
            calories: calories,
            protein: protein,
            image:
                'assets/images/recipe-exemplars/02-grilled-chicken-grain-bowl.jpg',
          );
          Navigator.of(sheetContext).pop();
          showAppToast(
            context,
            'Meal logged',
            description: '$calories cal · ${protein}g protein',
          );
        },
      ),
    );
  }

  void _openLogDetails(BuildContext context, LoggedItem item) {
    showProductSheet(
      context,
      title: item.title,
      description: item.type == 'recipe'
          ? 'Home-cooked recipe'
          : item.type == 'manual'
          ? 'Manual entry'
          : 'Restaurant order',
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(item.image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DetailValue(
                    label: 'Calories',
                    value: '${item.calories}',
                  ),
                ),
                Expanded(
                  child: _DetailValue(
                    label: 'Protein',
                    value: '${item.protein}g',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AppState>().removeLog(item.id);
                  Navigator.of(sheetContext).pop();
                  showAppToast(context, 'Removed from today');
                },
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete01,
                  size: 18,
                ),
                label: const Text('Remove from today'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.destructive,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RhythmTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String value;
  final String label;
  final Color tint;
  const _RhythmTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: HugeIcon(icon: icon, size: 15, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppText.numericSm(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: AppText.caption()),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  final bool strong;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        height: 84,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: strong ? AppColors.accent : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: strong ? AppColors.homeHeroBorder : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(icon: icon, size: 21, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: AppText.label(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final LoggedItem item;
  final VoidCallback onTap;
  const _LogRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
                item.image,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppText.h3(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.calories} cal · ${item.protein}g protein',
                    style: AppText.caption(),
                  ),
                ],
              ),
            ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLog extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyLog({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nothing logged yet', style: AppText.h3()),
          const SizedBox(height: 5),
          Text(
            'Start with water, movement, or a meal when it becomes useful.',
            style: AppText.bodySm(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 14),
          TextButton(onPressed: onAdd, child: const Text('Add the first item')),
        ],
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String value;
  final Color tint;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  const _CounterRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.tint,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: HugeIcon(icon: icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h3()),
                Text(value, style: AppText.caption()),
              ],
            ),
          ),
          IconButton(
            onPressed: onDecrease,
            tooltip: 'Decrease $title',
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedMinusSign,
              size: 18,
            ),
          ),
          IconButton(
            onPressed: onIncrease,
            tooltip: 'Increase $title',
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 18),
          ),
        ],
      ),
    );
  }
}

class _CustomMealForm extends StatefulWidget {
  final void Function(String title, int calories, int protein) onSaved;
  const _CustomMealForm({required this.onSaved});

  @override
  State<_CustomMealForm> createState() => _CustomMealFormState();
}

class _CustomMealFormState extends State<_CustomMealForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _calories.dispose();
    _protein.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Meal name', style: AppText.label()),
            const SizedBox(height: 8),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Chicken grain bowl',
              ),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Enter a meal name'
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Calories', style: AppText.label()),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _calories,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '450'),
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          return parsed == null || parsed < 1 || parsed > 5000
                              ? 'Use 1–5000'
                              : null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Protein (g)', style: AppText.label()),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _protein,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '30'),
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          return parsed == null || parsed < 0 || parsed > 300
                              ? 'Use 0–300'
                              : null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  widget.onSaved(
                    _title.text.trim(),
                    int.parse(_calories.text),
                    int.parse(_protein.text),
                  );
                },
                child: const Text('Log meal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailValue extends StatelessWidget {
  final String label;
  final String value;
  const _DetailValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppText.eyebrow()),
        const SizedBox(height: 5),
        Text(value, style: AppText.numeric()),
      ],
    );
  }
}
