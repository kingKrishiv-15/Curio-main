import 'package:flutter/material.dart';

import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/game_catalog.dart';
import '../../games/presentation/game_card.dart';
import 'widgets/welcome_art.dart';

/// The longer introduction is optional, keeping the first welcome focused.
class AboutCurioPage extends StatelessWidget {
  const AboutCurioPage({super.key});

  @override
  Widget build(BuildContext context) => CurioPage(
    title: 'About Curio',
    maxWidth: 1180,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final gutter = wide ? 40.0 : 24.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 20, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: _HowItWorks(wide: wide),
              ),
              const SizedBox(height: 36),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: const _GameShelfHeading(),
              ),
              const SizedBox(height: 18),
              _GameShelf(wide: wide, gutter: gutter),
              const SizedBox(height: 36),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: _ForGrownUps(wide: wide),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Back to welcome'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
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
        'Choose a daily game in Maths, Memory, English or Logic. Each takes about five minutes.',
        WelcomeSkill.all[0],
      ),
      (
        '02',
        Icons.auto_awesome_rounded,
        'Unlock a discovery',
        'Daily play earns points, badges and surprising facts to collect.',
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
    return CurioClay(
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

  /// A taste of the catalog — two games from every daily section — drawn
  /// with the same art as inside the app.
  static const _ids = [
    'scale',
    'sequence',
    'memory_match',
    'memory_trail',
    'word_builder',
    'word_wise',
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
    return CurioClay(
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
    return CurioClay(
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
