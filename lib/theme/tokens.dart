import 'package:flutter/material.dart';

/// Design tokens — the single source for colour, radius, spacing, and elevation.
///
/// Values come from `docs/Design Style Guide.pdf` (Nutrition Health App). Where
/// the guide names a token, the guide wins; the older palette aliases below are
/// kept so existing screens keep compiling, remapped onto the guide's values
/// rather than deleted out from under them.
///
/// Guide principle 6 — "token-driven consistency: all colors, spacing, and radii
/// use design system variables for easy theming." Nothing in `lib/screens/`
/// should carry a raw hex, radius, or pixel gap.
class AppColors {
  AppColors._();

  // ── Primary (guide §Color Palette / Primary) ─────────────────────────────
  static const red = Color(0xFFCF161A);
  static const maroon = Color(0xFF4A140E);
  static const orange = Color(0xFFFF551D);
  static const yellow = Color(0xFFF5D630);

  // ── Neutral (guide §Color Palette / Neutral) ─────────────────────────────
  static const white = Color(0xFFFFFFFF);
  static const cream = Color(0xFFFFFBF1);
  static const creamWarm = Color(0xFFFFF4E0);
  static const goldLight = Color(0xFFFFF0B8);
  static const grayLight = Color(0xFFECECEC);

  // ── Text & semantic (guide §Text & Semantic) ─────────────────────────────
  static const textPrimary = maroon;
  static const textSecondary = Color(0xFF6E4740);
  static const textInverse = white;
  static const textAccent = red;
  static const accentGreen = Color(0xFF406051);

  // ── Surface (guide §Surface) ─────────────────────────────────────────────
  // Note the inversion against the previous build: Background is now the cream
  // (#FFFBF1) and Card is pure white. Screens read one step lighter throughout.
  static const background = cream;
  static const card = white;
  static const highlight = creamWarm;
  static const redLight = Color(0xFFFFC2C3);

  static const foreground = textPrimary;
  static const cardForeground = textPrimary;

  static const primary = red;
  static const primaryForeground = white;

  static const secondary = orange;
  static const secondaryForeground = maroon;

  static const muted = creamWarm;
  static const mutedForeground = textSecondary;

  static const accent = yellow;
  static const accentForeground = maroon;

  static const destructive = red;
  static const destructiveForeground = white;

  /// Borders carry all section separation in this build.
  ///
  /// This matters more than it looks: Card (#FFFFFF) against Background
  /// (#FFFBF1) is **1.03:1** — the fills are visually identical. The guide
  /// resolves that with Shadow/Small; keeping the surfaces flat means the border
  /// is the only thing defining a card, so it is set warm-but-visible (1.66:1
  /// against the background) rather than the near-invisible 1.31:1 that a
  /// literal reading of the neutral ramp would give.
  static const border = Color(0xFFD8C3A2);
  static const borderStrong = Color(0xFFBFA57F);
  static const input = borderStrong;
  static const ring = red;

  static const action = red;
  static const actionForeground = white;
  static const actionDeep = Color(0xFFA20F15);

  static const success = accentGreen;
  static const successForeground = white;

  // ── Compatibility aliases ────────────────────────────────────────────────
  // Existing screens reference these names. Kept and remapped onto the guide's
  // values so this change is a re-skin, not a rewrite of every call site.
  static const paletteLava = red;
  static const paletteBrown = maroon;
  static const paletteNeonOrange = orange;
  static const paletteMargarine = yellow;
  static const paletteYellow = yellow;
  static const paletteOrange = orange;
  static const paletteRedOrange = orange;
  static const paletteCosmicLatte = creamWarm;
  static const paletteOffWhite = cream;
  static const paletteCream = goldLight;
  // ⚠️ Off-palette. The guide's ramp has no purple or pink; these predate it and
  // are still live on 8 call sites (icon plates on Home, You, and the log flow).
  // Retiring them is a deliberate design decision, not a mechanical rename, so
  // they are flagged rather than silently remapped onto a guide colour.
  static const paletteRoseBonbon = Color(0xFFFE51A4);
  static const paletteLavenderIndigo = Color(0xFF9E5AFD);
  static const paletteSkyBlue = paletteLavenderIndigo;
  static const paletteSpringGreen = accentGreen;
  static const paletteYellowGreen = yellow;

  static const brandBlue = orange;
  static const brandBlueForeground = maroon;
  static const brandBlueDeep = red;

  static const ingredientGreen = yellow;
  static const ingredientGreenDeep = Color(0xFF704414);

  static const warm = orange;
  static const warmForeground = maroon;
  static const warmSurface = creamWarm;

  static const coral = red;
  static const coralForeground = white;
  static const coralSurface = redLight;

  static const blueberry = paletteLavenderIndigo;
  static const blueberryForeground = white;
  static const blueberrySurface = Color(0xFFF0E7FF);

  static const mint = goldLight;
  static const mintForeground = maroon;

  static const honey = yellow;
  static const honeyForeground = maroon;

  // Screen-specific aliases.
  static const homeHeroBorder = red;
  static const homeHeroRing = maroon;
  static const homeGoodAfternoon = maroon;
  static const eatOutLunchLabel = red;
  static const eatOutCraveBg = goldLight;
  static const questionnaireLabel = red;
  static const hackDetailProtein = red;
  static const hackWhySurface = goldLight;
}

/// Guide §Border Radius. Materially rounder than the previous scale — [lg] was
/// 8, it is now 16, and cards use it.
class AppRadius {
  AppRadius._();
  static const none = 0.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 999.0;

  // ── Figma-exact card radii (redesign pulled 2026-08-06) ──────────────────
  // The style-guide scale above (8/12/16/24) doesn't hit the actual values
  // Figma's card containers use — these read as their own step, not rounding
  // error, so they're named rather than snapped onto the nearest guide value.
  /// Thumbnail/small image corners (meal-row photos, 68×20).
  static const thumb = 20.0;
  /// Standard content card (Home's stat/tile cards, list-row cards).
  static const card = 21.0;
  /// Stat tile / meal-row article card (Track).
  static const tile = 26.0;
  /// CTA / notification banner card.
  static const banner = 28.0;
  /// Full-bleed hero card (Track's red "Today so far" card).
  static const hero = 32.0;

  /// Legacy name kept for existing call sites; the guide's XL is 24.
  static const xxl = xl;
}

/// Guide §Spacing — 2 · 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 64.
class AppSpace {
  AppSpace._();
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;
  static const huge2 = 48.0;
  static const huge3 = 64.0;
}

/// Guide §Elevation / Shadows.
///
/// ⚠️ **None of these are currently referenced anywhere in the app.** They are
/// defined because the guide specifies them and principle 6 wants elevation
/// tokenised, but the build stays flat: sections separate by border and colour.
/// Dialogs and sheets use Material's numeric `elevation:` in `theme.dart`, not
/// these lists.
///
/// If the guide's card treatment is wanted, applying [card] to the card
/// containers is the change — note that doing so is what the guide assumes when
/// it pairs Card #FFFFFF with Background #FFFBF1 (a 1.03:1 fill difference).
class AppElevation {
  AppElevation._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x24000000),
      offset: Offset(0, 8),
      blurRadius: 32,
      spreadRadius: -4,
    ),
  ];
}
