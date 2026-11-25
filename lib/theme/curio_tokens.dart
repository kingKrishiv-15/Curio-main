import 'package:flutter/material.dart';

/// Curio's whole visual budget. See DESIGN.md at the repo root.
///
/// Every colour, radius, gap, type role, shadow and duration in the app
/// comes from here. Tests in test/design_rules_test.dart fail the build
/// when a screen reaches for a value this file does not define.
@immutable
class CurioTokens extends ThemeExtension<CurioTokens> {
  const CurioTokens();

  static CurioTokens of(BuildContext context) =>
      Theme.of(context).extension<CurioTokens>() ?? const CurioTokens();

  // Colour: 13 tokens. The page is a whisper of coral over white and
  // panels are white, as on Airbnb; quiet fills (round buttons, tracks,
  // empty cells) are a neutral grey. Accents keep the original palette.
  static const base = Color(0xFFFEF7F6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceRaised = Color(0xFFF2F2F1);
  static const border = Color(0x1F2E2417);
  static const textPrimary = Color(0xFF2E2417);
  static const textSecondary = Color(0xFF5B4E3B);
  static const accent = Color(0xFFF2564A);
  static const onAccent = Color(0xFF2A2014);
  static const correct = Color(0xFF15803F);
  static const wrong = Color(0xFFD8362B);
  static const tintMaths = Color(0xFFDB9A2C);
  static const tintLogic = Color(0xFF2E9FD6);
  static const tintThinking = Color(0xFF8467E0);

  /// A section tint as a flat, opaque panel wash (the tint at low opacity
  /// over [surface]).
  static Color wash(Color tint, [double amount = .12]) =>
      Color.alphaBlend(tint.withValues(alpha: amount), surface);

  // Radii: 2.
  static const radiusCard = 20.0;
  static const radiusPill = 999.0;
  static const cardShape = BorderRadius.all(Radius.circular(radiusCard));
  static const pillShape = BorderRadius.all(Radius.circular(radiusPill));

  // Elevation: 2. shadowRaised belongs to one element per screen.
  static const shadowNone = <BoxShadow>[];
  static const shadowRaised = <BoxShadow>[
    BoxShadow(color: Color(0x242E2417), blurRadius: 24, offset: Offset(0, 8)),
  ];

  // Spacing: one scale.
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s48 = 48.0;

  // Type: one face, 5 roles. Like Airbnb, everything is set in one sans
  // (DM Sans) and weight does the work: headings bold and slightly tight.
  // Fraunces survives only in the "curio" wordmark.
  static const faceBody = 'DM Sans';
  static const display = TextStyle(
    fontFamily: faceBody,
    fontSize: 32,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -.6,
    color: textPrimary,
  );
  static const title = TextStyle(
    fontFamily: faceBody,
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -.2,
    color: textPrimary,
  );
  static const body = TextStyle(
    fontFamily: faceBody,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );
  static const bodySmall = TextStyle(
    fontFamily: faceBody,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  static const label = TextStyle(
    fontFamily: faceBody,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  // Motion: 2 durations, 1 curve.
  static const fast = Duration(milliseconds: 120);
  static const slow = Duration(milliseconds: 220);
  static const curve = Curves.easeOutCubic;

  /// [duration], or zero when the person has asked for reduced motion.
  static Duration motion(BuildContext context, [Duration duration = fast]) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false
      ? Duration.zero
      : duration;

  @override
  CurioTokens copyWith() => this;

  @override
  CurioTokens lerp(ThemeExtension<CurioTokens>? other, double t) => this;
}
