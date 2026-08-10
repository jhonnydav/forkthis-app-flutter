import 'package:flutter/material.dart';
import 'tokens.dart';
import 'text_styles.dart';

/// Material theme built from [AppColors]/[AppText]. Encodes the de-defaulting
/// overrides from the web app's DESIGN-BRIEF.md §5 — Flutter's own defaults need the
/// same corrections shadcn's did, just via different knobs:
///
///  • PALETTE 2026-08-03 — interactive elements (buttons, switches, radios, focus
///    ring, `ColorScheme.primary`) use Lava Red through [AppColors.action]. Neon
///    Orange and Margarine Yellow carry supporting emphasis, while warm dark ink
///    remains the high-contrast text role.
///  • Filled = primary action; outlined/text = secondary.
///
///  • #1 no decorative elevation — Card/Button/AppBar/BottomNavigationBar all ship a
///    non-zero `elevation` in Material by default. Set to 0 everywhere except the two
///    documented exceptions: true overlays (dialog/bottom sheet) and the floating tab
///    bar, which draws its own manual shadow in widgets/app_shell.dart rather than
///    using Material elevation, matching the web app's approach exactly.
///  • #6 44px floor — `minimumSize` set explicitly on every button style; Material's
///    default (36–48 depending on widget) does not guarantee this.
///  • #12 static skeletons — enforced in widgets/skeleton.dart, not here; no shimmer
///    package is a dependency, which is itself the enforcement.
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.background,
  fontFamily: AppText.body().fontFamily,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.action,
    onPrimary: AppColors.actionForeground,
    secondary: AppColors.secondary,
    onSecondary: AppColors.secondaryForeground,
    error: AppColors.destructive,
    onError: AppColors.destructiveForeground,
    surface: AppColors.background,
    onSurface: AppColors.foreground,
    surfaceContainerHighest: AppColors.muted,
    onSurfaceVariant: AppColors.mutedForeground,
    outline: AppColors.border,
    outlineVariant: AppColors.borderStrong,
  ),
  splashFactory: InkRipple.splashFactory,
  dividerTheme: const DividerThemeData(
    color: AppColors.border,
    thickness: 1,
    space: 1,
  ),
  cardTheme: CardThemeData(
    color: AppColors.card,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.background.withValues(alpha: 0.92),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: AppColors.foreground,
    titleTextStyle: AppText.h3(),
    iconTheme: const IconThemeData(color: AppColors.foreground),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.actionDeep,
      foregroundColor: AppColors.actionForeground,
      disabledBackgroundColor: AppColors.actionDeep.withValues(alpha: 0.4),
      disabledForegroundColor: AppColors.actionForeground.withValues(
        alpha: 0.7,
      ),
      elevation: 0,
      minimumSize: const Size.fromHeight(56),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      textStyle: AppText.buttonLarge(color: AppColors.actionForeground),
      side: BorderSide.none,
      shape: const StadiumBorder(),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      side: BorderSide.none,
      shape: const StadiumBorder(),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      backgroundColor: AppColors.muted,
      side: BorderSide.none,
      minimumSize: const Size.fromHeight(56),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      textStyle: AppText.buttonLarge(color: AppColors.primary),
      shape: const StadiumBorder(),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: AppText.button(color: AppColors.primary),
      shape: const StadiumBorder(),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      minimumSize: const Size(48, 48),
      shape: const CircleBorder(),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.card,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpace.lg,
      vertical: 14,
    ),
    hintStyle: AppText.body(color: AppColors.mutedForeground),
    labelStyle: AppText.label(color: AppColors.mutedForeground),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.ring, width: 2),
    ),
    constraints: const BoxConstraints(minHeight: 48), // override #6
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.background,
    modalBackgroundColor: AppColors.background,
    // Exception #1: true overlay — a soft shadow here communicates real z-order.
    modalElevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.card,
    elevation: 8, // exception #1 — true overlay
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    titleTextStyle: AppText.h2(),
    contentTextStyle: AppText.body(color: AppColors.mutedForeground),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.card,
    selectedColor: AppColors.action,
    side: const BorderSide(color: AppColors.border),
    labelStyle: AppText.label(),
    secondaryLabelStyle: AppText.label(color: AppColors.actionForeground),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    shape: const StadiumBorder(),
    showCheckmark: false,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.foreground,
    contentTextStyle: AppText.bodySm(color: AppColors.background),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    // Placement is set per-call (see widgets/app_toast.dart) — the sonner lesson from
    // the web build was that a bare default sits on top of the tab bar. Same care here.
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.card
          : AppColors.card,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.action
          : AppColors.border,
    ),
  ),
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.action
          : AppColors.border,
    ),
  ),
  textTheme: TextTheme(
    displayLarge: AppText.displayLarge(),
    displayMedium: AppText.displayMedium(),
    displaySmall: AppText.displaySmall(),
    headlineLarge: AppText.h1(),
    headlineMedium: AppText.h2(),
    headlineSmall: AppText.h3(),
    bodyLarge: AppText.bodyLarge(),
    bodyMedium: AppText.body(),
    bodySmall: AppText.bodySm(),
    labelLarge: AppText.labelLarge(),
    labelMedium: AppText.label(),
    labelSmall: AppText.labelSm(),
  ),
);
