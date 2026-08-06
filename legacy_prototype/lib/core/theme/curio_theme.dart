import 'package:flutter/material.dart';

import 'curio_colors.dart';

abstract final class CurioTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: CurioColors.teal,
        brightness: Brightness.light,
        primary: CurioColors.teal,
        secondary: CurioColors.coral,
        surface: CurioColors.cream,
      ),
      scaffoldBackgroundColor: CurioColors.cream,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            bodyColor: CurioColors.navy,
            displayColor: CurioColors.navy,
            fontFamily: 'Arial',
          )
          .copyWith(
            headlineLarge: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
            headlineMedium: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
            titleLarge: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            bodyLarge: const TextStyle(
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
            bodyMedium: const TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CurioColors.cream,
        foregroundColor: CurioColors.navy,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: CurioColors.creamDeep, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: CurioColors.teal, width: 2),
        ),
      ),
    );
  }
}
