import 'package:flutter/material.dart';

import 'curio_colors.dart';

/// Font pairing rationale (the brief asked this be justified, not just
/// picked):
///
/// - Display / headers / big numbers (streaks, XP, scores): **Unbounded**.
///   A bold geometric-grotesk with genuinely chunky, confident letterforms
///   and great numeral design - it reads as current and a little playful
///   without tipping into "kids app" cutesy, which is exactly the Discord/
///   Spotify-adjacent energy the brief wants. Its wide weight range (200-900,
///   bundled here as a single variable font) covers everything from a large
///   hero number down to a bold section label with one consistent voice.
/// - Body / UI copy: **Manrope**. A clean geometric sans that shares
///   Unbounded's geometric DNA (so the pairing feels designed together, not
///   like two unrelated fonts glued on) but is far more neutral and legible
///   at small sizes - exactly what body copy needs and Unbounded doesn't
///   have to try to be.
///
/// Both are open-source (SIL OFL) variable fonts, bundled locally (see
/// pubspec.yaml) rather than fetched at runtime, so text renders correctly
/// offline from first launch.
class CurioTypography {
  CurioTypography._();

  static const _display = 'Unbounded';
  static const _body = 'Manrope';

  static TextTheme textTheme(Color baseColor) {
    final base = TextTheme(
      displayLarge: TextStyle(fontFamily: _display, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.05, color: baseColor),
      displayMedium: TextStyle(fontFamily: _display, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.08, color: baseColor),
      headlineLarge: TextStyle(fontFamily: _display, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.1, color: baseColor),
      headlineMedium: TextStyle(fontFamily: _display, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.15, color: baseColor),
      headlineSmall: TextStyle(fontFamily: _display, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.1, height: 1.2, color: baseColor),
      titleLarge: TextStyle(fontFamily: _display, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0, height: 1.25, color: baseColor),
      titleMedium: TextStyle(fontFamily: _body, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0, height: 1.3, color: baseColor),
      bodyLarge: TextStyle(fontFamily: _body, fontSize: 16, fontWeight: FontWeight.w500, height: 1.4, color: baseColor),
      bodyMedium: TextStyle(fontFamily: _body, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4, color: baseColor),
      bodySmall: TextStyle(fontFamily: _body, fontSize: 12, fontWeight: FontWeight.w500, height: 1.35, color: baseColor),
      labelLarge: TextStyle(fontFamily: _body, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: baseColor),
      labelMedium: TextStyle(fontFamily: _body, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: baseColor),
    );
    return base;
  }

  /// A dedicated style for the big animated stat numbers (streak count, XP,
  /// score) - one step bigger and heavier than displayLarge, with tighter
  /// tracking, because these need to feel like the visual anchor of a card.
  static TextStyle statNumber(Color color) => TextStyle(
    fontFamily: _display,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.0,
    color: color,
  );

  static final platform = textTheme(CurioColors.ink);
}
