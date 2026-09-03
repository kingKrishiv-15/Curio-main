import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// One day's puzzle, as much of it as a client is allowed to see. The answer
/// is not in here and never comes down the wire - `config` holds only what
/// the board needs to render.
class DailyPuzzle {
  const DailyPuzzle({
    required this.id,
    required this.date,
    required this.type,
    required this.config,
  });

  final String id;
  final DateTime date;
  final String type;
  final Map<String, dynamic> config;
}

/// A player's run at one puzzle. `state` is the server's record of progress -
/// which round they are on, how many guesses they've spent - so closing the
/// app mid-puzzle resumes instead of restarting.
class PuzzleAttempt {
  const PuzzleAttempt({
    required this.id,
    required this.status,
    required this.state,
    required this.score,
  });

  final String id;
  final String status;
  final Map<String, dynamic> state;
  final int? score;

  bool get isFinished => status != 'in_progress';
}

/// The server's verdict on one move. Deliberately a thin wrapper over the
/// returned map: each game reads the keys it cares about, and what matters
/// is what the server chose *not* to include (nothing that would give away
/// an answer still in play).
class MoveVerdict {
  const MoveVerdict(this.data);

  final Map<String, dynamic> data;

  bool get isCorrect => data['correct'] == true;
  bool get isRoundOver => data['round_over'] == true;
  bool get isFinished => data['finished'] == true;
  int? get target => data['target'] as int?;
  String? get explanation => data['explanation'] as String?;
  int? get score => data['score'] as int?;
  List<int> get marks =>
      (data['marks'] as List?)?.map((m) => m as int).toList() ?? const [];
}

class MinigameNotAvailable implements Exception {
  const MinigameNotAvailable(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Talks to the daily-puzzle RPCs. Every call goes through a database
/// function rather than a table read, because those functions are what hold
/// the rules the client isn't trusted with: the answer stays server-side and
/// only a verdict comes back.
class MinigameService {
  /// The optional client is a seam for tests; production callers use
  /// `MinigameService()` and get the shared Supabase instance.
  MinigameService([this._client]);

  final SupabaseClient? _client;
  String? _childId;

  SupabaseClient get _db {
    if (!SupabaseConfig.isConfigured) {
      throw const MinigameNotAvailable(
        'Daily puzzles need a Supabase connection. Run with '
        '--dart-define-from-file=config/supabase.json.',
      );
    }
    return _client ?? Supabase.instance.client;
  }

  bool get isSignedIn =>
      SupabaseConfig.isConfigured && _db.auth.currentUser != null;

  /// Resolves the child this device is playing as, creating one on first run.
  /// Mirrors how SupabaseProgressStore picks a child so both agree on which
  /// profile a signed-in parent is playing.
  Future<String> _childProfileId() async {
    if (_childId != null) return _childId!;

    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      throw const MinigameNotAvailable('Sign in to play the daily puzzle.');
    }

    final existing = await _db
        .from('child_profiles')
        .select('id')
        .eq('parent_id', userId)
        .order('created_at')
        .limit(1)
        .maybeSingle();

    final child =
        existing ??
        await _db
            .from('child_profiles')
            .insert({'parent_id': userId, 'name': 'Explorer'})
            .select('id')
            .single();

    _childId = child['id'] as String;
    return _childId!;
  }

  /// The puzzle for [type] on [date] (today's, or a past date from the
  /// archive). Null when nothing is published for that day.
  Future<DailyPuzzle?> fetchPuzzle(String type, DateTime date) async {
    final rows =
        await _db.rpc(
              'get_daily_puzzle',
              params: {
                'p_puzzle_type': type,
                'p_puzzle_date': _dateOnly(date),
              },
            )
            as List<dynamic>;

    if (rows.isEmpty) return null;
    final row = rows.first as Map<String, dynamic>;
    return DailyPuzzle(
      id: row['id'] as String,
      date: DateTime.parse(row['puzzle_date'] as String),
      type: row['puzzle_type'] as String,
      config: Map<String, dynamic>.from(row['public_config'] as Map),
    );
  }

  Future<PuzzleAttempt> startAttempt(String puzzleId) async {
    final childId = await _childProfileId();
    final row =
        await _db.rpc(
              'start_puzzle_attempt',
              params: {'p_child_id': childId, 'p_puzzle_id': puzzleId},
            )
            as Map<String, dynamic>;
    return _attempt(row);
  }

  /// [idempotencyKey] must be stable for a given logical move - derived from
  /// the attempt and the move's position, never random - so a retry after a
  /// dropped connection returns the original verdict instead of spending
  /// another guess.
  Future<MoveVerdict> submitMove({
    required String attemptId,
    required Map<String, dynamic> moveData,
    required String idempotencyKey,
  }) async {
    final result = await _db.rpc(
      'submit_puzzle_move',
      params: {
        'p_attempt_id': attemptId,
        'p_move_data': moveData,
        'p_idempotency_key': idempotencyKey,
      },
    );
    return MoveVerdict(Map<String, dynamic>.from(result as Map));
  }

  Future<int> currentStreak(String type) async {
    final childId = await _childProfileId();
    final row = await _db
        .from('puzzle_streaks')
        .select('current_count')
        .eq('child_id', childId)
        .eq('puzzle_type', type)
        .maybeSingle();
    return (row?['current_count'] as int?) ?? 0;
  }

  Future<void> recordStreak(String type, DateTime playedOn) async {
    final childId = await _childProfileId();
    await _db.rpc(
      'record_puzzle_streak',
      params: {
        'p_child_id': childId,
        'p_puzzle_type': type,
        'p_played_on': _dateOnly(playedOn),
      },
    );
  }

  PuzzleAttempt _attempt(Map<String, dynamic> row) => PuzzleAttempt(
    id: row['id'] as String,
    status: row['status'] as String,
    state: Map<String, dynamic>.from(row['state'] as Map? ?? const {}),
    score: row['score'] as int?,
  );

  /// A Postgres `date` wants a bare yyyy-MM-dd. Sending a full timestamp
  /// would make "today" depend on the time of day as well as the date, which
  /// is the one thing a shared daily puzzle cannot tolerate.
  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
