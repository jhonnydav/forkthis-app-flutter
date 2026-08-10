import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../data/fixtures.dart';
import '../product.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

const _tourSteps = [
  (
    icon: HugeIcons.strokeRoundedRestaurant01,
    eyebrow: 'START HERE',
    title: 'Name the ForkThis! moment',
    body:
        'Eating out, craving something, short on time, or coming back after a gap all start from one useful next choice.',
  ),
  (
    icon: HugeIcons.strokeRoundedChefHat,
    eyebrow: 'COOK AT HOME',
    title: 'Every recipe keeps the numbers visible',
    body:
        'Browse realistic meals with time, calories, protein, carbs, fat, and a photo before you commit.',
  ),
  (
    icon: HugeIcons.strokeRoundedNotebook01,
    eyebrow: 'NO REPORT CARDS',
    title: 'Build momentum without punishment',
    body:
        'Log a meal in one tap, earn small badges for helpful actions, and come back whenever you are ready.',
  ),
];

Future<void> showGuidedTour(BuildContext context, {bool replay = false}) async {
  var current = 0;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) {
        final step = _tourSteps[current];
        final last = current == _tourSteps.length - 1;
        return PopScope(
          canPop: false,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          replay ? 'QUICK TOUR' : 'WELCOME IN',
                          style: AppText.eyebrow(color: AppColors.actionDeep),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            sheetContext.read<AppState>().completeGuidedTour();
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Text('Skip'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: Column(
                        key: ValueKey(current),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: current == 0
                                  ? AppColors.paletteOrange
                                  : current == 1
                                  ? AppColors.paletteYellow
                                  : AppColors.paletteCream,
                              borderRadius: BorderRadius.circular(
                                AppRadius.xxl,
                              ),
                            ),
                            child: HugeIcon(
                              icon: step.icon,
                              size: 27,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(step.eyebrow, style: AppText.eyebrow()),
                          const SizedBox(height: 6),
                          Text(step.title, style: AppText.h1()),
                          const SizedBox(height: 10),
                          Text(
                            step.body,
                            style: AppText.bodySm(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        for (var index = 0; index < _tourSteps.length; index++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: index == current ? 28 : 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: index == current
                                  ? AppColors.action
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                        const Spacer(),
                        SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            onPressed: () {
                              if (!last) {
                                setSheetState(() => current++);
                                return;
                              }
                              sheetContext
                                  .read<AppState>()
                                  .completeGuidedTour();
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(last ? 'Start exploring' : 'Next'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> showWelcomeBackExperience(BuildContext context) async {
  final state = context.read<AppState>();
  final hack = fastHacks.first;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOU ARE BACK',
                style: AppText.eyebrow(color: AppColors.actionDeep),
              ),
              const SizedBox(height: 8),
              Text('You are back!!', style: AppText.h1()),
              const SizedBox(height: 10),
              Text(
                'Here is a new menu suggestion to keep your momentum. You are making huge strides toward your goal.',
                style: AppText.bodySm(color: AppColors.mutedForeground),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
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
                        hack.image,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('A $productName pick', style: AppText.caption()),
                          const SizedBox(height: 3),
                          Text(hack.title, style: AppText.h3()),
                          const SizedBox(height: 3),
                          Text(
                            '${hack.calories} cal · ${hack.protein}g protein',
                            style: AppText.caption(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    state.dismissWelcomeBack();
                    Navigator.of(sheetContext).pop();
                    context.push('/hack/${hack.id}');
                  },
                  child: const Text('Keep momentum'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    state.dismissWelcomeBack();
                    Navigator.of(sheetContext).pop();
                  },
                  child: const Text('Not right now'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (state.welcomeBackPending) state.dismissWelcomeBack();
}
