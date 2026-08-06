import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/curio_theme.dart';
import 'router.dart';

class CurioApp extends ConsumerWidget {
  const CurioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Curio',
      debugShowCheckedModeBanner: false,
      theme: CurioTheme.light(),
      routerConfig: router,
    );
  }
}
