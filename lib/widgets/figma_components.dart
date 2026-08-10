import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';

/// Shared components introduced by the Figma redesign pulled 2026-08-06
/// (`figma.com/design/LjDp489aFZaYiDx88MvvkQ`). These patterns repeat across
/// Home, Track, Cook, and Eat Out in the new design, so they live here once
/// rather than being reimplemented per screen.
///
/// Every screen file restyled against that Figma file should reach for these
/// before writing a new one-off container — check here first.

// ─────────────────────────────────────────────────────────────────────────
// Segmented pill control — "For you / By goal / Nearest", "Today / History"
// ─────────────────────────────────────────────────────────────────────────

/// A pill-track segmented control: options laid side by side inside a rounded
/// track, the active one filled solid. Used for Track's Today/History switch
/// and Eat Out's For you/By goal/Nearest.
class SegmentedPills<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;

  /// Track background — defaults to Card so the control reads as a control,
  /// not a card, when it sits directly on a Background/Highlight page.
  final Color trackColor;
  final Color activeColor;
  final Color activeForeground;
  final Color inactiveForeground;

  const SegmentedPills({
    super.key,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onChanged,
    this.trackColor = AppColors.card,
    this.activeColor = AppColors.primary,
    this.activeForeground = AppColors.primaryForeground,
    this.inactiveForeground = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          for (final value in values)
            Expanded(
              child: _Segment(
                label: labelFor(value),
                selected: value == selected,
                activeColor: activeColor,
                activeForeground: activeForeground,
                inactiveForeground: inactiveForeground,
                onTap: () => onChanged(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final Color activeForeground;
  final Color inactiveForeground;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.activeForeground,
    required this.inactiveForeground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppText.button(
            color: selected ? activeForeground : inactiveForeground,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Stat hero cards — Home's yellow "Today" card, Track's red "Today so far"
// ─────────────────────────────────────────────────────────────────────────

/// One figure in a stat row: icon, bold value, small caption label underneath.
/// Used inside [StatSummaryCard] and standalone in Track's 3-tile stat row.
class StatFigure extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String value;
  final String label;
  final Color color;
  final Color labelColor;

  const StatFigure({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppColors.textPrimary,
    this.labelColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: icon, size: 16, color: color),
        const SizedBox(height: 8),
        Text(value, style: AppText.statFigure(color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppText.caption(color: labelColor)),
      ],
    );
  }
}

/// Home's yellow "Today" summary card: eyebrow, then a row of [StatFigure]s
/// separated by hairline dividers. Corresponds to Figma node 321:501.
class StatSummaryCard extends StatelessWidget {
  final String eyebrow;
  final List<StatFigure> figures;
  final Color background;

  const StatSummaryCard({
    super.key,
    required this.eyebrow,
    required this.figures,
    this.background = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Stack(
        children: [
          // A soft decorative shape in the corner, echoing the wavy vector
          // Figma layers behind this card — approximated rather than shipping
          // the exported SVG, since it is purely atmospheric.
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: AppText.caption(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              IntrinsicHeight(
                child: Row(
                  children: [
                    for (final (index, figure) in figures.indexed) ...[
                      if (index > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.18,
                            ),
                          ),
                        ),
                      Expanded(child: figure),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Track's red "Today so far" hero: eyebrow + big stat figure + description on
/// the left, a ring showing a percentage on the right, then a progress bar and
/// a min/max caption row underneath. Figma node 321:685.
///
/// The ring in Figma is a plain bordered circle (a full-circumference stroke
/// in a light color, not a partial arc) — reproduced literally as
/// `Container` + `Border`, not a `CircularProgressIndicator` arc.
class HeroProgressCard extends StatelessWidget {
  final String eyebrow;
  final String statValue;
  final String statUnit;
  final String description;
  final int percent;
  final double progress;
  final String leftCaption;
  final String rightCaption;
  final Color background;
  final Color foreground;
  final Color trackColor;
  final Color fillColor;

  const HeroProgressCard({
    super.key,
    required this.eyebrow,
    required this.statValue,
    required this.statUnit,
    required this.description,
    required this.percent,
    required this.progress,
    required this.leftCaption,
    required this.rightCaption,
    this.background = AppColors.primary,
    this.foreground = AppColors.highlight,
    this.trackColor = AppColors.highlight,
    this.fillColor = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: AppText.caption(color: foreground),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$statValue ',
                            style: AppText.heroStat(color: foreground),
                          ),
                          TextSpan(
                            text: statUnit,
                            style: AppText.buttonLarge(color: foreground),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(description, style: AppText.bodySm(color: foreground)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: foreground, width: 7),
                ),
                child: Text(
                  '$percent%',
                  style: AppText.buttonLarge(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation(fillColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Expanded rather than spaceBetween on two bare Texts — at
              // large text scales (NFR-2) "N cal left in this guide" +
              // "Guide: N,NNN" together no longer fit a 321px card, so the
              // longer left caption wraps instead of overflowing the row.
              Expanded(
                child: Text(
                  leftCaption,
                  style: AppText.labelSm(color: foreground),
                ),
              ),
              const SizedBox(width: 8),
              Text(rightCaption, style: AppText.labelSm(color: foreground)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// List rows
// ─────────────────────────────────────────────────────────────────────────

/// Simple row: circular thumbnail, title, subtitle, trailing chevron. Used by
/// Eat Out's restaurant list (Figma node 321:1901).
class ThumbListRow extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ThumbListRow({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              ClipOval(
                child: Image.asset(
                  image,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.body()),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.caption()),
                  ],
                ),
              ),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Article row with a square-ish rounded thumbnail, title, subtitle, and a
/// trailing round icon-button (delete, by default). Used by Track's meal list
/// (Figma node 321:751).
class ThumbActionRow extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final List<List<dynamic>> actionIcon;
  final String actionTooltip;

  const ThumbActionRow({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.onAction,
    this.actionIcon = HugeIcons.strokeRoundedDelete02,
    this.actionTooltip = 'Remove',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.tile),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.thumb),
                child: Image.asset(
                  image,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppText.body(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppText.caption(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onAction != null)
                IconButton(
                  tooltip: actionTooltip,
                  onPressed: onAction,
                  icon: HugeIcon(
                    icon: actionIcon,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// CTA / notification banner card
// ─────────────────────────────────────────────────────────────────────────

/// Icon plate + title + subtitle banner card, optionally tappable. Used for
/// Home's "Progress, not perfection." card and Track's "Need your next meal?"
/// card (Figma nodes 321:610 and 321:797).
class CtaBannerCard extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final Color plateColor;
  final Color iconColor;
  final Color background;
  final VoidCallback? onTap;
  final bool showArrow;

  const CtaBannerCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.plateColor = AppColors.accent,
    this.iconColor = AppColors.textPrimary,
    this.background = AppColors.card,
    this.onTap,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.banner),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: plateColor,
              shape: BoxShape.circle,
            ),
            child: HugeIcon(icon: icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.body()),
                const SizedBox(height: 4),
                Text(subtitle, style: AppText.caption()),
              ],
            ),
          ),
          if (showArrow) ...[
            const SizedBox(width: 8),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.banner),
      child: card,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Rail card — Home's horizontal "Pick an order" cards
// ─────────────────────────────────────────────────────────────────────────

/// Image-led card for a horizontal rail: full-bleed image with a badge chip
/// top-left, then a dark footer panel carrying an eyebrow, title, and meta
/// line. Figma node 321:576.
class RailCard extends StatefulWidget {
  final String image;
  final String badge;
  final String eyebrow;
  final String title;
  final String meta;
  final VoidCallback onTap;
  final double width;

  const RailCard({
    super.key,
    required this.image,
    required this.badge,
    required this.eyebrow,
    required this.title,
    required this.meta,
    required this.onTap,
    this.width = 277,
  });

  @override
  State<RailCard> createState() => _RailCardState();
}

class _RailCardState extends State<RailCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: widget.width,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.asset(
                    widget.image,
                    height: 207,
                    width: widget.width,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    left: 8,
                    top: 12,
                    child:
                        Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.22,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.badge.toUpperCase(),
                                style: AppText.tagBold(
                                  color: AppColors.primary,
                                ).copyWith(letterSpacing: 0.3),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 220.ms, delay: 80.ms)
                            .scaleXY(
                              begin: 0.85,
                              end: 1,
                              duration: 220.ms,
                              delay: 80.ms,
                              curve: Curves.easeOutBack,
                            ),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppColors.textPrimary,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.eyebrow.toUpperCase(),
                      style: AppText.tagBold(color: AppColors.accent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      style: AppText.cardTitle(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.meta,
                      style: AppText.caption(color: AppColors.goldLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(
      begin: 0.06,
      end: 0,
      duration: 280.ms,
      curve: Curves.easeOutCubic,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Two-tile image link card — Home's "What do you need?" grid
// ─────────────────────────────────────────────────────────────────────────

/// A colored tile with a large display-face label bottom-left and a food
/// photo bleeding off the top-right corner. Figma node 321:537/544.
class ImageLinkTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final String image;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const ImageLinkTile({
    super.key,
    required this.label,
    required this.subtitle,
    required this.image,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        height: 123 + ((textScale - 1).clamp(0, 1).toDouble() * 48),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -40,
              child: Opacity(
                opacity: 0.95,
                child: Image.asset(image, width: 150, height: 150),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppText.headline(28, color: foreground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppText.caption(
                      color: foreground.withValues(alpha: 0.82),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

// ─────────────────────────────────────────────────────────────────────────
// Stat tile banner — Cook's red "Kitchen flow" banner
// ─────────────────────────────────────────────────────────────────────────

/// Colored banner: eyebrow + heading, then a row of equal-width rounded stat
/// tiles (big value + kicker label underneath), each tile on its own
/// surface color. Distinct from [StatSummaryCard]'s single divided-row card —
/// this is a grid of separately-colored tiles, which the divided layout
/// cannot express without changing its signature. Figma node 321:1072
/// (Cook's "Kitchen flow" banner).
class StatTileBanner extends StatelessWidget {
  final String eyebrow;
  final String heading;
  final List<StatTile> tiles;
  final Color background;
  final Color foreground;

  const StatTileBanner({
    super.key,
    required this.eyebrow,
    required this.heading,
    required this.tiles,
    this.background = AppColors.primary,
    this.foreground = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(), style: AppText.kicker(color: foreground)),
          const SizedBox(height: 6),
          Text(heading, style: AppText.h2(color: foreground)),
          const SizedBox(height: 16),
          // IntrinsicHeight + Expanded, not CrossAxisAlignment.stretch — a
          // stretched Row inside a scrolling list renders fully blank with no
          // exception (see StatSummaryCard above for the same guard).
          IntrinsicHeight(
            child: Row(
              children: [
                for (final (index, tile) in tiles.indexed) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(child: tile),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One tile inside [StatTileBanner]: a value line and an uppercase kicker
/// label, on its own rounded colored surface.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color background;
  final Color foreground;

  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.background = AppColors.highlight,
    this.foreground = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppText.h3(color: foreground)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(), style: AppText.kicker(color: foreground)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Count chip — Cook's "Browse lanes" pills with a circular count badge
// ─────────────────────────────────────────────────────────────────────────

/// A pill button pairing a label with a small circular count badge. Used for
/// Cook's "Browse lanes" row (Figma node 321:1135) — filters presented as
/// counted shortcuts rather than plain toggle chips.
class CountChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color badgeColor;

  const CountChip({
    super.key,
    required this.label,
    required this.count,
    required this.onTap,
    this.selected = false,
    this.badgeColor = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.banner),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.banner),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppText.body(
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.white : badgeColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: AppText.button(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tagged thumb row — Cook's recipe-library rows with a colored corner tag
// ─────────────────────────────────────────────────────────────────────────

/// List row for a photo-led item: a square rounded thumbnail carrying a
/// colored corner tag chip, a meta line, title, subtitle, and a trailing pill
/// row that ends in a round action button. Figma node 321:1191 (Cook's recipe
/// library rows) — generic enough for any tagged, photo-led list item, not
/// specific to recipes.
class TaggedThumbRow extends StatelessWidget {
  final String image;
  final String tag;
  final Color tagBackground;
  final Color tagForeground;
  final String meta;
  final String title;
  final String subtitle;
  final List<Widget> pills;
  final VoidCallback onTap;
  final List<List<dynamic>> trailingIcon;
  final Color background;

  const TaggedThumbRow({
    super.key,
    required this.image,
    required this.tag,
    required this.meta,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tagBackground = AppColors.goldLight,
    this.tagForeground = AppColors.textPrimary,
    this.pills = const [],
    this.trailingIcon = HugeIcons.strokeRoundedArrowRight01,
    this.background = AppColors.background,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.banner),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.banner),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Image.asset(
                    image,
                    width: 104,
                    height: 104,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tagBackground,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      tag.toUpperCase(),
                      style: AppText.tagBold(color: tagForeground),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meta, style: AppText.caption()),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: AppText.cardTitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppText.caption(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final (index, pill) in pills.indexed) ...[
                        if (index > 0) const SizedBox(width: 6),
                        pill,
                      ],
                      const Spacer(),
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: trailingIcon,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
