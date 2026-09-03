import 'minigame_type.dart';

/// One day's puzzle for one game, as the client is allowed to see it.
///
/// [publicConfig] is deliberately an untyped map: it holds whatever that
/// game needs to render (Loophole's statement tokens, Odd Cluster's sixteen
/// tiles, Bridge's start/target and operation tiles), and each game parses
/// its own shape out of it. What it never contains is the answer - that
/// lives encrypted server-side and is only ever compared against, never
/// returned.
class MinigamePuzzle {
  const MinigamePuzzle({
    required this.id,
    required this.puzzleDate,
    required this.type,
    required this.publicConfig,
  });

  final String id;
  final DateTime puzzleDate;
  final MinigameType type;
  final Map<String, dynamic> publicConfig;
}
