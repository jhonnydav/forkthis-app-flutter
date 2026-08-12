import 'package:flutter/material.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

enum BrandLogoVariant {
  fullColor,
  redOnYellow,
  yellowOnRed,
  whiteOnRed,
  redOnly,
}

class BrandLogo extends StatelessWidget {
  final double size;
  final BrandLogoVariant variant;
  final BorderRadiusGeometry? borderRadius;

  const BrandLogo({
    super.key,
    this.size = 48,
    this.variant = BrandLogoVariant.fullColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == BrandLogoVariant.fullColor) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.asset(
          'assets/images/brand/forkthis-logo-full-color.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          semanticLabel: 'ForkThis!',
        ),
      );
    }

    final colors = switch (variant) {
      BrandLogoVariant.redOnYellow => (
        background: AppColors.accent,
        foreground: AppColors.primary,
      ),
      BrandLogoVariant.yellowOnRed => (
        background: AppColors.primary,
        foreground: AppColors.accent,
      ),
      BrandLogoVariant.whiteOnRed => (
        background: AppColors.primary,
        foreground: AppColors.primaryForeground,
      ),
      BrandLogoVariant.redOnly => (
        background: Colors.transparent,
        foreground: AppColors.primary,
      ),
      BrandLogoVariant.fullColor => (
        background: AppColors.accent,
        foreground: AppColors.primary,
      ),
    };

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: borderRadius,
      ),
      child: Text(
        'F!',
        style: AppText.h3(
          color: colors.foreground,
        ).copyWith(fontSize: size * 0.44, height: 1),
        textAlign: TextAlign.center,
      ),
    );
  }
}
