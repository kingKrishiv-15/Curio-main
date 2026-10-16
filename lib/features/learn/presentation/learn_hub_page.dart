import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/common/game_rewards.dart';
import '../../games/game_catalog.dart';
import '../../games/presentation/game_card.dart';
import '../../skills/presentation/skill_quest_page.dart';

/// The Games tab: today's featured quest, then every game as a card,
/// filterable by skill, with what's already been played today sorted last.
class LearnHubPage extends StatefulWidget {
  const LearnHubPage({super.key});

  @override
  State<LearnHubPage> createState() => _LearnHubPageState();
}

class _LearnHubPageState extends State<LearnHubPage> {
  /// null shows every skill.
  String? _skill;

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final featured = featuredGame();
    bool done(GameEntry g) => g.isDaily
        ? state.completedToday(g.id)
        : state.completedActivities.contains(g.id);

    final daily = dailyGames;
    final playedToday = daily.where(done).length;
    // The featured game already has the hero card; skip it in the grid.
    final shown = [
      for (final g in daily)
        if (g.id != featured.id && (_skill == null || g.skill == _skill)) g,
    ]..sort((a, b) => (done(a) ? 1 : 0).compareTo(done(b) ? 1 : 0));
    final stories = gameCatalog.where((g) => !g.isDaily);
    final muted = curioColor(context, CurioColors.inkSoft, CurioColorsLight.inkSoft);

    return CurioPage(
      extendBehindBottom: true,
      maxWidth: 1040,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 104),
        children: [
          const PageIntro(
            eyebrow: 'The playroom',
            title: 'Ways to learn',
            subtitle:
                'Short, thoughtful games that stretch logic, number sense, patterns and good judgement.',
          ),
          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: GameCard(
                game: featured,
                style: GameCardStyle.hero,
                featured: true,
                done: done(featured),
              ),
            ),
          ),
          const SizedBox(height: 26),
          SectionHeading(
            'Daily games',
            subtitle:
                '$playedToday of ${daily.length} played today · a fresh puzzle in each, every day',
          ),
          const SizedBox(height: 12),
          _SkillFilter(
            selected: _skill,
            counts: {
              for (final skill in learningSkills)
                skill: daily.where((g) => g.skill == skill).length,
            },
            onSelected: (skill) => setState(() => _skill = skill),
          ),
          const SizedBox(height: 14),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Today’s featured quest is the ${_skill?.toLowerCase()} game — it’s at the top.',
                style: TextStyle(color: muted),
              ),
            )
          else
            GameGrid(
              children: [
                for (final g in shown) GameCard(game: g, done: done(g)),
              ],
            ),
          const SizedBox(height: 28),
          const SectionHeading(
            'Stories',
            subtitle: 'Slow down with a choose-your-path adventure',
          ),
          const SizedBox(height: 12),
          for (final story in stories) ...[
            GameCard(game: story, style: GameCardStyle.row, done: done(story)),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 18),
          const SectionHeading('Your progress'),
          const SizedBox(height: 12),
          ModeTile(
            title: 'Skill Quest',
            subtitle: 'See how your four thinking skills are growing',
            icon: Icons.route_rounded,
            color: curioColor(context, CurioColors.forest, CurioColorsLight.forest),
            onTap: () => openPage(context, const SkillQuestPage()),
          ),
        ],
      ),
    );
  }
}

class _SkillFilter extends StatelessWidget {
  const _SkillFilter({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final String? selected;
  final Map<String, int> counts;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final all = counts.values.fold(0, (a, b) => a + b);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _FilterChip(
            label: 'All · $all',
            selected: selected == null,
            color: curioColor(context, CurioColors.forest, CurioColorsLight.forest),
            onTap: () => onSelected(null),
          ),
          for (final MapEntry(key: skill, value: count) in counts.entries) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: '$skill · $count',
              icon: skillIcon(skill),
              selected: selected == skill,
              color: skillColor(context, skill),
              onTap: () => onSelected(skill),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final surface = curioColor(context, CurioColors.surface, CurioColorsLight.surface);
    final outline = curioColor(context, CurioColors.outline, CurioColorsLight.outline);
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final muted = curioColor(context, CurioColors.inkSoft, CurioColorsLight.inkSoft);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: .18) : surface,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: selected ? color : outline, width: selected ? 1.6 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: selected ? ink : color),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? ink : muted,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
