import 'package:flutter/material.dart';

import '../../../core/widgets/curio_ui.dart';
import '../../games/presentation/daily_plan.dart';

class LearnHubPage extends StatelessWidget {
  const LearnHubPage({super.key});

  @override
  Widget build(BuildContext context) => CurioPage(
    extendBehindBottom: true,
    maxWidth: 760,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 104),
      children: const [
        PageIntro(
          eyebrow: 'Your daily playroom',
          title: 'Three little adventures',
          subtitle:
              'One game each in Maths, Memory and English. A new set arrives at midnight on this device. Take your time and enjoy learning.',
        ),
        SizedBox(height: 20),
        DailyPointsCard(),
        SizedBox(height: 28),
        DailyPlan(),
      ],
    ),
  );
}
