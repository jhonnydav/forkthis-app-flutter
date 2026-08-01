import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';

/// Override #8, learned the hard way in the web build: a default toast/snackbar sits
/// on top of the bottom tab bar unless you explicitly account for its height. There,
/// the fix was `mobileOffset`, silently ignored until set alongside `offset`; here the
/// equivalent is a manual bottom margin sized to [kTabBarClearance] rather than trusting
/// `SnackBarBehavior.floating`'s default inset. Verify placement with a screenshot, not
/// by reading the property — that's what caught it last time.
const double kTabBarClearance = 96; // tab bar height + safe-area + breathing room

void showAppToast(
  BuildContext context,
  String message, {
  String? description,
  bool persistent = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: persistent ? const Duration(days: 1) : const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.foreground,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: kTabBarClearance),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppText.bodySm(color: AppColors.background).copyWith(fontWeight: FontWeight.w700)),
          if (description != null) ...[
            const SizedBox(height: 2),
            Text(description, style: AppText.caption(color: AppColors.background.withValues(alpha: 0.75))),
          ],
        ],
      ),
    ),
  );
}
