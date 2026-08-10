import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../product.dart';
import '../data/fixtures.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../widgets/app_notifications.dart';
import '../widgets/app_shell.dart';

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
    'prefer_not': 'Not specified',
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
    final profile = state.profile;
    final saved = state.savedHackIds.length + state.savedRecipeIds.length;
    final unread = state.unreadNotificationCount;
    final calories = state.logs.fold<int>(
      0,
      (sum, item) => sum + item.calories,
    );
    final protein = state.logs.fold<int>(0, (sum, item) => sum + item.protein);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AppShell(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 36),
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _ProfileHero(
                      name: profile.name,
                      email: profile.email,
                      initials: _initials(profile.name),
                      goal: goalLabel[profile.goal]!,
                      measurements: _measurementSummary(profile),
                      onEdit: () => context.go('/you/edit'),
                      onAsk: () => context.go('/ask'),
                    )
                    .animate()
                    .fadeIn(duration: 240.ms)
                    .slideY(begin: 0.04, end: 0, duration: 240.ms),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _DailySnapshot(
                    calories: calories,
                    protein: protein,
                    water: state.waterCups,
                    onTrack: () => context.go('/track'),
                  )
                  .animate()
                  .fadeIn(duration: 240.ms, delay: 60.ms)
                  .slideY(begin: 0.04, end: 0, duration: 240.ms, delay: 60.ms),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _MomentumCard(
                    points: state.momentumPoints,
                    streakDays: state.streakDays,
                    longestStreakDays: state.longestStreakDays,
                    badges: state.earnedBadges,
                    onOpen: () => context.go('/track'),
                  )
                  .animate()
                  .fadeIn(duration: 240.ms, delay: 110.ms)
                  .slideY(
                    begin: 0.04,
                    end: 0,
                    duration: 240.ms,
                    delay: 110.ms,
                  ),
            ),
            _SectionHeader(
              eyebrow: 'YOUR CONTEXT',
              title: 'What shapes your recommendations',
              top: 32,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MenuGroup(
                children: [
                  _MenuRow(
                    icon: HugeIcons.strokeRoundedWeightScale,
                    title: goalLabel[profile.goal]!,
                    subtitle:
                        '${_activityLabels[profile.activity]!} · ${_surgicalLabels[profile.surgical] ?? 'Not specified'}',
                    onTap: () => context.go('/you/goal'),
                  ),
                  _MenuRow(
                    icon: HugeIcons.strokeRoundedRuler,
                    title: _measurementSummary(profile),
                    subtitle: profile.units == 'imperial'
                        ? 'US units'
                        : 'Metric units',
                    onTap: () => context.go('/you/measurements'),
                    last: true,
                  ),
                ],
              ),
            ),
            _SectionHeader(
              eyebrow: 'READY WHEN YOU NEED IT',
              title: 'Saved meals and app controls',
              top: 28,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MenuGroup(
                children: [
                  _MenuRow(
                    icon: HugeIcons.strokeRoundedBookmark02,
                    title: 'Saved library',
                    subtitle: saved == 0
                        ? 'Nothing saved yet'
                        : '$saved saved ${saved == 1 ? 'item' : 'items'}',
                    onTap: () => context.go('/you/saved'),
                  ),
                  _MenuRow(
                    icon: HugeIcons.strokeRoundedNotification01,
                    title: 'Notifications',
                    subtitle: unread == 0
                        ? 'No new messages'
                        : '$unread unread',
                    onTap: () => context.go('/you/notifications'),
                  ),
                  _MenuRow(
                    icon: HugeIcons.strokeRoundedSettings01,
                    title: 'Settings',
                    subtitle: profile.notifications
                        ? 'Reminders on · reminder at ${profile.reminderTime}'
                        : 'Reminders paused',
                    onTap: () => context.go('/you/settings'),
                  ),
                  _MenuRow(
                    icon: HugeIcons.strokeRoundedShield01,
                    title: 'Privacy and data',
                    subtitle: 'Export, reset, or delete what is stored here',
                    onTap: () => context.go('/you/privacy'),
                  ),
                  _MenuRow(
                    icon: HugeIcons.strokeRoundedRefresh,
                    title: 'Restart demo',
                    subtitle: 'Start the onboarding flow again',
                    onTap: () {
                      context.read<AppState>().restartDemoFromOnboarding();
                      context.go('/onboarding?step=0');
                    },
                  ),
                  _MenuRow(
                    icon: HugeIcons.strokeRoundedLogout03,
                    title: 'Sign out',
                    subtitle: state.accountEmail.isEmpty
                        ? 'Return to login'
                        : state.accountEmail,
                    destructive: true,
                    onTap: () {
                      context.read<AppState>().signOut();
                      context.go('/login');
                    },
                  ),
                  _MenuRow(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    title: 'About and help',
                    subtitle:
                        'What this app does, its limits, and the app tour',
                    onTap: () => context.go('/you/about'),
                    last: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String name;
  final String email;
  final String initials;
  final String goal;
  final String measurements;
  final VoidCallback onEdit;
  final VoidCallback onAsk;
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.initials,
    required this.goal,
    required this.measurements,
    required this.onEdit,
    required this.onAsk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -54,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: AppColors.primaryForeground.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryForeground.withValues(
                          alpha: 0.26,
                        ),
                        width: 3,
                      ),
                    ),
                    child: Text(
                      initials,
                      style: AppText.h2(color: AppColors.textPrimary),
                    ),
                  ),
                  const Spacer(),
                  _HeroPillButton(
                    icon: HugeIcons.strokeRoundedSparkles,
                    label: 'Ask',
                    onTap: onAsk,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryForeground.withValues(
                        alpha: 0.14,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const NotificationBell(
                      color: AppColors.primaryForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                name,
                style: AppText.headline(
                  36,
                  height: 36,
                  color: AppColors.primaryForeground,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                email.isEmpty ? 'Local profile on this device' : email,
                style: AppText.bodySm(
                  color: AppColors.primaryForeground.withValues(alpha: 0.78),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroChip(label: goal),
                  _HeroChip(label: measurements),
                  const _HeroChip(label: 'Stored locally'),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryForeground,
                    foregroundColor: AppColors.primary,
                  ),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedEdit02,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: const Text('Edit profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPillButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  const _HeroPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryForeground.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, size: 17, color: AppColors.primaryForeground),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppText.label(color: AppColors.primaryForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;
  const _HeroChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryForeground.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.primaryForeground.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        label,
        style: AppText.caption(
          color: AppColors.primaryForeground.withValues(alpha: 0.86),
        ),
      ),
    );
  }
}

class _DailySnapshot extends StatelessWidget {
  final int calories;
  final int protein;
  final int water;
  final VoidCallback onTrack;
  const _DailySnapshot({
    required this.calories,
    required this.protein,
    required this.water,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTrack,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'TODAY',
                  style: AppText.kicker(color: AppColors.textPrimary),
                ),
                const Spacer(),
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricFigure(value: '$calories', label: 'Calories'),
                ),
                _MetricDivider(),
                Expanded(
                  child: _MetricFigure(value: '${protein}g', label: 'Protein'),
                ),
                _MetricDivider(),
                Expanded(
                  child: _MetricFigure(value: '$water/8', label: 'Water'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentumCard extends StatelessWidget {
  final int points;
  final int streakDays;
  final int longestStreakDays;
  final List<MomentumBadge> badges;
  final VoidCallback onOpen;

  const _MomentumCard({
    required this.points,
    required this.streakDays,
    required this.longestStreakDays,
    required this.badges,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final visibleBadges = badges.isEmpty
        ? momentumBadgeCatalog.take(2).toList()
        : badges.take(4).toList();
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$productName MOMENTUM',
                  style: AppText.kicker(color: AppColors.primary),
                ),
                const Spacer(),
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _MomentumFigure(
                    value: '$points',
                    label: 'points',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MomentumFigure(
                    value: '$streakDays',
                    label: 'day streak',
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              badges.isEmpty
                  ? 'Save a pick, log a meal, or come back after a gap to unlock your first badge.'
                  : 'Small choices are adding up. Best streak: $longestStreakDays days. Missed days never erase this.',
              style: AppText.bodySm(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (index, badge) in visibleBadges.indexed) ...[
                    if (index > 0) const SizedBox(width: 10),
                    _BadgeMedallion(
                      badge: badge,
                      earned: badges.any((item) => item.id == badge.id),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeMedallion extends StatelessWidget {
  final MomentumBadge badge;
  final bool earned;

  const _BadgeMedallion({required this.badge, required this.earned});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.description,
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            Semantics(
              image: true,
              label: badge.title,
              child: Opacity(
                opacity: earned ? 1 : 0.44,
                child: _ProfileBadgeShield(
                  tier: badge.tier,
                  icon: _badgeIcon(badge.id),
                  label: badge.unlockAt > 1 ? '${badge.unlockAt}' : '',
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              style: AppText.caption(
                color: earned ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentumFigure extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MomentumFigure({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
      decoration: BoxDecoration(
        color: AppColors.highlight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.heroStat(color: color)),
          Text(label, style: AppText.caption(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ProfileBadgeShield extends StatelessWidget {
  final String tier;
  final List<List<dynamic>> icon;
  final String label;

  const _ProfileBadgeShield({
    required this.tier,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 86,
      child: CustomPaint(
        painter: _ProfileBadgeShieldPainter(_tierColor(tier)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: icon, size: 24, color: AppColors.primary),
              if (label.isNotEmpty)
                Text(label, style: AppText.label(color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBadgeShieldPainter extends CustomPainter {
  final Color color;
  const _ProfileBadgeShieldPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 3)
      ..lineTo(size.width - 8, size.height * 0.25)
      ..lineTo(size.width - 12, size.height * 0.67)
      ..quadraticBezierTo(
        size.width / 2,
        size.height - 3,
        12,
        size.height * 0.67,
      )
      ..lineTo(8, size.height * 0.25)
      ..close();
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.22), 7, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, size.height - 22, size.width - 16, 18),
        const Radius.circular(5),
      ),
      Paint()..color = AppColors.secondary,
    );
  }

  @override
  bool shouldRepaint(covariant _ProfileBadgeShieldPainter oldDelegate) =>
      oldDelegate.color != color;
}

Color _tierColor(String tier) {
  switch (tier) {
    case 'silver':
      return const Color(0xFFC8D2D5);
    case 'diamond':
      return const Color(0xFFFF8A3D);
    case 'gold':
      return AppColors.accent;
    case 'bronze':
    default:
      return AppColors.redLight;
  }
}

List<List<dynamic>> _badgeIcon(String id) {
  switch (id) {
    case 'back-at-it':
      return HugeIcons.strokeRoundedRefresh;
    case 'first-forkthis-pick':
      return HugeIcons.strokeRoundedBookmark02;
    case 'protein-helper':
      return HugeIcons.strokeRoundedDumbbell01;
    case 'three-day-streak':
    case 'seven-day-streak':
      return HugeIcons.strokeRoundedFire;
    case 'momentum-builder':
    default:
      return HugeIcons.strokeRoundedCrown;
  }
}

class _MetricFigure extends StatelessWidget {
  final String value;
  final String label;
  const _MetricFigure({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppText.statFigure(color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: AppText.caption(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.textPrimary.withValues(alpha: 0.16),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final double top;
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.top,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: AppText.kicker(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(title, style: AppText.h2()),
        ],
      ),
    );
  }
}


class _MenuGroup extends StatelessWidget {
  final List<Widget> children;
  const _MenuGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool last;
  final bool destructive;
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.last = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = destructive ? AppColors.destructive : AppColors.primary;
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
            HugeIcon(icon: icon, size: 21, color: tint),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h3(color: destructive ? tint : null)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.caption()),
                ],
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: destructive ? tint : AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
