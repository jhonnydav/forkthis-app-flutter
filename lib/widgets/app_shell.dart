import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import 'app_notifications.dart';
import 'brand_logo.dart';
import 'forkthis_moments.dart';

class _TabDef {
  final String path;
  final String label;
  final List<List<dynamic>> icon;
  const _TabDef(this.path, this.label, this.icon);
}

const _tabs = [
  _TabDef('/home', 'Home', HugeIcons.strokeRoundedHome01),
  _TabDef('/eat-out', 'Eat Out', HugeIcons.strokeRoundedRestaurant01),
  _TabDef('/cook', 'Cook', HugeIcons.strokeRoundedChefHat),
  _TabDef('/track', 'Track', HugeIcons.strokeRoundedNotebook01),
  _TabDef('/you', 'You', HugeIcons.strokeRoundedUserCircle02),
];

/// Bottom tab bar — fixed flush to the screen edge (not the earlier floating,
/// inset pill). The bar's `DecoratedBox` runs full-bleed to the true bottom of the
/// screen; `SafeArea` sits *inside* it around the content only, so the home-indicator
/// inset is respected without leaving a gap of bare background beneath the bar (same
/// full-bleed-background-vs-inset-content pattern as Home/Eat Out — see README's
/// safe-area section).
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key});

  static const double contentHeight = 58;

  static double totalHeight(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return contentHeight + (bottomInset > 8 ? bottomInset : 8);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    bool isActive(_TabDef tab) {
      if (location.startsWith(tab.path)) return true;
      if (tab.path == '/eat-out') {
        return location.startsWith('/restaurant') ||
            location.startsWith('/hack');
      }
      if (tab.path == '/cook') return location.startsWith('/cook/recipe');
      if (tab.path == '/track') return location.startsWith('/track/');
      if (tab.path == '/you') {
        return location.startsWith('/you/') ||
            location.startsWith('/help') ||
            location.startsWith('/ask') ||
            location.startsWith('/legal');
      }
      return false;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          height: contentHeight,
          child: Row(
            children: _tabs.map((tab) {
              final active = isActive(tab);
              return Expanded(
                child: InkWell(
                  onTap: () => active ? null : context.go(tab.path),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: tab.icon,
                        size: 24,
                        color: active
                            ? AppColors.brandBlueDeep
                            : AppColors.mutedForeground,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab.label,
                        style: AppText.caption(
                          color: active
                              ? AppColors.brandBlueDeep
                              : AppColors.mutedForeground,
                        ).copyWith(fontSize: 10, height: 1),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Ported from `ScreenHeader` in AppShell.tsx.
class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? eyebrow;
  final VoidCallback? onBack;
  final Widget? trailing;

  const ScreenHeader({
    super.key,
    this.title,
    this.eyebrow,
    this.onBack,
    this.trailing,
  });

  static const double _barHeight = 64;

  // Scaffold does not add the status-bar inset for an arbitrary
  // PreferredSizeWidget the way it does for a real AppBar — AppBar handles that
  // internally. Without this the title and back button render underneath the
  // clock and the Dynamic Island on every detail screen. The inset is added to
  // preferredSize *and* consumed by a SafeArea inside, so the bar's background
  // still runs full-bleed to the top of the screen.
  static double _topInset(BuildContext context) =>
      MediaQuery.paddingOf(context).top;

  @override
  Size get preferredSize => const Size.fromHeight(_barHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _barHeight + _topInset(context),
      padding: EdgeInsets.only(top: _topInset(context), left: 8, right: 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                size: 22,
              ),
              tooltip: 'Back',
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) Text(eyebrow!, style: AppText.eyebrow()),
                if (title != null)
                  Text(
                    title!,
                    style: AppText.h3(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Device shell — ported from `AppShell` in AppShell.tsx. Bottom padding reserves
/// space for the fixed tab bar so content never sits beneath it; computed from the
/// same formula the bar itself uses so the two never drift apart.
class AppShell extends StatefulWidget {
  final Widget child;
  final bool tabBar;
  final PreferredSizeWidget? header;
  final String? scrollTitle;
  final String? scrollEyebrow;
  final Widget? fixedAction;

  const AppShell({
    super.key,
    required this.child,
    this.tabBar = true,
    this.header,
    this.scrollTitle,
    this.scrollEyebrow,
    this.fixedAction,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _showScrollHeader = false;
  bool _showingReward = false;

  bool _handleScroll(ScrollNotification notification) {
    if (widget.scrollTitle == null ||
        notification.metrics.axis != Axis.vertical ||
        notification.depth != 0) {
      return false;
    }
    final shouldShow = notification.metrics.pixels > 72;
    if (shouldShow != _showScrollHeader) {
      setState(() => _showScrollHeader = shouldShow);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    _scheduleRewardDrawer();
    final location = GoRouterState.of(context).uri.path;
    final showMomentLauncher =
        widget.tabBar &&
        const {
          '/home',
          '/eat-out',
          '/cook',
          '/track',
          '/you',
        }.contains(location);
    final actionHeight = widget.fixedAction == null ? 0.0 : 80.0;
    final tabHeight = widget.tabBar ? AppTabBar.totalHeight(context) : 0.0;
    final bottomBars = <Widget>[
      if (widget.fixedAction != null)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: widget.fixedAction,
        ),
      if (widget.tabBar) const AppTabBar(),
    ];

    final header = widget.header;
    return Scaffold(
      backgroundColor: AppColors.background,
      // Reserve the status-bar inset on top of the header's own height.
      // `preferredSize` cannot see a BuildContext, so the inset is added here,
      // where one exists, and consumed by the header's internal top padding.
      appBar: header == null
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(
                header.preferredSize.height + MediaQuery.paddingOf(context).top,
              ),
              child: header,
            ),
      extendBody: true,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: tabHeight + actionHeight),
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScroll,
              child: widget.child,
            ),
          ),
          // The collapse-on-scroll bar exists for the tab roots, which have no
          // persistent header of their own. A screen that already shows a
          // ScreenHeader would otherwise render its title twice, stacked.
          if (widget.scrollTitle != null && header == null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: _showScrollHeader ? 1 : 0),
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutCubic,
                builder: (context, progress, child) {
                  return IgnorePointer(
                    ignoring: progress < 0.92,
                    child: Transform.translate(
                      offset: Offset(0, -24 * (1 - progress)),
                      child: Transform.scale(
                        scale: 0.98 + (progress * 0.02),
                        alignment: Alignment.topCenter,
                        child: Opacity(opacity: progress, child: child),
                      ),
                    ),
                  );
                },
                child: _ScrollTopBar(
                  title: widget.scrollTitle!,
                  eyebrow: widget.scrollEyebrow,
                ),
              ),
            ),
          if (showMomentLauncher)
            Positioned(
              right: 18,
              bottom: tabHeight + actionHeight + 16,
              child: _MomentLauncher(
                onTap: () => openForkThisMomentSearchSheet(context),
              ),
            ),
        ],
      ),
      bottomNavigationBar: bottomBars.isEmpty
          ? null
          : Column(mainAxisSize: MainAxisSize.min, children: bottomBars),
    );
  }

  void _scheduleRewardDrawer() {
    if (_showingReward || !mounted || !widget.tabBar) return;
    final state = context.watch<AppState>();
    if (state.pendingStreakDays == 0 && state.pendingBadges.isEmpty) return;
    _showingReward = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final current = context.read<AppState>();
      if (current.pendingStreakDays > 0) {
        final streak = current.pendingStreakDays;
        await showModalBottomSheet<void>(
          context: context,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _StreakRewardSheet(days: streak),
        );
        if (mounted) current.consumePendingStreak();
      }
      while (mounted && current.pendingBadges.isNotEmpty) {
        final badge = current.pendingBadges.first;
        if (!mounted) break;
        await showModalBottomSheet<void>(
          context: context,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _BadgeRewardSheet(badge: badge),
        );
        if (mounted) current.consumePendingBadge(badge.id);
      }
      if (mounted) setState(() => _showingReward = false);
    });
  }
}

class _StreakRewardSheet extends StatelessWidget {
  final int days;
  const _StreakRewardSheet({required this.days});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final week = List.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));
      return day;
    });
    return _RewardSheetFrame(
      accent: AppColors.accent,
      badge: _TierBadgeVisual(
        tier: 'gold',
        icon: HugeIcons.strokeRoundedFire,
        label: '$days',
      ),
      eyebrow: 'HEALTHY HABIT',
      title: '$days Day Streak!',
      body: 'You are on the right track. One helpful action today counts.',
      actionLabel: 'Claim',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final (index, day) in week.indexed)
            _StreakDay(
              label: _weekdayLabel(day.weekday),
              active: index >= week.length - days.clamp(0, 7),
              number: day.day,
            ),
        ],
      ),
    );
  }

  String _weekdayLabel(int weekday) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
}

class _BadgeRewardSheet extends StatelessWidget {
  final MomentumBadge badge;
  const _BadgeRewardSheet({required this.badge});

  @override
  Widget build(BuildContext context) {
    return _RewardSheetFrame(
      accent: _tierColor(badge.tier),
      badge: _TierBadgeVisual(
        tier: badge.tier,
        icon: _badgeIcon(badge.id),
        label: badge.unlockAt > 1 ? '${badge.unlockAt}' : '',
      ),
      eyebrow: 'BADGE UNLOCKED',
      title: badge.title,
      body: badge.description,
      actionLabel: 'Ok',
    );
  }
}

class _RewardSheetFrame extends StatelessWidget {
  final Color accent;
  final Widget badge;
  final String eyebrow;
  final String title;
  final String body;
  final String actionLabel;
  final Widget? child;

  const _RewardSheetFrame({
    required this.accent,
    required this.badge,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.actionLabel,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(34),
          boxShadow: AppElevation.modal,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: 18),
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(padding: const EdgeInsets.all(18), child: badge),
            ),
            const SizedBox(height: 18),
            Text(eyebrow, style: AppText.kicker(color: AppColors.primary)),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.h2(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppText.bodySm(color: AppColors.textSecondary),
            ),
            if (child != null) ...[const SizedBox(height: 20), child!],
            const SizedBox(height: 22),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierBadgeVisual extends StatelessWidget {
  final String tier;
  final List<List<dynamic>> icon;
  final String label;

  const _TierBadgeVisual({
    required this.tier,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(tier);
    return SizedBox(
      width: 104,
      height: 112,
      child: CustomPaint(
        painter: _BadgeShieldPainter(color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: icon, size: 34, color: AppColors.primary),
              if (label.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(label, style: AppText.h3(color: AppColors.primary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakDay extends StatelessWidget {
  final String label;
  final int number;
  final bool active;
  const _StreakDay({
    required this.label,
    required this.number,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppText.caption(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : AppColors.grayLight,
            shape: BoxShape.circle,
          ),
          child: active
              ? const HugeIcon(
                  icon: HugeIcons.strokeRoundedFire,
                  size: 16,
                  color: AppColors.primary,
                )
              : Text('$number', style: AppText.label()),
        ),
      ],
    );
  }
}

class _BadgeShieldPainter extends CustomPainter {
  final Color color;
  const _BadgeShieldPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final path = Path()
      ..moveTo(center.dx, 4)
      ..lineTo(size.width - 12, size.height * 0.26)
      ..lineTo(size.width - 18, size.height * 0.7)
      ..quadraticBezierTo(center.dx, size.height - 4, 18, size.height * 0.7)
      ..lineTo(12, size.height * 0.26)
      ..close();
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.26), 10, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.white.withValues(alpha: 0.34),
    );
    final ribbon = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, size.height - 28, size.width - 24, 22),
      const Radius.circular(6),
    );
    canvas.drawRRect(ribbon, Paint()..color = AppColors.secondary);
  }

  @override
  bool shouldRepaint(covariant _BadgeShieldPainter oldDelegate) =>
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

class _MomentLauncher extends StatelessWidget {
  final VoidCallback onTap;
  const _MomentLauncher({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open ForkThis moments',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            height: 54,
            padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: AppColors.primaryForeground.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.26),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedSparkles,
                    size: 17,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Moment',
                  style: AppText.label(color: AppColors.primaryForeground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrollTopBar extends StatelessWidget {
  final String title;
  final String? eyebrow;
  const _ScrollTopBar({required this.title, this.eyebrow});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        padding: EdgeInsets.fromLTRB(14, topInset + 8, 14, 8),
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: 62,
            padding: const EdgeInsets.fromLTRB(8, 7, 7, 7),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const BrandLogo(
                  size: 46,
                  variant: BrandLogoVariant.whiteOnRed,
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null)
                        Text(
                          eyebrow!,
                          style: AppText.kicker(color: AppColors.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.h3(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _TopBarAction(
                  tooltip: 'Ask AI assistant',
                  icon: HugeIcons.strokeRoundedSparkles,
                  label: 'Ask',
                  filled: true,
                  onTap: () => context.go('/ask'),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.highlight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const NotificationBell(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  final String tooltip;
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _TopBarAction({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? AppColors.primaryForeground : AppColors.primary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : AppColors.highlight,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: filled ? null : Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: icon, size: 16, color: foreground),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppText.label(color: foreground).copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
