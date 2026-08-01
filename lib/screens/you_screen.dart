import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/fixtures.dart';
import '../data/recipes.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_toast.dart';
import '../widgets/product_sheet.dart';

/// Ported from `YouScreen` in `../app/src/screens/NotBuilt.tsx` (S-34–S-38).
class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.where((p) => p.isNotEmpty).map((p) => p[0]).join();
    return letters.isEmpty
        ? 'U'
        : letters.substring(0, letters.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final savedCount = state.savedHackIds.length + state.savedRecipeIds.length;

    return AppShell(
      child: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR SPACE',
                          style: AppText.eyebrow(color: AppColors.primary),
                        ),
                        const SizedBox(height: 8),
                        Text('Built around your life', style: AppText.h1()),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(
                            'Your goals and preferences stay visible, adjustable, and private.',
                            style: AppText.bodySm(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      onPressed: () => _openSettings(context),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                onTap: () => _openProfile(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(-0.6, -1),
                      end: Alignment(0.6, 1),
                      colors: [
                        AppColors.primary,
                        AppColors.blueberry,
                        AppColors.success,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _initials(state.profile.name),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.profile.name,
                              style: AppText.h2(color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${goalLabel[state.profile.goal]} · ${state.profile.units == "imperial" ? "US units" : "Metric"}',
                              style: AppText.caption(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR PLAN',
                    style: AppText.eyebrow(color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Text('What guides recommendations', style: AppText.h2()),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                children: [
                  _MenuRow(
                    icon: Icons.monitor_weight_outlined,
                    iconBg: AppColors.warmSurface,
                    title: goalLabel[state.profile.goal]!,
                    subtitle: 'Tap to adjust your goal',
                    onTap: () => context.go('/onboarding?step=5'),
                  ),
                  _MenuRow(
                    icon: Icons.bookmark_outline_rounded,
                    iconBg: AppColors.mint,
                    title: '$savedCount saved items',
                    subtitle: 'Orders and recipes for busy days',
                    onTap: () => _openSaved(context),
                  ),
                  _MenuRow(
                    icon: Icons.shield_outlined,
                    iconBg: AppColors.blueberrySurface,
                    title: 'Privacy and preferences',
                    subtitle: 'Stored locally on this device',
                    onTap: () => _openSettings(context),
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    final state = context.read<AppState>();
    final name = TextEditingController(text: state.profile.name);
    final email = TextEditingController(text: state.profile.email);
    final formKey = GlobalKey<FormState>();
    showProductSheet(
      context,
      title: 'Edit profile',
      description: 'Keep the basics current so the app feels like yours.',
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Name', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextFormField(
                controller: name,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    context.read<AppState>().updateProfile(
                      name: name.text,
                      email: email.text,
                    );
                    Navigator.of(context).pop();
                    showAppToast(context, 'Profile updated');
                  },
                  child: const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSaved(BuildContext context) {
    final state = context.read<AppState>();
    showProductSheet(
      context,
      title: 'Saved for later',
      description: 'Your restaurant orders and recipes in one place.',
      builder: (context) {
        if (state.savedHackIds.isEmpty && state.savedRecipeIds.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: [
                const Icon(
                  Icons.bookmark_outline_rounded,
                  size: 28,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nothing saved yet',
                  style: AppText.h2(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Save an order or recipe and it will appear here.',
                  style: AppText.bodySm(color: AppColors.mutedForeground),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 4),
          child: Column(
            children: [
              for (final id in state.savedHackIds)
                if (hackById(id) case final hack?)
                  _SavedRow(
                    image: hack.image,
                    title: hack.title,
                    subtitle: 'Restaurant order',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/hack/${hack.id}');
                    },
                  ),
              for (final id in state.savedRecipeIds)
                if (recipeById(id) case final recipe?)
                  _SavedRow(
                    image: recipe.image,
                    title: recipe.title,
                    subtitle: 'Recipe · ${recipe.time}',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/cook?recipe=${recipe.id}');
                    },
                  ),
            ],
          ),
        );
      },
    );
  }

  void _openSettings(BuildContext context) {
    showProductSheet(
      context,
      title: 'Settings',
      description: 'Control reminders and local product data.',
      builder: (context) => Consumer<AppState>(
        builder: (context, state, _) => Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_outlined, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Helpful reminders', style: AppText.h3()),
                        Text(
                          'Meal, water and recovery nudges',
                          style: AppText.caption(),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.profile.notifications,
                    onChanged: (v) {
                      state.updateProfile(notifications: v);
                      showAppToast(
                        context,
                        v ? 'Reminders enabled' : 'Reminders paused',
                      );
                    },
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                _openProfile(context);
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text('Account details', style: AppText.label()),
                    ),
                    const Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                _confirmClear(context);
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: AppColors.destructive,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Clear local profile and data',
                        style: AppText.label(color: AppColors.destructive),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear this device?'),
        content: const Text(
          'This removes your profile, saved items, and logs from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            onPressed: () {
              context.read<AppState>().clearLocalData();
              Navigator.of(context).pop();
              showAppToast(context, 'Local data cleared');
            },
            child: const Text('Clear data'),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool last;
  const _MenuRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h3()),
                  Text(subtitle, style: AppText.caption()),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedRow extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SavedRow({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Image.asset(
                image,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.h3(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(subtitle, style: AppText.caption()),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}
