import 'minigame_type.dart';

/// Builds the copyable result string every game produces.
///
/// The rule these all follow: the string encodes *how it went*, never *what
/// the answer was*. Emoji squares show hits and misses in order; nothing in
/// here lets a friend who hasn't played work out the solution, which is the
/// whole reason a Wordle grid is safe to post and a screenshot isn't.
class MinigameShare {
  const MinigameShare._();

  static const correctSquare = '🟩';
  static const closeSquare = '🟨';
  static const wrongSquare = '⬛';
  static const blankSquare = '⬜';

  /// [rows] are pre-built emoji lines, one per guess/round. [subtitle] is an
  /// optional spoiler-safe summary such as "2/3" or "cracked on clue 2".
  static String build({
    required MinigameType type,
    required DateTime puzzleDate,
    required List<String> rows,
    String? subtitle,
  }) {
    final buffer = StringBuffer()
      ..writeln('Curio ${type.displayName} · ${_formatDate(puzzleDate)}');

    if (subtitle != null && subtitle.isNotEmpty) {
      buffer.writeln(subtitle);
    }

    for (final row in rows) {
      buffer.writeln(row);
    }

    return buffer.toString().trimRight();
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime date) => '${_months[date.month - 1]} ${date.day}';
}
