import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

/// Shared state surfaces — App Flow §5 makes these a handoff requirement, not a
/// nicety: "undesigned states are where the product looks cheap."
///
/// Three shapes, one grammar: an icon plate, a headline in the product's own
/// voice, a sentence of context, and at most two actions. Flat — a hairline
/// border and a tinted plate, no cards-on-cards and no shadows.
///
/// Voice rules that apply to every state in this file (PRD §10.1 Q-10/Q-11,
/// FR-30): nothing here may read as a failure the user caused. No "you have no
/// …", no red, no exclamation of alarm. Empty is an invitation; error is a
/// hiccup that we own.

enum _StateTone { calm, warm, alert }

class StateSurface extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String body;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final _StateTone _tone;
  final EdgeInsetsGeometry padding;

  /// Nothing here *yet*. The default and by far the most common case.
  const StateSurface.empty({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
  }) : _tone = _StateTone.calm;

  /// A search or filter returned nothing — the user did something, it just
  /// didn't match. Warmer plate, always offers a way to widen the net.
  const StateSurface.noResults({
    super.key,
    required this.title,
    required this.body,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
  }) : icon = HugeIcons.strokeRoundedSearchRemove,
       _tone = _StateTone.warm;

  /// Something broke on our side. Always retryable, never blames the user, and
  /// never shows a raw exception.
  const StateSurface.error({
    super.key,
    required this.title,
    required this.body,
    this.primaryLabel = 'Try again',
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
  }) : icon = HugeIcons.strokeRoundedRefresh,
       _tone = _StateTone.alert;

  /// Offline is a first-class state, not an error: what still works is the
  /// headline, not the connection that doesn't.
  const StateSurface.offline({
    super.key,
    required this.title,
    required this.body,
    this.primaryLabel = 'Try again',
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
  }) : icon = HugeIcons.strokeRoundedWifiDisconnected01,
       _tone = _StateTone.alert;

  (Color, Color) get _plate => switch (_tone) {
    _StateTone.calm => (AppColors.secondary, AppColors.primary),
    _StateTone.warm => (AppColors.eatOutCraveBg, AppColors.foreground),
    _StateTone.alert => (AppColors.coralSurface, AppColors.primary),
  };

  @override
  Widget build(BuildContext context) {
    final (plateBg, plateFg) = _plate;
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: plateBg,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
            ),
            child: HugeIcon(icon: icon, size: 28, color: plateFg),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(title, style: AppText.h2(), textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.sm),
          Text(
            body,
            style: AppText.bodySm(color: AppColors.mutedForeground),
            textAlign: TextAlign.center,
          ),
          if (primaryLabel != null || secondaryLabel != null) ...[
            const SizedBox(height: AppSpace.xxl),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              alignment: WrapAlignment.center,
              children: [
                if (primaryLabel != null)
                  ElevatedButton(
                    onPressed: onPrimary,
                    child: Text(primaryLabel!),
                  ),
                if (secondaryLabel != null)
                  OutlinedButton(
                    onPressed: onSecondary,
                    child: Text(secondaryLabel!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline variant for states that sit inside an already-scrolling section
/// rather than owning the whole viewport (e.g. one tab of Saved).
class InlineNote extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String text;
  final Color? background;

  const InlineNote({
    super.key,
    required this.icon,
    required this.text,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: background ?? AppColors.muted,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, size: 18, color: AppColors.mutedForeground),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              text,
              style: AppText.bodySm(color: AppColors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeletons matched to the final layout, not spinners (App Flow §5).
class SkeletonBlock extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;

  const SkeletonBlock({
    super.key,
    required this.height,
    this.width,
    this.radius = AppRadius.xl,
  });

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 0.9).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Row-shaped skeleton used by list surfaces (Saved, History, Search results)
/// so the loading frame has the same rhythm as the loaded one.
class SkeletonListRows extends StatelessWidget {
  final int count;
  final double height;

  const SkeletonListRows({super.key, this.count = 4, this.height = 84});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : AppSpace.md),
            child: SkeletonBlock(height: height),
          ),
      ],
    );
  }
}
