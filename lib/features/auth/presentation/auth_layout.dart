import 'package:curio/theme/curio_tokens.dart';

import 'package:flutter/material.dart';

import '../../../core/widgets/curio_logo.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../core/widgets/curio_clay.dart';

/// Pushes a signed-out step with the same fade-and-drift as `openPage`
/// (which can't be used here: it needs a signed-in `CurioScope`).
Route<T> authRoute<T>(Widget page) => PageRouteBuilder<T>(
  pageBuilder: (context, animation, secondaryAnimation) => page,
  transitionDuration: CurioTokens.slow,
  reverseTransitionDuration: CurioTokens.slow,
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curve = CurvedAnimation(
      parent: animation,
      curve: CurioTokens.curve,
      reverseCurve: CurioTokens.curve,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.04, 0),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  },
);

/// The frame for every step after the landing page: back + logo on top and
/// one calm column of content. On wide screens the orbit art sits alongside
/// so the form never stretches into a long, thin line.
class AuthFrame extends StatelessWidget {
  const AuthFrame({
    required this.child,
    this.onBack,
    this.trailing,
    this.maxContentWidth = 440,
    super.key,
  });

  final Widget child;

  /// Overrides the back button. When null, a back button appears only if
  /// there is a route to go back to.
  final VoidCallback? onBack;
  final Widget? trailing;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final canPop = onBack != null || (ModalRoute.of(context)?.canPop ?? false);
    return CurioPage(
      maxWidth: 1160,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= 880 && constraints.maxHeight >= 560;
          final top = Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: canPop
                      ? IconButton(
                          tooltip: 'Back',
                          onPressed:
                              onBack ?? () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        )
                      : null,
                ),
                const Expanded(child: Center(child: CurioLogo(markSize: 28))),
                SizedBox(
                  width: 56,
                  child: trailing == null
                      ? null
                      : Align(
                          alignment: Alignment.centerRight,
                          child: trailing,
                        ),
                ),
              ],
            ),
          );
          final content = Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: child,
            ),
          );
          if (!wide) {
            return Column(
              children: [
                top,
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: content,
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              top,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(child: WelcomePanel()),
                      const SizedBox(width: 32),
                      Expanded(
                        child: SingleChildScrollView(
                          child: CurioClay(
                            radius: CurioTokens.radiusCard,
                            padding: const EdgeInsets.all(32),
                            child: content,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The quiet panel beside a form on wide screens: the mark and one line.
class WelcomePanel extends StatelessWidget {
  const WelcomePanel({super.key});

  @override
  Widget build(BuildContext context) => CurioClay(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CurioLogoMark(size: 48),
        const SizedBox(height: 24),
        Text(
          'One sharp puzzle a day.',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ],
    ),
  );
}

/// Frames a signed-in setup step: the logo, then the form.
class AuthLayout extends StatelessWidget {
  const AuthLayout({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => CurioPage(
    maxWidth: 520,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(alignment: Alignment.centerLeft, child: CurioBrand()),
          const SizedBox(height: 32),
          child,
        ],
      ),
    ),
  );
}

class AuthNotice extends StatelessWidget {
  const AuthNotice(this.message, {this.error = false, super.key});
  final String message;
  final bool error;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: error ? scheme.errorContainer : scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(CurioTokens.radiusCard),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: error ? scheme.onErrorContainer : scheme.onSurface,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
