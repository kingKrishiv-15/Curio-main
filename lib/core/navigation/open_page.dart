import 'package:flutter/material.dart';

import '../state/curio_state.dart';

Future<T?> openPage<T>(BuildContext context, Widget page) {
  final state = CurioScope.of(context);
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      pageBuilder: (_, animation, secondaryAnimation) =>
          CurioScope(notifier: state, child: page),
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 320),
      reverseTransitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 240),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.035, .025),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    ),
  );
}
