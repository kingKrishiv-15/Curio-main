import 'package:flutter/material.dart';

import '../core/theme/curio_theme.dart';
import '../features/auth/presentation/auth_gate.dart';

class CurioApp extends StatelessWidget {
  const CurioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curio',
      debugShowCheckedModeBanner: false,
      theme: CurioTheme.dark,
      home: const AuthGate(),
    );
  }
}
