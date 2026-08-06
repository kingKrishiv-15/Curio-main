import 'package:flutter/material.dart';

import '../core/state/curio_state.dart';
import '../core/theme/curio_theme.dart';
import '../features/shell/presentation/main_shell.dart';

class CurioApp extends StatefulWidget {
  const CurioApp({super.key});

  @override
  State<CurioApp> createState() => _CurioAppState();
}

class _CurioAppState extends State<CurioApp> {
  final CurioState _state = CurioState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CurioScope(
      notifier: _state,
      child: MaterialApp(
        title: 'Curio',
        debugShowCheckedModeBanner: false,
        theme: CurioTheme.light,
        home: const MainShell(),
      ),
    );
  }
}
