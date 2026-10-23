import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/curio_logo.dart';
import '../../../core/widgets/curio_motion.dart';
import '../../../core/widgets/curio_ui.dart';
import 'about_curio_page.dart';
import 'auth_layout.dart';
import 'auth_page.dart';
import 'intro_page.dart';
import 'widgets/welcome_art.dart';

/// A focused welcome: a little wonder, then the two account actions.
/// The optional longer introduction lives on [AboutCurioPage].
class LandingPage extends StatefulWidget {
  const LandingPage({required this.authService, super.key});
  final AuthService authService;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _motionPaused = false;

  Future<void> _getStarted(BuildContext context) async {
    final seen = await IntroPage.hasBeenSeen();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      authRoute(
        seen
            ? AuthPage(authService: widget.authService, mode: AuthMode.signUp)
            : IntroPage(authService: widget.authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => CurioPage(
    maxWidth: 1100,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final artSize = wide
            ? 380.0
            : math
                  .min(constraints.maxWidth - 64, constraints.maxHeight * .42)
                  .clamp(200.0, 340.0);
        final message = _WelcomeMessage(wide: wide);
        final actions = _WelcomeActions(
          onStart: () => _getStarted(context),
          onSignIn: () => Navigator.of(
            context,
          ).push(authRoute(AuthPage(authService: widget.authService))),
        );
        final motionOff =
            _motionPaused || MediaQuery.disableAnimationsOf(context);
        final systemReduced = View.of(
          context,
        ).platformDispatcher.accessibilityFeatures.disableAnimations;
        final art = MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: motionOff),
          child: CurioFadeSlideIn(
            child: OrbitHero(key: const Key('landing_art'), size: artSize),
          ),
        );
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 40 : 24,
                  12,
                  wide ? 40 : 24,
                  12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: CurioLogo(markSize: 32),
                          ),
                        ),
                        IconButton(
                          key: const Key('landing_motion'),
                          tooltip: systemReduced
                              ? 'Your device’s Reduce Motion setting is on'
                              : motionOff
                              ? 'Play welcome animation'
                              : 'Pause welcome animation',
                          icon: Icon(
                            motionOff
                                ? Icons.play_circle_outline_rounded
                                : Icons.pause_circle_outline_rounded,
                          ),
                          onPressed: systemReduced
                              ? null
                              : () {
                                  if (motionOff) {
                                    CurioThemeScope.maybeOf(
                                      context,
                                    )?.setReading(motion: false);
                                  }
                                  setState(() => _motionPaused = !motionOff);
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: wide
                          ? Row(
                              children: [
                                Expanded(child: message),
                                const SizedBox(width: 48),
                                Expanded(child: Center(child: art)),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Center(child: art),
                                const SizedBox(height: 16),
                                message,
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: actions,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton.icon(
                        key: const Key('landing_about'),
                        onPressed: () => Navigator.of(
                          context,
                        ).push(authRoute(const AboutCurioPage())),
                        icon: const Icon(Icons.info_outline_rounded, size: 18),
                        label: const Text('About Curio'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return CurioFadeSlideIn(
      delay: const Duration(milliseconds: 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text.rich(
              key: const Key('landing_headline'),
              TextSpan(
                children: [
                  const TextSpan(text: 'Little games.\n'),
                  TextSpan(
                    text: 'Big discoveries.',
                    style: TextStyle(color: coral),
                  ),
                ],
              ),
              textAlign: wide ? TextAlign.start : TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: wide ? 54 : 36,
                height: 1.08,
                letterSpacing: -1.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Maths, Memory & English. A little every day.',
            textAlign: wide ? TextAlign.start : TextAlign.center,
            style: TextStyle(color: muted, height: 1.5, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({required this.onStart, required this.onSignIn});
  final VoidCallback onStart, onSignIn;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton(
        key: const Key('landing_get_started'),
        onPressed: onStart,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text('Get started', textAlign: TextAlign.center)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 19),
          ],
        ),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        key: const Key('landing_sign_in'),
        onPressed: onSignIn,
        child: const Text(
          'I already have an account',
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}
