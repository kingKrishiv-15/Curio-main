import 'package:flutter/material.dart';

import '../core/theme/curio_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/auth/presentation/auth_gate.dart';

class CurioApp extends StatefulWidget {
  const CurioApp({super.key});

  @override
  State<CurioApp> createState() => _CurioAppState();
}

class _CurioAppState extends State<CurioApp> {
  final _themeController = ThemeController();

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CurioThemeScope(
      controller: _themeController,
      child: ListenableBuilder(
        listenable: _themeController,
        builder: (context, _) {
          return MaterialApp(
            title: 'Curio',
            debugShowCheckedModeBanner: false,
            theme: CurioTheme.light,
            darkTheme: CurioTheme.dark,
            themeMode: _themeController.mode,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  disableAnimations:
                      media.disableAnimations || _themeController.reduceMotion,
                  textScaler: TextScaler.linear(
                    media.textScaler.scale(1) * _themeController.readingScale,
                  ),
                ),
                child: child!,
              );
            },
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
