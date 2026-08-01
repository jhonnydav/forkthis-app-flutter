import 'package:flutter/material.dart';

/// Design tokens — ported verbatim from `../app/src/index.css` (`:root`), which is
/// the only source of truth for the current palette. Do not "improve" values here
/// without also changing the web app; the two must stay in sync by hand until a
/// real shared-token pipeline exists (see ENGINEERING-PLAN.md §3).
///
/// CONTRAST AUDIT (computed OKLCH→sRGB→WCAG against the live values, 2026):
/// Real failures exist in the current palette and were ported as-is rather than
/// silently corrected — this file mirrors what actually ships today:
///   • warmForeground on warm:      4.05:1 (needs 4.5 for body text; used only on
///     bold caption-weight badge text, which is borderline against the 3:1
///     large-text floor — acceptable there, NOT safe for body copy)
///   • warm as plain text on bg:    2.75:1 — do not use `warm` as a text color
///   • coralForeground on coral:    2.99:1 — `coral` is icon/accent-fill only
///   • input vs background/card:    ~1.3:1 — `input` no longer functions as a
///     ≥3:1 control-boundary token (it now equals `border`). Rely on `borderStrong`
///     for anything that must hit the 3:1 non-text UI floor.
/// See app-flutter/README.md for the full note.
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
  static const input = Color(0xFFDBDEE6);
  static const borderStrong = Color(0xFF838691);
  static const ring = primary;

  // ── Product semantic tokens ──────────────────────────────────────────
  static const warm = Color(0xFFF27424);
  static const warmForeground = Color(0xFF5C2B06);
  static const warmSurface = Color(0xFFFFE7C9);

  static const coral = Color(0xFFE96E50);
  static const coralForeground = Color(0xFFFDFCF8);
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
