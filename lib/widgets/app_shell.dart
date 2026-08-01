import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';

class _TabDef {
  final String path;
  final String label;
  final IconData icon;
  const _TabDef(this.path, this.label, this.icon);
}

const _tabs = [
  _TabDef('/eat-out', 'Eat Out', Icons.restaurant_menu_rounded),
  _TabDef('/cook', 'Cook', Icons.soup_kitchen_rounded),
  _TabDef('/track', 'Track', Icons.edit_note_rounded),
  _TabDef('/you', 'You', Icons.person_rounded),
];

/// Floating pill tab bar — ported from `../app/src/layout/AppShell.tsx` `TabBar`.
/// This, plus dialogs/bottom sheets, are the ONLY places elevation is used (override
/// #1): it communicates real z-order over scrolling content, drawn manually rather
/// than via Material elevation so the shadow matches the web app's soft, wide values
/// instead of Material's default umbra/penumbra stack.
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        height: 64,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 50, offset: const Offset(0, 18)),
          ],
        ),
        child: Row(
          children: _tabs.map((tab) {
            final active = location.startsWith(tab.path);
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => active ? null : context.go(tab.path),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: active ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab.icon, size: 20, color: active ? AppColors.primary : AppColors.mutedForeground),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: AppText.caption(color: active ? AppColors.primary : AppColors.mutedForeground)
                            .copyWith(fontSize: 10, height: 1),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
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

  const ScreenHeader({super.key, this.title, this.eyebrow, this.onBack, this.trailing});

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
              icon: const Icon(Icons.chevron_left_rounded, size: 26),
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
                  Text(title!, style: AppText.h3(), maxLines: 1, overflow: TextOverflow.ellipsis),
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
/// space for the floating tab bar so content never sits beneath it.
class AppShell extends StatelessWidget {
  final Widget child;
  final bool tabBar;
  final PreferredSizeWidget? header;

  const AppShell({super.key, required this.child, this.tabBar = true, this.header});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: header,
      extendBody: true,
      body: Padding(
        padding: EdgeInsets.only(bottom: tabBar ? 84 : 0),
        child: child,
      ),
      bottomNavigationBar: tabBar ? const AppTabBar() : null,
    );
  }
}
