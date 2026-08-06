import '../../domain/dashboard/entities/child_dashboard.dart';
import '../../domain/dashboard/repositories/dashboard_repository.dart';

/// In-memory sample data for this sprint's UI work - no network, no
/// Supabase. Realistic-looking numbers so the screens demo well; nothing
/// here is meant to be "correct" data, just plausible enough to design and
/// screenshot against.
class FakeDashboardRepository implements DashboardRepository {
  static const _sample = ChildDashboard(
    childId: 'fake-child-1',
    displayName: 'Maya',
    currentStreak: 7,
    longestStreak: 12,
    dragonStage: 3,
    totalXp: 1240,
  );

  @override
  Stream<ChildDashboard> watchDashboard(String childId) async* {
    yield _sample;
  }
}
