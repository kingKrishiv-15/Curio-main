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
      maxWidth: 880,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 104),
        children: [
          const PageIntro(
            eyebrow: 'The playroom',
            title: 'Ways to learn',
            subtitle:
                'Short, thoughtful games built to stretch logic, language, number sense, and good judgement.',
          ),
          const SizedBox(height: 20),
          const SectionHeading(
            'Daily brain breaks',
            subtitle: 'Fresh challenges that reward careful thinking',
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
          const SizedBox(height: 10),
          ModeTile(
            title: 'Signal Grid',
            subtitle: 'Balance a binary grid using deduction, never guessing',
            icon: Icons.grid_4x4_rounded,
            color: CurioColors.blue,
            badge: 'NEW',
            duration: '4–6 min',
            skill: 'Logic',
            onTap: () => openPage(context, const SignalGridPage()),
          ),
          const SizedBox(height: 22),
          _FeaturedQuest(onTap: () => openPage(context, const SqueezePage())),
          const SizedBox(height: 24),
          const SectionHeading(
            'Longer adventures',
            subtitle: 'Build mastery through guided, story-rich play',
          ),
          const SizedBox(height: 12),
          ModeTile(
            title: 'Pattern Forge',
            subtitle: 'Predict, explain, and repair number patterns',
            icon: Icons.blur_on_rounded,
            color: CurioColors.forest,
            duration: '5 min',
            skill: 'Patterns',
            onTap: () => openPage(context, const PatternForgePage()),
          ),
          const SizedBox(height: 10),
          ModeTile(
            title: 'Evidence Detective',
            subtitle: 'Separate reliable clues from tempting distractions',
            icon: Icons.manage_search_rounded,
            color: CurioColors.plum,
            duration: '6 min',
            skill: 'Evidence',
            onTap: () => openPage(context, const EvidenceDetectivePage()),
          ),
          const SizedBox(height: 10),
          ModeTile(
            title: 'Frostlands Story',
            subtitle: 'Your choices decide how Ash crosses the ice',
            icon: Icons.ac_unit_rounded,
            color: CurioColors.blue,
            duration: '8 min',
            skill: 'Decisions',
            onTap: () => openPage(context, const FrostlandsStoryPage()),
          ),
          const SizedBox(height: 10),
          ModeTile(
            title: 'Skill Quest',
            subtitle: 'See how your four thinking domains are growing',
            icon: Icons.route_rounded,
            color: CurioColors.saffronStrong,
            duration: 'Progress map',
            skill: 'All skills',
            onTap: () => openPage(context, const SkillQuestPage()),
          ),
        ],
      ),
    );
  }
}

class _FeaturedQuest extends StatelessWidget {
  const _FeaturedQuest({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play today’s featured game, Squeeze',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CurioRadius.hero),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: CurioColors.heroGradient,
              borderRadius: BorderRadius.circular(CurioRadius.hero),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CurioEyebrow(
                        'Featured quest',
                        color: CurioColors.saffron,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Squeeze the\nsecret number',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: CurioColors.onDark),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        'Seven guesses. One shrinking range. How quickly can you find it?',
                        style: TextStyle(
                          color: CurioColors.onDark.withValues(alpha: .72),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 13),
                      const Row(
                        children: [
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: CurioColors.saffron,
                            size: 22,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'PLAY NOW',
                            style: TextStyle(
                              color: CurioColors.onDark,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 104,
                  height: 102,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CurioColors.onDark.withValues(alpha: .08),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(54),
                    ),
                    border: Border.all(
                      color: CurioColors.onDark.withValues(alpha: .1),
                    ),
                  ),
                  child: const Text(
                    '?',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      color: CurioColors.saffron,
                      fontSize: 72,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
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
