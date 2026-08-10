import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../product.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

class ForkThisMoment {
  final String id;
  final String title;
  final String subtitle;
  final String query;
  final String scope;
  final List<List<dynamic>> icon;
  final Color tone;

  const ForkThisMoment({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.query,
    required this.scope,
    required this.icon,
    required this.tone,
  });
}

const forkThisMoments = [
  ForkThisMoment(
    id: 'eat-out',
    title: 'I am eating out',
    subtitle: 'Get the exact order and swaps before the counter.',
    query: 'something high-protein I can grab nearby',
    scope: 'orders',
    icon: HugeIcons.strokeRoundedRestaurant01,
    tone: AppColors.accent,
  ),
  ForkThisMoment(
    id: 'craving',
    title: 'I am craving something',
    subtitle: 'Find a recipe or order that still fits the day.',
    query: 'a craving-friendly meal that keeps me on track',
    scope: 'all',
    icon: HugeIcons.strokeRoundedFire,
    tone: AppColors.coralSurface,
  ),
  ForkThisMoment(
    id: 'fast',
    title: 'I need something fast',
    subtitle: 'Shortlist meals that do not cost extra energy.',
    query: 'quick high-protein meal',
    scope: 'all',
    icon: HugeIcons.strokeRoundedTimeQuarterPass,
    tone: AppColors.mint,
  ),
  ForkThisMoment(
    id: 'calories-left',
    title: 'I have calories left',
    subtitle: 'Use the room in today without guessing.',
    query: 'I have 400 calories left and I am out',
    scope: 'all',
    icon: HugeIcons.strokeRoundedPieChart,
    tone: AppColors.blueberrySurface,
  ),
  ForkThisMoment(
    id: 'back-on-track',
    title: 'I am getting back on track',
    subtitle: 'Start with one low-friction meal suggestion.',
    query: 'an easy meal to restart my momentum',
    scope: 'all',
    icon: HugeIcons.strokeRoundedFavourite,
    tone: AppColors.goldLight,
  ),
];

Future<void> showForkThisMomentSheet(
  BuildContext context, {
  required ValueChanged<ForkThisMoment> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Align(
      alignment: Alignment.bottomCenter,
      child: _ForkThisMomentSheet(onSelected: onSelected),
    ),
  );
}

Future<void> openForkThisMomentSearchSheet(BuildContext context) {
  final pageContext = context;
  final state = pageContext.read<AppState>();
  return showForkThisMomentSheet(
    pageContext,
    onSelected: (moment) {
      state.recordForkThisMoment(moment.id);
      pageContext.go(
        '/search?q=${Uri.encodeComponent(moment.query)}&scope=${moment.scope}',
      );
    },
  );
}

class ForkThisMomentPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final ValueChanged<ForkThisMoment> onSelected;
  final bool compact;

  const ForkThisMomentPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final shown = compact ? forkThisMoments.take(3) : forkThisMoments;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(productMomentLabel.toUpperCase(), style: AppText.kicker()),
          const SizedBox(height: 6),
          Text(title, style: AppText.h2()),
          const SizedBox(height: 6),
          Text(subtitle, style: AppText.bodySm(color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          for (final moment in shown) ...[
            _MomentRow(moment: moment, onTap: () => onSelected(moment)),
            if (moment != shown.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ForkThisMomentSheet extends StatefulWidget {
  final ValueChanged<ForkThisMoment> onSelected;

  const _ForkThisMomentSheet({required this.onSelected});

  @override
  State<_ForkThisMomentSheet> createState() => _ForkThisMomentSheetState();
}

class _ForkThisMomentSheetState extends State<_ForkThisMomentSheet> {
  ForkThisMoment _selected = forkThisMoments.first;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final width = math.min(MediaQuery.sizeOf(context).width - 16, 430.0);
    return SafeArea(
      top: false,
      child: Container(
        width: width,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 184,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/figma/forkthis-moment-sheet-bg.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.highlight.withValues(alpha: 0.96),
                          AppColors.highlight.withValues(alpha: 0.72),
                          AppColors.highlight.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.24),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          productMomentLabel.toUpperCase(),
                          style: AppText.kicker(
                            color: AppColors.primaryForeground,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 270),
                        child: Text(
                          'What kind of moment is this?',
                          style: AppText.headline(
                            34,
                            height: 34,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                children: [
                  Text(
                    'Tap a situation. The card expands before you choose.',
                    style: AppText.bodySm(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  for (final moment in forkThisMoments) ...[
                    _InteractiveMomentCard(
                      moment: moment,
                      selected: moment.id == _selected.id,
                      onTap: () => setState(() => _selected = moment),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(child: _SelectedMomentSummary(moment: _selected)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 118,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onSelected(_selected);
                      },
                      iconAlignment: IconAlignment.end,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 16,
                      ),
                      label: const Text('Find it'),
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
}

class _InteractiveMomentCard extends StatelessWidget {
  final ForkThisMoment moment;
  final bool selected;
  final VoidCallback onTap;

  const _InteractiveMomentCard({
    required this.moment,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? moment.tone : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: EdgeInsets.all(selected ? 16 : 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: selected ? 58 : 46,
                height: selected ? 58 : 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : moment.tone,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: HugeIcon(
                  icon: moment.icon,
                  size: selected ? 25 : 20,
                  color: selected
                      ? AppColors.primaryForeground
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(moment.title, style: AppText.cardTitle()),
                    const SizedBox(height: 3),
                    Text(
                      moment.subtitle,
                      style: AppText.caption(color: AppColors.textSecondary),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.card.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '"${moment.query}"',
                            style: AppText.caption(color: AppColors.primary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      crossFadeState: selected
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 180),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary),
                ),
                child: selected
                    ? const HugeIcon(
                        icon: HugeIcons.strokeRoundedTick02,
                        size: 14,
                        color: AppColors.primaryForeground,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedMomentSummary extends StatelessWidget {
  final ForkThisMoment moment;

  const _SelectedMomentSummary({required this.moment});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Column(
        key: ValueKey(moment.id),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selected', style: AppText.kicker(color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(
            moment.title,
            style: AppText.label(color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MomentRow extends StatelessWidget {
  final ForkThisMoment moment;
  final VoidCallback onTap;

  const _MomentRow({required this.moment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: moment.tone,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: HugeIcon(
                icon: moment.icon,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(moment.title, style: AppText.cardTitle()),
                  const SizedBox(height: 3),
                  Text(
                    moment.subtitle,
                    style: AppText.caption(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
