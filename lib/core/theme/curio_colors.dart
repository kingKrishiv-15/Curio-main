import 'package:flutter/material.dart';

/// Curio's semantic colour system.
///
/// A deep, textured evergreen night palette: near-black canvas, glass
/// surfaces a few steps lighter (not another shade of green, so cards
/// separate from the page by hue as well as brightness), and accent hues
/// brightened to actually pop against a dark background rather than the
/// muted, light-page-oriented tones this used to hold.
abstract final class CurioColors {
  static const canvas = Color(0xFF05100D);
  static const canvasDeep = Color(0xFF0A1A15);
  static const surface = Color(0xFF232A2C);
  static const surfaceMuted = Color(0xFF15191A);
  static const onDark = Color(0xFFF4FAF6);
  static const ink = Color(0xFFF4FAF6);
  static const inkSoft = Color(0xFFC7D0CC);
  static const inkMuted = Color(0xFF8D948F);
  static const outline = Color(0x3DFFFFFF);
  static const outlineSoft = Color(0x24FFFFFF);

  static const forest = Color(0xFF49BB8C);
  static const forestStrong = Color(0xFF1F6B50);
  static const forestSoft = Color(0x2949BB8C);
  static const forestMist = Color(0x1449BB8C);

  static const coral = Color(0xFFE49577);
  static const coralStrong = Color(0xFFC97552);
  static const coralSoft = Color(0x29E49577);
  static const saffron = Color(0xFFE7BE6B);
  static const saffronStrong = Color(0xFFB8934A);
  static const saffronSoft = Color(0x29E7BE6B);
  static const blue = Color(0xFF8FC3D9);
  static const blueSoft = Color(0x298FC3D9);
  static const plum = Color(0xFFBFA6E0);
  static const plumSoft = Color(0x29BFA6E0);
  static const success = Color(0xFF4FD69B);
  static const successSoft = Color(0x294FD69B);
  static const danger = Color(0xFFF0685A);
  static const dangerSoft = Color(0x29F0685A);

  static const night = Color(0xFF05100D);
  static const ice = Color(0xFF7FB8A8);
  static const iceSoft = Color(0x257FB8A8);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1A15), forestStrong, Color(0xFF15392E)],
  );

  /// The logo mark's evergreen tile, glyph and spark. Identical in both
  /// palettes on purpose: the mark doesn't change colour with the theme.
  static const markGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3FA67C), Color(0xFF1F6B50), Color(0xFF123F30)],
    stops: [0, .55, 1],
  );
  static const markGlyph = Color(0xFFFFF8EE);

  /// The brand spark — the mark's sparkle and the wordmark's i-dot. Also a
  /// fine accent wherever a "moment of discovery" is being celebrated.
  static const spark = Color(0xFFF2C660);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forestStrong, forest],
  );

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0E211B), Color(0xFF0A1A15), canvas],
    stops: [0, .55, 1],
  );

  // Compatibility aliases for established game presentation code.
  static const cream = canvas;
  static const creamDeep = outlineSoft;

  /// A deep, jewel-toned card fill — deliberately independent of [ink] (the
  /// two used to be the same colour, which broke the moment text needed to
  /// go light-on-dark while these "hero" cards needed to stay a rich, dark
  /// accent). Used for the bold stat/reward display cards in the game
  /// pages (e.g. Squeeze's secret-range card).
  static const navy = Color(0xFF123A30);
  static const navySoft = inkSoft;
  static const navyMuted = inkMuted;
  static const primary = forest;
  static const primaryStrong = forestStrong;
  static const primarySoft = forestSoft;
  static const jade = forest;
  static const jadeStrong = forestStrong;
  static const jadeSoft = forestSoft;
  static const teal = forest;
  // Only ever used for text and icons, where forestStrong (#1F6B50) is too
  // dark to read on dark surfaces (~2.3:1); the brighter forest passes.
  static const tealDark = forest;
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
  static const mintBright = Color(0xFF5FD9A8);
  static const skyBright = Color(0xFF8FC3D9);
  static const auroraGradient = brandGradient;
}
