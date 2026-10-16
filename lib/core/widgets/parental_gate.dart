import 'dart:math';

import 'package:flutter/material.dart';

import '../navigation/open_page.dart';
import '../theme/curio_colors.dart';
import '../theme/curio_colors_light.dart';
import 'curio_ui.dart';

/// "Grown-ups only": a times-table question in front of the parent areas
/// (dashboard, family settings, data export), as kids' app stores expect.
/// Passing it unlocks those areas for ten minutes so a parent isn't asked
/// again on every tap.
abstract final class ParentalGate {
  static DateTime? _passedAt;
  static const _window = Duration(minutes: 10);

  static bool get _open =>
      _passedAt != null && DateTime.now().difference(_passedAt!) < _window;

  /// True if the grown-up answered correctly (or recently did).
  static Future<bool> check(BuildContext context, {Random? random}) async {
    if (_open) return true;
    final passed = await showDialog<bool>(
      context: context,
      builder: (_) => _GateDialog(random: random ?? Random()),
    );
    if (passed == true) _passedAt = DateTime.now();
    return passed == true;
  }

  /// Opens [page] behind the gate.
  static Future<void> open(BuildContext context, Widget page) async {
    if (await check(context) && context.mounted) {
      await openPage(context, page);
    }
  }

  @visibleForTesting
  static void reset({bool passed = false}) =>
      _passedAt = passed ? DateTime.now() : null;
}

class _GateDialog extends StatefulWidget {
  const _GateDialog({required this.random});
  final Random random;

  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> {
  late int _a, _b;
  late List<int> _choices;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    final r = widget.random;
    _a = 6 + r.nextInt(4);
    _b = 6 + r.nextInt(4);
    final answer = _a * _b;
    final options = <int>{answer};
    while (options.length < 4) {
      final offset = (r.nextInt(4) + 1) * (r.nextBool() ? 1 : -1);
      final candidate = answer + offset * (r.nextBool() ? 1 : _a);
      if (candidate > 0) options.add(candidate);
    }
    _choices = options.toList()..shuffle(r);
  }

  void _pick(int value) {
    if (value == _a * _b) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _wrong = true;
      _newQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(context, CurioColors.inkSoft, CurioColorsLight.inkSoft);
    return AlertDialog(
      title: const Text('Grown-ups only'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This area has family settings and account details. To continue, answer:',
            style: TextStyle(color: muted, height: 1.45),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'What is $_a × $_b?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          if (_wrong) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Not quite — here’s a new one.',
                style: TextStyle(
                  color: curioColor(context, CurioColors.danger, CurioColorsLight.danger),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final choice in _choices)
                SizedBox(
                  width: 96,
                  child: OutlinedButton(
                    key: Key('gate_$choice'),
                    onPressed: () => _pick(choice),
                    child: Text('$choice', style: const TextStyle(fontSize: 18)),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
