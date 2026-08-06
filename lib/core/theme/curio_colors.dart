import 'package:flutter/material.dart';

/// Curio's color system. Two families:
///
/// - Platform neutrals + electric accents: the bold light-mode base every
///   platform-layer screen (Home, Maths hub, Curio Special hub, Sharpen)
///   shares. Deliberately NOT cream/pastel - a cool, punchy off-white base
///   with fully saturated accents doing real work, not decoration.
/// - World palettes (Frostlands, Vaultkeeper) live in world_theme.dart as
///   ThemeExtension instances, not here - they're dark-mode and
///   scene-specific, a different system entirely from the platform layer.
class CurioColors {
  CurioColors._();

  // ---- Platform neutrals -----------------------------------------------
  // Cool, light, slightly lavender-tinted - not warm cream, not sterile
  // pure white. This is the "bold light mode" base.
  static const platformBackground = Color(0xFFF4F3FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFEBE9F4);

  static const ink = Color(0xFF15121F); // primary text - near-black, not pure black
  static const inkMuted = Color(0xFF6E6B7A); // secondary text

  // ---- Electric accents --------------------------------------------------
  // Four fully saturated colors, each doing a specific job rather than
  // being interchangeable decoration - see curio_theme.dart's
  // ModeAccent usage for which entry point owns which color.
  static const electricPurple = Color(0xFF7C3AED); // brand primary
  static const acidGreen = Color(0xFF1FE873); // growth / mastery / success
  static const hotCoral = Color(0xFFFF4D6D); // energy / streaks / urgency
  static const cyberLime = Color(0xFFD4FF3F); // highlights / celebratory pops

  // Soft tints of each accent, for card backgrounds behind a saturated
  // icon/text of the same hue - keeps large surfaces from turning into a
  // wall of neon while the accent itself stays fully vivid where it counts.
  static const electricPurpleTint = Color(0xFFEDE4FF);
  static const acidGreenTint = Color(0xFFDCFFEA);
  static const hotCoralTint = Color(0xFFFFE1E8);
  static const cyberLimeTint = Color(0xFFF4FFC9);
}
