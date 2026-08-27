import 'package:flutter/material.dart';

/// Curio's semantic colour system.
///
/// Palette adapted from the provided Hasta Kalā reference: warm paper,
/// oxblood action, forest contrast, antique gold, and ink typography.
abstract final class CurioColors {
  static const canvas = Color(0xFFE2ECE6);
  static const canvasDeep = Color(0xFFD4E3DA);
  static const surface = Color(0xFFF1F6F2);
  static const surfaceMuted = Color(0xFFDCE8E0);
  static const onDark = Color(0xFFF4FAF6);
  static const ink = Color(0xFF17201D);
  static const inkSoft = Color(0xFF46514C);
  static const inkMuted = Color(0xFF68736E);
  static const outline = Color(0x3D405049);
  static const outlineSoft = Color(0x24405049);

  static const forest = Color(0xFF183E35);
  static const forestStrong = Color(0xFF102C26);
  static const forestSoft = Color(0xFFD4E4DD);
  static const forestMist = Color(0xFFE2ECE7);

  static const coral = Color(0xFF2D6A5B);
  static const coralStrong = Color(0xFF19483D);
  static const coralSoft = Color(0xFFCFE0D7);
  static const saffron = Color(0xFFCBD957);
  static const saffronStrong = Color(0xFF667119);
  static const saffronSoft = Color(0xFFF0F3C9);
  static const blue = Color(0xFF487568);
  static const blueSoft = Color(0xFFD9E7E1);
  static const plum = Color(0xFF315B50);
  static const plumSoft = Color(0xFFDCE8E3);
  static const success = Color(0xFF237A54);
  static const successSoft = Color(0xFFDFEFE5);
  static const danger = Color(0xFFB84335);
  static const dangerSoft = Color(0xFFF8E1DD);

  static const night = forestStrong;
  static const ice = Color(0xFF5A8D7D);
  static const iceSoft = Color(0xFFDCEAE4);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forestStrong, forest, Color(0xFF2D6A5B)],
  );

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forestStrong, forest],
  );

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F1EB), Color(0xFFDDEAE2), Color(0xFFD5E5DC)],
    stops: [0, .6, 1],
  );

  // Compatibility aliases for established game presentation code.
  static const cream = canvas;
  static const creamDeep = outlineSoft;
  static const navy = ink;
  static const navySoft = inkSoft;
  static const navyMuted = inkMuted;
  static const primary = forest;
  static const primaryStrong = forestStrong;
  static const primarySoft = forestSoft;
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
  static const mintBright = Color(0xFF4AAD8C);
  static const skyBright = Color(0xFF78A99A);
  static const auroraGradient = brandGradient;
}
