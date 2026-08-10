import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

/// Settings/profile form vocabulary, shared so every control surface in the You
/// tab uses one grammar. These were private to `account_pages.dart` until the
/// profile grew past a single settings page; promoting them keeps Settings,
/// Goal, Measurements, and Privacy from drifting into four dialects.
///
/// Flat throughout: one hairline border per group, no nested cards, no shadows.

/// A titled block of related controls.
class SettingsGroup extends StatelessWidget {
  final String title;
  final String? note;
  final List<Widget> children;

  const SettingsGroup({
    super.key,
    required this.title,
    required this.children,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: AppText.eyebrow(color: AppColors.primary),
            ),
            if (note != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(note!, style: AppText.caption()),
            ],
            const SizedBox(height: AppSpace.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Chip-based single-select. Used where the options are short and comparing
/// them at a glance matters (goal, activity, units).
class SegmentRow<T> extends StatelessWidget {
  final String title;
  final String? help;
  final T value;
  final List<T> values;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;

  const SegmentRow({
    super.key,
    required this.title,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
    this.help,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.label()),
        if (help != null) ...[
          const SizedBox(height: 2),
          Text(help!, style: AppText.caption()),
        ],
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: values
              .map(
                (item) => ChoiceChip(
                  label: Text(labelFor(item)),
                  selected: item == value,
                  onSelected: (_) => onChanged(item),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

/// A navigation or command row. `destructive` is the only colour change — and
/// it is reserved for actions that remove data, never for a state the user is
/// "failing" at.
class ActionRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final bool destructive;

  const ActionRow({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 12,
      leading: HugeIcon(
        icon: icon,
        size: 21,
        color: destructive ? AppColors.destructive : AppColors.primary,
      ),
      title: Text(
        title,
        style: AppText.h3(
          color: destructive ? AppColors.destructive : AppColors.foreground,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle!, style: AppText.caption()),
            ),
      trailing: const HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        size: 18,
      ),
      onTap: onTap,
    );
  }
}

/// Full-width selectable tile. Preferred over chips when the option text is a
/// sentence rather than a word — surgical context, for instance, where the
/// wording is doing sensitivity work (FR-6) and must not be truncated.
class ChoiceTile extends StatelessWidget {
  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primaryForeground : AppColors.foreground;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: AppSpace.md,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.label(color: fg)),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: AppText.caption(
                        color: selected
                            ? AppColors.primaryForeground.withValues(alpha: 0.8)
                            : AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                size: 20,
                color: AppColors.primaryForeground,
              ),
          ],
        ),
      ),
    );
  }
}

/// Label + value line for read-only detail rows.
class DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const DetailLine({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppText.bodySm())),
          const SizedBox(width: AppSpace.md),
          Text(value, style: AppText.label()),
        ],
      ),
    );
  }
}
