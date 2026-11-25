import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../theme/curio_tokens.dart';
import '../../games/common/game_rewards.dart';
import '../../../core/widgets/curio_kit.dart';

/// The week so far: a section title with the streak beside it, then one
/// bordered card with a dot per day and the daily goal underneath.
class WeeklyProgress extends StatelessWidget {
  const WeeklyProgress({required this.state, super.key});

  final CurioState state;

  static const _weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  Widget build(BuildContext context) {
    final today = state.today;
    final monday = today.day - today.weekday + 1;
    final playedDates = state.completedActivities
        .map((id) => id.substring(activityGame(id).length))
        .toSet();
    final goal = state.dailyGoal;
    final completed = state.dailyGoalCompleted;
    final goalMet = completed >= goal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(
          'This week',
          trailing: _StreakChip(streak: state.streak),
        ),
        const SizedBox(height: CurioTokens.s16),
        CurioClay(
          padding: const EdgeInsets.all(CurioTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (var i = 0; i < _weekdays.length; i++) ...[
                    if (i > 0) const SizedBox(width: CurioTokens.s4),
                    Expanded(
                      child: _WeekDay(
                        label: _weekdays[i],
                        date: DateTime(today.year, today.month, monday + i),
                        isToday: i == today.weekday - 1,
                        playedDates: playedDates,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: CurioTokens.s16),
              const Divider(height: 1, color: CurioTokens.border),
              const SizedBox(height: CurioTokens.s16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goalMet
                          ? 'Daily goal reached'
                          : 'Daily goal: $completed of $goal',
                      style: CurioType.strong,
                    ),
                  ),
                  const SizedBox(width: CurioTokens.s12),
                  Text('${state.totalXp} XP total', style: CurioType.meta),
                ],
              ),
              const SizedBox(height: CurioTokens.s8),
              ExcludeSemantics(
                child: CurioProgressBar(
                  value: completed / goal,
                  color: goalMet ? CurioTokens.correct : CurioTokens.accent,
                  height: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: streak == 0
          ? CurioTokens.surfaceRaised
          : CurioTokens.wash(CurioTokens.accent, .12),
      borderRadius: CurioTokens.pillShape,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CurioTokens.s12,
        vertical: CurioTokens.s4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 16,
            color: streak == 0 ? CurioTokens.textSecondary : CurioTokens.accent,
          ),
          const SizedBox(width: CurioTokens.s4),
          Text(
            streak == 0 ? 'No streak yet' : '$streak day streak',
            key: const Key('home_streak'),
            style: CurioType.chip,
          ),
        ],
      ),
    ),
  );
}

class _WeekDay extends StatelessWidget {
  const _WeekDay({
    required this.label,
    required this.date,
    required this.isToday,
    required this.playedDates,
  });

  final String label;
  final DateTime date;
  final bool isToday;
  final Set<String> playedDates;

  @override
  Widget build(BuildContext context) {
    final played = playedDates.contains(CurioState.dailyActivityId('', date));
    final day = MaterialLocalizations.of(context).formatFullDate(date);
    final ink = isToday ? CurioTokens.textPrimary : CurioTokens.textSecondary;
    // A capsule per day, as in a booking calendar: the weekday, the date,
    // and a flame once something was played. Today wears a dark outline.
    return Semantics(
      label:
          '$day${isToday ? ', today' : ''}, ${played ? 'played' : 'not played'}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: StadiumBorder(
            side: isToday
                ? const BorderSide(color: CurioTokens.textPrimary, width: 1.5)
                : BorderSide.none,
          ),
          color: played
              ? CurioTokens.wash(CurioTokens.accent, .14)
              : isToday
              ? CurioTokens.surface
              : CurioTokens.surfaceRaised,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: CurioTokens.s8),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: CurioTokens.label.copyWith(color: ink),
                ),
              ),
              const SizedBox(height: CurioTokens.s4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${date.day}',
                  style: CurioType.strong.copyWith(
                    color: ink,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: CurioTokens.s4),
              Icon(
                played
                    ? Icons.local_fire_department_rounded
                    : Icons.circle_outlined,
                size: 14,
                color: played
                    ? CurioTokens.accent
                    : CurioTokens.wash(CurioTokens.textPrimary, .2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
