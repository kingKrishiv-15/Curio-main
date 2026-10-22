import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../domain/english_game.dart';

class EnglishPage extends StatefulWidget {
  const EnglishPage({this.date, this.builder = false, super.key});
  final DateTime? date;
  final bool builder;

  @override
  State<EnglishPage> createState() => _EnglishPageState();
}

class _EnglishPageState extends State<EnglishPage> {
  final _scroll = ScrollController();
  late final _date = widget.date ?? DateTime.now();
  int _round = 0, _score = 0, _practice = 0;
  bool _answered = false,
      _correct = false,
      _result = false,
      _alreadyDone = false;
  String? _picked, _error;
  final List<int> _selected = [];

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _toTop() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
  });
  int get _day => DailyPick.dayNumber(_date) - _practice;
  String get _id => widget.builder ? 'word_builder' : 'word_wise';
  String get _title => widget.builder ? 'Word Builder' : 'Word Wise';
  WordQuestion get _question => questionsForDay(_day)[_round];
  (String, String) get _word => wordsForDay(_day)[_round];
  List<String> get _letters => shuffledLetters(_word.$1, _day * 17 + _round);

  void _answer(bool correct, {String? picked}) => setState(() {
    if (_answered) return;
    _answered = true;
    _correct = correct;
    _picked = picked;
    _error = null;
    if (correct) _score++;
  });

  void _checkWord() {
    if (_answered) return;
    if (_selected.map((i) => _letters[i]).join() == _word.$1) {
      _answer(true);
    } else {
      setState(
        () => _error =
            'Not quite. Try a different letter order, or use “Show the word”.',
      );
    }
  }

  void _next() {
    if (!_answered) return;
    if (_round == 4) {
      if (_practice == 0) _alreadyDone = awardDaily(context, _id);
      setState(() => _result = true);
    } else {
      setState(() {
        _round++;
        _answered = false;
        _picked = null;
        _selected.clear();
        _error = null;
      });
    }
    _toTop();
  }

  void _replay() {
    setState(() {
      _practice++;
      _round = 0;
      _score = 0;
      _answered = false;
      _result = false;
      _picked = null;
      _selected.clear();
      _error = null;
    });
    _toTop();
  }

  @override
  Widget build(BuildContext context) => CurioPage(
    title: _title,
    actions: [
      HowToPlayButton(
        rules: widget.builder
            ? const [
                'Read the clue, then tap the letters in the right order to make a word.',
                'Use Undo or Clear to change your word. You can try again without a timer.',
                'If you get stuck, reveal the word and learn its spelling. Complete five words to finish.',
              ]
            : const [
                'Read the question and tap the answer you think fits best.',
                'Each answer has an explanation. Read it before moving on.',
                'There are five questions. Completing them earns your daily XP, even when you are still learning.',
              ],
      ),
    ],
    child: ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        GameHeader(
          eyebrow: 'Today’s English game',
          title: _title,
          subtitle: widget.builder
              ? 'A clue, a handful of letters, a new word to discover.'
              : 'Play with words. Find their meanings. Read between the lines.',
          chips: const [
            GameMetaChip(icon: Icons.menu_book_rounded, label: 'English'),
            GameMetaChip(icon: Icons.schedule_rounded, label: '3 min'),
          ],
        ),
        if (_practice > 0)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: PracticeBadge(),
            ),
          ),
        const SizedBox(height: 20),
        if (_result)
          GameResultCard(
            title: _score == 5
                ? 'Wonderful word work!'
                : 'Your words are growing!',
            score: '$_score / 5',
            shareText:
                'Curio · $_title\n$_score of 5 ${widget.builder ? 'words built' : 'questions answered correctly'}',
            gameId: _id,
            xp: _practice == 0 ? gameRewards[_id]!.xp : null,
            alreadyDone: _alreadyDone,
            onPractice: _replay,
          )
        else ...[
          Text(
            '${widget.builder ? 'Word' : 'Question'} ${_round + 1} of 5',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          CurioProgressBar(value: _round / 5),
          const SizedBox(height: 20),
          if (widget.builder) ..._builderBoard() else ..._questionBoard(),
          if (_answered) ...[
            const SizedBox(height: 16),
            GameNotice(
              message: widget.builder
                  ? '${_correct ? 'You built it!' : 'A word to remember:'} ${_word.$1}. ${_word.$2}.'
                  : '${_correct ? 'That’s right!' : 'Good try!'} ${_question.explanation}',
              tone: _correct ? GameNoticeTone.good : GameNoticeTone.info,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('english_next'),
              onPressed: _next,
              child: Text(
                _round == 4
                    ? 'See result'
                    : widget.builder
                    ? 'Next word'
                    : 'Next question',
              ),
            ),
          ],
        ],
      ],
    ),
  );

  List<Widget> _questionBoard() {
    final options = List.of(_question.options)
      ..shuffle(Random(_day * 29 + _round));
    return [
      Text(_question.prompt, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      for (var i = 0; i < options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OutlinedButton(
            key: Key('english_option_$i'),
            onPressed: _answered
                ? null
                : () => _answer(
                    options[i] == _question.answer,
                    picked: options[i],
                  ),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(16),
              disabledForegroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            child: Row(
              children: [
                Expanded(child: Text(options[i])),
                if (_answered && options[i] == _question.answer)
                  const Icon(Icons.check_circle_rounded)
                else if (_picked == options[i])
                  const Icon(Icons.close_rounded),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _builderBoard() => [
    Text(_word.$2, style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 16),
    Semantics(
      liveRegion: true,
      label: 'Your word: ${_selected.map((i) => _letters[i]).join(' ')}',
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          _answered
              ? _word.$1
              : _selected.isEmpty
              ? '_ _ _ _ _'
              : _selected.map((i) => _letters[i]).join(' '),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    ),
    const SizedBox(height: 16),
    Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < _letters.length; i++)
          OutlinedButton(
            key: Key('english_letter_$i'),
            onPressed: _answered || _selected.contains(i)
                ? null
                : () => setState(() {
                    _selected.add(i);
                    _error = null;
                  }),
            style: OutlinedButton.styleFrom(minimumSize: const Size(52, 56)),
            child: Text(_letters[i]),
          ),
      ],
    ),
    if (!_answered) ...[
      const SizedBox(height: 10),
      Wrap(
        spacing: 12,
        alignment: WrapAlignment.center,
        children: [
          TextButton.icon(
            onPressed: _selected.isEmpty
                ? null
                : () => setState(() => _selected.removeLast()),
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Undo'),
          ),
          TextButton(
            onPressed: _selected.isEmpty
                ? null
                : () => setState(_selected.clear),
            child: const Text('Clear'),
          ),
        ],
      ),
      if (_error != null) GameNotice(message: _error!),
      const SizedBox(height: 12),
      FilledButton(
        key: const Key('english_check'),
        onPressed: _selected.length == _letters.length ? _checkWord : null,
        child: const Text('Check word'),
      ),
      TextButton(
        key: const Key('english_reveal'),
        onPressed: () => _answer(false),
        child: const Text('Show the word'),
      ),
    ],
  ];
}
