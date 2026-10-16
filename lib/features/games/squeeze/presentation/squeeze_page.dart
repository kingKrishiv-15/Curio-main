import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../domain/squeeze_engine.dart';

class SqueezePage extends StatefulWidget {
  const SqueezePage({super.key});

  @override
  State<SqueezePage> createState() => _SqueezePageState();
}

class _SqueezePageState extends State<SqueezePage> {
  SqueezeEngine _engine = SqueezeEngine();
  final _controller = TextEditingController();
  String _message = 'Pick a smart first guess. Halfway is often powerful.';
  bool _practice = false;
  bool _awarded = false;
  bool _alreadyDone = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text);
    if (value == null) {
      setState(() => _message = 'Enter a whole number first.');
      return;
    }
    setState(() {
      _message = _engine.guess(value);
      _controller.clear();
    });
    // The day counts once it's finished, found or not — otherwise losing,
    // reopening and typing the revealed number would farm the XP.
    if (_engine.finished && !_practice && !_awarded) {
      _awarded = true;
      _alreadyDone = awardDaily(context, 'squeeze');
    }
  }

  void _restartPractice() {
    setState(() {
      _engine = SqueezeEngine(target: Random().nextInt(100) + 1);
      _practice = true;
      _message = 'Practice round ready. Find the new number!';
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _engine.guesses.length / SqueezeEngine.maxGuesses;
    final navy = curioColor(context, CurioColors.navy, CurioColorsLight.navy);
    final gold = curioColor(context, CurioColors.gold, CurioColorsLight.gold);
    // `navy` is coral in light mode: gold text and a coral bar vanish on it.
    final cardLabel = curioColor(
      context,
      CurioColors.gold,
      Colors.white.withValues(alpha: .85),
    );
    final cardBar = curioColor(context, CurioColors.coral, Colors.white);
    final onDark = curioColor(context, CurioColors.onDark, CurioColorsLight.onDark);
    final greenSoft = curioColor(context, CurioColors.greenSoft, CurioColorsLight.greenSoft);
    final tealSoft = curioColor(context, CurioColors.tealSoft, CurioColorsLight.tealSoft);
    final green = curioColor(context, CurioColors.green, CurioColorsLight.green);
    final teal = curioColor(context, CurioColors.teal, CurioColorsLight.teal);
    final tealDark = curioColor(context, CurioColors.tealDark, CurioColorsLight.tealDark);
    final goldSoft = curioColor(context, CurioColors.goldSoft, CurioColorsLight.goldSoft);
    final surface = curioColor(context, CurioColors.surface, CurioColorsLight.surface);
    return CurioPage(
      title: 'Daily Squeeze',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          CurioCard(
            color: navy,
            borderColor: navy,
            child: Column(
              children: [
                Text(
                  _practice ? 'PRACTICE RANGE' : 'SECRET RANGE',
                  style: TextStyle(
                    color: cardLabel,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_engine.minimum}  —  ${_engine.maximum}',
                  style: TextStyle(
                    color: onDark,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 13),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    backgroundColor: onDark.withValues(alpha: .18),
                    color: cardBar,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_engine.guessesLeft} guesses left',
                  style: TextStyle(
                    color: onDark.withValues(alpha: .7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CurioCard(
            color: _engine.solved ? greenSoft : tealSoft,
            borderColor: _engine.solved ? green : teal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _engine.solved
                      ? Icons.celebration_rounded
                      : Icons.tips_and_updates_rounded,
                  color: _engine.solved ? green : tealDark,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_message),
                      if (_engine.guesses.length >= 3 && !_engine.finished) ...[
                        const SizedBox(height: 6),
                        Text(
                          _engine.numberFact,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_engine.finished) ...[
            TextField(
              key: const Key('squeezeInput'),
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              decoration: const InputDecoration(hintText: 'Your guess'),
            ),
            const SizedBox(height: 11),
            PrimaryButton(
              label: 'Squeeze the range',
              icon: Icons.compress_rounded,
              onPressed: _submit,
            ),
          ] else ...[
            CurioCard(
              color: goldSoft,
              borderColor: gold,
              child: Column(
                children: [
                  Text(
                    _engine.solved
                        ? 'Found it: ${_engine.target}'
                        : 'The number was ${_engine.target}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _practice
                        ? 'Practice round — no XP, just sharper guessing.'
                        : _alreadyDone
                        ? 'Today’s XP was already earned — this one was for fun.'
                        : '+${gameRewards['squeeze']!.xp} XP for today’s hunt.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(_engine.numberFact, textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _restartPractice,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try a practice round'),
            ),
          ],
          if (_engine.guesses.isNotEmpty) ...[
            const SizedBox(height: 24),
            const SectionHeading('Your trail'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _engine.guesses
                  .map(
                    (guess) => Chip(
                      label: Text(
                        '$guess',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      backgroundColor: guess == _engine.target
                          ? greenSoft
                          : surface,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
