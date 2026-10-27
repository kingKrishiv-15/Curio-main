import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_clay.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../../game_catalog.dart';
import '../../presentation/game_banner.dart';
import '../domain/number_hunt.dart';

class NumberHuntPage extends StatefulWidget {
  const NumberHuntPage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<NumberHuntPage> createState() => _NumberHuntPageState();
}

class _NumberHuntPageState extends State<NumberHuntPage> {
  static const _game = 'number_hunt';
  static const _rules = [
    'A secret number is hiding somewhere from 1 to 1,000.',
    'Type a guess on the number pad. Each clue says go higher or lower, and how close you are: sizzling, hot, warm, cool or cold.',
    'You have 10 guesses. Guess the middle of what’s left every time and 10 is always enough.',
  ];

  late NumberHunt _hunt = NumberHunt.daily(DailyPick.dayNumber(widget.date));
  String _typed = '';
  bool _practice = false;
  bool _alreadyDone = false;
  String _message =
      'Where would you start? The middle is a strong first guess.';
  GameNoticeTone _tone = GameNoticeTone.info;

  void _type(String digit) {
    if (_typed.length >= 4 || (_typed.isEmpty && digit == '0')) return;
    setState(() => _typed += digit);
  }

  void _erase() {
    if (_typed.isEmpty) return;
    setState(() => _typed = _typed.substring(0, _typed.length - 1));
  }

  void _guess() {
    final value = int.tryParse(_typed);
    if (value == null) return;
    final clue = _hunt.guess(value);
    final heat = Heat.of(value, _hunt.target).label.toLowerCase();
    final (message, tone) = switch (clue) {
      Clue.found => (
        'You found it in ${_hunt.guesses.length}!',
        GameNoticeTone.good,
      ),
      Clue.outside => (
        'Your clues already rule $value out — it’s between '
            '${_fmt(_hunt.floor)} and ${_fmt(_hunt.ceiling)}.',
        GameNoticeTone.close,
      ),
      Clue.higher || Clue.lower when _hunt.over => (
        'Out of guesses — it was ${_fmt(_hunt.target)}.',
        GameNoticeTone.bad,
      ),
      Clue.higher => ('Go higher than $value. You’re $heat.', _toneOf(heat)),
      Clue.lower => ('Go lower than $value. You’re $heat.', _toneOf(heat)),
      Clue.finished => (_message, _tone),
    };
    setState(() {
      _typed = '';
      _message = message;
      _tone = tone;
    });
    if (clue == Clue.found) {
      HapticFeedback.mediumImpact();
    } else if (clue != Clue.outside) {
      HapticFeedback.lightImpact();
    }
    if (_hunt.over && !_practice) {
      _alreadyDone = awardDaily(context, _game);
    }
  }

  GameNoticeTone _toneOf(String heat) => switch (heat) {
    'sizzling' || 'hot' => GameNoticeTone.close,
    _ => GameNoticeTone.info,
  };

  void _practiceRound() {
    setState(() {
      _hunt = NumberHunt(Random().nextInt(NumberHunt.high) + NumberHunt.low);
      _practice = true;
      _typed = '';
      _message = 'A fresh number is hiding. Halve the range each time!';
      _tone = GameNoticeTone.info;
    });
  }

  String get _share {
    final marks = _hunt.guesses
        .map(
          (g) => switch (Heat.of(g, _hunt.target)) {
            Heat.found => '✅',
            Heat.sizzling => '🟥',
            Heat.hot => '🟧',
            Heat.warm => '🟨',
            Heat.cool => '🟦',
            Heat.cold => '⬜',
          },
        )
        .join();
    return 'Curio · Number Hunt\n$marks  '
        '${_hunt.found ? '${_hunt.guesses.length}/${NumberHunt.maxGuesses}' : 'X/${NumberHunt.maxGuesses}'}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = bannerFill(
      context,
      gameColor(_game, skillColor(context, 'Number sense')),
    );
    return CurioPage(
      title: 'Number Hunt',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          GameHeader(
            eyebrow: _practice ? 'Practice hunt' : 'Daily number hunt',
            title: _hunt.over
                ? (_hunt.found ? 'Tracked down.' : 'It got away.')
                : 'Find the number.',
            subtitle:
                'It’s hiding somewhere from 1 to 1,000. Every guess tells you '
                'higher or lower — and how close you are.',
            chips: [
              const GameMetaChip(
                icon: Icons.schedule_rounded,
                label: '3–4 min',
              ),
              GameMetaChip(
                icon: Icons.ads_click_rounded,
                label: _hunt.over
                    ? '${_hunt.guesses.length} of ${NumberHunt.maxGuesses} used'
                    : '${_hunt.left} ${_hunt.left == 1 ? 'guess' : 'guesses'} left',
              ),
            ],
          ),
          if (_practice) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: PracticeBadge(),
            ),
          ],
          const SizedBox(height: 16),
          _RangeCard(hunt: _hunt, accent: accent),
          const SizedBox(height: 14),
          GameNotice(message: _message, tone: _tone),
          const SizedBox(height: 14),
          if (!_hunt.over) ...[
            _Display(typed: _typed),
            const SizedBox(height: 12),
            _Keypad(
              canGuess: _typed.isNotEmpty,
              onDigit: _type,
              onErase: _erase,
              onGuess: _guess,
            ),
          ] else ...[
            const GameNotice(
              message:
                  'Halving trick: guess the middle of what’s left every time. '
                  'Ten halvings shrink 1,000 numbers to one.',
            ),
            const SizedBox(height: 14),
            GameResultCard(
              gameId: _game,
              title: _hunt.found
                  ? 'Found in ${_hunt.guesses.length} '
                        '${_hunt.guesses.length == 1 ? 'guess' : 'guesses'}!'
                  : 'The number was…',
              score: _fmt(_hunt.target),
              shareText: _share,
              xp: _practice ? null : gameRewards[_game]!.xp,
              alreadyDone: _alreadyDone,
              onPractice: _practiceRound,
            ),
          ],
          if (_hunt.guesses.isNotEmpty) ...[
            const SizedBox(height: 24),
            const SectionHeading('Your trail'),
            const SizedBox(height: 10),
            _Trail(hunt: _hunt),
          ],
        ],
      ),
    );
  }
}

String _fmt(int n) =>
    n >= 1000 ? '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}' : '$n';

/// What's still possible: the window the clues allow, as a puffy strip in a
/// groove that runs from 1 to 1,000, and a pip for every guess.
class _RangeCard extends StatelessWidget {
  const _RangeCard({required this.hunt, required this.accent});
  final NumberHunt hunt;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    const span = NumberHunt.high - NumberHunt.low + 1;
    final from = (hunt.floor - NumberHunt.low) / span;
    final to = (hunt.ceiling - NumberHunt.low + 1) / span;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Semantics(
        label:
            'The number is between ${hunt.floor} and ${hunt.ceiling}. '
            '${hunt.left} guesses left.',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hunt.found ? 'FOUND' : 'SOMEWHERE BETWEEN',
              style: TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                hunt.found
                    ? _fmt(hunt.target)
                    : '${_fmt(hunt.floor)} – ${_fmt(hunt.ceiling)}',
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(fontSize: 42),
              ),
            ),
            const SizedBox(height: 16),
            // Offset as a pair of fractions, since it already knows how to
            // tween smoothly.
            TweenAnimationBuilder<Offset>(
              tween: Tween(end: Offset(from, to)),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, window, _) => SizedBox(
                height: 22,
                width: double.infinity,
                child: CustomPaint(
                  painter: _RangePainter(
                    from: window.dx,
                    to: window.dy,
                    color: accent,
                    base: clayBase(context),
                    dark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('1', style: TextStyle(color: muted, fontSize: 11)),
                const Spacer(),
                Text('1,000', style: TextStyle(color: muted, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 14),
            // Guesses still in hand puff up; spent ones are dents.
            Row(
              children: [
                for (var i = 0; i < NumberHunt.maxGuesses; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 14,
                      child: CurioClay(
                        radius: 7,
                        pressed: i < hunt.guesses.length,
                        color: i < hunt.guesses.length
                            ? null
                            : accent.withValues(alpha: .55),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RangePainter extends CustomPainter {
  const _RangePainter({
    required this.from,
    required this.to,
    required this.color,
    required this.base,
    required this.dark,
  });

  final double from, to;
  final Color color, base;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    paintClay(
      canvas,
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Color.alphaBlend(color.withValues(alpha: .12), base),
      dark: dark,
      pressed: true,
    );
    // Never thinner than a dot, so a one-number window still shows.
    final left = from * size.width;
    final right = max(to * size.width, left + size.height);
    paintClay(
      canvas,
      RRect.fromLTRBR(
        min(left, size.width - size.height),
        0,
        min(right, size.width),
        size.height,
        radius,
      ),
      color,
      dark: dark,
    );
  }

  @override
  bool shouldRepaint(_RangePainter old) =>
      old.from != from ||
      old.to != to ||
      old.color != color ||
      old.base != base ||
      old.dark != dark;
}

/// The guess being typed, in a well pressed into the page.
class _Display extends StatelessWidget {
  const _Display({required this.typed});
  final String typed;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return Semantics(
      liveRegion: true,
      label: typed.isEmpty ? 'No guess typed yet' : 'Your guess: $typed',
      excludeSemantics: true,
      child: SizedBox(
        key: const Key('hunt_display'),
        height: 72,
        child: CurioClay(
          radius: 22,
          pressed: true,
          child: Center(
            child: Text(
              typed.isEmpty ? 'Your guess' : typed,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: typed.isEmpty ? 22 : 34,
                color: typed.isEmpty ? muted : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.canGuess,
    required this.onDigit,
    required this.onErase,
    required this.onGuess,
  });

  final bool canGuess;
  final ValueChanged<String> onDigit;
  final VoidCallback onErase, onGuess;

  @override
  Widget build(BuildContext context) {
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    // Coral is bright in both modes, so the Guess key's label stays dark.
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final onCoral = curioColor(
      context,
      CurioColors.night,
      CurioColorsLight.ink,
    );
    Widget digit(String d) => _ClayKey(
      key: Key('hunt_key_$d'),
      label: d,
      onTap: () => onDigit(d),
      child: Text(
        d,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontSize: 26, color: ink),
      ),
    );
    final rows = [
      [digit('1'), digit('2'), digit('3')],
      [digit('4'), digit('5'), digit('6')],
      [digit('7'), digit('8'), digit('9')],
      [
        _ClayKey(
          key: const Key('hunt_backspace'),
          label: 'Delete',
          onTap: onErase,
          child: Icon(Icons.backspace_outlined, color: ink, size: 22),
        ),
        digit('0'),
        _ClayKey(
          key: const Key('hunt_guess'),
          label: 'Guess',
          color: coral,
          onTap: canGuess ? onGuess : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_rounded, color: onCoral, size: 20),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Guess',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onCoral,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ];
    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (var c = 0; c < rows[r].length; c++) ...[
                if (c > 0) const SizedBox(width: 10),
                Expanded(child: rows[r][c]),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// A number-pad key: raised clay that squishes into a dent while held.
class _ClayKey extends StatefulWidget {
  const _ClayKey({
    required this.label,
    required this.child,
    required this.onTap,
    this.color,
    super.key,
  });

  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  @override
  State<_ClayKey> createState() => _ClayKeyState();
}

class _ClayKeyState extends State<_ClayKey> {
  bool _down = false;

  void _hold(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _hold(true) : null,
        onTapUp: enabled ? (_) => _hold(false) : null,
        onTapCancel: () => _hold(false),
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1 : .45,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58),
            child: CurioClay(
              radius: 20,
              pressed: _down,
              color: widget.color,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Every guess so far: the number, which way the clue pointed, and how hot.
class _Trail extends StatelessWidget {
  const _Trail({required this.hunt});
  final NumberHunt hunt;

  @override
  Widget build(BuildContext context) {
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final g in hunt.guesses)
          Builder(
            builder: (context) {
              final heat = Heat.of(g, hunt.target);
              final color = _heatColor(context, heat);
              return Semantics(
                label:
                    '$g, ${heat == Heat.found ? 'found' : '${g < hunt.target ? 'go higher' : 'go lower'}, ${heat.label}'}',
                excludeSemantics: true,
                child: CurioClay(
                  radius: 16,
                  color: color.withValues(alpha: .2),
                  outline: heat == Heat.found ? color : null,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _fmt(g),
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        heat == Heat.found
                            ? Icons.check_circle_rounded
                            : g < hunt.target
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        heat.label,
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

Color _heatColor(BuildContext context, Heat heat) => switch (heat) {
  Heat.found => curioColor(
    context,
    CurioColors.success,
    CurioColorsLight.forestStrong,
  ),
  Heat.sizzling => curioColor(
    context,
    CurioColors.danger,
    CurioColorsLight.danger,
  ),
  Heat.hot => curioColor(
    context,
    CurioColors.coral,
    CurioColorsLight.coralStrong,
  ),
  Heat.warm => curioColor(
    context,
    CurioColors.saffron,
    CurioColorsLight.saffronStrong,
  ),
  Heat.cool => curioColor(context, CurioColors.blue, CurioColorsLight.blue),
  Heat.cold => curioColor(context, CurioColors.plum, CurioColorsLight.plum),
};
