import 'package:flutter/material.dart';

/// The light-mode counterpart to [CurioColors] — same field names, so any
/// call site can pick between the two with
/// `isDark ? CurioColors.x : CurioColorsLight.x`. A warm, bright, clean
/// cream palette: white cards, saturated (not washed-out) accent hues that
/// read clearly as text/icons on a light surface, one primary coral accent.
///
/// See [design.md](../../../design.md) for the full system and the
/// per-token rationale.
abstract final class CurioColorsLight {
  static const canvas = Color(0xFFFDF1E2);
  static const canvasDeep = Color(0xFFFFF8EE);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF3E9D8);

  /// The default clay body (`CurioClay`): warm white on cream.
  static const clay = Color(0xFFFFFCF7);
  static const onDark = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2E2417);
  static const inkSoft = Color(0xFF5B4E3B);
  static const inkMuted = Color(0xFF8C7C63);
  static const outline = Color(0x1F2E2417);
  static const outlineSoft = Color(0x142E2417);

  static const forest = Color(0xFF25A369);
  static const forestStrong = Color(0xFF15803F);
  static const forestSoft = Color(0xFFDBF5E4);
  static const forestMist = Color(0xFFEFFBF3);

  static const coral = Color(0xFFF2564A);
  static const coralStrong = Color(0xFFD8362B);
  static const coralSoft = Color(0xFFFCE1DE);
  static const saffron = Color(0xFFDB9A2C);
  static const saffronStrong = Color(0xFFAD7A0C);
  static const saffronSoft = Color(0xFFFFEEBE);
  static const blue = Color(0xFF2E9FD6);
  static const blueSoft = Color(0xFFDBEFFA);
  static const plum = Color(0xFF8467E0);
  static const plumSoft = Color(0xFFEAE3FC);

  /// A sixth hue for puzzles that need one more distinct colour.
  static const rose = Color(0xFFD9548E);
  static const success = Color(0xFF25A369);
  static const successSoft = Color(0xFFDBF5E4);
  static const danger = Color(0xFFD8362B);
  static const dangerSoft = Color(0xFFFCE1DE);

  static const night = Color(0xFF2E2417);
  static const ice = Color(0xFF2E9FD6);
  static const iceSoft = Color(0xFFDBEFFA);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFEEBE), Color(0xFFFCE1DE), Color(0xFFEAE3FC)],
  );

  /// The logo mark's evergreen tile, glyph and spark. Identical in both
  /// palettes on purpose: the mark doesn't change colour with the theme.
  static const markGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D4E3F), Color(0xFF143D31), Color(0xFF0D2B23)],
    stops: [0, .55, 1],
  );
  static const markGlyph = Color(0xFF8FE3BD);

  /// The brand gold — the mark's lens and the wordmark's i-dot. Also a
  /// fine accent wherever a "moment of discovery" is being celebrated.
  static const spark = Color(0xFFE3A21A);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coral, coralStrong],
  );

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF8EE), canvas],
    stops: [0, 1],
  );

  // Compatibility aliases — mirrors CurioColors 1:1 so a call site can swap
  // classes without needing a different field name.
  static const cream = canvas;
  static const creamDeep = outlineSoft;

  /// The bold "hero" card fill (e.g. Squeeze's secret-range card) — a
  /// saturated coral-tinted deep tone in light mode rather than the
  /// near-black jewel tone [CurioColors.navy] uses in dark mode. Paired
  /// with white text, same as its dark-mode counterpart.
  static const navy = Color(0xFFE24A3D);
  static const navySoft = inkSoft;
  static const navyMuted = inkMuted;
  static const primary = coral;
  static const primaryStrong = coralStrong;
  static const primarySoft = coralSoft;
  static const jade = forest;
  static const jadeStrong = forestStrong;
  static const jadeSoft = forestSoft;
  static const teal = forest;
  static const tealDark = forestStrong;
  static const tealSoft = forestSoft;
  static const coralDark = coralStrong;
  static const gold = saffron;
  static const goldStrong = saffronStrong;
  static const goldSoft = saffronSoft;
  static const frost = blue;
  static const frostDark = night;
  static const green = success;
  static const greenSoft = successSoft;
  static const orange = coral;
  static const orangeSoft = coralSoft;
  static const pink = plum;
  static const mintBright = forest;
  static const skyBright = blue;
  static const auroraGradient = brandGradient;
}
