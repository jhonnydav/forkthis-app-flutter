import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'product_sheet.dart';

class NotificationBell extends StatelessWidget {
  final Color? color;
  const NotificationBell({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final unread = context.select<AppState, int>(
      (state) => state.unreadNotificationCount,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => showNotificationCenter(context),
          tooltip: 'Notifications',
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedNotification01,
            size: 22,
            color: color ?? AppColors.primary,
          ),
        ),
        if (unread > 0)
          Positioned(
            right: 5,
            top: 5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: AppColors.warm,
                shape: BoxShape.circle,
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: AppText.caption(
                  color: AppColors.foreground,
                ).copyWith(fontSize: 9, height: 1),
              ),
            ),
          ),
      ],
    );
  }
}

void showNotificationCenter(BuildContext context) {
  showProductSheet(
    context,
    title: 'Notifications',
    description: 'Helpful updates from your plan and recent activity.',
    builder: (context) => Consumer<AppState>(
      builder: (context, state, _) {
        final items = state.notifications;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            children: [
              if (items.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: state.unreadNotificationCount == 0
                        ? null
                        : state.markAllNotificationsRead,
                    child: const Text('Mark all as read'),
                  ),
                ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 48,
                    horizontal: 24,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedNotificationOff01,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('You are all caught up', style: AppText.h3()),
                      const SizedBox(height: 6),
                      Text(
                        'New plan updates and reminders will appear here.',
                        textAlign: TextAlign.center,
                        style: AppText.bodySm(color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => state.markNotificationRead(item.id),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
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
                          const SizedBox(width: 12),
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
                                const SizedBox(height: 8),
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
          ),
        );
      },
    ),
  );
}

String _relativeTime(DateTime time) {
  final difference = DateTime.now().difference(time);
  if (difference.inMinutes < 1) return 'Now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  return '${difference.inDays}d ago';
}
