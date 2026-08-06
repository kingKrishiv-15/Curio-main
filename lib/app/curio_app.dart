import 'package:flutter/material.dart';

import '../core/theme/curio_theme.dart';

/// Root widget for Phase 0. Deliberately just a blank shell right now - no
/// routing, no auth gate, no feature screens. Those land as later Phase 0
/// steps (auth) and later phases (everything else) build on this.
class CurioApp extends StatelessWidget {
  const CurioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curio',
      debugShowCheckedModeBanner: false,
      theme: CurioTheme.light(),
      home: const _BlankShellPage(),
    );
  }
}

class _BlankShellPage extends StatelessWidget {
  const _BlankShellPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Curio',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
