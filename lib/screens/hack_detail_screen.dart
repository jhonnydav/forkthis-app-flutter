import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../data/fixtures.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_toast.dart';
import '../widgets/primitives.dart';

/// S-18 — the hero screen. Ported from `../app/src/screens/HackDetail.tsx`.
class HackDetailScreen extends StatelessWidget {
  final String id;
  const HackDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final hack = hackById(id);
    if (hack == null) {
      return AppShell(
        header: ScreenHeader(
          title: 'Not found',
          onBack: () => context.go('/eat-out'),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'That order is not in the sample data.',
            style: AppText.body(color: AppColors.mutedForeground),
          ),
        ),
      );
    }
    final restaurant = restaurantById(hack.restaurantId);
    final state = context.watch<AppState>();
    final isSaved = state.savedHackIds.contains(hack.id);

    return AppShell(
      header: ScreenHeader(
        title: restaurant?.name,
        onBack: () => context.pop(),
      ),
      fixedAction: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () {
            state.logItem(
              sourceId: hack.id,
              type: 'order',
              title: hack.title,
              calories: hack.calories,
              protein: hack.protein,
              image: hack.image,
            );
            showAppToast(
              context,
              'Logged to today',
              description: '${hack.calories} cal · ${hack.protein}g protein',
            );
          },
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
          label: const Text('Log this'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Image.asset(
            hack.image,
            height: 260,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hack.title, style: AppText.h1(color: AppColors.primary)),
                const SizedBox(height: 8),
                Text(
                  'A practical menu choice with the high-impact swaps already worked out for you.',
                  style: AppText.bodySm(color: AppColors.mutedForeground),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in hack.conditions) ConditionTag(condition: c),
                    for (final g in hack.goals) GoalFitBadge(goal: g),
                  ],
                ),
                const SizedBox(height: 16),
                NutritionRow(
                  calories: hack.calories,
                  protein: hack.protein,
                  portionNote: hack.portionNote,
                  large: true,
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(20),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHAT TO ORDER',
                  style: AppText.caption(
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w800, fontSize: 11),
                ),
                const SizedBox(height: 12),
                for (final (index, line) in hack.orderScript.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            line,
                            style: AppText.body(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THE SWAPS',
                        style: AppText.caption(
                          color: AppColors.primary,
                        ).copyWith(fontWeight: FontWeight.w800, fontSize: 9),
                      ),
                      const SizedBox(height: 6),
                      for (final swap in hack.swaps)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            swap,
                            style: AppText.bodySm(color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (isSaved) {
                        state.toggleSavedHack(hack.id);
                        showAppToast(context, 'Removed from saved items');
                      } else {
                        state.toggleSavedHack(hack.id);
                        showAppToast(context, 'Saved for later');
                      }
                    },
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedBookmark02,
                      color: isSaved ? AppColors.primary : null,
                    ),
                    label: Text(isSaved ? 'Saved' : 'Save it'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    onPressed: () => context.push(
                      '/search?q=${Uri.encodeComponent("something like ${hack.title}")}',
                    ),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedMessage01,
                    ),
                    label: const Text('Ask about this order'),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.hackWhySurface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why this works',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hack.why,
                  style: AppText.bodySm(
                    color: AppColors.mutedForeground,
                  ).copyWith(height: 17 / 14),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Center(child: const DisclaimerNote()),
          ),
        ],
      ),
    );
  }
}
