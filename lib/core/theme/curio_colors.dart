import 'package:flutter/material.dart';

abstract final class CurioColors {
  // Product neutrals: cool enough to feel modern, warm enough for long
  // learning sessions. These carry the majority of the interface.
  static const cream = Color(0xFFF4F7FB);
  static const creamDeep = Color(0xFFDDE5EF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEDF2F7);
  static const navy = Color(0xFF14213D);
  static const navyMuted = Color(0xFF607089);
  static const navySoft = Color(0xFF33445F);

  // Semantic brand ramps. Cobalt is instructive/action, jade communicates
  // exploration, and sunbeam is reserved for rewards. Legacy aliases keep
  // feature code readable while the product migrates to semantic names.
  static const primary = Color(0xFF315EDB);
  static const primaryStrong = Color(0xFF1E3A8A);
  static const primarySoft = Color(0xFFE6EEFF);
  static const jade = Color(0xFF0F766E);
  static const jadeStrong = Color(0xFF115E59);
  static const jadeSoft = Color(0xFFDDF7F2);
  static const mintBright = Color(0xFF2DD4BF);
  static const skyBright = Color(0xFF38BDF8);

  static const teal = jade;
  static const tealDark = jadeStrong;
  static const tealSoft = jadeSoft;
  static const coral = primary;
  static const coralDark = primaryStrong;
  static const coralSoft = primarySoft;
  static const gold = Color(0xFFF7C948);
  static const goldStrong = Color(0xFF8A6100);
  static const goldSoft = Color(0xFFFFF4CF);
  static const frost = Color(0xFF7057E8);
  static const frostDark = Color(0xFF243B64);
  static const green = Color(0xFF178654);
  static const greenSoft = Color(0xFFDFF6E9);
  static const orange = Color(0xFFB5472F);
  static const orangeSoft = Color(0xFFFFE8E1);
  static const pink = Color(0xFFC93D78);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF102D4F), Color(0xFF165C72), Color(0xFF0F8B80)],
    stops: [0, .55, 1],
  );

  static const auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mintBright, skyBright],
  );

  static const pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF9FBFF), cream, Color(0xFFF0FAF7)],
    stops: [0, .55, 1],
  );
}
