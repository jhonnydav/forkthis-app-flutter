import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../data/fixtures.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/ask_entry.dart';
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
              description:
                  '+10 momentum points · ${hack.calories} cal · ${hack.protein}g protein',
            );
          },
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
          label: const Text('Log this'),
          style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                hack.image,
                height: 146,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (restaurant != null) ...[
                  Text(restaurant.name, style: AppText.cardTitle()),
                  const SizedBox(height: 4),
                ],
                Text(
                  hack.title,
                  style: AppText.headline(42, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  'A practical menu choice with the high-impact swaps already worked out for you.',
                  style: AppText.caption(color: AppColors.foreground),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -60,
                    top: -64,
                    child: Container(
                      width: 176,
                      height: 176,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.19),
                          width: 41,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WHAT TO ORDER',
                          style: AppText.tagBold(color: AppColors.foreground),
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
                                    style: AppText.caption(color: Colors.white)
                                        .copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: AppText.caption(
                                      color: AppColors.foreground,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (hack.swaps.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.only(top: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.55,
                                  ),
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'THE SWAPS',
                                  style: AppText.tagBold(
                                    color: AppColors.foreground,
                                  ).copyWith(fontSize: 9),
                                ),
                                const SizedBox(height: 6),
                                for (final swap in hack.swaps)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      swap,
                                      style: AppText.caption(
                                        color: AppColors.foreground,
                                      ).copyWith(fontSize: 11),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
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
                        showAppToast(
                          context,
                          'Saved for later',
                          description: '+10 momentum points',
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedBookmark02,
                      color: isSaved ? AppColors.primary : null,
                    ),
                    label: Text(isSaved ? 'Saved' : 'Bookmark'),
                  ),
                ),
                const SizedBox(height: 8),
                // App Flow §3.3 node O. This used to open search, which is a
                // different thing wearing the same label.
                AskAboutRow(
                  seedQuestion: 'Tell me about ${hack.title}',
                  label: 'Ask about this order',
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.hackWhySurface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why this works',
                  style: AppText.cardTitle().copyWith(
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
