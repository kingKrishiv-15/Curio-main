import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'curio_colors.dart';
import 'curio_colors_light.dart';

abstract final class CurioTheme {
  static const _display = 'Fraunces';
  static const _body = 'DM Sans';

  static ThemeData get dark => _build(dark: true);
  static ThemeData get light => _build(dark: false);

  /// One builder for both modes: every colour reference goes through [c],
  /// which just picks the matching named constant from [CurioColors]
  /// (dark) or [CurioColorsLight] (light) — the two classes share field
  /// names by design specifically so this stays a 1:1 swap, never a
  /// judgement call about which `ColorScheme` slot something maps to.
  static ThemeData _build({required bool dark}) {
    Color c(Color darkColor, Color lightColor) => dark ? darkColor : lightColor;

    final scheme = ColorScheme.fromSeed(
      seedColor: c(CurioColors.coral, CurioColorsLight.coral),
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: c(CurioColors.coral, CurioColorsLight.coral),
      // Coral is a *bright* accent in both modes, so its "on" colour is
      // always the dark ink, never the light text colour.
      onPrimary: c(CurioColors.night, CurioColorsLight.ink),
      primaryContainer: c(CurioColors.coralSoft, CurioColorsLight.coralSoft),
      onPrimaryContainer: c(
        CurioColors.coralStrong,
        CurioColorsLight.coralStrong,
      ),
      secondary: c(CurioColors.forest, CurioColorsLight.forest),
      onSecondary: c(CurioColors.night, CurioColorsLight.ink),
      secondaryContainer: c(
        CurioColors.forestSoft,
        CurioColorsLight.forestSoft,
      ),
      onSecondaryContainer: c(
        CurioColors.forestStrong,
        CurioColorsLight.forestStrong,
      ),
      surface: c(CurioColors.surface, CurioColorsLight.surface),
      onSurface: c(CurioColors.ink, CurioColorsLight.ink),
      surfaceContainerLowest: c(CurioColors.surface, CurioColorsLight.surface),
      surfaceContainerLow: c(CurioColors.surface, CurioColorsLight.surface),
      surfaceContainer: c(
        CurioColors.surfaceMuted,
        CurioColorsLight.surfaceMuted,
      ),
      surfaceContainerHigh: c(
        CurioColors.canvasDeep,
        CurioColorsLight.canvasDeep,
      ),
      onSurfaceVariant: c(CurioColors.inkSoft, CurioColorsLight.inkSoft),
      error: c(CurioColors.danger, CurioColorsLight.danger),
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: c(CurioColors.canvas, CurioColorsLight.canvas),
      canvasColor: c(CurioColors.canvas, CurioColorsLight.canvas),
      cardColor: c(CurioColors.surface, CurioColorsLight.surface),
      fontFamily: _body,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            fontFamily: _body,
            bodyColor: c(CurioColors.ink, CurioColorsLight.ink),
            displayColor: c(CurioColors.ink, CurioColorsLight.ink),
          )
          .copyWith(
            displayLarge: TextStyle(
              fontFamily: _display,
              color: c(CurioColors.ink, CurioColorsLight.ink),
              fontSize: 52,
              height: .91,
              fontWeight: FontWeight.w500,
              letterSpacing: -2.6,
            ),
            headlineLarge: TextStyle(
              fontFamily: _display,
              color: c(CurioColors.ink, CurioColorsLight.ink),
              fontSize: 38,
              height: .96,
              fontWeight: FontWeight.w500,
              letterSpacing: -2,
            ),
            headlineMedium: TextStyle(
              fontFamily: _display,
              color: c(CurioColors.ink, CurioColorsLight.ink),
              fontSize: 29,
              height: 1.02,
              fontWeight: FontWeight.w500,
              letterSpacing: -1.2,
            ),
            headlineSmall: TextStyle(
              fontFamily: _display,
              color: c(CurioColors.ink, CurioColorsLight.ink),
              fontSize: 24,
              height: 1.08,
              fontWeight: FontWeight.w500,
              letterSpacing: -.8,
            ),
            titleLarge: TextStyle(
              fontFamily: _display,
              color: c(CurioColors.ink, CurioColorsLight.ink),
              fontSize: 21,
              height: 1.18,
              fontWeight: FontWeight.w500,
              letterSpacing: -.55,
            ),
            titleMedium: TextStyle(
              color: c(CurioColors.ink, CurioColorsLight.ink),
              fontSize: 16,
              height: 1.28,
              fontWeight: FontWeight.w700,
              letterSpacing: -.15,
            ),
            bodyLarge: TextStyle(
              color: c(CurioColors.ink, CurioColorsLight.ink),
              fontSize: 16,
              height: 1.52,
              fontWeight: FontWeight.w500,
            ),
            bodyMedium: TextStyle(
              color: c(CurioColors.ink, CurioColorsLight.ink),
              fontSize: 14,
              height: 1.48,
              fontWeight: FontWeight.w500,
            ),
            bodySmall: TextStyle(
              color: c(CurioColors.inkSoft, CurioColorsLight.inkSoft),
              fontSize: 12,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
            labelLarge: TextStyle(
              color: c(CurioColors.ink, CurioColorsLight.ink),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -.05,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: c(CurioColors.ink, CurioColorsLight.ink),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: _display,
          color: c(CurioColors.ink, CurioColorsLight.ink),
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: -.35,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: c(CurioColors.outlineSoft, CurioColorsLight.outlineSoft),
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? c(CurioColors.coral, CurioColorsLight.coral)
                : c(CurioColors.inkMuted, CurioColorsLight.inkMuted),
            size: 23,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? c(CurioColors.coral, CurioColorsLight.coral)
                : c(CurioColors.inkMuted, CurioColorsLight.inkMuted),
            fontSize: 10.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? c(CurioColors.forest, CurioColorsLight.forest)
                    .withValues(alpha: .055)
              : Colors.transparent,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          elevation: 0,
          backgroundColor: c(CurioColors.coral, CurioColorsLight.coral),
          // Coral is a bright accent in both modes, so its label needs to
          // go dark-on-bright, matching the ink-on-lime treatment used for
          // the home nav's active pill.
          foregroundColor: c(CurioColors.night, CurioColorsLight.ink),
          disabledBackgroundColor: c(
            CurioColors.surfaceMuted,
            CurioColorsLight.surfaceMuted,
          ),
          disabledForegroundColor: c(
            CurioColors.inkMuted,
            CurioColorsLight.inkMuted,
          ),
          shadowColor: c(
            CurioColors.coral,
            CurioColorsLight.coral,
          ).withValues(alpha: .4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: _body,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: c(CurioColors.ink, CurioColorsLight.ink),
          side: BorderSide(
            color: c(CurioColors.outline, CurioColorsLight.outline),
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c(CurioColors.coral, CurioColorsLight.coral),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: c(CurioColors.surface, CurioColorsLight.surface),
        side: BorderSide(color: c(CurioColors.outline, CurioColorsLight.outline)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(
          color: c(CurioColors.inkSoft, CurioColorsLight.inkSoft),
          fontWeight: FontWeight.w600,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? c(CurioColors.coralSoft, CurioColorsLight.coralSoft)
                : c(CurioColors.surface, CurioColorsLight.surface),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? c(CurioColors.coralStrong, CurioColorsLight.coralStrong)
                : c(CurioColors.inkMuted, CurioColorsLight.inkMuted),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: c(CurioColors.outline, CurioColorsLight.outline)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c(CurioColors.surface, CurioColorsLight.surface),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: TextStyle(
          fontFamily: _display,
          color: c(CurioColors.ink, CurioColorsLight.ink),
          fontSize: 23,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          fontFamily: _body,
          color: c(CurioColors.inkSoft, CurioColorsLight.inkSoft),
          fontSize: 14,
          height: 1.48,
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: c(CurioColors.ink, CurioColorsLight.ink),
        iconColor: c(CurioColors.inkSoft, CurioColorsLight.inkSoft),
        titleTextStyle: TextStyle(
          fontFamily: _body,
          color: c(CurioColors.ink, CurioColorsLight.ink),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: _body,
          color: c(CurioColors.inkMuted, CurioColorsLight.inkMuted),
          fontSize: 12,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c(CurioColors.surface, CurioColorsLight.surface),
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c(CurioColors.navy, CurioColorsLight.navy),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: _body,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c(CurioColors.coral, CurioColorsLight.coral),
        linearTrackColor: c(
          CurioColors.outlineSoft,
          CurioColorsLight.outlineSoft,
        ),
        circularTrackColor: c(
          CurioColors.outlineSoft,
          CurioColorsLight.outlineSoft,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c(CurioColors.surface, CurioColorsLight.surface),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          color: c(CurioColors.inkMuted, CurioColorsLight.inkMuted),
        ),
        labelStyle: TextStyle(
          color: c(CurioColors.inkSoft, CurioColorsLight.inkSoft),
        ),
        floatingLabelStyle: TextStyle(
          color: c(CurioColors.forest, CurioColorsLight.forest),
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: c(CurioColors.inkMuted, CurioColorsLight.inkMuted),
        suffixIconColor: c(CurioColors.inkMuted, CurioColorsLight.inkMuted),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(
            color: c(CurioColors.outline, CurioColorsLight.outline),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(
            color: c(CurioColors.coral, CurioColorsLight.coral),
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(
            color: c(CurioColors.danger, CurioColorsLight.danger),
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c(CurioColors.forestStrong, CurioColorsLight.forestStrong),
        selectionColor: c(CurioColors.forestSoft, CurioColorsLight.forestSoft),
        selectionHandleColor: c(CurioColors.forest, CurioColorsLight.forest),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
