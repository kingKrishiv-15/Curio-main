import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/evidence/presentation/evidence_detective_page.dart';
import '../../games/pattern/presentation/pattern_forge_page.dart';
import '../../games/squeeze/presentation/squeeze_page.dart';
import '../../skills/presentation/skill_quest_page.dart';
import '../../story/presentation/frostlands_story_page.dart';

class LearnHubPage extends StatelessWidget {
  const LearnHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CurioPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
        children: [
          const Text(
            'CHOOSE YOUR PATH',
            style: TextStyle(
              color: CurioColors.coral,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.7,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Ways to learn',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Short challenges with no school vibes required.',
            style: TextStyle(color: CurioColors.navyMuted),
          ),
          const SizedBox(height: 24),
          const SectionHeading('Maths lab'),
          const SizedBox(height: 11),
          ModeTile(
            title: 'Squeeze',
            subtitle: 'Hunt today\'s secret number in seven guesses',
            icon: Icons.compress_rounded,
            color: CurioColors.coral,
            badge: 'DAILY',
            onTap: () => openPage(context, const SqueezePage()),
          ),
          const SizedBox(height: 11),
          ModeTile(
            title: 'Pattern Forge',
            subtitle: 'Predict, explain and repair number patterns',
            icon: Icons.blur_on_rounded,
            color: CurioColors.teal,
            onTap: () => openPage(context, const PatternForgePage()),
          ),
          const SizedBox(height: 11),
          ModeTile(
            title: 'Skill Quest',
            subtitle: 'See your path through four thinking domains',
            icon: Icons.route_rounded,
            color: CurioColors.gold,
            onTap: () => openPage(context, const SkillQuestPage()),
          ),
          const SizedBox(height: 26),
          const SectionHeading('Curio special'),
          const SizedBox(height: 11),
          ModeTile(
            title: 'Evidence Detective',
            subtitle: 'Separate strong clues from tempting distractions',
            icon: Icons.manage_search_rounded,
            color: CurioColors.tealDark,
            badge: 'NEW',
            onTap: () => openPage(context, const EvidenceDetectivePage()),
          ),
          const SizedBox(height: 11),
          ModeTile(
            title: 'Frostlands Story',
            subtitle: 'Your choices decide how Ash crosses the ice',
            icon: Icons.ac_unit_rounded,
            color: CurioColors.frost,
            onTap: () => openPage(context, const FrostlandsStoryPage()),
          ),
          const SizedBox(height: 26),
          CurioCard(
            color: CurioColors.goldSoft,
            borderColor: CurioColors.gold,
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFFC78312),
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'More modes are mapped for later: Error Detective, Curio Court, Maths Marketplace and Logic Grid Mysteries.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
