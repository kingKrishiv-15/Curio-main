import '../entities/minigame_archive_entry.dart';
import '../entities/minigame_attempt.dart';
import '../entities/minigame_move_result.dart';
import '../entities/minigame_puzzle.dart';
import '../entities/minigame_streak.dart';
import '../entities/minigame_type.dart';

/// The one data interface all five minigames use. Every game gets its
/// puzzle, attempt, and move validation through here - no game talks to
/// Supabase directly, and no game gets its own repository.
abstract class MinigameRepository {
  /// Today's puzzle for [type], or a past date's for archive play. Null when
  /// nothing is published for that date.
  Future<MinigamePuzzle?> fetchPuzzle({required MinigameType type, required DateTime date});

  /// Starts an attempt, or returns the in-flight one so a player who closed
  /// the app mid-puzzle resumes rather than restarts.
  Future<MinigameAttempt> startOrResumeAttempt({required String childId, required String puzzleId});

  /// Submits one move for server-side validation. [idempotencyKey] must be
  /// stable for a given logical move (see [MinigameIdempotency]) so a retry
  /// after a dropped connection returns the original verdict instead of
  /// spending another guess.
  Future<MinigameMoveResult> submitMove({
    required String attemptId,
    required Map<String, dynamic> moveData,
    required String idempotencyKey,
  });

  /// Re-reads an attempt, for resuming into the right mid-puzzle state.
  Future<MinigameAttempt?> fetchAttempt({required String childId, required String puzzleId});

  Future<List<MinigameArchiveEntry>> listArchive({
    required String childId,
    required MinigameType type,
    int limit,
  });

  Future<MinigameStreak> recordStreak({
    required String childId,
    required MinigameType type,
    required DateTime playedOn,
  });

  Future<MinigameStreak> fetchStreak({required String childId, required MinigameType type});
}

/// Builds the idempotency keys [MinigameRepository.submitMove] expects.
///
/// Deliberately derived from the attempt and the move's position rather than
/// random: a retry of "move 3 of this attempt" has to produce the same key it
/// did the first time, or the server would treat it as a fresh guess and the
/// player would lose one to a flaky connection.
class MinigameIdempotency {
  const MinigameIdempotency._();

  static String forMove({required String attemptId, required int moveNumber}) {
    return '$attemptId:move:$moveNumber';
  }
}

/// Thrown for any minigame data failure; the UI shows [message] directly
/// rather than a raw PostgrestException.
class MinigameFailure implements Exception {
  const MinigameFailure(this.message);

  final String message;

  @override
  String toString() => 'MinigameFailure: $message';
}
