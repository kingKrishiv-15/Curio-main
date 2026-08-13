import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/evidence/presentation/evidence_detective_page.dart';
import '../../games/link_lab/presentation/link_lab_page.dart';
import '../../games/pattern/presentation/pattern_forge_page.dart';
import '../../games/signal_grid/presentation/signal_grid_page.dart';
import '../../games/squeeze/presentation/squeeze_page.dart';
import '../../skills/presentation/skill_quest_page.dart';
import '../../story/presentation/frostlands_story_page.dart';

class LearnHubPage extends StatelessWidget {
  const LearnHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CurioPage(
      maxWidth: 820,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 112),
        children: [
          const PageIntro(
            eyebrow: 'Curio games',
            title: 'Ways to learn',
            subtitle: 'Pick a quick challenge for the skill you want to grow.',
          ),
          const SizedBox(height: 22),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: 'For you', selected: true),
                _FilterChip(label: 'Daily'),
                _FilterChip(label: 'Logic'),
                _FilterChip(label: 'Numbers'),
                _FilterChip(label: 'Stories'),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const SectionHeading(
            'Daily collection',
            subtitle: 'Fresh puzzles designed for a focused brain break',
          ),
          const SizedBox(height: 12),
          ModeTile(
            title: 'Link Lab',
            subtitle: 'Sort sixteen clues into four precise knowledge groups',
            icon: Icons.hub_rounded,
            color: CurioColors.coral,
            badge: 'NEW',
            duration: '3–5 min',
            skill: 'Reasoning',
            onTap: () => openPage(context, const LinkLabPage()),
          ),
          const SizedBox(height: 11),
          ModeTile(
            title: 'Signal Grid',
            subtitle: 'Balance a binary grid using deduction, not guessing',
            icon: Icons.grid_4x4_rounded,
            color: CurioColors.teal,
            badge: 'NEW',
            duration: '4–6 min',
            skill: 'Logic',
            onTap: () => openPage(context, const SignalGridPage()),
          ),
          const SizedBox(height: 11),
          ModeTile(
            title: 'Squeeze',
            subtitle: 'Hunt today’s secret number in seven smart guesses',
            icon: Icons.compress_rounded,
            color: CurioColors.orange,
            badge: 'DAILY',
            duration: '2–4 min',
            skill: 'Numbers',
            onTap: () => openPage(context, const SqueezePage()),
          ),
          const SizedBox(height: 26),
          const SectionHeading(
            'Learning adventures',
            subtitle: 'Build mastery through guided play',
          ),
          const SizedBox(height: 12),
          ModeTile(
            title: 'Pattern Forge',
            subtitle: 'Predict, explain and repair number patterns',
            icon: Icons.blur_on_rounded,
            color: CurioColors.tealDark,
            duration: '5 min',
            skill: 'Patterns',
            onTap: () => openPage(context, const PatternForgePage()),
          ),
          const SizedBox(height: 11),
          ModeTile(
            title: 'Evidence Detective',
            subtitle: 'Separate reliable clues from tempting distractions',
            icon: Icons.manage_search_rounded,
            color: CurioColors.frost,
            duration: '6 min',
            skill: 'Evidence',
            onTap: () => openPage(context, const EvidenceDetectivePage()),
          ),
          const SizedBox(height: 11),
          ModeTile(
            title: 'Frostlands Story',
            subtitle: 'Your choices decide how Ash crosses the ice',
            icon: Icons.ac_unit_rounded,
            color: CurioColors.frostDark,
            duration: '8 min',
            skill: 'Decisions',
            onTap: () => openPage(context, const FrostlandsStoryPage()),
          ),
          const SizedBox(height: 11),
          ModeTile(
            title: 'Skill Quest',
            subtitle: 'See progress across your four thinking domains',
            icon: Icons.route_rounded,
            color: CurioColors.gold,
            duration: 'Progress map',
            skill: 'All skills',
            onTap: () => openPage(context, const SkillQuestPage()),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        avatar: selected ? const Icon(Icons.check_rounded, size: 17) : null,
        backgroundColor: selected ? CurioColors.coralSoft : Colors.white,
        side: BorderSide(
          color: selected
              ? CurioColors.coral.withValues(alpha: .25)
              : CurioColors.creamDeep,
        ),
        labelStyle: TextStyle(
          color: selected ? CurioColors.coralDark : CurioColors.navyMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
