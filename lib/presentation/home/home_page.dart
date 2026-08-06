import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/curio_colors.dart';
import '../../core/theme/curio_typography.dart';
import '../widgets/animated_stat_number.dart';
import '../widgets/companion_badge.dart';
import '../widgets/idle_float.dart';
import '../widgets/pressable_scale.dart';
import 'providers/dashboard_providers.dart';
import 'widgets/entry_point_card.dart';

/// Bold light-mode platform-layer Home. Fake data only this sprint (see
/// dashboard_providers.dart) - no live Supabase calls.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Falls back to the fake repository's sample child when there's no
    // real onboarding session yet (e.g. jumping straight to /home during
    // this UI-only sprint) - see FakeDashboardRepository.
    final childId = ref.watch(activeChildProvider)?.id ?? 'fake-child-1';
    final dashboardAsync = ref.watch(dashboardProvider(childId));

    return Scaffold(
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Something went wrong: $error')),
          data: (dashboard) => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hey,', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: CurioColors.inkMuted)),
                            Text(dashboard.displayName, style: Theme.of(context).textTheme.displayMedium),
                          ],
                        ),
                      ),
                      _ProfileButton(onTap: () => context.go('/home')),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: _StreakCard(
                          currentStreak: dashboard.currentStreak,
                          longestStreak: dashboard.longestStreak,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _CompanionCard(dragonStage: dashboard.dragonStage, totalXp: dashboard.totalXp),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Text('Ways to learn', style: CurioTypography.platform.labelLarge?.copyWith(color: CurioColors.inkMuted)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: EntryPointCard(
                    label: 'Curio Special',
                    subtitle: 'Story worlds, encounters, and discoveries',
                    icon: Icons.auto_awesome,
                    tintColor: CurioColors.electricPurpleTint,
                    accentColor: CurioColors.electricPurple,
                    featured: true,
                    onTap: () => context.go('/curio-special'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: EntryPointCard(
                          label: 'Maths',
                          icon: Icons.grid_view_rounded,
                          tintColor: CurioColors.acidGreenTint,
                          accentColor: CurioColors.acidGreen,
                          onTap: () => context.go('/maths'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: EntryPointCard(
                          label: 'IPM & MAT',
                          icon: Icons.bolt_rounded,
                          tintColor: CurioColors.cyberLimeTint,
                          accentColor: const Color(0xFF8A9600), // darker lime for icon contrast against white glyph
                          onTap: () => context.go('/sharpen'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.currentStreak, required this.longestStreak});

  final int currentStreak;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CurioColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: CurioColors.hotCoral, size: 26),
          const SizedBox(height: 10),
          AnimatedStatNumber(
            value: currentStreak,
            style: CurioTypography.statNumber(Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            'day streak',
            style: CurioTypography.platform.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 8),
          Text(
            'Best: $longestStreak',
            style: CurioTypography.platform.labelMedium?.copyWith(color: CurioColors.hotCoral),
          ),
        ],
      ),
    );
  }
}

class _CompanionCard extends StatelessWidget {
  const _CompanionCard({required this.dragonStage, required this.totalXp});

  final int dragonStage;
  final int totalXp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CurioColors.electricPurpleTint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IdleFloat(
            amplitude: 5,
            child: CompanionBadge(stage: dragonStage, size: 64),
          ),
          const SizedBox(height: 8),
          Text('Stage $dragonStage', style: CurioTypography.platform.titleMedium),
          Text(
            '$totalXp XP',
            style: CurioTypography.platform.bodySmall?.copyWith(color: CurioColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: CurioColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.person_outline, color: CurioColors.ink),
      ),
    );
  }
}
