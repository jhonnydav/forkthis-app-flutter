import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/fixtures.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_toast.dart';
import '../widgets/primitives.dart';
import '../widgets/product_sheet.dart';

/// S-18 — the hero screen. Ported from `../app/src/screens/HackDetail.tsx`.
class HackDetailScreen extends StatelessWidget {
  final String id;
  const HackDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final hack = hackById(id);
    if (hack == null) {
      return AppShell(
        header: ScreenHeader(title: 'Not found', onBack: () => context.go('/eat-out')),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('That order is not in the sample data.', style: AppText.body(color: AppColors.mutedForeground)),
        ),
      );
    }
    final restaurant = restaurantById(hack.restaurantId);
    final state = context.watch<AppState>();
    final isSaved = state.savedHackIds.contains(hack.id);

    return AppShell(
      header: ScreenHeader(title: restaurant?.name, onBack: () => context.pop()),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              child: Image.asset('assets/images/figma/detail-salad.jpg', height: 313, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hack.title, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 32, height: 38 / 32, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 8),
                Text(
                  'A tender, slow-roasted protein bowl with crisp vegetables, bright herbs, and a balanced savory finish.',
                  style: AppText.caption(color: AppColors.foreground).copyWith(fontSize: 12, height: 19 / 12),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final c in hack.conditions) ConditionTag(condition: c),
                  for (final g in hack.goals) GoalFitBadge(goal: g),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('CALORIES', style: AppText.caption().copyWith(fontSize: 9)),
                      const SizedBox(height: 4),
                      Text('${hack.calories}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('PROTEIN', style: AppText.caption().copyWith(fontSize: 9)),
                      const SizedBox(height: 4),
                      Text('${hack.protein}g', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.warm)),
                    ]),
                  ),
                ]),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(20),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.xl)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WHAT TO ORDER', style: AppText.caption(color: AppColors.primary).copyWith(fontWeight: FontWeight.w800, fontSize: 11)),
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
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                          child: Text('${index + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(line, style: const TextStyle(fontSize: 12, height: 18 / 12, color: AppColors.primary))),
                      ],
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.55)))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('THE SWAPS', style: AppText.caption(color: AppColors.primary).copyWith(fontWeight: FontWeight.w800, fontSize: 9)),
                      const SizedBox(height: 6),
                      for (final swap in hack.swaps) Text(swap, style: const TextStyle(fontSize: 11, height: 16 / 11, color: AppColors.primary)),
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
                  child: ElevatedButton.icon(
                    onPressed: () {
                      state.logItem(sourceId: hack.id, type: 'order', title: hack.title, calories: hack.calories, protein: hack.protein, image: hack.image);
                      showAppToast(context, 'Logged to today', description: '${hack.calories} cal · ${hack.protein}g protein');
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Log this'),
                    style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill))),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (isSaved) {
                        state.toggleSavedHack(hack.id);
                        showAppToast(context, 'Removed from saved items');
                      } else if (state.profile.email.isNotEmpty) {
                        state.toggleSavedHack(hack.id);
                        showAppToast(context, 'Saved for later');
                      } else {
                        _showSavePrompt(context, hack.id, hack.title);
                      }
                    },
                    icon: Icon(isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded),
                    label: Text(isSaved ? 'Saved' : 'Save it'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    onPressed: () => context.push('/search?q=${Uri.encodeComponent("something like ${hack.title}")}'),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Ask about this order'),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(color: AppColors.hackWhySurface, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Why this works', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(hack.why, style: AppText.bodySm(color: AppColors.mutedForeground).copyWith(height: 17 / 14)),
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

  /// SavePromptSheet — the only funnel in a no-paywall product. Sign-up happens
  /// inside the sheet, and "Not now" is genuinely free of consequence.
  void _showSavePrompt(BuildContext context, String hackId, String title) {
    showProductSheet(
      context,
      title: 'Keep this one?',
      description: 'Save this order and keep your day together.',
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.xl)),
              child: const Icon(Icons.bookmark_rounded, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'A free profile keeps your saved orders and everything you’ve tracked so far. No card, no subscription — Nutrition Platform doesn’t have one.',
              style: AppText.body(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSignUp(context, hackId);
                },
                child: const Text('Create a free profile'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Not now')),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignUp(BuildContext context, String hackId) {
    final formKey = GlobalKey<FormState>();
    final email = TextEditingController();
    final password = TextEditingController();
    showProductSheet(
      context,
      title: 'Create your profile',
      description: 'Your profile is stored on this device in this demo.',
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Free profile', style: AppText.h1()),
              const SizedBox(height: 4),
              Text('We’ll bring across the 4 things you’ve tracked today.', style: AppText.bodySm(color: AppColors.mutedForeground)),
              const SizedBox(height: 16),
              const Text('Email', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),
              const Text('Password', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextFormField(
                controller: password,
                obscureText: true,
                validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters' : null,
              ),
              const SizedBox(height: 4),
              Text('This prototype does not send credentials to a server.', style: AppText.caption()),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    final appState = context.read<AppState>();
                    appState.updateProfile(email: email.text);
                    if (!appState.savedHackIds.contains(hackId)) appState.toggleSavedHack(hackId);
                    Navigator.of(context).pop();
                    showAppToast(context, 'Saved, and your day came with you', description: '4 tracked items moved to your profile');
                  },
                  child: const Text('Create profile and save'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Not now')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
