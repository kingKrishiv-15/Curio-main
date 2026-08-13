import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/state/curio_state.dart';
import '../../../../core/theme/curio_colors.dart';
import '../../../../core/widgets/curio_ui.dart';
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
  bool _rewardGranted = false;

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
    if (_engine.solved && !_rewardGranted) {
      _rewardGranted = true;
      CurioScope.of(context).completeActivity(
        id: CurioState.dailyActivityId('squeeze'),
        xp: 80,
        skill: 'Number sense',
        factId: 'prime_numbers',
      );
    }
  }

  void _restartPractice() {
    setState(() {
      _engine = SqueezeEngine(target: 37);
      _message = 'Practice round ready. Find the new number!';
      _rewardGranted = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _engine.guesses.length / SqueezeEngine.maxGuesses;
    return CurioPage(
      title: 'Daily Squeeze',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          CurioCard(
            color: CurioColors.navy,
            borderColor: CurioColors.navy,
            child: Column(
              children: [
                const Text(
                  'SECRET RANGE',
                  style: TextStyle(
                    color: CurioColors.gold,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_engine.minimum}  —  ${_engine.maximum}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 39,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 13),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    backgroundColor: Colors.white12,
                    color: CurioColors.coral,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_engine.guessesLeft} guesses left',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CurioCard(
            color: _engine.solved
                ? CurioColors.greenSoft
                : CurioColors.tealSoft,
            borderColor: _engine.solved ? CurioColors.green : CurioColors.teal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _engine.solved
                      ? Icons.celebration_rounded
                      : Icons.tips_and_updates_rounded,
                  color: _engine.solved
                      ? CurioColors.green
                      : CurioColors.tealDark,
                ),
                const SizedBox(width: 11),
                Expanded(child: Text(_message)),
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
              color: CurioColors.goldSoft,
              borderColor: CurioColors.gold,
              child: Column(
                children: [
                  Text(
                    _engine.solved
                        ? '+80 XP earned'
                        : 'The number was ${_engine.target}',
                    style: Theme.of(context).textTheme.titleLarge,
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
                          ? CurioColors.greenSoft
                          : Colors.white,
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
