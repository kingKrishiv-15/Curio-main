import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/widgets/curio_logo.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../theme/curio_tokens.dart';
import '../../games/common/daily_schedule.dart';
import 'about_curio_page.dart';
import 'auth_layout.dart';
import 'auth_page.dart';
import 'intro_page.dart';

/// Welcome: the mark, one sentence, two ways in.
class LandingPage extends StatelessWidget {
  const LandingPage({required this.authService, super.key});

  final AuthService authService;

  Future<void> _getStarted(BuildContext context) async {
    final seen = await IntroPage.hasBeenSeen();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      authRoute(
        seen
            ? AuthPage(authService: authService, mode: AuthMode.signUp)
            : IntroPage(authService: authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => CurioPage(
    maxWidth: 480,
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: CurioLogo(markSize: 32),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'One sharp puzzle a day, and a few more if you want them.',
                        key: const Key('landing_headline'),
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$sectionNames, for ages 10 to 18.',
                      key: const Key('landing_sections'),
                      style: CurioTokens.body.copyWith(
                        color: CurioTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    key: const Key('landing_get_started'),
                    onPressed: () => _getStarted(context),
                    child: const Text('Get started'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('landing_sign_in'),
                    onPressed: () => Navigator.of(
                      context,
                    ).push(authRoute(AuthPage(authService: authService))),
                    child: const Text(
                      'I already have an account',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    key: const Key('landing_about'),
                    onPressed: () => Navigator.of(
                      context,
                    ).push(authRoute(const AboutCurioPage())),
                    child: const Text('About Curio'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
