import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';

OverlayEntry? _activeToast;

void showAppToast(
  BuildContext context,
  String message, {
  String? description,
  bool persistent = false,
  bool addToInbox = true,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  if (addToInbox) {
    context.read<AppState>().addNotification(
      title: message,
      body: description ?? 'Activity saved to your timeline.',
    );
  }
  _activeToast?.remove();
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastBanner(
      message: message,
      description: description,
      persistent: persistent,
      actionLabel: actionLabel,
      onAction: onAction,
      onDismissed: () {
        if (entry.mounted) entry.remove();
        if (identical(_activeToast, entry)) _activeToast = null;
      },
    ),
  );
  _activeToast = entry;
  overlay.insert(entry);
}

class _ToastBanner extends StatefulWidget {
  final String message;
  final String? description;
  final bool persistent;
  final VoidCallback onDismissed;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _ToastBanner({
    required this.message,
    this.description,
    required this.persistent,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_ToastBanner> createState() => _ToastBannerState();
}

class _ToastBannerState extends State<_ToastBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    if (!widget.persistent) {
      Future.delayed(const Duration(seconds: 4), _dismiss);
    }
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + 10,
      child: FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(_curve),
          child: Material(
            color: Colors.transparent,
            child: Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                decoration: BoxDecoration(
                  color: AppColors.foreground,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
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
                        icon: HugeIcons.strokeRoundedTick02,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.message,
                            style: AppText.label(color: AppColors.background),
                          ),
                          if (widget.description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.description!,
                              style: AppText.caption(
                                color: AppColors.background.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.actionLabel != null)
                      TextButton(
                        onPressed: () {
                          widget.onAction?.call();
                          _dismiss();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          textStyle: AppText.label(color: AppColors.accent),
                        ),
                        child: Text(widget.actionLabel!),
                      ),
                    IconButton(
                      onPressed: _dismiss,
                      tooltip: 'Dismiss',
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: 18,
                        color: AppColors.background,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
