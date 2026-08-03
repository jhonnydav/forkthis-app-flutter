import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import 'app_notifications.dart';

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
              final active = location.startsWith(tab.path);
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
                            ? AppColors.primary
                            : AppColors.mutedForeground,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab.label,
                        style: AppText.caption(
                          color: active
                              ? AppColors.primary
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

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.header,
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
          if (widget.scrollTitle != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(
                ignoring: !_showScrollHeader,
                child: AnimatedSlide(
                  offset: _showScrollHeader ? Offset.zero : const Offset(0, -1),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: _showScrollHeader ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: _ScrollTopBar(
                      title: widget.scrollTitle!,
                      eyebrow: widget.scrollEyebrow,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: bottomBars.isEmpty
          ? null
          : Column(mainAxisSize: MainAxisSize.min, children: bottomBars),
    );
  }
}

class _ScrollTopBar extends StatelessWidget {
  final String title;
  final String? eyebrow;
  const _ScrollTopBar({required this.title, this.eyebrow});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.96),
          border: const Border(bottom: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eyebrow != null)
                          Text(
                            eyebrow!,
                            style: AppText.eyebrow(color: AppColors.primary),
                          ),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.h3(),
                        ),
                      ],
                    ),
                  ),
                  const NotificationBell(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
