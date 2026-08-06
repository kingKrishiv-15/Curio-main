import 'package:flutter/material.dart';

import 'curio_colors.dart';
import 'curio_typography.dart';

/// The platform layer's theme: bold light mode, not pastel/cream. This is
/// what Home, the Maths hub, the Curio Special hub, and Sharpen build on -
/// Story World screens (Frostlands, Vaultkeeper) use WorldTheme instead
/// (see world_theme.dart), not this.
class CurioTheme {
  CurioTheme._();

  static ThemeData platform() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: CurioColors.electricPurple,
      brightness: Brightness.light,
      surface: CurioColors.surface,
      onSurface: CurioColors.ink,
      primary: CurioColors.electricPurple,
      secondary: CurioColors.hotCoral,
      tertiary: CurioColors.acidGreen,
      error: CurioColors.hotCoral,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: CurioColors.platformBackground,
      textTheme: CurioTypography.platform,
      splashFactory: NoSplash.splashFactory, // custom press feedback replaces the default ripple - see PressableScale
      highlightColor: Colors.transparent,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CurioColors.ink,
          foregroundColor: CurioColors.surface,
          textStyle: CurioTypography.platform.titleLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CurioColors.electricPurple,
          textStyle: CurioTypography.platform.titleMedium,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: CurioColors.platformBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: CurioTypography.platform.headlineSmall,
        iconTheme: const IconThemeData(color: CurioColors.ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CurioColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
