import 'package:flutter/material.dart';
import 'tokens.dart';

/// Type scale reconciled against the Figma redesign pulled 2026-08-06
/// (`figma.com/design/LjDp489aFZaYiDx88MvvkQ`, node 321:2 "Page 5" — Onboarding,
/// Home, Track, Cook, Eat Out). This supersedes the `Design Style Guide.pdf`
/// scale in `h1`/`h2`/`h3`/`display*` below; the guide's names are kept because
/// call sites across the app already use them, but the *sizes* and the second
/// display face now come from Figma's actual node inspection, not the PDF.
///
/// Three families, matching Figma's own font usage exactly (verified per-node
/// via `get_design_context`, not guessed from the screenshot):
///  * **Galantic** — big display headlines only ("Real meals with the macros
///    worked out.", "Your day, in context", "Cook"/"Eat out" tile labels).
///  * **Satoshi** — greetings, card/row titles, bold stat figures. This was
///    removed from the project during the Style Guide pass on 2026-08-05 and
///    is restored here (`git checkout` from commit f198437) because this Figma
///    depends on it throughout.
///  * **Manrope** — body copy, captions, labels, buttons, kickers — unchanged.
///
/// One documented substitution: Track's big "1,090 cal" figure is set in
/// `DM Sans Variable ExtraBold` in Figma. DM Sans is not part of this project
/// and pulling in a fourth font family for one number was not worth it —
/// [heroStat] uses Satoshi Black instead, which is visually the same weight
/// class (a bold-to-black grotesque) at the sizes this app uses it at.
class AppText {
  AppText._();

  static TextStyle _display(double size, double height, {Color? color}) =>
      TextStyle(
        fontFamily: 'Galantic',
        fontSize: size,
        height: height / size,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle _satoshi(
    double size,
    double height,
    FontWeight weight, {
    Color? color,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: 'Satoshi',
    fontSize: size,
    height: height / size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle _manrope(
    double size,
    double height,
    FontWeight weight, {
    Color? color,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: 'Manrope',
    fontSize: size,
    height: height / size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    color: color ?? AppColors.textPrimary,
  );

  // ── Display (Galantic) ───────────────────────────────────────────────────
  static TextStyle displayLarge({Color? color}) =>
      _display(72, 68, color: color);
  static TextStyle displayMedium({Color? color}) =>
      _display(56, 52, color: color);
  static TextStyle displaySmall({Color? color}) => _display(42, 38, color: color);

  /// Existing call sites use `display()` for the largest on-screen number or
  /// headline. Maps to Display/Small — the sizes above it are for marketing
  /// canvases, not a 430px phone frame.
  static TextStyle display({Color? color}) => displaySmall(color: color);

  /// Arbitrary-size Galantic escape hatch. Figma uses the display face at
  /// several one-off sizes per screen (40px on Home's hero line, 32px on
  /// "What do you need?"/"Pick an order"/tile labels) that don't line up with
  /// the guide's fixed H1/H2/H3 steps. Reach for this instead of inventing a
  /// new named preset for a size used once.
  static TextStyle headline(double size, {double? height, Color? color}) =>
      _display(size, height ?? size * 0.95, color: color);

  // ── Headings (Galantic) ──────────────────────────────────────────────────
  static TextStyle h1({Color? color}) => _display(36, 34, color: color);
  static TextStyle h2({Color? color}) => _display(28, 28, color: color);
  static TextStyle h3({Color? color}) => _display(22, 24, color: color);

  // ── Body (Manrope Regular) ───────────────────────────────────────────────
  static TextStyle bodyLarge({Color? color}) =>
      _manrope(18, 28, FontWeight.w400, color: color);
  static TextStyle body({Color? color}) =>
      _manrope(16, 24, FontWeight.w400, color: color);
  static TextStyle bodySm({Color? color}) =>
      _manrope(14, 20, FontWeight.w400, color: color);

  // ── Labels (Manrope Medium) ──────────────────────────────────────────────
  static TextStyle labelLarge({Color? color}) =>
      _manrope(16, 20, FontWeight.w500, color: color);
  static TextStyle label({Color? color}) =>
      _manrope(14, 18, FontWeight.w500, color: color);
  static TextStyle labelSm({Color? color}) =>
      _manrope(12, 16, FontWeight.w500, color: color);

  // ── Caption (Manrope Regular) ────────────────────────────────────────────
  static TextStyle caption({Color? color}) => _manrope(
    12,
    16,
    FontWeight.w400,
    color: color ?? AppColors.textSecondary,
  );

  // ── Buttons (Manrope Bold) ───────────────────────────────────────────────
  static TextStyle buttonLarge({Color? color}) =>
      _manrope(16, 20, FontWeight.w700, color: color);
  static TextStyle button({Color? color}) =>
      _manrope(14, 18, FontWeight.w700, color: color);
  static TextStyle buttonSm({Color? color}) =>
      _manrope(12, 16, FontWeight.w700, color: color);

  /// Section kickers above a heading — "TODAY", "MEALS", "SMALL WINS",
  /// "TRACK". Figma's own eyebrow style: Manrope SemiBold 11px, 1.2 tracking,
  /// applied to uppercase text. This is the one consistent eyebrow treatment
  /// across the redesign's screens; call sites uppercase their own copy.
  static TextStyle kicker({Color? color}) => _manrope(
    11,
    16,
    FontWeight.w600,
    color: color ?? AppColors.textPrimary,
    letterSpacing: 1.2,
  );

  /// Legacy name for [kicker] — kept so pre-redesign call sites keep compiling.
  static TextStyle eyebrow({Color? color}) => _manrope(
    12,
    16,
    FontWeight.w700,
    color: color ?? AppColors.textSecondary,
  ).copyWith(letterSpacing: 0.6);

  // ── Satoshi — greetings, card titles, stat figures ──────────────────────

  /// Page-level personal greeting ("Hi, Steven"). Satoshi Regular, tight
  /// negative tracking, per Home's "Heading 1" node.
  static TextStyle greeting({Color? color}) =>
      _satoshi(24, 28, FontWeight.w400, color: color, letterSpacing: -1);

  /// Card/row titles that sit on a photo or a colored surface — the rail
  /// cards on Home, restaurant/recipe headline text. Satoshi Regular 17px.
  static TextStyle cardTitle({Color? color}) =>
      _satoshi(17, 22, FontWeight.w400, color: color);

  /// Small bold stat readouts ("69g", "18m") — Satoshi Black at label size.
  static TextStyle statFigure({Color? color}) =>
      _satoshi(16, 18, FontWeight.w900, color: color);

  /// Uppercase eyebrow tag on a card/hero image ("POLLO PERCH", "BEST FOR
  /// TODAY" pattern) — Satoshi Bold 11px, no tracking (Figma sets this one
  /// without letter-spacing, unlike [kicker]).
  static TextStyle tagBold({Color? color}) =>
      _satoshi(11, 16, FontWeight.w700, color: color);

  // ── Numeric ──────────────────────────────────────────────────────────────

  /// Hero figures — the guide's "Stat cards: large number + unit label". Uses
  /// the display face, matching H1.
  ///
  /// ⚠️ Galantic ships **no `tnum`** feature (verified against the font's GSUB
  /// table: aalt, dlig, frac, liga, ordn, salt, ss01, ss02, sups), so digits
  /// here are proportional and a value changing in place will shift width. That
  /// is fine for a single headline number; do **not** use this style for a
  /// column of figures that must stay aligned — use [numericSm], which is
  /// Manrope and does carry `tnum`.
  static TextStyle numeric({Color? color}) => _display(36, 34, color: color);

  /// Inline and tabular figures. Manrope, with real tabular digits.
  static TextStyle numericSm({Color? color}) => _manrope(
    16,
    20,
    FontWeight.w700,
    color: color,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// The oversized "1,090 cal" hero number on Track. Satoshi Black in place of
  /// Figma's DM Sans (see class doc) — also no `tnum`, same caveat as
  /// [numeric]: single headline figure only, never a column.
  static TextStyle heroStat({double size = 38, Color? color}) =>
      _satoshi(size, size, FontWeight.w900, color: color);
}
