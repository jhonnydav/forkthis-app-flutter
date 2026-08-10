import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../product.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/ask_entry.dart';
import '../widgets/app_toast.dart';
import '../widgets/figma_components.dart';
import '../widgets/forkthis_moments.dart';
import '../widgets/product_sheet.dart';

/// Restyled against Figma node 321:659 ("3.1 Track – Today"),
/// `figma.com/design/LjDp489aFZaYiDx88MvvkQ`, pulled 2026-08-06.
///
/// The Today/History segmented control in Figma is two separate screens, not
/// one screen with internal state — that already matches this app's routing
/// (`/track` and `/track/history` are separate routes), so [SegmentedPills]
/// here just navigates rather than toggling local state.
class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  static String _sourceLabel(String type) => switch (type) {
    'order' => 'Restaurant order',
    'recipe' => 'Home-cooked recipe',
    _ => 'Manual entry',
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = DateTime.now();
    final todayLogs = state.logs
        .where(
          (item) =>
              item.loggedAt.year == today.year &&
              item.loggedAt.month == today.month &&
              item.loggedAt.day == today.day,
        )
        .toList();
    final calories = todayLogs.fold<int>(0, (sum, item) => sum + item.calories);
    final protein = todayLogs.fold<int>(0, (sum, item) => sum + item.protein);
    const guide = 1850;
    final remaining = (guide - calories).clamp(0, guide);

    return AppShell(
      scrollTitle: 'Track',
      scrollEyebrow: 'TRACK',
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TRACK', style: AppText.kicker()),
                        const SizedBox(height: 8),
                        Text('Keep your momentum', style: AppText.h1()),
                        const SizedBox(height: 8),
                        Text(
                          'A calm snapshot for making the next ForkThis! choice. This demo uses a general planning guide, not a personalized medical target.',
                          style: AppText.bodySm(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedPills<String>(
                      values: const ['today', 'history'],
                      selected: 'today',
                      labelFor: (v) => v == 'today' ? 'Today' : 'History',
                      onChanged: (v) {
                        if (v == 'history') context.go('/track/history');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const AskPill(),
                ],
              ),
            ),
            // App Flow §3.4 node O — a designed screen, not copy. After a gap
            // this is the first thing on Track, and it names the gap warmly
            // instead of rendering it as a hole in a chart. No red, no streak,
            // no tally of the missed days. Copy is the client's own reference
            // wording (PRD §10.1, Q-11).
            if (state.lapseDays >= 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(AppRadius.hero),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You are back!!', style: AppText.h3()),
                      const SizedBox(height: 6),
                      Text(
                        'Here is a new menu suggestion or recipe to keep your momentum. You are making huge strides toward your goal.',
                        style: AppText.bodySm(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => context.go('/eat-out'),
                              child: const Text('Find an easy order'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.go('/cook'),
                              child: const Text('Quick recipe'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              child: HeroProgressCard(
                eyebrow: '$productName momentum',
                statValue: '${state.momentumPoints}',
                statUnit: 'pts',
                description: remaining == 0
                    ? 'The guide is fully logged. However the rest of the day goes, it still counts.'
                    : 'Helpful actions count: saved picks, logged meals, comeback moments, water, and movement.',
                percent: (state.momentumPoints % 100).clamp(0, 99),
                progress: (state.momentumPoints % 100) / 100,
                leftCaption: remaining == 0
                    ? 'Guide reached'
                    : '$remaining cal left in this guide',
                rightCaption: 'Guide: ${_grouped(guide)}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: ForkThisMomentPanel(
                title: 'Need one next step?',
                subtitle:
                    'Choose the situation and get a practical order or recipe.',
                compact: true,
                onSelected: (moment) {
                  state.recordForkThisMoment(moment.id);
                  context.go(
                    '/search?q=${Uri.encodeComponent(moment.query)}&scope=${moment.scope}',
                  );
                },
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
                        Text('SMALL WINS', style: AppText.kicker()),
                        const SizedBox(height: 4),
                        Text(
                          'The things that support you',
                          style: AppText.h1(),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openQuickLog(context),
                    child: const Text('Quick add'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              // No CrossAxisAlignment.stretch here — a horizontal-stretch Row
              // inside a ListView item has unbounded height to stretch to,
              // which throws (not just overflows; a blank screen with no
              // error UI, since the exception fires mid-layout before paint).
              // Each _PlainStatTile already enforces its own minHeight.
              child: Row(
                children: [
                  Expanded(
                    child: _PlainStatTile(
                      icon: HugeIcons.strokeRoundedDroplet,
                      value: '${state.waterCups}',
                      label: 'cups of water',
                      onTap: () {
                        state.adjustWater(1);
                        showAppToast(context, 'Water added', addToInbox: false);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PlainStatTile(
                      icon: HugeIcons.strokeRoundedWalking,
                      value: '${state.movementMinutes}',
                      label: 'minutes moved',
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PlainStatTile(
                      icon: HugeIcons.strokeRoundedBodyPartMuscle,
                      value: '${protein}g',
                      label: 'protein logged',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MEALS', style: AppText.kicker()),
                        const SizedBox(height: 4),
                        Text('What is on your day', style: AppText.h3()),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/track/add'),
                    child: const Text('Add meal'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (todayLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _EmptyLog(onAdd: () => _openQuickLog(context)),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (final item in todayLogs)
                      ThumbActionRow(
                        image: item.image,
                        title: item.title,
                        subtitle:
                            '${_sourceLabel(item.type)} · ${item.calories} cal · ${item.protein}g protein',
                        onTap: () => _openLogDetails(context, item),
                        onAction: () {
                          state.removeLog(item.id);
                          showAppToast(context, 'Removed from today');
                        },
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: CtaBannerCard(
                icon: HugeIcons.strokeRoundedSearch01,
                title: 'Need your next meal?',
                subtitle: 'Find an order that fits the day you have.',
                plateColor: AppColors.accent,
                background: AppColors.goldLight,
                showArrow: true,
                onTap: () => context.go('/eat-out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _grouped(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
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
                onDecrease: () => state.adjustWater(-1),
                onIncrease: () => state.adjustWater(1),
              ),
              const SizedBox(height: 10),
              _CounterRow(
                icon: HugeIcons.strokeRoundedWalking,
                title: 'Movement',
                value: '${state.movementMinutes} min',
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
                    pageContext.go('/track/log');
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

  void _openLogDetails(BuildContext context, LoggedItem item) {
    showProductSheet(
      context,
      title: item.title,
      description: _sourceLabel(item.type),
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

/// Track's small stat card — bare icon, plain Manrope figure (not the bold
/// Satoshi treatment Home uses), caption label. Figma node 321:717.
class _PlainStatTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _PlainStatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 116),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(icon: icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(height: 12),
            Text(value, style: AppText.body()),
            const SizedBox(height: 2),
            Text(label, style: AppText.caption()),
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
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nothing logged yet', style: AppText.h3()),
          const SizedBox(height: 5),
          Text(
            'Start with water, movement, or a meal when it becomes useful.',
            style: AppText.bodySm(color: AppColors.textSecondary),
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
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  const _CounterRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 20, color: AppColors.textPrimary),
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

class _DetailValue extends StatelessWidget {
  final String label;
  final String value;
  const _DetailValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppText.kicker()),
        const SizedBox(height: 5),
        Text(value, style: AppText.numeric()),
      ],
    );
  }
}
