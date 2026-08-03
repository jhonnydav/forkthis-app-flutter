import 'package:flutter/material.dart';

/// Design tokens — ported verbatim from `../app/src/index.css` (`:root`), which is
/// the only source of truth for the current palette. Do not "improve" values here
/// without also changing the web app; the two must stay in sync by hand until a
/// real shared-token pipeline exists (see ENGINEERING-PLAN.md §3).
///
/// CONTRAST AUDIT (computed sRGB→WCAG, fixed 2026-08-03 per DESIGN-BRIEF.md §4.1):
/// The four failures previously documented here were real bugs, not accepted risk —
/// fixed as part of reconciling the design brief with client discovery feedback:
///   • warmForeground on warm:  4.05:1 → 5.30:1 (darkened warmForeground)
///   • coralForeground on coral: 2.99:1 → 3.90:1 (darkened coral itself)
///   • input vs background/card: ~1.3:1 → 3.47:1 / 3.63:1 (input no longer equals
///     border; it now matches borderStrong's verified value)
/// `warm` itself is still icon/badge-fill only — 2.75:1 as plain text on `background`,
/// never use it as a text color. See app-flutter/README.md for the full note.
class AppColors {
  AppColors._();

  // ── Neutrals & surfaces ──────────────────────────────────────────────
  static const background = Color(0xFFF8FAFE);
  static const foreground = Color(0xFF11131C);
  static const card = Color(0xFFFFFFFF);
  static const cardForeground = foreground;

  static const primary = Color(0xFF0F3A27);
  static const primaryForeground = Color(0xFFFFFFFF);

  static const secondary = Color(0xFFE6EDE7);
  static const secondaryForeground = primary;

  static const muted = Color(0xFFE6EDE7);
  static const mutedForeground = Color(0xFF545864);

  static const accent = Color(0xFFD5ED73);
  static const accentForeground = primary;

  static const destructive = Color(0xFFBA1E20);
  static const destructiveForeground = Color(0xFFFDFCF8);

  static const border = Color(0xFFDBDEE6);
  static const input = Color(0xFF838691);
  static const borderStrong = Color(0xFF838691);
  static const ring = primary;

  // ── Product semantic tokens ──────────────────────────────────────────
  static const warm = Color(0xFFF27424);
  static const warmForeground = Color(0xFF3D1D04);
  static const warmSurface = Color(0xFFFFE7C9);

  static const coral = Color(0xFFD65A3D);
  static const coralForeground = Color(0xFFFFFFFF);
  static const coralSurface = Color(0xFFFFE5DA);

  static const blueberry = Color(0xFF406051);
  static const blueberryForeground = Color(0xFFFFFFFF);
  static const blueberrySurface = Color(0xFFE6EDE7);

  static const mint = Color(0xFFFCFFF2);
  static const mintForeground = primary;

  static const honey = Color(0xFFD5ED73);
  static const honeyForeground = primary;

  static const success = Color(0xFF5D7300);
  static const successForeground = Color(0xFFFFFFFF);

  // Onboarding conic-gradient loading ring + a couple of literal hex values
  // used inline in the web app rather than as named tokens. Kept named here
  // for traceability back to their source usage.
  static const homeHeroBorder = Color(0xFF798742);
  static const homeHeroRing = Color(0xFF173F2D);
  static const homeGoodAfternoon = Color(0xFF5D7300);
  static const eatOutLunchLabel = Color(0xFF6F8A00);
  static const eatOutCraveBg = Color(0xFFEEF3ED);
  static const questionnaireLabel = Color(0xFF406051);
  static const hackDetailProtein = Color(0xFFF27424);
  static const hackWhySurface = Color(0xFFFCFFF2);
}

class AppRadius {
  AppRadius._();
  static const sm = 5.0; // 0.5rem * 0.6 * 16
  static const md = 6.4; // 0.5rem * 0.8 * 16
  static const lg = 8.0; // --radius: 0.5rem
  static const xl = 12.0; // 0.5rem * 1.5 * 16
  static const xxl = 16.0; // 0.5rem * 2 * 16
  static const pill = 999.0;
}

class AppSpace {
  AppSpace._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}
