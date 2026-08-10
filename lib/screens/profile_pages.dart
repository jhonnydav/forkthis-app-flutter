import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../data/fixtures.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_toast.dart';
import '../widgets/form_controls.dart';
import '../widgets/guided_experience.dart';
import '../widgets/primitives.dart';
import '../widgets/states.dart';

/// Profile detail surfaces. The You tab used to be a summary with one settings
/// page behind a gear; everything a user might want to *change* was one level
/// deeper than everything they could *see*. These are the destinations that
/// summary now links to, one concern each:
///
/// * [GoalContextScreen]     — FR-39, goal changeable without redoing onboarding
/// * [MeasurementsScreen]    — height/weight/units + a trend that isn't a streak
/// * [NotificationsInboxScreen] — the bell's sheet, as a real, linkable page
/// * [DataPrivacyScreen]     — FR-15 export + delete, within 3 taps of profile
/// * [AboutScreen]           — what this is and isn't, tour replay, legal

const activityLabels = {
  'sedentary': 'Sedentary',
  'lightly': 'Lightly active',
  'moderately': 'Moderately active',
  'very': 'Very active',
};

const surgicalLabels = {
  'prepare': 'Preparing for surgery',
  'recover': 'Recovery support',
  'none': 'General guidance',
  'prefer_not': 'Not specified',
};

const _surgicalHelp = {
  'prepare':
      'Protein-forward guidance and portions that build the habit early.',
  'recover': 'Smaller portions and texture-aware suggestions come first.',
  'none': 'Standard guidance, no surgical framing.',
  'prefer_not': 'We will keep suggestions general.',
};

const _dietaryOptions = [
  'High protein',
  'Lower carb',
  'Vegetarian',
  'Dairy light',
  'Gluten light',
  'Lower sodium',
];

/// ─────────────────────────────────────────────────────────────────────────
/// Goal & context — FR-39
/// ─────────────────────────────────────────────────────────────────────────
class GoalContextScreen extends StatelessWidget {
  const GoalContextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

    return AppShell(
      header: ScreenHeader(
        title: 'Goal and context',
        eyebrow: 'YOU',
        onBack: () => context.go('/you'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text('What we plan around', style: AppText.h1()),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Change any of this whenever it changes for you. Nothing here restarts your setup, and nothing you have already tracked is affected.',
            style: AppText.bodySm(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: AppSpace.xxl),
          SettingsGroup(
            title: 'Your goal',
            children: [
              SegmentRow<Goal>(
                title: 'Right now I am aiming to',
                value: profile.goal,
                values: Goal.values,
                labelFor: (goal) => goalLabel[goal]!,
                onChanged: (goal) {
                  state.updateProfile(goal: goal);
                  showAppToast(context, 'Goal updated to ${goalLabel[goal]!}');
                },
              ),
              const SizedBox(height: AppSpace.lg),
              SegmentRow<String>(
                title: 'Movement on a normal day',
                help: 'Used for portion guidance, not to set a target.',
                value: profile.activity,
                values: activityLabels.keys.toList(),
                labelFor: (key) => activityLabels[key]!,
                onChanged: (key) => state.updateProfile(activity: key),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SettingsGroup(
            title: 'Health context',
            note:
                'Optional, private to this device, and changeable at any time. It only shapes which suggestions come first.',
            children: [
              for (final entry in surgicalLabels.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: ChoiceTile(
                    label: entry.value,
                    description: _surgicalHelp[entry.key],
                    selected: profile.surgical == entry.key,
                    onTap: () => state.updateProfile(surgical: entry.key),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SettingsGroup(
            title: 'Food preferences',
            note: 'Recipes and orders matching these move up the list.',
            children: [
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: _dietaryOptions.map((preference) {
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
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          const DisclaimerNote(),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// Measurements — height, weight, units, and a plain trend
/// ─────────────────────────────────────────────────────────────────────────
class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  late final TextEditingController _weight;
  late final TextEditingController _heightPrimary;
  late final TextEditingController _heightInches;
  late String _units;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    _units = profile.units;
    _weight = TextEditingController(text: _weightFieldValue(profile));
    final (primary, inches) = _heightFieldValues(profile);
    _heightPrimary = TextEditingController(text: primary);
    _heightInches = TextEditingController(text: inches);
  }

  String _weightFieldValue(UserProfile profile) {
    if (profile.weightKg <= 0) return '';
    return _units == 'metric'
        ? profile.weightKg.round().toString()
        : (profile.weightKg / 0.45359237).round().toString();
  }

  (String, String) _heightFieldValues(UserProfile profile) {
    if (profile.heightCm <= 0) return ('', '');
    if (_units == 'metric') return (profile.heightCm.round().toString(), '');
    final totalInches = profile.heightCm / 2.54;
    final feet = totalInches ~/ 12;
    return (feet.toString(), (totalInches - feet * 12).round().toString());
  }

  @override
  void dispose() {
    _weight.dispose();
    _heightPrimary.dispose();
    _heightInches.dispose();
    super.dispose();
  }

  void _switchUnits(String next) {
    if (next == _units) return;
    // Convert what is already typed rather than blanking the fields — retyping
    // your own height because you tapped a toggle is a small insult.
    final profile = context.read<AppState>().profile;
    setState(() {
      _units = next;
      _weight.text = _weightFieldValue(profile);
      final (primary, inches) = _heightFieldValues(profile);
      _heightPrimary.text = primary;
      _heightInches.text = inches;
    });
  }

  void _save() {
    final state = context.read<AppState>();
    final weightInput = double.tryParse(_weight.text.trim());
    final primary = double.tryParse(_heightPrimary.text.trim());
    final inches = double.tryParse(_heightInches.text.trim()) ?? 0;

    double? heightCm;
    if (primary != null && primary > 0) {
      heightCm = _units == 'metric' ? primary : (primary * 12 + inches) * 2.54;
    }
    final weightKg = weightInput == null || weightInput <= 0
        ? null
        : (_units == 'metric' ? weightInput : weightInput * 0.45359237);

    state.updateProfile(units: _units, heightCm: heightCm);
    if (weightKg != null) state.recordWeight(weightKg);
    showAppToast(context, 'Measurements updated');
    context.go('/you');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final metric = _units == 'metric';
    final history = state.weightLog.reversed.toList();

    return AppShell(
      tabBar: false,
      header: ScreenHeader(
        title: 'Measurements',
        eyebrow: 'YOU',
        onBack: () => context.go('/you'),
      ),
      fixedAction: ElevatedButton(
        onPressed: _save,
        child: const Text('Save measurements'),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Text('Your numbers', style: AppText.h1()),
            const SizedBox(height: AppSpace.sm),
            Text(
              'Used to size portions sensibly. Update them when it is useful — there is no schedule to keep.',
              style: AppText.bodySm(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: AppSpace.xxl),
            SettingsGroup(
              title: 'Units',
              children: [
                SegmentRow<String>(
                  title: 'Show measurements in',
                  value: _units,
                  values: const ['imperial', 'metric'],
                  labelFor: (value) =>
                      value == 'imperial' ? 'US units' : 'Metric',
                  onChanged: _switchUnits,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            SettingsGroup(
              title: 'Height and weight',
              children: [
                Text('Height', style: AppText.label()),
                const SizedBox(height: AppSpace.sm),
                if (metric)
                  TextField(
                    controller: _heightPrimary,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: 'cm'),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _heightPrimary,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(suffixText: 'ft'),
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: TextField(
                          controller: _heightInches,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(suffixText: 'in'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpace.lg),
                Text('Weight', style: AppText.label()),
                const SizedBox(height: AppSpace.sm),
                TextField(
                  controller: _weight,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(suffixText: metric ? 'kg' : 'lb'),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Saving a weight adds a dated entry below. One per day — saving again replaces today rather than stacking.',
                  style: AppText.caption(),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            SettingsGroup(
              title: 'Recorded weights',
              children: [
                if (history.isEmpty)
                  const InlineNote(
                    icon: HugeIcons.strokeRoundedChartLineData01,
                    text:
                        'No entries yet. Save a weight above and it will start a simple list here — no charts to live up to.',
                  )
                else
                  for (final entry in history.take(12))
                    _WeightRow(
                      entry: entry,
                      metric: metric,
                      onRemove: () => state.removeWeightEntry(entry.recordedAt),
                    ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            const DisclaimerNote(),
          ],
        ),
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  final WeightEntry entry;
  final bool metric;
  final VoidCallback onRemove;

  const _WeightRow({
    required this.entry,
    required this.metric,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final value = metric
        ? '${entry.weightKg.round()} kg'
        : '${(entry.weightKg / 0.45359237).round()} lb';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(_formatDate(entry.recordedAt), style: AppText.bodySm()),
          ),
          Text(value, style: AppText.numericSm()),
          IconButton(
            tooltip: 'Remove entry',
            onPressed: onRemove,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// Notifications inbox — the bell's sheet as a real page
/// ─────────────────────────────────────────────────────────────────────────
class NotificationsInboxScreen extends StatelessWidget {
  const NotificationsInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.notifications;

    return AppShell(
      header: ScreenHeader(
        title: 'Notifications',
        eyebrow: 'YOU',
        onBack: () => context.go('/you'),
        trailing: items.isEmpty || state.unreadNotificationCount == 0
            ? null
            : TextButton(
                onPressed: state.markAllNotificationsRead,
                child: const Text('Mark all read'),
              ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          if (items.isEmpty)
            StateSurface.empty(
              icon: HugeIcons.strokeRoundedNotification01,
              title: 'Nothing waiting',
              body:
                  'Plan updates and gentle reminders land here. You can turn reminders off entirely in Settings — this page stays either way.',
              primaryLabel: 'Reminder settings',
              onPrimary: () => context.go('/you/settings'),
            )
          else ...[
            if (!state.profile.notifications)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.lg),
                child: InlineNote(
                  icon: HugeIcons.strokeRoundedNotificationOff01,
                  text:
                      'Reminders are paused. Past messages stay here; no new ones will arrive.',
                  background: AppColors.warmSurface,
                ),
              ),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                child: InkWell(
                  onTap: () => state.markNotificationRead(item.id),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpace.lg),
                    decoration: BoxDecoration(
                      color: item.read ? AppColors.card : AppColors.mint,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: item.read
                            ? AppColors.border
                            : AppColors.homeHeroBorder,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item.read
                                ? AppColors.borderStrong
                                : AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: AppText.label()),
                              if (item.body.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  item.body,
                                  style: AppText.bodySm(
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpace.sm),
                              Text(
                                _relativeTime(item.createdAt),
                                style: AppText.caption(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// Data & privacy — FR-15
/// ─────────────────────────────────────────────────────────────────────────
class DataPrivacyScreen extends StatelessWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return AppShell(
      header: ScreenHeader(
        title: 'Privacy and data',
        eyebrow: 'YOU',
        onBack: () => context.go('/you'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text('What is stored, and where', style: AppText.h1()),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Everything in this build lives on this device. Nothing is uploaded, and there is no account behind it.',
            style: AppText.bodySm(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: AppSpace.xxl),
          SettingsGroup(
            title: 'On this device',
            children: [
              DetailLine(label: 'Profile details', value: '1 record'),
              DetailLine(
                label: 'Saved items',
                value:
                    '${state.savedHackIds.length + state.savedRecipeIds.length}',
              ),
              DetailLine(label: 'Logged items', value: '${state.logs.length}'),
              DetailLine(
                label: 'Weight entries',
                value: '${state.weightLog.length}',
              ),
              DetailLine(
                label: 'Notifications',
                value: '${state.notifications.length}',
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SettingsGroup(
            title: 'Your copy',
            note:
                'Export gives you everything above as readable JSON on your clipboard.',
            children: [
              ActionRow(
                title: 'Export my data',
                subtitle: 'Copies a full JSON export to the clipboard',
                icon: HugeIcons.strokeRoundedDownload01,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: state.exportJson()));
                  showAppToast(context, 'Export copied to clipboard');
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SettingsGroup(
            title: 'Removing data',
            note:
                'Two different things: a reset keeps the app set up, deleting removes everything including your setup.',
            children: [
              ActionRow(
                title: 'Reset tracked data',
                subtitle: 'Clears logs and saves, keeps the app set up',
                icon: HugeIcons.strokeRoundedRefresh,
                onTap: () => _confirm(
                  context,
                  title: 'Reset tracked data?',
                  body:
                      'This clears saved items, logged meals, weights, and notifications on this device. Your goal and measurements stay.',
                  confirmLabel: 'Reset data',
                  onConfirm: () {
                    context.read<AppState>().clearLocalData();
                    context.go('/you');
                    showAppToast(context, 'Tracked data reset');
                  },
                ),
              ),
              ActionRow(
                title: 'Delete everything',
                subtitle: 'Removes all data and returns to setup',
                icon: HugeIcons.strokeRoundedDelete02,
                destructive: true,
                onTap: () => _confirm(
                  context,
                  title: 'Delete everything?',
                  body:
                      'This removes all data on this device, including your goal, measurements, and health context, and returns you to setup. It cannot be undone.',
                  confirmLabel: 'Delete everything',
                  onConfirm: () {
                    context.read<AppState>().deleteEverything();
                    context.go('/onboarding?step=0');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              TextButton(
                onPressed: () => context.go('/legal/privacy'),
                child: const Text('Privacy policy'),
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
}

Future<void> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required VoidCallback onConfirm,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.destructive,
            foregroundColor: AppColors.destructiveForeground,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) onConfirm();
}

/// ─────────────────────────────────────────────────────────────────────────
/// About — scope, boundaries, tour replay, legal
/// ─────────────────────────────────────────────────────────────────────────
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      header: ScreenHeader(
        title: 'About',
        eyebrow: 'YOU',
        onBack: () => context.go('/you'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text('Food that works in real life', style: AppText.h1()),
          const SizedBox(height: AppSpace.md),
          Text(
            'ForkThis! assumes you are going to eat out, get busy, and miss days. That is the normal case it is built around, not the exception it apologises for.',
            style: AppText.body(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: AppSpace.xxl),
          SettingsGroup(
            title: 'What it does',
            children: const [
              DetailLine(label: 'Tells you what to order', value: 'Eat Out'),
              DetailLine(label: 'Gives you the recipe', value: 'Cook'),
              DetailLine(label: 'Keeps a light record', value: 'Track'),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SettingsGroup(
            title: 'What it does not do',
            note:
                'These are deliberate limits, not features that are missing yet.',
            children: [
              const InlineNote(
                icon: HugeIcons.strokeRoundedStethoscope,
                text:
                    'It does not give medical advice, diagnose anything, or tell you what to do about symptoms, medication, or a recovery complication. Your care team owns those.',
              ),
              const SizedBox(height: AppSpace.sm),
              const InlineNote(
                icon: HugeIcons.strokeRoundedTarget02,
                text:
                    'Momentum points and badges celebrate useful actions. They do not reset into shame, rank your body, or turn missed days into failure.',
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SettingsGroup(
            title: 'Getting around',
            children: [
              ActionRow(
                title: 'Replay the app tour',
                subtitle: 'The same three steps as your first run',
                icon: HugeIcons.strokeRoundedPlay,
                onTap: () => showGuidedTour(context, replay: true),
              ),
              ActionRow(
                title: 'Help and boundaries',
                subtitle: 'How to use it, and when to ask your care team',
                icon: HugeIcons.strokeRoundedHelpCircle,
                onTap: () => context.go('/help'),
              ),
              ActionRow(
                title: 'Ask a question',
                subtitle: 'Answers drawn only from this app\'s own guidance',
                icon: HugeIcons.strokeRoundedMessage01,
                onTap: () => context.go('/ask'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SettingsGroup(
            title: 'Legal',
            children: [
              ActionRow(
                title: 'Privacy policy',
                icon: HugeIcons.strokeRoundedShieldKey,
                onTap: () => context.go('/legal/privacy'),
              ),
              ActionRow(
                title: 'Terms of use',
                icon: HugeIcons.strokeRoundedFile01,
                onTap: () => context.go('/legal/terms'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          Center(
            child: Text(
              'Prototype build · design review only',
              style: AppText.caption(),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          const DisclaimerNote(),
        ],
      ),
    );
  }
}

String _relativeTime(DateTime time) {
  final difference = DateTime.now().difference(time);
  if (difference.inMinutes < 1) return 'Now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  return '${difference.inDays}d ago';
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final today = DateTime.now();
  if (date.year == today.year &&
      date.month == today.month &&
      date.day == today.day) {
    return 'Today';
  }
  return '${months[date.month - 1]} ${date.day}';
}
