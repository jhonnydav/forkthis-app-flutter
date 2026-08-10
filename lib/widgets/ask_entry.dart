import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../screens/assistant_screen.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

/// The assistant's single entry point (App Flow §1.3) — one affordance, the
/// same shape everywhere, present on Eat Out, Cook, and Track.
///
/// Not a fifth tab: a tab would advertise a general-purpose assistant, and this
/// one is deliberately bounded to approved content (FR-33). A quiet pill next to
/// the screen's own title says "there is help here if you want it" without
/// promising a chatbot that knows everything.
///
/// Flat by construction — a tinted pill with a hairline border, no elevation
/// and no FAB shadow, so it sits in the page rather than floating above it.
class AskPill extends StatelessWidget {
  /// Optional question to open with, when the entry point has context worth
  /// carrying (a specific order, a specific recipe).
  final String? seedQuestion;
  final String label;

  const AskPill({super.key, this.seedQuestion, this.label = 'Ask'});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ask about food, orders, and recipes',
      child: InkWell(
        onTap: () => showAssistantSheet(context, seedQuestion: seedQuestion),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedSparkles,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(label, style: AppText.label(color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width variant for detail screens, where the question the user has is
/// usually about the thing they are looking at.
class AskAboutRow extends StatelessWidget {
  final String seedQuestion;
  final String label;

  const AskAboutRow({
    super.key,
    required this.seedQuestion,
    this.label = 'Ask about this',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton.icon(
        onPressed: () =>
            showAssistantSheet(context, seedQuestion: seedQuestion),
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedMessage01,
          size: 18,
          color: AppColors.primary,
        ),
        label: Text(label),
      ),
    );
  }
}
