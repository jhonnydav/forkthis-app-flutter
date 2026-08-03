import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../data/fixtures.dart';
import '../data/recipes.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_toast.dart';
import '../widgets/product_sheet.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  static const _activityLabels = {
    'sedentary': 'Sedentary',
    'lightly': 'Lightly active',
    'moderately': 'Moderately active',
    'very': 'Very active',
  };

  static const _surgicalLabels = {
    'prepare': 'Preparing for surgery',
    'recover': 'Recovery support',
    'none': 'General guidance',
  };

  String _initials(String name) {
    final letters = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .join();
    if (letters.isEmpty) return 'U';
    return letters.substring(0, letters.length.clamp(0, 2)).toUpperCase();
  }

  String _measurementSummary(UserProfile profile) {
    if (profile.heightCm <= 0 || profile.weightKg <= 0) {
      return profile.units == 'imperial' ? 'US units' : 'Metric units';
    }
    if (profile.units == 'metric') {
      return '${profile.heightCm.round()} cm · ${profile.weightKg.round()} kg';
    }
    final totalInches = profile.heightCm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches - feet * 12).round();
    final pounds = (profile.weightKg / 0.45359237).round();
    return '$feet ft $inches in · $pounds lb';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.2;
    final profile = state.profile;
    final saved = state.savedHackIds.length + state.savedRecipeIds.length;
    final calories = state.logs.fold<int>(
      0,
      (sum, item) => sum + item.calories,
    );
    final protein = state.logs.fold<int>(0, (sum, item) => sum + item.protein);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AppShell(
        scrollTitle: profile.name,
        scrollEyebrow: 'YOUR PROFILE',
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'YOUR PROFILE',
                            style: AppText.eyebrow(color: AppColors.accent),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => _openSettings(context),
                            tooltip: 'Settings',
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedSettings01,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 74,
                            height: 74,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                                width: 3,
                              ),
                            ),
                            child: Text(
                              _initials(profile.name),
                              style: AppText.h2(color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  style: AppText.h1(color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile.email.isEmpty
                                      ? 'Local profile on this device'
                                      : profile.email,
                                  style: AppText.bodySm(
                                    color: Colors.white.withValues(alpha: 0.68),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedShield01,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Stored locally',
                                  style: AppText.caption(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _openProfile(context),
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedEdit02,
                              size: 17,
                              color: AppColors.accent,
                            ),
                            label: Text(
                              'Edit profile',
                              style: AppText.label(color: AppColors.accent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR CONTEXT',
                    style: AppText.eyebrow(color: AppColors.primary),
                  ),
                  const SizedBox(height: 3),
                  Text('What shapes your recommendations', style: AppText.h2()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (largeText) ...[
                    _ContextTile(
                      icon: HugeIcons.strokeRoundedWeightScale,
                      label: 'Goal',
                      value: goalLabel[profile.goal]!,
                      tint: AppColors.warmSurface,
                      onTap: () => context.go('/onboarding?step=5'),
                    ),
                    const SizedBox(height: 10),
                    _ContextTile(
                      icon: HugeIcons.strokeRoundedWalking,
                      label: 'Activity',
                      value: _activityLabels[profile.activity]!,
                      tint: AppColors.mint,
                      onTap: () => _openProfile(context),
                    ),
                    const SizedBox(height: 10),
                    _ContextTile(
                      icon: HugeIcons.strokeRoundedFavourite,
                      label: 'Health context',
                      value: _surgicalLabels[profile.surgical]!,
                      tint: AppColors.coralSurface,
                      onTap: () => context.go('/onboarding?step=7'),
                    ),
                    const SizedBox(height: 10),
                    _ContextTile(
                      icon: HugeIcons.strokeRoundedSettings02,
                      label: 'Measurements',
                      value: _measurementSummary(profile),
                      tint: AppColors.blueberrySurface,
                      onTap: () => _openProfile(context),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _ContextTile(
                            icon: HugeIcons.strokeRoundedWeightScale,
                            label: 'Goal',
                            value: goalLabel[profile.goal]!,
                            tint: AppColors.warmSurface,
                            onTap: () => context.go('/onboarding?step=5'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ContextTile(
                            icon: HugeIcons.strokeRoundedWalking,
                            label: 'Activity',
                            value: _activityLabels[profile.activity]!,
                            tint: AppColors.mint,
                            onTap: () => _openProfile(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ContextTile(
                            icon: HugeIcons.strokeRoundedFavourite,
                            label: 'Health context',
                            value: _surgicalLabels[profile.surgical]!,
                            tint: AppColors.coralSurface,
                            onTap: () => context.go('/onboarding?step=7'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ContextTile(
                            icon: HugeIcons.strokeRoundedSettings02,
                            label: 'Measurements',
                            value: _measurementSummary(profile),
                            tint: AppColors.blueberrySurface,
                            onTap: () => _openProfile(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TODAY',
                    style: AppText.eyebrow(color: AppColors.primary),
                  ),
                  const SizedBox(height: 3),
                  Text('Your rhythm so far', style: AppText.h2()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TodayValue(value: '$calories', label: 'Calories'),
                    ),
                    Container(width: 1, height: 42, color: AppColors.border),
                    Expanded(
                      child: _TodayValue(
                        value: '${protein}g',
                        label: 'Protein',
                      ),
                    ),
                    Container(width: 1, height: 42, color: AppColors.border),
                    Expanded(
                      child: _TodayValue(
                        value: '${state.waterCups}/8',
                        label: 'Water',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
              child: Text(
                'LIBRARY & CONTROLS',
                style: AppText.eyebrow(color: AppColors.primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _MenuRow(
                      icon: HugeIcons.strokeRoundedBookmark02,
                      title: 'Saved library',
                      subtitle: '$saved recipes and restaurant orders',
                      onTap: () => _openSaved(context),
                    ),
                    _MenuRow(
                      icon: HugeIcons.strokeRoundedNotification01,
                      title: 'Helpful reminders',
                      subtitle: profile.notifications
                          ? 'Meal, water and recovery nudges are on'
                          : 'Reminders are paused',
                      onTap: () => _openSettings(context),
                    ),
                    _MenuRow(
                      icon: HugeIcons.strokeRoundedShield01,
                      title: 'Privacy and device data',
                      subtitle: 'Review or clear information stored here',
                      onTap: () => _openSettings(context),
                      last: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    final pageContext = context;
    final state = context.read<AppState>();
    final name = TextEditingController(text: state.profile.name);
    final email = TextEditingController(text: state.profile.email);
    final formKey = GlobalKey<FormState>();
    var units = state.profile.units;
    var activity = state.profile.activity;

    showProductSheet(
      context,
      title: 'Edit profile',
      description: 'Keep the context that shapes your recommendations current.',
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name', style: AppText.label()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => value == null || value.trim().length < 2
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 16),
                Text('Email', style: AppText.label()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    return value.contains('@') ? null : 'Enter a valid email';
                  },
                ),
                const SizedBox(height: 22),
                Text('Measurements', style: AppText.label()),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _SheetChoice(
                        label: 'US units',
                        selected: units == 'imperial',
                        onTap: () => setSheetState(() => units = 'imperial'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SheetChoice(
                        label: 'Metric',
                        selected: units == 'metric',
                        onTap: () => setSheetState(() => units = 'metric'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text('Activity level', style: AppText.label()),
                const SizedBox(height: 8),
                for (final option in _activityLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SheetChoice(
                      label: option.value,
                      selected: activity == option.key,
                      onTap: () => setSheetState(() => activity = option.key),
                    ),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      state.updateProfile(
                        name: name.text.trim(),
                        email: email.text.trim(),
                        units: units,
                        activity: activity,
                      );
                      Navigator.of(sheetContext).pop();
                      showAppToast(pageContext, 'Profile updated');
                    },
                    child: const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      name.dispose();
      email.dispose();
    });
  }

  void _openSaved(BuildContext context) {
    final state = context.read<AppState>();
    showProductSheet(
      context,
      title: 'Saved library',
      description: 'Recipes and restaurant orders you wanted to keep close.',
      builder: (sheetContext) {
        if (state.savedHackIds.isEmpty && state.savedRecipeIds.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedBookmark02,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Nothing saved yet', style: AppText.h2()),
                const SizedBox(height: 6),
                Text(
                  'Save an order or recipe and it will appear here.',
                  textAlign: TextAlign.center,
                  style: AppText.bodySm(color: AppColors.mutedForeground),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              for (final id in state.savedHackIds)
                if (hackById(id) case final hack?)
                  _SavedRow(
                    image: hack.image,
                    title: hack.title,
                    subtitle: 'Restaurant order',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.push('/hack/${hack.id}');
                    },
                  ),
              for (final id in state.savedRecipeIds)
                if (recipeById(id) case final recipe?)
                  _SavedRow(
                    image: recipe.image,
                    title: recipe.title,
                    subtitle: '${recipe.time} · ${recipe.protein}g protein',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.push('/cook/recipe/${recipe.id}');
                    },
                  ),
            ],
          ),
        );
      },
    );
  }

  void _openSettings(BuildContext context) {
    final pageContext = context;
    showProductSheet(
      context,
      title: 'Settings',
      description: 'Control reminders and information stored on this device.',
      builder: (sheetContext) => Consumer<AppState>(
        builder: (context, state, _) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedNotification01,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
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
                      onChanged: (value) {
                        state.updateProfile(notifications: value);
                        showAppToast(
                          pageContext,
                          value ? 'Reminders enabled' : 'Reminders paused',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _SettingsAction(
                icon: HugeIcons.strokeRoundedUserCircle02,
                title: 'Account details',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openProfile(pageContext);
                },
              ),
              const SizedBox(height: 10),
              _SettingsAction(
                icon: HugeIcons.strokeRoundedDelete01,
                title: 'Clear local profile and data',
                destructive: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmClear(pageContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear this device?'),
        content: const Text(
          'This removes your profile, saved items, logs, and notifications from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            onPressed: () {
              context.read<AppState>().clearLocalData();
              Navigator.of(dialogContext).pop();
              context.go('/onboarding?step=0');
              showAppToast(context, 'Local data cleared');
            },
            child: const Text('Clear data'),
          ),
        ],
      ),
    );
  }
}

class _ContextTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color tint;
  final VoidCallback onTap;
  const _ContextTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        constraints: const BoxConstraints(minHeight: 136),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: HugeIcon(icon: icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(label.toUpperCase(), style: AppText.eyebrow()),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppText.h3(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayValue extends StatelessWidget {
  final String value;
  final String label;
  const _TodayValue({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppText.numericSm()),
        const SizedBox(height: 3),
        Text(label, style: AppText.caption()),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool last;
  const _MenuRow({
    required this.icon,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            HugeIcon(icon: icon, size: 21, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h3()),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.caption()),
                ],
              ),
            ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SheetChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppText.label(color: AppColors.primary),
              ),
            ),
            if (selected)
              const HugeIcon(
                icon: HugeIcons.strokeRoundedTick01,
                size: 17,
                color: AppColors.primary,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(10),
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
                  image,
                  width: 58,
                  height: 58,
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

class _SettingsAction extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;
  const _SettingsAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.destructive : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            HugeIcon(icon: icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: AppText.label(color: color)),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
