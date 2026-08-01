import 'package:flutter/material.dart';
import 'tokens.dart';

/// Type ramp — Satoshi (Fontshare), bundled locally as `assets/fonts/Satoshi-*.ttf`
/// (not on Google Fonts/pub.dev). Satoshi only ships weights 300/400/500/700/900 —
/// there is no 600 or 800 — so every style below is pinned to one of those five real
/// faces rather than letting Flutter synthesize an in-between weight, which looks
/// wrong on a geometric sans like this. See app-flutter/README.md.
class AppText {
  AppText._();

  /// "Small kerning" per the design instruction — a slight negative tracking,
  /// tighter at larger display sizes the way most display faces are set.
  static double _kerning(double size) => size >= 23 ? -0.4 : -0.2;

  static TextStyle _satoshi(double size, double height, FontWeight weight, {Color? color}) => TextStyle(
        fontFamily: 'Satoshi',
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        letterSpacing: _kerning(size),
        color: color ?? AppColors.foreground,
      );

  static TextStyle display({Color? color}) => _satoshi(42, 44, FontWeight.w900, color: color);
  static TextStyle h1({Color? color}) => _satoshi(30, 34, FontWeight.w900, color: color);
  static TextStyle h2({Color? color}) => _satoshi(23, 28, FontWeight.w900, color: color);
  static TextStyle h3({Color? color}) => _satoshi(17, 22, FontWeight.w700, color: color);

  static TextStyle body({Color? color}) => _satoshi(16, 24, FontWeight.w500, color: color);
  static TextStyle bodySm({Color? color}) => _satoshi(14, 20, FontWeight.w500, color: color);
  static TextStyle label({Color? color}) => _satoshi(14, 18, FontWeight.w700, color: color);
  static TextStyle caption({Color? color}) =>
      _satoshi(12, 17, FontWeight.w700, color: color ?? AppColors.mutedForeground);

  static TextStyle numeric({Color? color}) =>
      _satoshi(28, 32, FontWeight.w900, color: color).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle numericSm({Color? color}) =>
      _satoshi(16, 20, FontWeight.w700, color: color).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// `.eyebrow` — 11px/16, 900 weight (nearest real face to the web app's 800), uppercase, muted by default.
  static TextStyle eyebrow({Color? color}) =>
      _satoshi(11, 16, FontWeight.w900, color: color ?? AppColors.mutedForeground);
}
