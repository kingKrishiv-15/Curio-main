import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'curio_colors.dart';

abstract final class CurioTheme {
  static const _display = 'Fraunces';
  static const _body = 'DM Sans';

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: CurioColors.coral,
      brightness: Brightness.light,
      primary: CurioColors.coral,
      onPrimary: CurioColors.onDark,
      primaryContainer: CurioColors.coralSoft,
      onPrimaryContainer: CurioColors.coralStrong,
      secondary: CurioColors.forest,
      onSecondary: CurioColors.onDark,
      secondaryContainer: CurioColors.forestSoft,
      onSecondaryContainer: CurioColors.forestStrong,
      surface: CurioColors.surface,
      onSurface: CurioColors.ink,
      surfaceContainerLowest: CurioColors.surface,
      surfaceContainerLow: CurioColors.surface,
      surfaceContainer: CurioColors.surfaceMuted,
      surfaceContainerHigh: CurioColors.canvasDeep,
      onSurfaceVariant: CurioColors.inkSoft,
      error: CurioColors.danger,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: CurioColors.canvas,
      canvasColor: CurioColors.canvas,
      cardColor: CurioColors.surface,
      fontFamily: _body,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            fontFamily: _body,
            bodyColor: CurioColors.ink,
            displayColor: CurioColors.ink,
          )
          .copyWith(
            displayLarge: const TextStyle(
              fontFamily: _display,
              color: CurioColors.ink,
              fontSize: 52,
              height: .91,
              fontWeight: FontWeight.w500,
              letterSpacing: -2.6,
            ),
            headlineLarge: const TextStyle(
              fontFamily: _display,
              color: CurioColors.ink,
              fontSize: 38,
              height: .96,
              fontWeight: FontWeight.w500,
              letterSpacing: -2,
            ),
            headlineMedium: const TextStyle(
              fontFamily: _display,
              color: CurioColors.ink,
              fontSize: 29,
              height: 1.02,
              fontWeight: FontWeight.w500,
              letterSpacing: -1.2,
            ),
            headlineSmall: const TextStyle(
              fontFamily: _display,
              color: CurioColors.ink,
              fontSize: 24,
              height: 1.08,
              fontWeight: FontWeight.w500,
              letterSpacing: -.8,
            ),
            titleLarge: const TextStyle(
              fontFamily: _display,
              color: CurioColors.ink,
              fontSize: 21,
              height: 1.18,
              fontWeight: FontWeight.w500,
              letterSpacing: -.55,
            ),
            titleMedium: const TextStyle(
              color: CurioColors.ink,
              fontSize: 16,
              height: 1.28,
              fontWeight: FontWeight.w700,
              letterSpacing: -.15,
            ),
            bodyLarge: const TextStyle(
              color: CurioColors.ink,
              fontSize: 16,
              height: 1.52,
              fontWeight: FontWeight.w500,
            ),
            bodyMedium: const TextStyle(
              color: CurioColors.ink,
              fontSize: 14,
              height: 1.48,
              fontWeight: FontWeight.w500,
            ),
            bodySmall: const TextStyle(
              color: CurioColors.inkSoft,
              fontSize: 12,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
            labelLarge: const TextStyle(
              color: CurioColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -.05,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: CurioColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: _display,
          color: CurioColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: -.35,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: CurioColors.outlineSoft,
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
                ? CurioColors.coral
                : CurioColors.inkMuted,
            size: 23,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? CurioColors.coral
                : CurioColors.inkMuted,
            fontSize: 10.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? CurioColors.forest.withValues(alpha: .055)
              : Colors.transparent,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 49),
          elevation: 0,
          backgroundColor: CurioColors.coral,
          foregroundColor: CurioColors.onDark,
          disabledBackgroundColor: CurioColors.surfaceMuted,
          disabledForegroundColor: CurioColors.inkMuted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          textStyle: const TextStyle(
            fontFamily: _body,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 47),
          foregroundColor: CurioColors.ink,
          side: const BorderSide(color: CurioColors.outline, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CurioColors.coral,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: CurioColors.surface,
        side: const BorderSide(color: CurioColors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        labelStyle: const TextStyle(
          color: CurioColors.inkSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? CurioColors.coralSoft
                : CurioColors.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? CurioColors.coralStrong
                : CurioColors.inkMuted,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: CurioColors.outline),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: CurioColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        titleTextStyle: const TextStyle(
          fontFamily: _display,
          color: CurioColors.ink,
          fontSize: 23,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: _body,
          color: CurioColors.inkSoft,
          fontSize: 14,
          height: 1.48,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: CurioColors.ink,
        iconColor: CurioColors.inkSoft,
        titleTextStyle: TextStyle(
          fontFamily: _body,
          color: CurioColors.ink,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: _body,
          color: CurioColors.inkMuted,
          fontSize: 12,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CurioColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CurioColors.ink,
        contentTextStyle: const TextStyle(
          color: CurioColors.onDark,
          fontFamily: _body,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CurioColors.coral,
        linearTrackColor: CurioColors.outlineSoft,
        circularTrackColor: CurioColors.outlineSoft,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CurioColors.forestMist,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: CurioColors.inkMuted),
        labelStyle: const TextStyle(color: CurioColors.inkSoft),
        floatingLabelStyle: const TextStyle(
          color: CurioColors.forestStrong,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: CurioColors.inkMuted,
        suffixIconColor: CurioColors.inkMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: const BorderSide(color: CurioColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: const BorderSide(color: CurioColors.coral, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: const BorderSide(color: CurioColors.danger),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: CurioColors.forestStrong,
        selectionColor: CurioColors.forestSoft,
        selectionHandleColor: CurioColors.forest,
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
