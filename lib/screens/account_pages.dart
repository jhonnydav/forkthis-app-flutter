import 'package:flutter/material.dart';
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
import '../widgets/guided_experience.dart';
import '../widgets/states.dart';

class SavedLibraryScreen extends StatefulWidget {
  const SavedLibraryScreen({super.key});

  @override
  State<SavedLibraryScreen> createState() => _SavedLibraryScreenState();
}

class _SavedLibraryScreenState extends State<SavedLibraryScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allHacks = state.savedHackIds
        .map(hackById)
        .whereType<FastHack>()
        .toList();
    final allRecipes = state.savedRecipeIds
        .map(recipeById)
        .whereType<Recipe>()
        .toList();
    final savedHacks = _filter == 'recipes' ? <FastHack>[] : allHacks;
    final savedRecipes = _filter == 'orders' ? <Recipe>[] : allRecipes;
    final total = allHacks.length + allRecipes.length;
    // Whether *this tab* is empty, as distinct from having saved nothing at
    // all — a filter that hides your items should say so, not imply you never
    // saved anything.
    final tabEmpty = savedHacks.isEmpty && savedRecipes.isEmpty;

    return AppShell(
      header: ScreenHeader(
        title: 'Saved',
        eyebrow: 'YOU',
        onBack: () => context.go('/you'),
      ),
      child: !state.loaded
          ? const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: SkeletonListRows(count: 5),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Text('Everything worth keeping', style: AppText.h1()),
                const SizedBox(height: 8),
                Text(
                  total == 0
                      ? 'Save a restaurant order or a recipe and it lands here, ready for the next time you need it.'
                      : 'Restaurant orders and recipes stay together so dinner decisions are easier later.',
                  style: AppText.bodySm(color: AppColors.mutedForeground),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  children: [
                    _FilterChip(
                      label: 'All${total > 0 ? ' · $total' : ''}',
                      value: 'all',
                      active: _filter,
                      onTap: _setFilter,
                    ),
                    _FilterChip(
                      label:
                          'Orders${allHacks.isNotEmpty ? ' · ${allHacks.length}' : ''}',
                      value: 'orders',
                      active: _filter,
                      onTap: _setFilter,
                    ),
                    _FilterChip(
                      label:
                          'Recipes${allRecipes.isNotEmpty ? ' · ${allRecipes.length}' : ''}',
                      value: 'recipes',
                      active: _filter,
                      onTap: _setFilter,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (tabEmpty && total > 0)
                  // Saved things exist, just not in this filter.
                  StateSurface.noResults(
                    title: _filter == 'orders'
                        ? 'No saved orders yet'
                        : 'No saved recipes yet',
                    body: _filter == 'orders'
                        ? 'You have saved recipes, but no restaurant orders so far. Eat Out is where those come from.'
                        : 'You have saved restaurant orders, but no recipes so far. Cook is where those come from.',
                    primaryLabel: _filter == 'orders' ? 'Browse Eat Out' : 'Browse Cook',
                    onPrimary: () =>
                        context.go(_filter == 'orders' ? '/eat-out' : '/cook'),
                    secondaryLabel: 'Show all saved',
                    onSecondary: () => _setFilter('all'),
                  )
                else if (tabEmpty)
                  StateSurface.empty(
                    icon: HugeIcons.strokeRoundedBookmark02,
                    title: 'Nothing saved yet',
                    body:
                        'Tap the bookmark on any restaurant order or recipe. Saved items work offline and stay on this device.',
                    primaryLabel: 'Find an order',
                    onPrimary: () => context.go('/eat-out'),
                    secondaryLabel: 'Browse recipes',
                    onSecondary: () => context.go('/cook'),
                  )
                else ...[
                  if (savedHacks.isNotEmpty) ...[
                    _SectionLabel(
                      label: 'RESTAURANT ORDERS',
                      count: savedHacks.length,
                    ),
                    for (final hack in savedHacks)
                      _SavedItem(
                        image: hack.image,
                        title: hack.title,
                        subtitle:
                            '${restaurantById(hack.restaurantId)?.name ?? 'Restaurant order'} · ${hack.calories} cal · ${hack.protein}g protein',
                        onTap: () => context.push('/hack/${hack.id}'),
                        onRemove: () => _removeHack(state, hack),
                      ),
                  ],
                  if (savedRecipes.isNotEmpty) ...[
                    if (savedHacks.isNotEmpty) const SizedBox(height: 12),
                    _SectionLabel(
                      label: 'RECIPES',
                      count: savedRecipes.length,
                    ),
                    for (final recipe in savedRecipes)
                      _SavedItem(
                        image: recipe.image,
                        title: recipe.title,
                        subtitle:
                            '${recipe.time} · ${recipe.calories} cal · ${recipe.protein}g protein',
                        onTap: () => context.push('/cook/recipe/${recipe.id}'),
                        onRemove: () => _removeRecipe(state, recipe),
                      ),
                  ],
                ],
              ],
            ),
    );
  }

  /// Removal is undoable — a saved item is a small thing to lose to a mis-tap,
  /// and an undo costs less than a confirmation dialog on every row.
  void _removeHack(AppState state, FastHack hack) {
    state.toggleSavedHack(hack.id);
    showAppToast(
      context,
      'Removed from saved',
      actionLabel: 'Undo',
      onAction: () => state.toggleSavedHack(hack.id),
    );
  }

  void _removeRecipe(AppState state, Recipe recipe) {
    state.toggleSavedRecipe(recipe.id);
    showAppToast(
      context,
      'Removed from saved',
      actionLabel: 'Undo',
      onAction: () => state.toggleSavedRecipe(recipe.id),
    );
  }

  void _setFilter(String value) => setState(() => _filter = value);
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        '$label · $count',
        style: AppText.eyebrow(color: AppColors.primary),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  String _units = 'imperial';
  String _activity = 'lightly';

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    _name = TextEditingController(text: profile.name);
    _email = TextEditingController(text: profile.email);
    _units = profile.units;
    _activity = profile.activity;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      tabBar: false,
      header: ScreenHeader(
        title: 'Edit profile',
        eyebrow: 'YOU',
        onBack: () => context.go('/you'),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text('Keep your context current', style: AppText.h1()),
            const SizedBox(height: 8),
            Text(
              'This prototype stores profile details on this device only.',
              style: AppText.bodySm(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name', style: AppText.label()),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text('Email', style: AppText.label()),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      return value.contains('@') ? null : 'Enter a valid email';
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Units', style: AppText.label()),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _Choice(
                          label: 'US units',
                          selected: _units == 'imperial',
                          onTap: () => setState(() => _units = 'imperial'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Choice(
                          label: 'Metric',
                          selected: _units == 'metric',
                          onTap: () => setState(() => _units = 'metric'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Activity', style: AppText.label()),
                  const SizedBox(height: 8),
                  for (final option in const {
                    'sedentary': 'Sedentary',
                    'lightly': 'Lightly active',
                    'moderately': 'Moderately active',
                    'very': 'Very active',
                  }.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _Choice(
                        label: option.value,
                        selected: _activity == option.key,
                        onTap: () => setState(() => _activity = option.key),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save changes'),
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

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AppState>().updateProfile(
      name: _name.text.trim(),
      email: _email.text.trim(),
      units: _units,
      activity: _activity,
    );
    showAppToast(context, 'Profile updated');
    context.go('/you');
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _preferences = [
    'High protein',
    'Lower carb',
    'Vegetarian',
    'Dairy light',
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

    return AppShell(
      header: ScreenHeader(
        title: 'Settings',
        eyebrow: 'YOU',
        onBack: () => context.go('/you'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text('Controls that matter', style: AppText.h1()),
          const SizedBox(height: 8),
          Text(
            'Change recommendations, reminders, privacy, and local data from one place.',
            style: AppText.bodySm(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 22),
          _SettingsGroup(
            title: 'Recommendations',
            children: [
              _SegmentRow<Goal>(
                title: 'Goal',
                value: profile.goal,
                values: Goal.values,
                labelFor: (goal) => goalLabel[goal]!,
                onChanged: (goal) => state.updateProfile(goal: goal),
              ),
              const SizedBox(height: 14),
              Text('Food preferences', style: AppText.label()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _preferences.map((preference) {
                  final selected = profile.dietaryPreferences.contains(
                    preference,
                  );
                  return FilterChip(
                    label: Text(preference),
                    selected: selected,
                    onSelected: (_) {
                      final next = selected
                          ? profile.dietaryPreferences
                                .where((item) => item != preference)
                                .toList()
                          : [...profile.dietaryPreferences, preference];
                      state.updateProfile(dietaryPreferences: next);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              _ActionRow(
                title: 'Health context and full preferences',
                icon: HugeIcons.strokeRoundedFavourite,
                onTap: () => context.go('/you/goal'),
              ),
              _ActionRow(
                title: 'Measurements and units',
                icon: HugeIcons.strokeRoundedRuler,
                onTap: () => context.go('/you/measurements'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            title: 'Reminders and location',
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('Helpful reminders', style: AppText.h3()),
                subtitle: Text(
                  'Meal, water and recovery nudges',
                  style: AppText.caption(),
                ),
                value: profile.notifications,
                onChanged: (value) {
                  state.setReminderNotifications(value);
                  showAppToast(
                    context,
                    value ? 'Reminders enabled' : 'Reminders paused',
                  );
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('Location-based sorting', style: AppText.h3()),
                subtitle: Text(
                  'Use nearby places when browsing Eat Out',
                  style: AppText.caption(),
                ),
                value: profile.locationEnabled,
                onChanged: (value) =>
                    state.updateProfile(locationEnabled: value),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Reminder time', style: AppText.h3()),
                subtitle: Text(profile.reminderTime, style: AppText.caption()),
                trailing: const HugeIcon(
                  icon: HugeIcons.strokeRoundedClock01,
                  size: 20,
                ),
                onTap: () => _pickReminderTime(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            title: 'Account and data',
            children: [
              _ActionRow(
                title: 'Edit profile',
                icon: HugeIcons.strokeRoundedUserCircle02,
                onTap: () => context.go('/you/edit'),
              ),
              _ActionRow(
                title: 'Replay app tour',
                icon: HugeIcons.strokeRoundedPlay,
                onTap: () => showGuidedTour(context, replay: true),
              ),
              _ActionRow(
                title: 'Help and boundaries',
                icon: HugeIcons.strokeRoundedInformationCircle,
                onTap: () => context.go('/help'),
              ),
              _ActionRow(
                title: 'Notifications',
                icon: HugeIcons.strokeRoundedNotification01,
                onTap: () => context.go('/you/notifications'),
              ),
              _ActionRow(
                title: 'Privacy and data',
                icon: HugeIcons.strokeRoundedShieldKey,
                onTap: () => context.go('/you/privacy'),
              ),
              _ActionRow(
                title: 'About this app',
                icon: HugeIcons.strokeRoundedInformationCircle,
                onTap: () => context.go('/you/about'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () => context.go('/legal/privacy'),
                child: const Text('Privacy'),
              ),
              TextButton(
                onPressed: () => context.go('/legal/terms'),
                child: const Text('Terms'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final state = context.read<AppState>();
    final parts = state.profile.reminderTime.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 18,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 30 : 30,
      ),
    );
    if (picked == null || !context.mounted) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    state.updateProfile(reminderTime: value);
    showAppToast(context, 'Reminder time updated');
  }


}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String active;
  final ValueChanged<String> onTap;
  const _FilterChip({
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: active == value,
      onSelected: (_) => onTap(value),
    );
  }
}

class _SavedItem extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _SavedItem({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onRemove,
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
                  width: 68,
                  height: 68,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: AppText.caption()),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove from saved',
                onPressed: onRemove,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedBookmarkRemove01,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppText.label(
            color: selected
                ? AppColors.primaryForeground
                : AppColors.foreground,
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: AppText.eyebrow(color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SegmentRow<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<T> values;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;
  const _SegmentRow({
    required this.title,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.label()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (item) => ChoiceChip(
                  label: Text(labelFor(item)),
                  selected: item == value,
                  onSelected: (_) => onChanged(item),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String title;
  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  const _ActionRow({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: HugeIcon(icon: icon, size: 21, color: AppColors.primary),
      title: Text(title, style: AppText.h3()),
      trailing: const HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        size: 18,
      ),
      onTap: onTap,
    );
  }
}
