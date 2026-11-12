import 'package:flutter/material.dart';

import '../../theme/curio_tokens.dart';

/// Maps [CurioTokens] onto Material. Curio is dark only.
abstract final class CurioTheme {
  static ThemeData get dark => _theme;
  static ThemeData get light => _theme;

  static final _theme = _build();

  static ThemeData _build() {
    const t = CurioTokens.textPrimary;
    const muted = CurioTokens.textSecondary;
    const scheme = ColorScheme.dark(
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
    final buttonText = CurioTokens.body.copyWith(fontWeight: FontWeight.w600);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    final labelStrong = CurioTokens.label.copyWith(color: t);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: CurioTokens.base,
      canvasColor: CurioTokens.base,
      fontFamily: CurioTokens.faceBody,
      splashFactory: InkRipple.splashFactory,
      dividerColor: CurioTokens.border,
      extensions: const [CurioTokens()],
      textTheme: TextTheme(
        displayLarge: CurioTokens.display,
        displayMedium: CurioTokens.display,
        displaySmall: CurioTokens.display,
        headlineLarge: CurioTokens.display,
        headlineMedium: CurioTokens.title,
        headlineSmall: CurioTokens.title,
        titleLarge: CurioTokens.title,
        titleMedium: CurioTokens.body.copyWith(fontWeight: FontWeight.w600),
        titleSmall: labelStrong,
        bodyLarge: CurioTokens.body,
        bodyMedium: CurioTokens.bodySmall.copyWith(color: t),
        bodySmall: CurioTokens.bodySmall,
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
          padding: buttonPadding,
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
          padding: buttonPadding,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t,
          side: const BorderSide(color: CurioTokens.border),
          shape: pill,
          padding: buttonPadding,
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
