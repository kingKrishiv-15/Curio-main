import 'package:flutter/material.dart';

import '../../theme/curio_tokens.dart';
import '../widgets/curio_kit.dart';

/// Maps [CurioTokens] onto Material, in the Airbnb style Home set: a soft
/// blush page, white panels, one bold sans for headings, round back
/// buttons. There is no dark theme at the moment.
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
    // Headings in the one sans, bold and a little tight, as Airbnb sets
    // them. Line heights are opened up from the old serif's so descenders
    // never clip.
    TextStyle display(double size, double height, double tracking) => TextStyle(
      fontFamily: CurioTokens.faceBody,
      color: t,
      fontSize: size,
      height: height,
      fontWeight: FontWeight.w700,
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
      textTheme: TextTheme(
        displayLarge: display(48, 1.05, -1.4),
        displayMedium: display(40, 1.08, -1.1),
        displaySmall: display(34, 1.1, -.9),
        headlineLarge: display(34, 1.1, -.9),
        headlineMedium: display(28, 1.14, -.6),
        headlineSmall: display(24, 1.18, -.4),
        titleLarge: display(20, 1.25, -.2),
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
      // Airbnb's top bar: the page colour, a round back button on the
      // left and a small bold title in the middle.
      appBarTheme: AppBarTheme(
        backgroundColor: CurioTokens.base,
        foregroundColor: t,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: CurioTokens.body.copyWith(fontWeight: FontWeight.w700),
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) =>
            const CurioRoundIcon(Icons.arrow_back_ios_new_rounded),
        closeButtonIconBuilder: (context) =>
            const CurioRoundIcon(Icons.close_rounded),
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
        backgroundColor: t,
        contentTextStyle: CurioTokens.bodySmall.copyWith(
          color: CurioTokens.surface,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: CurioTokens.surface,
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
        floatingLabelStyle: CurioTokens.label.copyWith(color: t),
        border: _input(CurioTokens.border),
        enabledBorder: _input(CurioTokens.border),
        focusedBorder: _input(t, width: 1.5),
        errorBorder: _input(CurioTokens.wrong),
        focusedErrorBorder: _input(CurioTokens.wrong),
      ),
    );
  }

  static OutlineInputBorder _input(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: CurioTokens.cardShape,
        borderSide: BorderSide(color: color, width: width),
      );
}
