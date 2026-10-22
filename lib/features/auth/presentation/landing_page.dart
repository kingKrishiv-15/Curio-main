import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_gloss.dart';
import '../../../core/widgets/curio_logo.dart';
import '../../../core/widgets/curio_motion.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/game_catalog.dart';
import '../../games/presentation/game_card.dart';
import 'auth_layout.dart';
import 'auth_page.dart';
import 'guest_sheet.dart';
import 'intro_page.dart';
import 'widgets/welcome_art.dart';

/// The first thing a signed-out visitor sees. On a phone the first screen
/// is a complete welcome — logo, promise, and both ways in — with the
/// longer story for curious parents below the fold.
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

  void _signIn(BuildContext context) =>
      Navigator.of(context).push(authRoute(AuthPage(authService: authService)));

  @override
  Widget build(BuildContext context) {
    return CurioPage(
      maxWidth: 1180,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final gutter = wide ? 40.0 : 24.0;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(onSignIn: () => _signIn(context), gutter: gutter),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: wide ? 0 : constraints.maxHeight - 72,
                  ),
                  child: wide
                      ? _WideHero(
                          onStart: () => _getStarted(context),
                          onSignIn: () => _signIn(context),
                        )
                      : _PhoneHero(
                          viewport: constraints.biggest,
                          onStart: () => _getStarted(context),
                          onSignIn: () => _signIn(context),
                        ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: wide ? 72 : 40),
                      _HowItWorks(wide: wide),
                      const SizedBox(height: 56),
                      const _GameShelfHeading(),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
                _GameShelf(wide: wide, gutter: gutter),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 56),
                      _ForGrownUps(wide: wide),
                      const SizedBox(height: 56),
                      _FinalCall(
                        onStart: () => _getStarted(context),
                        onSignIn: () => _signIn(context),
                      ),
                      const SizedBox(height: 40),
                      const _Footer(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSignIn, required this.gutter});
  final VoidCallback onSignIn;
  final double gutter;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(gutter, 14, gutter - 8, 8),
    child: Row(
      children: [
        const Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CurioLogo(markSize: 32),
          ),
        ),
        const SizedBox(width: 12),
        TextButton(onPressed: onSignIn, child: const Text('Sign in')),
      ],
    ),
  );
}

class _Headline extends StatelessWidget {
  const _Headline({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final base = Theme.of(context).textTheme.displayLarge?.copyWith(
      fontSize: size,
      height: 1.02,
      letterSpacing: -size * .045,
    );
    return Semantics(
      header: true,
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Turn '),
            TextSpan(
              text: '“why?”',
              style: TextStyle(color: coral),
            ),
            const TextSpan(text: ' into a daily adventure.'),
          ],
        ),
        style: base,
      ),
    );
  }
}

const _promise =
    'Five-minute brain games that grow reasoning, number sense and pattern '
    'skills — with a calm, clear view for grown-ups.';

class _PhoneHero extends StatelessWidget {
  const _PhoneHero({
    required this.viewport,
    required this.onStart,
    required this.onSignIn,
  });

  final Size viewport;
  final VoidCallback onStart, onSignIn;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final art = math
        .min(viewport.width - 48, viewport.height * .36)
        .clamp(200.0, 340.0);
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            Center(
              child: CurioFadeSlideIn(child: OrbitHero(size: art)),
            ),
            const Spacer(),
            const SizedBox(height: 12),
            CurioFadeSlideIn(
              delay: const Duration(milliseconds: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CurioEyebrow('A little wonder, every day'),
                  const SizedBox(height: 12),
                  const _Headline(size: 38),
                  const SizedBox(height: 12),
                  Text(_promise, style: TextStyle(color: muted, height: 1.55)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CurioFadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: _Ctas(onStart: onStart, onSignIn: onSignIn),
            ),
            const SizedBox(height: 18),
            const _ScrollHint(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _WideHero extends StatelessWidget {
  const _WideHero({required this.onStart, required this.onSignIn});
  final VoidCallback onStart, onSignIn;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: CurioFadeSlideIn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CurioEyebrow('A little wonder, every day'),
                  const SizedBox(height: 18),
                  const _Headline(size: 62),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Text(
                      _promise,
                      style: TextStyle(color: muted, height: 1.6, fontSize: 17),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: _Ctas(onStart: onStart, onSignIn: onSignIn),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 10,
            child: CurioFadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: const Center(child: OrbitHero(size: 440)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ctas extends StatelessWidget {
  const _Ctas({
    required this.onStart,
    required this.onSignIn,
    this.keyPrefix = 'landing',
  });
  final VoidCallback onStart, onSignIn;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton(
        key: Key('${keyPrefix}_get_started'),
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
        key: Key('${keyPrefix}_sign_in'),
        onPressed: onSignIn,
        child: const Text('I already have an account'),
      ),
      const SizedBox(height: 4),
      TextButton(
        key: Key('${keyPrefix}_guest'),
        onPressed: () => showGuestSheet(context),
        child: const Text('Just looking? Continue as guest'),
      ),
    ],
  );
}

class _ScrollHint extends StatelessWidget {
  const _ScrollHint();

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return ExcludeSemantics(
      child: Column(
        children: [
          Text(
            'See how it works',
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          CurioFloat(
            distance: 3,
            period: const Duration(milliseconds: 1800),
            child: Icon(Icons.keyboard_arrow_down_rounded, color: muted),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String eyebrow, title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CurioEyebrow(eyebrow),
      const SizedBox(height: 10),
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            subtitle!,
            style: TextStyle(
              color: curioColor(
                context,
                CurioColors.inkSoft,
                CurioColorsLight.inkSoft,
              ),
              height: 1.55,
            ),
          ),
        ),
      ],
    ],
  );
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        '01',
        Icons.extension_rounded,
        'Play for five minutes',
        'One short, focused game a day — logic, numbers, patterns or evidence.',
        WelcomeSkill.all[0],
      ),
      (
        '02',
        Icons.auto_awesome_rounded,
        'Unlock a discovery',
        'Every finished game adds a surprising fact to their collection.',
        WelcomeSkill.all[1],
      ),
      (
        '03',
        Icons.trending_up_rounded,
        'Watch skills grow',
        'Streaks, skill levels and a parent view show the progress adding up.',
        WelcomeSkill.all[2],
      ),
    ];
    final cards = [
      for (final (n, icon, title, body, skill) in steps)
        _StepCard(
          number: n,
          icon: icon,
          title: title,
          body: body,
          color: skill.of(context),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          eyebrow: 'The daily loop',
          title: 'Small steps, big discoveries.',
          subtitle:
              'Curio is built around one gentle habit: a little thinking, every day, that adds up to a lot.',
        ),
        const SizedBox(height: 24),
        if (wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 16),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          )
        else
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            cards[i],
          ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final String number, title, body;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return CurioGloss(
      radius: 22,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(body, style: TextStyle(color: muted, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameShelfHeading extends StatelessWidget {
  const _GameShelfHeading();

  @override
  Widget build(BuildContext context) => const _SectionTitle(
    eyebrow: 'Inside Curio',
    title: 'Games that make thinking visible.',
    subtitle: 'Each one trains a real thinking skill, in about five minutes.',
  );
}

class _GameShelf extends StatelessWidget {
  const _GameShelf({required this.wide, required this.gutter});
  final bool wide;
  final double gutter;

  /// A taste of the catalog — at least one game from every skill — drawn
  /// with the same art as inside the app.
  static const _ids = [
    'scale',
    'odd_cluster',
    'mirror',
    'verdict',
    'whos_who',
    'loophole',
  ];

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (final id in _ids)
        if (findGame(id) case final game?) _ShelfCard(game: game),
    ];
    if (wide) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 32) / 3;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final card in cards) SizedBox(width: width, child: card),
              ],
            );
          },
        ),
      );
    }
    // A plain scrolling Row (not a fixed-height ListView) so the cards grow
    // with the reader's text size instead of clipping.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              SizedBox(width: 220, child: cards[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShelfCard extends StatelessWidget {
  const _ShelfCard({required this.game});

  final GameEntry game;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final skill = skillColor(context, game.skill);
    return CurioGloss(
      radius: 22,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: GameArt(game: game, height: 104, badges: false),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.skill.toUpperCase(),
                  style: TextStyle(
                    color: curioColor(
                      context,
                      skill,
                      Color.lerp(skill, Colors.black, .3)!,
                    ),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(game.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  game.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForGrownUps extends StatelessWidget {
  const _ForGrownUps({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    const points = [
      (
        Icons.lock_outline_rounded,
        'Private by design',
        'Progress lives in your own family account. Your child only ever needs a nickname.',
      ),
      (
        Icons.insights_rounded,
        'Progress you can actually see',
        'A parent view shows which skills are growing and what to try next.',
      ),
      (
        Icons.mark_email_read_outlined,
        'A weekly note, if you like',
        'An optional Monday email with last week’s practice. Turn it off anytime.',
      ),
      (
        Icons.spa_outlined,
        'Gentle, never pushy',
        'Daily goals are an invitation, never a screen-time limit.',
      ),
    ];
    final forest = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forest,
    );
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final tiles = [
      for (final (icon, title, body) in points)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurioIconTile(icon: icon, color: forest, size: 42, iconSize: 21),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(body, style: TextStyle(color: muted, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
    ];
    return CurioGloss(
      radius: 28,
      padding: EdgeInsets.all(wide ? 36 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            eyebrow: 'For grown-ups',
            title: 'Calm, clear, and on your terms.',
          ),
          const SizedBox(height: 24),
          if (wide)
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 28,
                runSpacing: 24,
                children: [
                  for (final tile in tiles)
                    SizedBox(
                      width: (constraints.maxWidth - 28) / 2,
                      child: tile,
                    ),
                ],
              ),
            )
          else
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(height: 20),
              tiles[i],
            ],
        ],
      ),
    );
  }
}

class _FinalCall extends StatelessWidget {
  const _FinalCall({required this.onStart, required this.onSignIn});
  final VoidCallback onStart, onSignIn;

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
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          const MascotBadge(size: 84),
          const SizedBox(height: 18),
          Text(
            'Ready when they are.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: ink),
          ),
          const SizedBox(height: 8),
          Text(
            'Setting up takes about a minute. Nova will take it from there.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ink, height: 1.5),
          ),
          const SizedBox(height: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: _Ctas(
              onStart: onStart,
              onSignIn: onSignIn,
              keyPrefix: 'landing_footer',
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const CurioLogoMark(size: 30, shadow: false),
      const SizedBox(height: 10),
      Text(
        'Little discoveries. Lifelong curiosity.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}
