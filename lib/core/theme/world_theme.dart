import 'package:flutter/material.dart';

/// Per-story-world visual identity (dark, cinematic, moody - a different
/// system from the platform layer's bold light mode). Implemented as a
/// `ThemeExtension` so each world's screens read one line off `Theme.of
/// (context)` instead of hardcoding colors - adding a new story world later
/// is "define one more WorldTheme instance," not "hunt down every
/// Color(0x...) in a new set of widgets."
///
/// Frostlands and Vaultkeeper instances live in their own theme files
/// (frostlands_theme.dart, vaultkeeper_theme.dart) once those screens are
/// built - this file only defines the shape every world theme follows.
@immutable
class WorldTheme extends ThemeExtension<WorldTheme> {
  const WorldTheme({
    required this.name,
    required this.backgroundGradient,
    required this.surfaceColor,
    required this.accentColor,
    required this.accentGlowColor,
    required this.textColor,
    required this.mutedTextColor,
  });

  /// Human-readable world name, used in scene labels ("Night 1 · Frostlands").
  final String name;

  /// Base scene backdrop, dark end to light end (e.g. deep navy -> frost
  /// blue for Frostlands, near-black -> amber for Vaultkeeper).
  final List<Color> backgroundGradient;

  /// Glass-panel / card backing color (usually a translucent dark).
  final Color surfaceColor;

  /// The world's signature light source color (ember firelight for
  /// Frostlands, gold torchlight for Vaultkeeper) - used for glows, active
  /// states, and the companion's accent lighting.
  final Color accentColor;

  /// A softer, blurrable version of accentColor for glow/shadow effects.
  final Color accentGlowColor;

  final Color textColor;
  final Color mutedTextColor;

  @override
  WorldTheme copyWith({
    String? name,
    List<Color>? backgroundGradient,
    Color? surfaceColor,
    Color? accentColor,
    Color? accentGlowColor,
    Color? textColor,
    Color? mutedTextColor,
  }) {
    return WorldTheme(
      name: name ?? this.name,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      accentColor: accentColor ?? this.accentColor,
      accentGlowColor: accentGlowColor ?? this.accentGlowColor,
      textColor: textColor ?? this.textColor,
      mutedTextColor: mutedTextColor ?? this.mutedTextColor,
    );
  }

  @override
  WorldTheme lerp(ThemeExtension<WorldTheme>? other, double t) {
    if (other is! WorldTheme) return this;
    return WorldTheme(
      name: t < 0.5 ? name : other.name,
      backgroundGradient: [
        for (var i = 0; i < backgroundGradient.length; i++)
          Color.lerp(backgroundGradient[i], other.backgroundGradient[i], t)!,
      ],
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      accentGlowColor: Color.lerp(accentGlowColor, other.accentGlowColor, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      mutedTextColor: Color.lerp(mutedTextColor, other.mutedTextColor, t)!,
    );
  }
}
