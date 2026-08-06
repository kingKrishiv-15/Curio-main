import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/dashboard/entities/child_dashboard.dart';
import '../../../domain/dashboard/repositories/dashboard_repository.dart';
import '../../../repository/dashboard/fake_dashboard_repository.dart';

/// UI-sprint wiring: points at the in-memory fake. Swapping to a real
/// Supabase-backed repository later is a one-line change here - nothing in
/// presentation/home/ imports FakeDashboardRepository directly.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return FakeDashboardRepository();
});

final dashboardProvider = StreamProvider.family<ChildDashboard, String>((ref, childId) {
  return ref.watch(dashboardRepositoryProvider).watchDashboard(childId);
});
