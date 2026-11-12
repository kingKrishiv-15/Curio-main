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

  // Colour: 13 tokens.
  static const base = Color(0xFF05100D);
  static const surface = Color(0xFF15191A);
  static const surfaceRaised = Color(0xFF232A2C);
  static const border = Color(0x24FFFFFF);
  static const textPrimary = Color(0xFFF4FAF6);
  static const textSecondary = Color(0xFF8D948F);
  static const accent = Color(0xFF49BB8C);
  static const onAccent = Color(0xFF05100D);
  static const correct = Color(0xFF4FD69B);
  static const wrong = Color(0xFFF0685A);
  static const tintMaths = Color(0xFFE7BE6B);
  static const tintLogic = Color(0xFF8FC3D9);
  static const tintThinking = Color(0xFFBFA6E0);

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
    BoxShadow(color: Color(0x73000000), blurRadius: 32, offset: Offset(0, 16)),
  ];

  // Spacing: one scale.
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s48 = 48.0;

  // Type: 2 faces, 5 roles.
  static const faceDisplay = 'Fraunces';
  static const faceBody = 'DM Sans';
  static const display = TextStyle(
    fontFamily: faceDisplay,
    fontSize: 32,
    height: 1.15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  static const title = TextStyle(
    fontFamily: faceDisplay,
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w600,
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
