import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../theme/curio_tokens.dart';
import '../../games/common/game_rewards.dart';

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

    return CurioClay(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Semantics(
                header: true,
                child: const Text('This week', style: CurioTokens.title),
              ),
              Text(
                state.streak == 0
                    ? 'No streak yet'
                    : '${state.streak} day streak',
                key: const Key('home_streak'),
                style: CurioTokens.label,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < _weekdays.length; i++)
                Expanded(
                  child: _WeekDay(
                    label: _weekdays[i],
                    date: DateTime(today.year, today.month, monday + i),
                    isToday: i == today.weekday - 1,
                    playedDates: playedDates,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: CurioTokens.border),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                goalMet
                    ? 'Daily goal reached'
                    : 'Daily goal: $completed of $goal',
                style: CurioTokens.label,
              ),
              Text('${state.totalXp} XP total', style: CurioTokens.label),
            ],
          ),
          const SizedBox(height: 4),
          ExcludeSemantics(
            child: CurioProgressBar(
              value: completed / goal,
              color: goalMet ? CurioTokens.correct : CurioTokens.accent,
              height: 5,
            ),
          ),
        ],
      ),
    );
  }
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
    return Semantics(
      label:
          '$day${isToday ? ', today' : ''}, ${played ? 'played' : 'not played'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            DecoratedBox(
              decoration: ShapeDecoration(
                shape: CircleBorder(
                  side: isToday
                      ? const BorderSide(color: CurioTokens.wrong, width: 1.5)
                      : BorderSide.none,
                ),
                color: played
                    ? CurioTokens.wash(CurioTokens.tintMaths, .3)
                    : isToday
                    ? CurioTokens.wash(CurioTokens.accent)
                    : CurioTokens.surfaceRaised,
              ),
              child: SizedBox.square(
                dimension: 32,
                child: Icon(
                  played ? Icons.local_fire_department_rounded : Icons.remove,
                  size: 16,
                  color: CurioTokens.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: CurioTokens.label.copyWith(
                  color: isToday ? CurioTokens.textPrimary : null,
                  fontWeight: isToday ? FontWeight.w800 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
