import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_logo.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../core/widgets/curio_gloss.dart';
import 'widgets/welcome_art.dart';

/// Pushes a signed-out step with the same fade-and-drift as `openPage`
/// (which can't be used here: it needs a signed-in `CurioScope`).
Route<T> authRoute<T>(Widget page) => PageRouteBuilder<T>(
  pageBuilder: (context, animation, secondaryAnimation) => page,
  transitionDuration: const Duration(milliseconds: 320),
  reverseTransitionDuration: const Duration(milliseconds: 240),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
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
                      const SizedBox(width: 28),
                      Expanded(
                        child: SingleChildScrollView(
                          child: CurioGloss(
                            radius: 28,
                            padding: const EdgeInsets.all(36),
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

/// The brand panel beside wide auth forms.
class WelcomePanel extends StatelessWidget {
  const WelcomePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: dark
            ? CurioColors.heroGradient
            : CurioColorsLight.heroGradient,
      ),
      padding: const EdgeInsets.all(32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final art = math
              .min(constraints.maxWidth * .86, constraints.maxHeight - 150)
              .clamp(180.0, 420.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A LITTLE WONDER, EVERY DAY',
                style: TextStyle(
                  color: ink,
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Center(child: OrbitHero(size: art)),
              ),
              Text(
                'Big ideas. Curious minds.',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: ink),
              ),
              const SizedBox(height: 8),
              Text(
                'Five-minute games that turn “why?” into a little adventure.',
                style: TextStyle(color: ink, height: 1.5),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A shared, responsive frame for every step into Curio.
class AuthLayout extends StatelessWidget {
  const AuthLayout({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CurioPage(
      maxWidth: 1120,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CurioBrand(),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 800;
                final form = CurioGloss(
                  radius: 28,
                  padding: EdgeInsets.all(wide ? 36 : 24),
                  child: child,
                );
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: CurioWelcomeBanner(expanded: true)),
                      const SizedBox(width: 32),
                      Expanded(child: form),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CurioWelcomeBanner(),
                    const SizedBox(height: 20),
                    form,
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Little discoveries. Lifelong curiosity.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurioWelcomeBanner extends StatelessWidget {
  const CurioWelcomeBanner({this.expanded = false, super.key});
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CurioColors.ink : CurioColorsLight.ink;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: dark
            ? CurioColors.heroGradient
            : CurioColorsLight.heroGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -65,
            top: -80,
            child: _Orbit(size: expanded ? 340 : 240),
          ),
          Positioned(
            left: -90,
            bottom: -150,
            child: _Orbit(size: expanded ? 380 : 260),
          ),
          Padding(
            padding: EdgeInsets.all(expanded ? 36 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A LITTLE WONDER, EVERY DAY',
                  style: TextStyle(
                    color: ink,
                    fontSize: 11,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: expanded ? 26 : 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'Big ideas.\nCurious minds.',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontSize: expanded ? 48 : 32,
                              height: 1.06,
                              color: ink,
                            ),
                      ),
                    ),
                    if (!expanded)
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: MascotBadge(size: 76),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Turn “why?” into a little adventure.',
                  style: TextStyle(color: ink, height: 1.5, fontSize: 15),
                ),
                if (expanded) ...[
                  const SizedBox(height: 38),
                  const Center(child: MascotBadge(size: 184)),
                  const SizedBox(height: 34),
                  Text(
                    'Meet Nova, your learning companion.',
                    style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Play thoughtful games, uncover surprising facts, and grow a little more confident every day.',
                    style: TextStyle(color: ink, height: 1.6),
                  ),
                  const SizedBox(height: 26),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final label in ['Play', 'Discover', 'Grow'])
                        Chip(
                          label: Text(label),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Orbit extends StatelessWidget {
  const _Orbit({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: .22),
          width: 28,
        ),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: error ? scheme.errorContainer : scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
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
