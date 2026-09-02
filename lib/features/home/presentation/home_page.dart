import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/evidence/presentation/evidence_detective_page.dart';
import '../../games/link_lab/presentation/link_lab_page.dart';
import '../../games/pattern/presentation/pattern_forge_page.dart';
import '../../games/signal_grid/presentation/signal_grid_page.dart';
import '../../games/squeeze/presentation/squeeze_page.dart';
import '../../parent/presentation/parent_dashboard_page.dart';
import '../../skills/presentation/skill_quest_page.dart';

/// Deep, textured evergreen backdrop — a gradient wash rather than a single
/// flat green. Cards are a neutral warm slate, deliberately *not* green, so
/// they separate from the backdrop by hue as well as brightness instead of
/// reading as "another shade of the same colour".
abstract final class _HomeColors {
  static const bgTop = Color(0xFF0E211B);
  static const bgMid = Color(0xFF091712);
  static const bgBottom = Color(0xFF05100D);

  static const surface = Color(0xFF2B3032);
  static const surfaceHigh = Color(0xFF343A3D);
  static const surfaceRaised = Color(0xFF3C4346);
  static const surfaceSunken = Color(0xFF15191A);

  static const line = Color(0x26FFFFFF);
  static const lineStrong = Color(0x3DFFFFFF);
  static const inkMuted = Color(0xFFC4CDC9);
  static const inkFaint = Color(0xFF8D948F);
  static const lime = Color(0xFFDCE66A);
  static const gold = Color(0xFFE7BE6B);
  static const coral = Color(0xFFE49577);
  static const sky = Color(0xFF8FC3D9);
  static const violet = Color(0xFFBFA6E0);

  static const cardShadow = [
    BoxShadow(color: Color(0x66020504), blurRadius: 28, offset: Offset(0, 14)),
  ];
}

/// A frosted-glass card: blurs whatever is behind it, tints with a neutral
/// slate colour (not green, so it reads as its own material against the
/// green backdrop), and adds a faint top sheen plus a lift shadow.
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 22,
    this.tint = _HomeColors.surface,
    this.opacity = .68,
    this.blur = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color tint;
  final double opacity;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: _HomeColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tint.withValues(alpha: opacity),
              borderRadius: borderRadius,
              border: Border.all(color: _HomeColors.lineStrong),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: borderRadius,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: .08),
                            Colors.white.withValues(alpha: 0),
                          ],
                          stops: const [0, .5],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _skillColor(String skill) {
  switch (skill) {
    case 'Number sense':
      return _HomeColors.gold;
    case 'Patterns':
      return _HomeColors.coral;
    case 'Evidence':
      return _HomeColors.sky;
    case 'Reasoning':
      return _HomeColors.violet;
    default:
      return _HomeColors.lime;
  }
}

class _GameInfo {
  const _GameInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.skill,
    required this.duration,
    required this.xp,
    required this.onTap,
    this.featured = false,
    this.imageAsset,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String skill;
  final String duration;
  final int xp;
  final VoidCallback onTap;
  final bool featured;

  /// Path to an illustrated banner (e.g. `assets/games/squeeze.png`).
  /// Left null until real artwork is dropped in — falls back to a
  /// gradient + icon placeholder so the layout works either way.
  final String? imageAsset;
}

/// Illustrated banner area for a game card. Renders [imageAsset] when one
/// is supplied; otherwise a gradient-and-icon placeholder that already
/// reads as an image slot, ready to swap in real artwork later.
class _CardArt extends StatelessWidget {
  const _CardArt({
    required this.icon,
    required this.color,
    this.imageAsset,
    this.height = 96,
    this.radius = 18,
  });

  final IconData icon;
  final Color color;
  final String? imageAsset;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: imageAsset != null
            ? Image.asset(imageAsset!, fit: BoxFit.cover)
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: .38),
                      color.withValues(alpha: .14),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: -height * .18,
                      bottom: -height * .22,
                      child: Icon(
                        icon,
                        size: height * .95,
                        color: color.withValues(alpha: .18),
                      ),
                    ),
                    Icon(icon, size: height * .38, color: color),
                  ],
                ),
              ),
      ),
    );
  }
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

    final games = <_GameInfo>[
      _GameInfo(
        id: 'squeeze',
        title: 'Squeeze',
        subtitle: 'Find the secret number before the range closes in.',
        icon: Icons.calculate_rounded,
        skill: 'Number sense',
        duration: '2–4 MIN',
        xp: 80,
        featured: true,
        onTap: () => openPage(context, const SqueezePage()),
      ),
      _GameInfo(
        id: 'link_lab',
        title: 'Link Lab',
        subtitle: 'Find four hidden connections.',
        icon: Icons.hub_outlined,
        skill: 'Reasoning',
        duration: '3–5 MIN',
        xp: 90,
        onTap: () => openPage(context, const LinkLabPage()),
      ),
      _GameInfo(
        id: 'signal_grid',
        title: 'Signal Grid',
        subtitle: 'Balance the grid without guessing.',
        icon: Icons.grid_view_rounded,
        skill: 'Reasoning',
        duration: '4–6 MIN',
        xp: 100,
        onTap: () => openPage(context, const SignalGridPage()),
      ),
      _GameInfo(
        id: 'pattern_forge',
        title: 'Pattern Forge',
        subtitle: 'Crack the rule behind the sequence.',
        icon: Icons.blur_on_rounded,
        skill: 'Patterns',
        duration: '3–5 MIN',
        xp: 60,
        onTap: () => openPage(context, const PatternForgePage()),
      ),
      _GameInfo(
        id: 'evidence_garden',
        title: 'Evidence Garden',
        subtitle: 'Rank the clues before you jump to conclusions.',
        icon: Icons.manage_search_rounded,
        skill: 'Evidence',
        duration: '4–6 MIN',
        xp: 70,
        onTap: () => openPage(context, const EvidenceDetectivePage()),
      ),
    ];

    return Scaffold(
      backgroundColor: _HomeColors.bgBottom,
      body: Stack(
        children: [
          const Positioned.fill(child: _HomeBackdrop()),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 940),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: CurioColors.onDark),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
                    children: [
                      _Header(
                        name: state.childName,
                        streak: state.streak,
                        onParentTap: () =>
                            openPage(context, const ParentDashboardPage()),
                      ),
                      const SizedBox(height: 28),
                      _Opening(
                        greeting: greeting,
                        name: state.childName,
                        completed: state.dailyGoalCompleted,
                      ),
                      const SizedBox(height: 22),
                      _Momentum(state: state),
                      const SizedBox(height: 24),
                      _WeekPracticeCard(state: state),
                      const SizedBox(height: 28),
                      _SectionTitle(
                        title: 'Today’s picks',
                        subtitle:
                            '${_dateLabel(now)} · Small puzzles, designed for a satisfying finish.',
                        action: 'See all',
                        onAction: onExplore,
                      ),
                      const SizedBox(height: 14),
                      _TodayPicksShelf(games: games, state: state),
                      const SizedBox(height: 30),
                      const _SectionTitle(
                        title: 'Pick your next adventure',
                        subtitle:
                            'Choose a skill, then dive into a focused challenge.',
                      ),
                      const SizedBox(height: 14),
                      _AdventurePicker(state: state, games: games),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime value) {
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

/// Soft gradient + faint blobs + a hint of grain — texture instead of a flat
/// wash of green.
class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_HomeColors.bgTop, _HomeColors.bgMid, _HomeColors.bgBottom],
          stops: [0, .55, 1],
        ),
      ),
      child: const CustomPaint(painter: _HomeTexturePainter(), child: SizedBox.expand()),
    );
  }
}

class _HomeTexturePainter extends CustomPainter {
  const _HomeTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final warm = Paint()..color = _HomeColors.gold.withValues(alpha: .05);
    final cool = Paint()..color = _HomeColors.sky.withValues(alpha: .045);
    canvas.drawCircle(
      Offset(size.width * .86, size.height * .05),
      size.width * .5,
      warm,
    );
    canvas.drawCircle(
      Offset(size.width * .04, size.height * .82),
      size.width * .46,
      cool,
    );

    final grain = Paint()..color = Colors.white.withValues(alpha: .022);
    for (var y = 20.0; y < size.height; y += 30) {
      for (var x = 10.0; x < size.width; x += 30) {
        if ((x + y).round().isEven) continue;
        canvas.drawCircle(Offset(x, y), .9, grain);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: CurioColors.brandGradient,
        shape: BoxShape.circle,
        border: Border.all(color: _HomeColors.line, width: 1.4),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontFamily: 'Fraunces',
          color: CurioColors.onDark,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _HomeColors.surfaceRaised,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _HomeColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: _HomeColors.gold,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            '$streak',
            style: const TextStyle(
              color: CurioColors.onDark,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.streak,
    required this.onParentTap,
  });

  final String name;
  final int streak;
  final VoidCallback onParentTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(name: name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HELLO THERE',
                style: TextStyle(
                  color: _HomeColors.inkMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Fraunces',
                  color: CurioColors.onDark,
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _StreakChip(streak: streak),
        const SizedBox(width: 10),
        IconButton(
          tooltip: 'Family dashboard',
          onPressed: onParentTap,
          style: IconButton.styleFrom(
            minimumSize: const Size(42, 42),
            backgroundColor: _HomeColors.surfaceRaised,
            foregroundColor: CurioColors.onDark,
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
                color: CurioColors.onDark,
                fontSize: compact ? 40 : 56,
                height: .88,
                letterSpacing: compact ? -2.3 : -3,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'A small challenge can change the way you see a big idea.',
              style: TextStyle(
                color: _HomeColors.inkMuted,
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
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: CurioColors.onDark),
          ),
          const SizedBox(height: 5),
          const Text(
            'DAILY GOAL',
            style: TextStyle(
              color: _HomeColors.inkMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 9),
          CurioProgressBar(
            value: completed / 3,
            color: _HomeColors.lime,
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
                color: CurioColors.onDark,
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
            color: CurioColors.onDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: _HomeColors.inkMuted, fontSize: 8.5),
        ),
      ],
    );
  }
}

class _WeekPracticeCard extends StatelessWidget {
  const _WeekPracticeCard({required this.state});
  final CurioState state;

  static const _goal = 5;
  static const _labels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}$month$day';
  }

  List<bool> _practicedDays() {
    final now = DateTime.now();
    final sunday = now.subtract(Duration(days: now.weekday % 7));
    return List.generate(7, (i) {
      final day = DateTime(sunday.year, sunday.month, sunday.day + i);
      final suffix = _dateKey(day);
      return state.completedActivities.any((id) => id.endsWith('_$suffix'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _practicedDays();
    final count = days.where((d) => d).length;
    final remaining = (_goal - count).clamp(0, _goal);
    final todayIndex = DateTime.now().weekday % 7;

    return _GlassPanel(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practiced $count day${count == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: CurioColors.onDark, fontSize: 21),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      remaining == 0
                          ? 'Weekly goal reached — amazing focus!'
                          : 'Just $remaining more day${remaining == 1 ? '' : 's'} to hit your goal',
                      style: const TextStyle(
                        color: _HomeColors.inkMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _HomeColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _HomeColors.lineStrong),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: CurioColors.onDark,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: List.generate(7, (i) {
              final practiced = days[i];
              final isToday = i == todayIndex;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: practiced
                            ? _HomeColors.gold
                            : (isToday
                                  ? _HomeColors.surfaceRaised
                                  : _HomeColors.surfaceSunken),
                        border: Border.all(
                          color: practiced
                              ? Colors.transparent
                              : _HomeColors.lineStrong,
                          width: 1.3,
                        ),
                      ),
                      child: Icon(
                        practiced
                            ? Icons.check_rounded
                            : (isToday
                                  ? Icons.local_fire_department_rounded
                                  : null),
                        color: practiced
                            ? _HomeColors.surfaceSunken
                            : _HomeColors.gold,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _labels[i],
                      style: TextStyle(
                        color: isToday
                            ? CurioColors.onDark
                            : _HomeColors.inkFaint,
                        fontSize: 9.5,
                        fontWeight: isToday
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
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
                  color: CurioColors.onDark,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _HomeColors.inkMuted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: _HomeColors.lime),
            child: Text(action!.toUpperCase()),
          ),
      ],
    );
  }
}

class _TodayPicksShelf extends StatelessWidget {
  const _TodayPicksShelf({required this.games, required this.state});
  final List<_GameInfo> games;
  final CurioState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 216,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: games.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final game = games[index];
          return SizedBox(
            width: 156,
            child: _PickCard(
              game: game,
              completed: state.completedToday(game.id),
            ),
          );
        },
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  const _PickCard({required this.game, required this.completed});
  final _GameInfo game;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final accent = _skillColor(game.skill);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: game.onTap,
        borderRadius: BorderRadius.circular(24),
        child: _GlassPanel(
          radius: 24,
          tint: _HomeColors.surfaceHigh,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _CardArt(
                    icon: game.icon,
                    color: accent,
                    imageAsset: game.imageAsset,
                    height: 84,
                    radius: 16,
                  ),
                  if (completed)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: _HomeColors.lime,
                        size: 22,
                      ),
                    ),
                  if (game.featured)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _HomeColors.lime,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'QUEST',
                          style: TextStyle(
                            color: _HomeColors.surfaceSunken,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: CurioColors.onDark, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomeColors.inkMuted,
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      completed
                          ? 'DONE TODAY'
                          : '${game.skill.toUpperCase()} · ${game.duration}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: completed ? _HomeColors.lime : accent,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdventurePicker extends StatefulWidget {
  const _AdventurePicker({required this.state, required this.games});
  final CurioState state;
  final List<_GameInfo> games;

  @override
  State<_AdventurePicker> createState() => _AdventurePickerState();
}

class _AdventurePickerState extends State<_AdventurePicker> {
  late String _selected = widget.state.skills.keys.first;

  @override
  Widget build(BuildContext context) {
    final skills = widget.state.skills.keys.toList();
    final matches = widget.games
        .where((game) => game.skill == _selected)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final skill in skills)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _SkillTab(
                    label: skill,
                    selected: skill == _selected,
                    color: _skillColor(skill),
                    onTap: () => setState(() => _selected = skill),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SkillProgressCard(
          skill: _selected,
          progress: widget.state.skills[_selected] ?? 0,
          color: _skillColor(_selected),
        ),
        for (final game in matches) ...[
          const SizedBox(height: 12),
          _AdventureCard(
            game: game,
            completed: widget.state.completedToday(game.id),
          ),
        ],
      ],
    );
  }
}

class _SkillTab extends StatelessWidget {
  const _SkillTab({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: .22) : _HomeColors.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? color : _HomeColors.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? CurioColors.onDark : _HomeColors.inkMuted,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillProgressCard extends StatelessWidget {
  const _SkillProgressCard({
    required this.skill,
    required this.progress,
    required this.color,
  });
  final String skill;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => openPage(context, const SkillQuestPage()),
        borderRadius: BorderRadius.circular(22),
        child: _GlassPanel(
          radius: 22,
          tint: _HomeColors.surfaceRaised,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.trending_up_rounded, color: color, size: 22),
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
                            '$skill path',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: CurioColors.onDark),
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CurioProgressBar(value: progress, color: color, height: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: CurioColors.onDark.withValues(alpha: .7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdventureCard extends StatelessWidget {
  const _AdventureCard({required this.game, required this.completed});
  final _GameInfo game;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final accent = _skillColor(game.skill);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: game.onTap,
        borderRadius: BorderRadius.circular(24),
        child: _GlassPanel(
          radius: 24,
          tint: _HomeColors.surfaceHigh,
          child: Row(
            children: [
              Container(
                width: 92,
                height: 100,
                margin: const EdgeInsets.all(10),
                child: _CardArt(
                  icon: game.icon,
                  color: accent,
                  imageAsset: game.imageAsset,
                  height: 100,
                  radius: 16,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(color: CurioColors.onDark, fontSize: 19),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _HomeColors.inkMuted,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        completed
                            ? 'COMPLETED TODAY'
                            : '${game.duration} · +${game.xp} XP',
                        style: TextStyle(
                          color: completed ? _HomeColors.lime : accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: CurioColors.onDark.withValues(alpha: .7),
                ),
              ),
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
        Container(width: 24, height: 1, color: _HomeColors.lime),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _HomeColors.lime,
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
