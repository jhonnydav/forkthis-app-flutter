import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

/// Type ramp — ported verbatim from `index.css` `@layer components` (`.t-*` classes).
/// Two families, matching the web app exactly: DM Sans for display/headings
/// (`--font-display`), Manrope for everything else (`--font-sans`).
class AppText {
  AppText._();

  static TextStyle _display(double size, double height, FontWeight weight, {Color? color}) =>
      GoogleFonts.dmSans(fontSize: size, height: height / size, fontWeight: weight, color: color ?? AppColors.foreground);

  static TextStyle _sans(double size, double height, FontWeight weight, {Color? color}) =>
      GoogleFonts.manrope(fontSize: size, height: height / size, fontWeight: weight, color: color ?? AppColors.foreground);

  static TextStyle display({Color? color}) => _display(42, 44, FontWeight.w800, color: color);
  static TextStyle h1({Color? color}) => _display(30, 34, FontWeight.w800, color: color);
  static TextStyle h2({Color? color}) => _display(23, 28, FontWeight.w800, color: color);
  static TextStyle h3({Color? color}) => _display(17, 22, FontWeight.w700 /* 750 → nearest */, color: color);

  static TextStyle body({Color? color}) => _sans(16, 24, FontWeight.w500 /* 450 → nearest */, color: color);
  static TextStyle bodySm({Color? color}) => _sans(14, 20, FontWeight.w500, color: color);
  static TextStyle label({Color? color}) => _sans(14, 18, FontWeight.w700, color: color);
  static TextStyle caption({Color? color}) =>
      _sans(12, 17, FontWeight.w600 /* 550 → nearest */, color: color ?? AppColors.mutedForeground);

  static TextStyle numeric({Color? color}) =>
      _sans(28, 32, FontWeight.w800, color: color).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle numericSm({Color? color}) =>
      _sans(16, 20, FontWeight.w700, color: color).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// `.eyebrow` — 11px/16, 800 weight, uppercase, muted by default.
  static TextStyle eyebrow({Color? color}) =>
      _sans(11, 16, FontWeight.w800, color: color ?? AppColors.mutedForeground);
}
