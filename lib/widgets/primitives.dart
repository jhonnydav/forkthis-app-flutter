import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/fixtures.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';

/// Ported from `../app/src/components/app/primitives.tsx`. Never colour alone
/// (WCAG 1.4.1) — every badge carries an icon and a label, matching the source.
class GoalFitBadge extends StatelessWidget {
  final Goal goal;
  const GoalFitBadge({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (goal) {
      Goal.lose => (AppColors.secondary, AppColors.secondaryForeground, Icons.south_east_rounded),
      Goal.gain => (AppColors.warmSurface, AppColors.warmForeground, Icons.north_east_rounded),
      Goal.maintain => (AppColors.mint, AppColors.mintForeground, Icons.remove_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(goalLabel[goal]!, style: AppText.caption(color: fg).copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class ConditionTag extends StatelessWidget {
  final Condition condition;
  const ConditionTag({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (condition) {
      Condition.pcos => (AppColors.blueberrySurface, AppColors.secondaryForeground),
      Condition.postOp => (AppColors.warmSurface, AppColors.warmForeground),
      Condition.glp1 => (AppColors.secondary, AppColors.secondaryForeground),
      Condition.highProtein => (AppColors.mint, AppColors.mintForeground),
      Condition.lowCarb => (AppColors.muted, AppColors.mutedForeground),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: fg.withValues(alpha: 0.15)),
      ),
      child: Text(conditionLabel[condition]!, style: AppText.caption(color: fg)),
    );
  }
}

/// Never calories alone — PRD §3, U-4. Protein sits level with calories, not beneath.
class NutritionRow extends StatelessWidget {
  final int calories;
  final int protein;
  final String? portionNote;
  final bool large;

  const NutritionRow({super.key, required this.calories, required this.protein, this.portionNote, this.large = false});

  @override
  Widget build(BuildContext context) {
    final numStyle = large ? AppText.numeric() : AppText.numericSm();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border.symmetric(horizontal: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calories', style: AppText.caption()),
                    const SizedBox(height: 2),
                    Text('$calories', style: numStyle),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Protein', style: AppText.caption()),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(text: '$protein', style: numStyle),
                        TextSpan(text: 'g', style: AppText.bodySm(color: AppColors.mutedForeground)),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (portionNote != null) ...[
          const SizedBox(height: 8),
          Text(portionNote!, style: AppText.bodySm(color: AppColors.mutedForeground)),
        ],
      ],
    );
  }
}

/// The most-seen object in the product — designed first, per DESIGN-BRIEF §6.2.
class FastHackCard extends StatelessWidget {
  final FastHack hack;
  final Restaurant? restaurant;

  const FastHackCard({super.key, required this.hack, this.restaurant});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      onTap: () => context.push('/hack/${hack.id}'),
      child: Container(
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.xxl)),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 112,
                child: Image.asset(hack.image, fit: BoxFit.cover),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (restaurant != null)
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                              child: Text(restaurant!.mark,
                                  style: AppText.caption(color: AppColors.primaryForeground).copyWith(fontSize: 10, fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(restaurant!.name,
                                  style: AppText.caption().copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      Text(hack.title, style: AppText.h3(), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(text: '${hack.calories} ', style: AppText.numericSm()),
                              TextSpan(text: 'cal', style: AppText.caption(color: AppColors.mutedForeground)),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          Text('${hack.protein}g protein', style: AppText.caption().copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (hack.goals.isNotEmpty) GoalFitBadge(goal: hack.goals.first),
                          if (hack.conditions.isNotEmpty) ConditionTag(condition: hack.conditions.first),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Read while standing at a counter: one-handed, at arm's length, in bad light.
/// 18px, not the 16px body floor — deliberately above it for legibility.
class OrderScript extends StatelessWidget {
  final List<String> lines;
  final List<String> swaps;

  const OrderScript({super.key, required this.lines, required this.swaps});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.6, -1),
          end: Alignment(0.6, 1),
          colors: [AppColors.primary, AppColors.blueberry, AppColors.success],
          stops: [0, 0.68, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WHAT TO ORDER', style: AppText.eyebrow(color: Colors.white.withValues(alpha: 0.72))),
          const SizedBox(height: 12),
          for (final (index, line) in lines.indexed) ...[
            if (index > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: 1),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                  child: Text('${index + 1}', style: AppText.label(color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(line, style: const TextStyle(fontSize: 18, height: 26 / 18, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ],
            ),
          ],
          if (swaps.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.22)))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THE SWAPS', style: AppText.eyebrow(color: Colors.white.withValues(alpha: 0.68))),
                  const SizedBox(height: 8),
                  for (final swap in swaps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(swap, style: AppText.bodySm(color: Colors.white).copyWith(fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// FR-48 — present wherever guidance is given, phrased as context not legalese.
class DisclaimerNote extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  const DisclaimerNote({super.key, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'General nutrition guidance. Not medical advice — check with your care team about your specific situation.',
              style: AppText.caption(),
            ),
          ),
        ],
      ),
    );
  }
}
