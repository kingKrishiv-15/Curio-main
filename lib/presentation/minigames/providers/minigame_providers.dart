import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/minigames/entities/minigame_archive_entry.dart';
import '../../../domain/minigames/entities/minigame_puzzle.dart';
import '../../../domain/minigames/entities/minigame_streak.dart';
import '../../../domain/minigames/entities/minigame_type.dart';
import '../../../domain/minigames/repositories/minigame_repository.dart';
import '../../../repository/minigames/supabase_minigame_repository.dart';

/// Unlike the UI sprint's dashboard providers, these point at real Supabase
/// from the start - the whole point of these games is that the server, not
/// the client, decides whether a move was right.
final minigameRepositoryProvider = Provider<MinigameRepository>((ref) {
  return SupabaseMinigameRepository(ref.watch(supabaseClientProvider));
});

/// The date a puzzle is being played for. Defaults to today; the archive
/// overrides it to replay a past day through the same providers.
final minigamePuzzleDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final minigamePuzzleProvider = FutureProvider.family<MinigamePuzzle?, MinigameType>((ref, type) {
  final date = ref.watch(minigamePuzzleDateProvider);
  return ref.watch(minigameRepositoryProvider).fetchPuzzle(type: type, date: date);
});

final minigameStreakProvider = FutureProvider.family<MinigameStreak, MinigameType>((ref, type) {
  final childId = ref.watch(activeChildProvider)?.id;
  if (childId == null) return Future.value(const MinigameStreak.empty());
  return ref.watch(minigameRepositoryProvider).fetchStreak(childId: childId, type: type);
});

final minigameArchiveProvider =
    FutureProvider.family<List<MinigameArchiveEntry>, MinigameType>((ref, type) {
  final childId = ref.watch(activeChildProvider)?.id;
  if (childId == null) return Future.value(const <MinigameArchiveEntry>[]);
  return ref.watch(minigameRepositoryProvider).listArchive(childId: childId, type: type);
});
