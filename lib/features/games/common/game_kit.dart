import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../discoveries/domain/discovery.dart';
import 'daily_schedule.dart';
import 'game_rewards.dart';
import 'daily_game_session.dart';

/// Shared pieces for Curio's daily games, so each game file is only the
/// game: which puzzle is today's, the page header, the how-to-play sheet and
/// the end-of-game card.
abstract final class DailyPick {
  static final _epoch = DateTime.utc(2026, 1, 1);

  /// Days since Curio's epoch, by local calendar date — everyone on the same
  /// date gets the same puzzle, whatever the time of day.
  static int dayNumber([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime.utc(d.year, d.month, d.day).difference(_epoch).inDays;
  }

  /// Today's index into a bank of [length] puzzles, offset by [shift] for
  /// practice rounds.
  static int index(int length, {DateTime? date, int shift = 0}) {
    if (length < 1) {
      throw ArgumentError.value(length, 'length', 'Must be positive');
    }
    return (dayNumber(date) + shift) % length;
  }
}

/// Records completion of [game] (today's, for daily games) using its entry in
/// [gameRewards], and returns whether it had *already* been completed — so
/// the result card can say "no new XP" instead of claiming it again. Safe
/// without a [CurioScope] (e.g. a page pumped alone in a test).
bool awardDaily(BuildContext context, String game) {
  final reward = gameRewards[game];
  assert(reward != null, 'No reward for $game — add it to gameRewards');
  final state = context.getInheritedWidgetOfExactType<CurioScope>()?.notifier;
  if (state == null || reward == null) return false;
  final id = reward.dated
      ? CurioState.dailyActivityId(
          game,
          DailyGameSession.of(context)?.date ?? state.today,
        )
      : game;
  final already = state.completedActivities.contains(id);
  state.completeActivity(
    id: id,
    xp: reward.xp,
    skill: reward.skill,
    factId: reward.factId,
  );
  return already;
}

/// Whether [game] already counts for today — for result cards that are
/// shown again on a replay.
bool completedAlready(BuildContext context, String game) {
  final reward = gameRewards[game];
  final state = context.getInheritedWidgetOfExactType<CurioScope>()?.notifier;
  if (state == null || reward == null) return false;
  return state.completedActivities.contains(
    reward.dated
        ? CurioState.dailyActivityId(
            game,
            DailyGameSession.of(context)?.date ?? state.today,
          )
        : game,
  );
}

class GameHeader extends StatelessWidget {
  const GameHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.chips,
    this.trailing,
    super.key,
  });

  final String eyebrow, title, subtitle;
  final List<Widget> chips;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CurioEyebrow(eyebrow),
      const SizedBox(height: 6),
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
      const SizedBox(height: 7),
      Text(
        subtitle,
        style: TextStyle(
          color: curioColor(
            context,
            CurioColors.inkSoft,
            CurioColorsLight.inkSoft,
          ),
          height: 1.45,
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(child: Wrap(spacing: 14, runSpacing: 6, children: chips)),
          ?trailing,
        ],
      ),
    ],
  );
}

/// The "?" button every game puts in its app bar.
class HowToPlayButton extends StatelessWidget {
  const HowToPlayButton({required this.rules, super.key});
  final List<String> rules;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'How to play',
    icon: const Icon(Icons.help_outline_rounded),
    onPressed: () => showHowToPlay(context, rules),
  );
}

Future<void> showHowToPlay(BuildContext context, List<String> rules) {
  final coral = curioColor(context, CurioColors.coral, CurioColorsLight.coral);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to play',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 14),
            for (final line in rules)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8, right: 10),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: coral,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(line, style: const TextStyle(height: 1.5)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A short status line under the board: a hint, a near miss, a verdict.
class GameNotice extends StatelessWidget {
  const GameNotice({
    required this.message,
    this.tone = GameNoticeTone.info,
    super.key,
  });

  final String message;
  final GameNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (tone) {
      GameNoticeTone.info => (
        curioColor(context, CurioColors.blue, CurioColorsLight.blue),
        Icons.tips_and_updates_rounded,
      ),
      GameNoticeTone.good => (
        curioColor(context, CurioColors.success, CurioColorsLight.success),
        Icons.check_circle_rounded,
      ),
      GameNoticeTone.close => (
        curioColor(context, CurioColors.saffron, CurioColorsLight.saffron),
        Icons.adjust_rounded,
      ),
      GameNoticeTone.bad => (
        curioColor(context, CurioColors.danger, CurioColorsLight.danger),
        Icons.close_rounded,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: CurioClay(
        radius: 18,
        color: color.withValues(alpha: .14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(height: 1.4))),
          ],
        ),
      ),
    );
  }
}

enum GameNoticeTone { info, good, close, bad }

/// The end-of-game card: headline, score, a spoiler-free share line, and
/// what happens next.
class GameResultCard extends StatelessWidget {
  const GameResultCard({
    required this.title,
    required this.score,
    required this.shareText,
    required this.onPractice,
    this.xp,
    this.alreadyDone = false,
    this.gameId,
    super.key,
  });

  final String title;
  final String score;
  final String shareText;
  final VoidCallback onPractice;
  final int? xp;

  /// Today's daily was already finished, so this run earns no new XP.
  final bool alreadyDone;

  /// The activity id in [gameRewards]. When given, the card also shows the
  /// discovery a first-ever finish unlocks, and how many of today's daily
  /// games are done.
  final String? gameId;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final gold = curioColor(context, CurioColors.gold, CurioColorsLight.gold);
    final plum = curioColor(context, CurioColors.plum, CurioColorsLight.plum);
    final state = context
        .dependOnInheritedWidgetOfExactType<CurioScope>()
        ?.notifier;
    final reward = gameRewards[gameId];

    // A game's discovery is collected the first time it's ever finished, so
    // it's news only when this is the one recorded play of the game.
    Discovery? unlocked;
    if (state != null && reward != null && xp != null && !alreadyDone) {
      final plays = state.completedActivities
          .where((id) => activityGame(id) == gameId)
          .length;
      if (plays == 1) {
        unlocked = discoveries.where((d) => d.id == reward.factId).firstOrNull;
      }
    }
    final doneToday = state?.sectionsCompleted().length ?? 0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(score, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 8),
          if (xp != null && !alreadyDone)
            Row(
              children: [
                Icon(Icons.bolt_rounded, color: gold, size: 20),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '+$xp XP earned',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            )
          else if (alreadyDone)
            Text(
              'Today’s XP was already earned — this one was for fun.',
              style: TextStyle(color: muted),
            ),
          if (unlocked != null) ...[
            const SizedBox(height: 12),
            CurioStatusStrip(
              key: const Key('result_discovery'),
              icon: unlocked.icon,
              title: 'New discovery · ${unlocked.title}',
              body: unlocked.fact,
              color: plum,
            ),
          ],
          const SizedBox(height: 14),
          // The share line sits in a well pressed into the card.
          SizedBox(
            width: double.infinity,
            child: CurioClay(
              radius: 18,
              pressed: true,
              padding: const EdgeInsets.all(14),
              child: Text(shareText, style: const TextStyle(height: 1.6)),
            ),
          ),
          const SizedBox(height: 12),
          // Stacked, not side by side, so long labels and large text fit.
          FilledButton.icon(
            key: const Key('game_practice'),
            onPressed: onPractice,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Play a practice round'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: shareText));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Result copied — no spoilers in it'),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy result'),
          ),
          if (state != null && reward != null) ...[
            const SizedBox(height: 16),
            Text(
              '$doneToday of ${LearningSection.values.length} sections complete today',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            CurioProgressBar(
              value: doneToday / LearningSection.values.length,
              height: 6,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('result_more_games'),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              label: const Text('Back to today’s games'),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'New games arrive in Maths, Memory, English and Logic tomorrow.',
            style: TextStyle(color: muted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

/// Small "Practice round" ribbon so it's obvious a replay earns nothing.
class PracticeBadge extends StatelessWidget {
  const PracticeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final plum = curioColor(context, CurioColors.plum, CurioColorsLight.plum);
    return CurioClay(
      radius: 99,
      color: plum.withValues(alpha: .16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        'PRACTICE',
        style: TextStyle(
          color: plum,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
