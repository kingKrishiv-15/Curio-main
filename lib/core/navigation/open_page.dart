import 'package:flutter/material.dart';
import 'package:curio/theme/curio_tokens.dart';

import '../state/curio_state.dart';

Future<T?> openPage<T>(BuildContext context, Widget page) {
  final state = CurioScope.of(context);
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      pageBuilder: (_, animation, secondaryAnimation) =>
          CurioScope(notifier: state, child: page),
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : CurioTokens.slow,
      reverseTransitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : CurioTokens.slow,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: CurioTokens.curve,
          reverseCurve: CurioTokens.curve,
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
