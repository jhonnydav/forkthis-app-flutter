import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      header: ScreenHeader(
        title: 'Help',
        eyebrow: 'SUPPORT',
        onBack: () => context.go('/you'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text('What this app can help with', style: AppText.h1()),
          const SizedBox(height: 8),
          Text(
            'Use ForkThis! moments to choose what to order or cook when real life puts your healthier habits on the spot.',
            style: AppText.bodySm(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 22),
          _HelpCard(
            icon: HugeIcons.strokeRoundedRestaurant01,
            title: 'Restaurant orders',
            body:
                'Start from a place, craving, or goal. Each order shows calories, protein, and a practical swap.',
            onTap: () => context.go('/eat-out'),
          ),
          _HelpCard(
            icon: HugeIcons.strokeRoundedChefHat,
            title: 'Recipes',
            body:
                'Browse by taste, time, and protein. Recipe detail pages include ingredients, steps, servings, and logging.',
            onTap: () => context.go('/cook'),
          ),
          _HelpCard(
            icon: HugeIcons.strokeRoundedNotebook01,
            title: 'Tracking',
            body:
                'Track meals, water, and movement with positive momentum. History stays editable, and missed days are not punished.',
            onTap: () => context.go('/track'),
          ),
          _HelpCard(
            icon: HugeIcons.strokeRoundedMessageQuestion,
            title: 'Ask a question',
            body:
                'The prototype assistant answers from app content and blocks medical-advice requests.',
            onTap: () => context.go('/ask'),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.paletteCream,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Text(
              'General nutrition education only. Questions about symptoms, medication, dosing, surgery instructions, or diagnosis need your care team.',
              style: AppText.bodySm(color: AppColors.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class LegalPage extends StatelessWidget {
  final String kind;
  const LegalPage({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final privacy = kind == 'privacy';
    return AppShell(
      tabBar: false,
      header: ScreenHeader(
        title: privacy ? 'Privacy' : 'Terms',
        eyebrow: 'LEGAL',
        onBack: () => context.go('/you/settings'),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text(
              privacy ? 'Privacy draft' : 'Terms draft',
              style: AppText.h1(),
            ),
            const SizedBox(height: 8),
            Text(
              'Design-stage template for prototype review. Counsel-approved copy is required before production.',
              style: AppText.bodySm(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 22),
            for (final section in privacy ? _privacySections : _termsSections)
              _LegalSection(title: section.$1, body: section.$2),
          ],
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  const _HelpCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              HugeIcon(icon: icon, size: 24, color: AppColors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.h3()),
                    const SizedBox(height: 4),
                    Text(body, style: AppText.caption()),
                  ],
                ),
              ),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String title;
  final String body;
  const _LegalSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h2()),
          const SizedBox(height: 6),
          Text(body, style: AppText.bodySm(color: AppColors.mutedForeground)),
        ],
      ),
    );
  }
}

const _privacySections = [
  (
    'Prototype storage',
    'This demo stores profile details, saved items, logs, and preferences locally on this device.',
  ),
  (
    'Health context',
    'Surgical and nutrition context is used only to shape educational recommendations in the prototype.',
  ),
  (
    'Production requirement',
    'A production app needs account controls, deletion/export flows, encrypted storage, and reviewed privacy language.',
  ),
];

const _termsSections = [
  (
    'General education',
    'The app provides general nutrition education and is not medical advice.',
  ),
  (
    'Restaurant data',
    'Demo restaurant names, meals, and macros are illustrative until verified launch content is loaded.',
  ),
  (
    'Care-team boundary',
    'Users should contact their clinician for medical, surgical, medication, symptom, or diagnosis guidance.',
  ),
];
