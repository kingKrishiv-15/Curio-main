import 'package:flutter/material.dart';

import '../../theme/curio_tokens.dart';

/// Maps [CurioTokens] onto Material. Curio is light, in the original warm
/// palette. There is no dark theme at the moment.
abstract final class CurioTheme {
  static ThemeData get dark => _theme;
  static ThemeData get light => _theme;

  static final _theme = _build();

  static ThemeData _build() {
    const t = CurioTokens.textPrimary;
    const muted = CurioTokens.textSecondary;
    const scheme = ColorScheme.light(
      primary: CurioTokens.accent,
      onPrimary: CurioTokens.onAccent,
      secondary: CurioTokens.accent,
      onSecondary: CurioTokens.onAccent,
      tertiary: CurioTokens.tintThinking,
      onTertiary: CurioTokens.onAccent,
      error: CurioTokens.wrong,
      onError: CurioTokens.onAccent,
      surface: CurioTokens.surface,
      onSurface: t,
      onSurfaceVariant: muted,
      outline: CurioTokens.border,
      outlineVariant: CurioTokens.border,
      surfaceContainerHighest: CurioTokens.surfaceRaised,
      surfaceContainerHigh: CurioTokens.surfaceRaised,
      surfaceContainer: CurioTokens.surface,
      surfaceContainerLow: CurioTokens.surface,
      surfaceContainerLowest: CurioTokens.base,
    );
    const shape = RoundedRectangleBorder(borderRadius: CurioTokens.cardShape);
    const pill = StadiumBorder();
    final buttonText = CurioTokens.bodySmall.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
    final labelStrong = CurioTokens.label.copyWith(color: t);
    TextStyle display(double size, double height, double tracking) => TextStyle(
      fontFamily: CurioTokens.faceDisplay,
      color: t,
      fontSize: size,
      height: height,
      fontWeight: FontWeight.w500,
      letterSpacing: tracking,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: CurioTokens.base,
      canvasColor: CurioTokens.base,
      fontFamily: CurioTokens.faceBody,
      splashFactory: InkRipple.splashFactory,
      dividerColor: CurioTokens.border,
      extensions: const [CurioTokens()],
      // The original type scale, restored so the onboarding screens look
      // as they did. Newer screens read their styles from CurioTokens.
      textTheme: TextTheme(
        displayLarge: display(52, .91, -2.6),
        displayMedium: display(44, .95, -2.2),
        displaySmall: display(38, .96, -2),
        headlineLarge: display(38, .96, -2),
        headlineMedium: display(29, 1.02, -1.2),
        headlineSmall: display(24, 1.08, -.8),
        titleLarge: display(21, 1.18, -.55),
        titleMedium: CurioTokens.body.copyWith(
          height: 1.28,
          fontWeight: FontWeight.w700,
          letterSpacing: -.15,
        ),
        titleSmall: labelStrong,
        bodyLarge: CurioTokens.body.copyWith(
          height: 1.52,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: CurioTokens.bodySmall.copyWith(
          color: t,
          height: 1.48,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: CurioTokens.bodySmall.copyWith(
          fontSize: 12,
          height: 1.42,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: labelStrong,
        labelMedium: CurioTokens.label,
        labelSmall: CurioTokens.label,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CurioTokens.base,
        foregroundColor: t,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: CurioTokens.title,
      ),
      dividerTheme: const DividerThemeData(
        color: CurioTokens.border,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: CurioTokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: CurioTokens.cardShape,
          side: BorderSide(color: CurioTokens.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: CurioTokens.accent,
          foregroundColor: CurioTokens.onAccent,
          disabledBackgroundColor: CurioTokens.surfaceRaised,
          disabledForegroundColor: muted,
          elevation: 0,
          shape: pill,
          minimumSize: const Size(48, 54),
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CurioTokens.accent,
          foregroundColor: CurioTokens.onAccent,
          disabledBackgroundColor: CurioTokens.surfaceRaised,
          disabledForegroundColor: muted,
          elevation: 0,
          shape: pill,
          minimumSize: const Size(48, 54),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t,
          side: const BorderSide(color: CurioTokens.border),
          shape: pill,
          minimumSize: const Size(48, 54),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CurioTokens.accent,
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      iconTheme: const IconThemeData(color: t),
      chipTheme: ChipThemeData(
        backgroundColor: CurioTokens.surface,
        selectedColor: CurioTokens.surfaceRaised,
        side: const BorderSide(color: CurioTokens.border),
        shape: pill,
        labelStyle: labelStrong,
        elevation: 0,
        pressElevation: 0,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: CurioTokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: CurioTokens.cardShape,
          side: BorderSide(color: CurioTokens.border),
        ),
        titleTextStyle: CurioTokens.title,
        contentTextStyle: CurioTokens.bodySmall,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CurioTokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(CurioTokens.radiusCard),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: t,
        titleTextStyle: CurioTokens.body,
        subtitleTextStyle: CurioTokens.bodySmall,
        shape: shape,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CurioTokens.surfaceRaised,
        contentTextStyle: CurioTokens.bodySmall.copyWith(color: t),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: shape,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? CurioTokens.onAccent : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? CurioTokens.accent
              : CurioTokens.surfaceRaised,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(CurioTokens.border),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CurioTokens.accent,
        linearTrackColor: CurioTokens.surfaceRaised,
        circularTrackColor: CurioTokens.surfaceRaised,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CurioTokens.surface,
        contentPadding: const EdgeInsets.all(16),
        hintStyle: CurioTokens.body.copyWith(color: muted),
        labelStyle: CurioTokens.bodySmall,
        floatingLabelStyle: CurioTokens.label.copyWith(
          color: CurioTokens.accent,
        ),
        border: _input(CurioTokens.border),
        enabledBorder: _input(CurioTokens.border),
        focusedBorder: _input(CurioTokens.accent),
        errorBorder: _input(CurioTokens.wrong),
        focusedErrorBorder: _input(CurioTokens.wrong),
      ),
    );
  }

  static OutlineInputBorder _input(Color color) => OutlineInputBorder(
    borderRadius: CurioTokens.cardShape,
    borderSide: BorderSide(color: color),
  );
}
