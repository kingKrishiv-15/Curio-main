import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/link_lab/presentation/link_lab_page.dart';
import '../../games/signal_grid/presentation/signal_grid_page.dart';
import '../../games/squeeze/presentation/squeeze_page.dart';
import '../../parent/presentation/parent_dashboard_page.dart';
import '../../skills/presentation/skill_quest_page.dart';

abstract final class _HomeColors {
  static const background = Color(0xFFE7EFEA);
  static const surface = Color(0xFFEEF5F0);
  static const ink = Color(0xFF17201D);
  static const muted = Color(0xFF65706B);
  static const line = Color(0xFFD7DDD8);
  static const evergreen = Color(0xFF183E35);
  static const evergreenBright = Color(0xFF2D6A5B);
  static const lime = Color(0xFFDCE66A);
  static const periwinkle = Color(0xFFD8E6DF);
  static const cobalt = Color(0xFF315F52);
  static const peach = Color(0xFFCFE0D7);
  static const terracotta = Color(0xFF2D6A5B);
}

class HomePage extends StatelessWidget {
  const HomePage({required this.onExplore, super.key});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return CurioPage(
      maxWidth: 940,
      backgroundColor: _HomeColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: [
          _Header(
            date: _dateLabel(now),
            onParentTap: () => openPage(context, const ParentDashboardPage()),
          ),
          const SizedBox(height: 30),
          _Opening(
            greeting: greeting,
            name: state.childName,
            completed: state.dailyGoalCompleted,
          ),
          const SizedBox(height: 24),
          _Momentum(state: state),
          const SizedBox(height: 22),
          _DailyFeature(
            completed: state.completedToday('squeeze'),
            onTap: () => openPage(context, const SqueezePage()),
          ),
          const SizedBox(height: 28),
          _SectionTitle(
            title: 'Today’s brain breaks',
            subtitle: 'Small puzzles, designed for a satisfying finish.',
            action: 'See all',
            onAction: onExplore,
          ),
          const SizedBox(height: 14),
          _QuickPlayShelf(
            linkCompleted: state.completedToday('link_lab'),
            signalCompleted: state.completedToday('signal_grid'),
            onLink: () => openPage(context, const LinkLabPage()),
            onSignal: () => openPage(context, const SignalGridPage()),
          ),
          const SizedBox(height: 30),
          const _SectionTitle(
            title: 'Continue your path',
            subtitle: 'One focused step, chosen from your recent play.',
          ),
          const SizedBox(height: 14),
          _NextStep(
            progress: state.skills['Number sense'] ?? 0,
            onTap: () => openPage(context, const SkillQuestPage()),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime value) {
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${weekdays[value.weekday - 1]} · ${months[value.month - 1]} ${value.day}';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.date, required this.onParentTap});

  final String date;
  final VoidCallback onParentTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CurioBrand(compact: true),
        const Spacer(),
        Text(
          date,
          style: const TextStyle(
            color: _HomeColors.muted,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Family dashboard',
          onPressed: onParentTap,
          style: IconButton.styleFrom(
            minimumSize: const Size(42, 42),
            backgroundColor: _HomeColors.surface,
            foregroundColor: _HomeColors.ink,
            side: const BorderSide(color: _HomeColors.line),
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.family_restroom_outlined, size: 19),
        ),
      ],
    );
  }
}

class _Opening extends StatelessWidget {
  const _Opening({
    required this.greeting,
    required this.name,
    required this.completed,
  });

  final String greeting;
  final String name;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Eyebrow('$greeting · $name!'),
            const SizedBox(height: 13),
            Text(
              'What will you\nsolve today?',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: _HomeColors.ink,
                fontSize: compact ? 42 : 58,
                height: .88,
                letterSpacing: compact ? -2.5 : -3.2,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'A small challenge can change the way you see a big idea.',
              style: TextStyle(
                color: _HomeColors.muted,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ],
        );
        if (compact) return copy;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: copy),
            _GoalMark(completed: completed),
          ],
        );
      },
    );
  }
}

class _GoalMark extends StatelessWidget {
  const _GoalMark({required this.completed});
  final int completed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$completed / 3',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          const Text(
            'DAILY GOAL',
            style: TextStyle(
              color: _HomeColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 9),
          CurioProgressBar(
            value: completed / 3,
            color: _HomeColors.terracotta,
            height: 5,
          ),
        ],
      ),
    );
  }
}

class _Momentum extends StatelessWidget {
  const _Momentum({required this.state});
  final CurioState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _HomeColors.line),
          bottom: BorderSide(color: _HomeColors.line),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Today’s rhythm',
              style: TextStyle(
                color: _HomeColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _Metric(value: '${state.streak}', label: 'day streak'),
          const SizedBox(width: 22),
          _Metric(value: '${state.totalXp}', label: 'XP'),
          const SizedBox(width: 22),
          _Metric(value: '${state.collectedFacts.length}', label: 'finds'),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _HomeColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: _HomeColors.muted, fontSize: 8.5),
        ),
      ],
    );
  }
}

class _DailyFeature extends StatelessWidget {
  const _DailyFeature({required this.completed, required this.onTap});

  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play Daily Squeeze',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            height: 236,
            decoration: BoxDecoration(
              color: _HomeColors.evergreen,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24172D27),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: _QuestPainter()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(19),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              completed ? 'COMPLETED' : "TODAY'S QUEST",
                              style: const TextStyle(
                                color: _HomeColors.lime,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.25,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '+80 XP',
                              style: TextStyle(
                                color: CurioColors.onDark.withValues(
                                  alpha: .62,
                                ),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'Squeeze',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: CurioColors.onDark,
                                fontSize: 38,
                                height: .9,
                              ),
                        ),
                        const SizedBox(height: 7),
                        SizedBox(
                          width: 235,
                          child: Text(
                            'Find the secret number before the range closes in.',
                            style: TextStyle(
                              color: CurioColors.onDark.withValues(alpha: .7),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: _HomeColors.lime,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    completed ? 'PLAY AGAIN' : 'START PUZZLE',
                                    style: const TextStyle(
                                      color: _HomeColors.ink,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: .7,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: _HomeColors.ink,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '2–4 MIN',
                              style: TextStyle(
                                color: CurioColors.onDark.withValues(
                                  alpha: .55,
                                ),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestPainter extends CustomPainter {
  const _QuestPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final soft = Paint()..color = CurioColors.onDark.withValues(alpha: .065);
    final line = Paint()
      ..color = CurioColors.onDark.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width - 42, 50), 94, soft);
    canvas.drawCircle(Offset(size.width - 42, 50), 69, line);
    final textPainter = TextPainter(
      text: TextSpan(
        text: '37',
        style: TextStyle(
          fontFamily: 'Fraunces',
          color: CurioColors.onDark.withValues(alpha: .17),
          fontSize: 84,
          fontWeight: FontWeight.w500,
          letterSpacing: -6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(size.width - 154, 24));
    canvas.drawRect(Rect.fromLTWH(size.width - 62, 174, 62, 48), soft);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _HomeColors.ink,
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _HomeColors.muted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!.toUpperCase())),
      ],
    );
  }
}

class _QuickPlayShelf extends StatelessWidget {
  const _QuickPlayShelf({
    required this.linkCompleted,
    required this.signalCompleted,
    required this.onLink,
    required this.onSignal,
  });
  final bool linkCompleted;
  final bool signalCompleted;
  final VoidCallback onLink;
  final VoidCallback onSignal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        final cardWidth = wide ? (constraints.maxWidth - 12) / 2 : 250.0;
        final row = Row(
          children: [
            SizedBox(
              width: cardWidth,
              child: _QuickGame(
                title: 'Link Lab',
                description: 'Find four hidden connections.',
                label: 'REASONING · 3–5 MIN',
                icon: Icons.hub_outlined,
                background: _HomeColors.peach,
                foreground: _HomeColors.terracotta,
                completed: linkCompleted,
                onTap: onLink,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: cardWidth,
              child: _QuickGame(
                title: 'Signal Grid',
                description: 'Balance the grid without guessing.',
                label: 'LOGIC · 4–6 MIN',
                icon: Icons.grid_view_rounded,
                background: _HomeColors.periwinkle,
                foreground: _HomeColors.cobalt,
                completed: signalCompleted,
                onTap: onSignal,
              ),
            ),
          ],
        );
        if (wide) return row;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: row,
        );
      },
    );
  }
}

class _QuickGame extends StatelessWidget {
  const _QuickGame({
    required this.title,
    required this.description,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.completed,
    required this.onTap,
  });
  final String title;
  final String description;
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 154,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      completed ? Icons.check_circle_rounded : icon,
                      color: foreground,
                      size: 24,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_outward_rounded,
                      color: foreground,
                      size: 18,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _HomeColors.ink,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomeColors.muted,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  completed ? 'COMPLETED TODAY' : label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
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

class _NextStep extends StatelessWidget {
  const _NextStep({required this.progress, required this.onTap});
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _HomeColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: _HomeColors.line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: _HomeColors.evergreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calculate_outlined,
                  color: CurioColors.onDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Number sense',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CurioProgressBar(
                      value: progress,
                      color: _HomeColors.evergreenBright,
                      height: 6,
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'LEVEL 3 · NEXT: ESTIMATION',
                      style: TextStyle(
                        color: _HomeColors.muted,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded, color: _HomeColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 24, height: 1, color: _HomeColors.evergreen),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _HomeColors.evergreen,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
