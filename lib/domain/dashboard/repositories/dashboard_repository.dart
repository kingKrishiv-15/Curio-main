import '../entities/child_dashboard.dart';

/// What the Home screen depends on. This sprint's implementation
/// (repository/dashboard/fake_dashboard_repository.dart) is in-memory sample
/// data - swapping in a real Supabase-backed implementation later means
/// writing one new class and changing one Riverpod provider override in
/// app/providers.dart. No presentation-layer code changes either way.
abstract class DashboardRepository {
  /// Streams the given child's dashboard summary, updating whenever their
  /// streak/XP/stage changes. A Stream (not a one-shot Future) because this
  /// is exactly the kind of value that changes underneath an already-open
  /// screen (finishing a session elsewhere should update Home live once
  /// it's wired to Supabase Realtime or simple refetch-on-focus later).
  Stream<ChildDashboard> watchDashboard(String childId);
}
