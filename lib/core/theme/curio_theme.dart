import 'package:flutter/material.dart';

/// Minimal placeholder theme for Phase 0. The full warm-teal/cream/coral/navy
/// design system (ported from the archived prototype's design intent, not
/// its code) lands with the presentation-layer screens in later phases.
class CurioTheme {
  CurioTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2FA398), // teal - matches the platform's primary brand color
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFFFFCF6), // warm cream
    );
  }
}
