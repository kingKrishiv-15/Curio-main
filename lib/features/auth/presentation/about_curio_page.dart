import 'package:flutter/material.dart';

import '../../../core/widgets/curio_ui.dart';
import '../../games/common/daily_schedule.dart';
import '../../games/game_catalog.dart';
import 'auth_layout.dart';

/// What Curio is, for a parent deciding whether to sign up.
class AboutCurioPage extends StatelessWidget {
  const AboutCurioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AuthFrame(
      maxContentWidth: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Games that make thinking visible.',
              style: text.displayLarge,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Curio is a daily set of $dailyGameCount short puzzles in '
            '$sectionNames, for ages 10 to 18. There are no ads, no chat and '
            'no purchases inside the games.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 32),
          for (final section in LearningSection.values) ...[
            Text(section.title, style: text.titleLarge),
            const SizedBox(height: 4),
            CurioRow(
              title: [
                for (final g in gameCatalog)
                  if (g.isDaily && g.section == section) g.title,
              ].join(', '),
              subtitle: section.description,
              tint: sectionColor(context, section),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),
          Text('For grown-ups', style: text.titleLarge),
          const SizedBox(height: 4),
          const CurioRow(
            title: 'One family account',
            subtitle:
                'A parent signs up and adds a learner. Children never enter an email address.',
          ),
          const CurioRow(
            title: 'A parent view behind a gate',
            subtitle:
                'Days played, games finished and skills, plus an optional weekly email.',
          ),
          const CurioRow(
            title: 'Your data stays yours',
            subtitle:
                'Export or delete the account at any time from Profile, Privacy and account.',
          ),
        ],
      ),
    );
  }
}
