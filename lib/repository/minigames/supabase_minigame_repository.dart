import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/minigames/entities/minigame_archive_entry.dart';
import '../../domain/minigames/entities/minigame_attempt.dart';
import '../../domain/minigames/entities/minigame_move_result.dart';
import '../../domain/minigames/entities/minigame_puzzle.dart';
import '../../domain/minigames/entities/minigame_streak.dart';
import '../../domain/minigames/entities/minigame_type.dart';
import '../../domain/minigames/repositories/minigame_repository.dart';

/// Talks to the RPCs in migration 0002. Everything goes through those
/// functions rather than direct table reads, because they are what enforce
/// the rules the client isn't trusted with - the answer never leaves the
/// database, and attempts/moves can only be written by the server.
class SupabaseMinigameRepository implements MinigameRepository {
  SupabaseMinigameRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<MinigamePuzzle?> fetchPuzzle({required MinigameType type, required DateTime date}) async {
    try {
      final rows = await _client.rpc(
        'get_minigame_puzzle',
        params: {'p_puzzle_type': type.wireValue, 'p_puzzle_date': _asDate(date)},
      ) as List<dynamic>;

      if (rows.isEmpty) return null;
      final row = rows.first as Map<String, dynamic>;

      return MinigamePuzzle(
        id: row['id'] as String,
        puzzleDate: DateTime.parse(row['puzzle_date'] as String),
        type: MinigameType.fromWire(row['puzzle_type'] as String),
        publicConfig: Map<String, dynamic>.from(row['public_config'] as Map),
      );
    } on PostgrestException catch (error) {
      throw MinigameFailure(error.message);
    }
  }

  @override
  Future<MinigameAttempt> startOrResumeAttempt({required String childId, required String puzzleId}) async {
    try {
      final row = await _client.rpc(
        'start_or_resume_minigame_attempt',
        params: {'p_child_id': childId, 'p_puzzle_id': puzzleId},
      ) as Map<String, dynamic>;

      return _attemptFromRow(row);
    } on PostgrestException catch (error) {
      throw MinigameFailure(error.message);
    }
  }

  @override
  Future<MinigameMoveResult> submitMove({
    required String attemptId,
    required Map<String, dynamic> moveData,
    required String idempotencyKey,
  }) async {
    try {
      final result = await _client.rpc(
        'submit_minigame_move',
        params: {
          'p_attempt_id': attemptId,
          'p_move_data': moveData,
          'p_idempotency_key': idempotencyKey,
        },
      );

      return MinigameMoveResult(Map<String, dynamic>.from(result as Map));
    } on PostgrestException catch (error) {
      throw MinigameFailure(error.message);
    }
  }

  @override
  Future<MinigameAttempt?> fetchAttempt({required String childId, required String puzzleId}) async {
    try {
      final row = await _client
          .from('minigame_attempt')
          .select()
          .eq('child_id', childId)
          .eq('puzzle_id', puzzleId)
          .maybeSingle();

      if (row == null) return null;
      return _attemptFromRow(row);
    } on PostgrestException catch (error) {
      throw MinigameFailure(error.message);
    }
  }

  @override
  Future<List<MinigameArchiveEntry>> listArchive({
    required String childId,
    required MinigameType type,
    int limit = 30,
  }) async {
    try {
      final rows = await _client.rpc(
        'list_minigame_archive',
        params: {'p_child_id': childId, 'p_puzzle_type': type.wireValue, 'p_limit': limit},
      ) as List<dynamic>;

      return rows.map((dynamic raw) {
        final row = raw as Map<String, dynamic>;
        final status = row['status'] as String?;
        return MinigameArchiveEntry(
          puzzleId: row['puzzle_id'] as String,
          puzzleDate: DateTime.parse(row['puzzle_date'] as String),
          status: status == null ? null : MinigameStatus.fromWire(status),
          score: row['score'] as int?,
        );
      }).toList();
    } on PostgrestException catch (error) {
      throw MinigameFailure(error.message);
    }
  }

  @override
  Future<MinigameStreak> recordStreak({
    required String childId,
    required MinigameType type,
    required DateTime playedOn,
  }) async {
    try {
      final row = await _client.rpc(
        'record_minigame_streak',
        params: {
          'p_child_id': childId,
          'p_puzzle_type': type.wireValue,
          'p_played_on': _asDate(playedOn),
        },
      ) as Map<String, dynamic>;

      return _streakFromRow(row);
    } on PostgrestException catch (error) {
      throw MinigameFailure(error.message);
    }
  }

  @override
  Future<MinigameStreak> fetchStreak({required String childId, required MinigameType type}) async {
    try {
      final row = await _client
          .from('streak')
          .select()
          .eq('child_id', childId)
          .eq('streak_type', type.wireValue)
          .maybeSingle();

      if (row == null) return const MinigameStreak.empty();
      return _streakFromRow(row);
    } on PostgrestException catch (error) {
      throw MinigameFailure(error.message);
    }
  }

  MinigameAttempt _attemptFromRow(Map<String, dynamic> row) {
    final completedAt = row['completed_at'] as String?;
    return MinigameAttempt(
      id: row['id'] as String,
      puzzleId: row['puzzle_id'] as String,
      status: MinigameStatus.fromWire(row['status'] as String),
      state: Map<String, dynamic>.from(row['state'] as Map? ?? const {}),
      score: row['score'] as int?,
      startedAt: DateTime.parse(row['started_at'] as String),
      completedAt: completedAt == null ? null : DateTime.parse(completedAt),
    );
  }

  MinigameStreak _streakFromRow(Map<String, dynamic> row) {
    final last = row['last_qualified_date'] as String?;
    return MinigameStreak(
      currentCount: row['current_count'] as int? ?? 0,
      longestCount: row['longest_count'] as int? ?? 0,
      lastQualifiedDate: last == null ? null : DateTime.parse(last),
    );
  }

  /// Postgres `date` params want a bare yyyy-MM-dd, not a full timestamp -
  /// sending a timestamp makes "today" depend on the device's clock time as
  /// well as its date, which is exactly the drift a shared daily puzzle
  /// can't have.
  String _asDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
