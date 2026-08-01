import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';

/// Ported from `../app/src/components/app/ProductSheet.tsx`. `showModalBottomSheet`
/// is Flutter's equivalent of the web `Sheet` primitive; this wrapper reproduces the
/// grab handle, title/description header, scrollable body and optional sticky footer.
Future<T?> showProductSheet<T>(
  BuildContext context, {
  required String title,
  String? description,
  required WidgetBuilder builder,
  Widget? footer,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    constraints: BoxConstraints(maxWidth: 430, maxHeight: MediaQuery.of(context).size.height * 0.9),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.borderStrong.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 56, 16),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h2(color: AppColors.primary)),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(description, style: AppText.bodySm(color: AppColors.mutedForeground)),
                  ],
                ],
              ),
            ),
            Flexible(child: SingleChildScrollView(child: builder(context))),
            if (footer != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).padding.bottom),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                child: footer,
              ),
          ],
        ),
      );
    },
  );
}
