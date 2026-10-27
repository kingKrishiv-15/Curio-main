import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_motion.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../family/presentation/family_inbox_page.dart';
import '../../games/common/game_rewards.dart';
import '../../games/presentation/daily_plan.dart';

/// Home's dark mode: a deep, textured evergreen backdrop with slate clay
/// cards (deliberately not another shade of green) and gold flames.
abstract final class _HomeDark {
  static const bgTop = Color(0xFF0E211B);
  static const bgBottom = Color(0xFF05100D);

  static const surfaceRaised = Color(0xFF3C4346);

  static const line = Color(0x26FFFFFF);
  static const ink = Color(0xFFF4FAF6);
  static const inkMuted = Color(0xFFC4CDC9);
  static const inkFaint = Color(0xFF8D948F);

  static const gold = Color(0xFFE7BE6B);
  static const sky = Color(0xFF8FC3D9);
}

/// Home's light mode: a bright, warm cream backdrop with warm-white clay
/// cards and a saturated coral "this is live right now" accent — kid-friendly and
/// vibrant rather than moody.
abstract final class _HomeLight {
  static const bgTop = Color(0xFFFFF8EE);
  static const bgBottom = Color(0xFFFDF1E2);

  static const line = Color(0xFFF0E4D0);
  static const ink = Color(0xFF2E2417);
  static const inkMuted = Color(0xFF8C7C63);
  static const inkFaint = Color(0xFFB8AB92);

  static const accent = Color(0xFFF2564A);
  static const gold = Color(0xFFDB9A2C);
  static const sky = Color(0xFF2E9FD6);

  static const yellowTile = Color(0xFFFFEEBE);
  static const yellowInk = Color(0xFFAD7A0C);
}

/// Picks between [_HomeDark] and [_HomeLight] for the current theme
/// brightness — every colour decision in this file goes through this so
/// the whole page adapts to the global light/dark toggle automatically.
Color _hc(BuildContext context, Color darkColor, Color lightColor) {
  return Theme.of(context).brightness == Brightness.dark
      ? darkColor
      : lightColor;
}

/// A gentle looping scale pulse — used on "live" streak flames so they read
/// as active rather than static icons.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  // Created up front and only looped while motion is allowed: a lazily
  // created controller would first be touched in dispose() when reduce
  // motion is on, which isn't allowed once the element is deactivated.
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncLoop(_controller, context, reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return ScaleTransition(
      scale: Tween(
        begin: 0.92,
        end: 1.1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

/// Fades and slides a section in once, staggered by [delay].
class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  Timer? _start;

  @override
  void initState() {
    super.initState();
    _start = Timer(widget.delay, _controller.forward);
  }

  @override
  void dispose() {
    _start?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * 18),
            child: child,
          ),
        );
      },
    );
  }
}

/// Home, in five sections that each do one job, top to bottom: who you are,
/// this week at a glance, how the week is going, today's games, and every
/// skill to explore.
class HomePage extends StatelessWidget {
  const HomePage({required this.onExplore, this.onProfile, super.key});

  /// Switches to the Games tab.
  final VoidCallback onExplore;

  /// Switches to the Profile tab (the avatar).
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);

    return Scaffold(
      backgroundColor: _hc(context, _HomeDark.bgBottom, _HomeLight.bgBottom),
      body: Stack(
        children: [
          const Positioned.fill(child: _HomeBackdrop()),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 940),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: _hc(context, _HomeDark.ink, _HomeLight.ink),
                  ),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      104 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    children: [
                      _Header(
                        name: state.childName,
                        goalDone: state.dailyGoalCompleted >= state.dailyGoal,
                        onProfile: onProfile,
                      ),
                      const SizedBox(height: 22),
                      _FadeSlideIn(child: _WeekCard(state: state)),
                      const SizedBox(height: _sectionGap),
                      const _FadeSlideIn(
                        delay: Duration(milliseconds: 80),
                        child: _SectionHeader(title: 'Weekly growth'),
                      ),
                      const SizedBox(height: 12),
                      _FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: _WeeklyGrowth(state: state),
                      ),
                      const SizedBox(height: _sectionGap),
                      const DailyPointsCard(),
                      const SizedBox(height: _sectionGap),
                      _SectionHeader(
                        title: 'Today’s four adventures',
                        action: 'Games',
                        onAction: onExplore,
                      ),
                      const SizedBox(height: 12),
                      const DailyPlan(),
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
}

/// Space between Home's sections — one value, so the rhythm is even.
const _sectionGap = 30.0;

String _dateKey(DateTime date) =>
    '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

/// Monday to Sunday of the current week, as calendar days (not 24-hour
/// steps, so a clock change can't skip one).
List<DateTime> _thisWeek() {
  final now = DateTime.now();
  final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  return [
    for (var i = 0; i < 7; i++)
      DateTime(monday.year, monday.month, monday.day + i),
  ];
}

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// The page backdrop: a textured evergreen gradient in dark mode, a clean
/// warm cream wash in light mode — both with just a hint of grain/glow,
/// never a flat single-colour fill.
class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [_HomeDark.bgTop, _HomeDark.bgBottom]
              : const [_HomeLight.bgTop, _HomeLight.bgBottom],
        ),
      ),
      child: CustomPaint(
        painter: _HomeTexturePainter(dark: dark),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _HomeTexturePainter extends CustomPainter {
  const _HomeTexturePainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final goldColor = dark ? _HomeDark.gold : _HomeLight.gold;
    final skyColor = dark ? _HomeDark.sky : _HomeLight.sky;
    final warm = Paint()..color = goldColor.withValues(alpha: dark ? .05 : .07);
    final cool = Paint()..color = skyColor.withValues(alpha: dark ? .045 : .06);
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

    final grainColor = dark ? Colors.white : const Color(0xFF2E2417);
    final grain = Paint()
      ..color = grainColor.withValues(alpha: dark ? .022 : .014);
    for (var y = 20.0; y < size.height; y += 30) {
      for (var x = 10.0; x < size.width; x += 30) {
        if ((x + y).round().isEven) continue;
        canvas.drawCircle(Offset(x, y), .9, grain);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HomeTexturePainter oldDelegate) =>
      oldDelegate.dark != dark;
}

/// "Hello, Krishiv!", a one-line nudge, and on the right only what a child
/// reaches for: family messages and their own profile.
class _Header extends StatelessWidget {
  const _Header({required this.name, required this.goalDone, this.onProfile});

  final String name;
  final bool goalDone;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final ink = _hc(context, _HomeDark.ink, _HomeLight.ink);
    final inkMuted = _hc(context, _HomeDark.inkMuted, _HomeLight.inkMuted);
    final bell = IconButton(
      tooltip: 'Family messages',
      onPressed: () => openPage(context, const FamilyInboxPage()),
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: ink,
      ),
      icon: const Icon(Icons.notifications_none_rounded, size: 21),
    );
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $name!',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: ink,
                  fontSize: 28,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                goalDone
                    ? 'Goal complete! Come back for new games tomorrow.'
                    : 'What will you discover today?',
                style: TextStyle(color: inkMuted, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CurioClay(radius: 22, child: bell),
        const SizedBox(width: 10),
        ExplorerAvatar(name: name, onTap: onProfile),
      ],
    );
  }
}

/// Section title with an optional "See all" on the right.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ink = _hc(context, _HomeDark.ink, _HomeLight.ink);
    final link = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forestStrong,
    );
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: ink, fontSize: 22),
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: link),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action!,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final count = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$streak',
          style: TextStyle(
            color: dark ? _HomeDark.ink : _HomeLight.yellowInk,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        _Pulse(
          child: Icon(
            Icons.local_fire_department_rounded,
            color: dark ? _HomeDark.gold : _HomeLight.accent,
            size: 17,
          ),
        ),
      ],
    );
    return Semantics(
      label: '$streak day streak',
      excludeSemantics: true,
      child: CurioClay(
        radius: 99,
        color: dark ? _HomeDark.surfaceRaised : _HomeLight.yellowTile,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: count,
      ),
    );
  }
}

/// Today's date and streak, a flame for every day played this week, and
/// today's goal underneath.
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.state});
  final CurioState state;

  static const _labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? _HomeDark.ink : _HomeLight.ink;
    final inkMuted = dark ? _HomeDark.inkMuted : _HomeLight.inkMuted;
    final inkFaint = dark ? _HomeDark.inkFaint : _HomeLight.inkFaint;
    final line = dark ? _HomeDark.line : _HomeLight.line;
    final accent = dark ? _HomeDark.gold : _HomeLight.accent;
    final flameFill = dark
        ? _HomeDark.gold.withValues(alpha: .2)
        : _HomeLight.yellowTile;
    final success = curioColor(
      context,
      CurioColors.success,
      CurioColorsLight.forest,
    );

    final now = state.today;
    final week = _thisWeek();
    final played = [
      for (final day in week)
        state.completedActivities.any((id) => id.endsWith('_${_dateKey(day)}')),
    ];
    final todayIndex = now.weekday - 1;
    final goal = state.dailyGoal;
    final doneToday = state.dailyGoalCompleted;
    final goalMet = doneToday >= goal;

    return CurioClay(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StreakChip(streak: state.streak),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Semantics(
                    label:
                        '${_weekdays[i]}${i == todayIndex ? ', today' : ''}: '
                        '${played[i] ? 'played' : 'not played'}',
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        _DayBubble(
                          played: played[i],
                          today: i == todayIndex,
                          fill: flameFill,
                          accent: accent,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _labels[i],
                          style: TextStyle(
                            color: i == todayIndex ? ink : inkFaint,
                            fontSize: 12,
                            fontWeight: i == todayIndex
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: line),
          const SizedBox(height: 14),
          Column(
            key: const Key('daily_goal_banner'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    goalMet ? Icons.emoji_events_rounded : Icons.flag_rounded,
                    color: goalMet ? success : accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      goalMet ? 'Today’s goal reached!' : 'Today’s goal',
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$doneToday of $goal games',
                style: TextStyle(
                  color: inkMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 9),
              CurioProgressBar(
                value: goal == 0 ? 1 : doneToday / goal,
                color: goalMet ? success : accent,
                height: 8,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One day of the week: played days puff up with a flame, the rest are
/// dents pressed into the card, and today is ringed (with a pulsing outline
/// flame while it's still to play).
class _DayBubble extends StatelessWidget {
  const _DayBubble({
    required this.played,
    required this.today,
    required this.fill,
    required this.accent,
  });

  final bool played, today;
  final Color fill, accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 36,
      child: CurioClay(
        radius: 18,
        pressed: !played,
        color: played ? fill : null,
        outline: today ? accent : null,
        child: Center(
          child: played
              ? Icon(
                  Icons.local_fire_department_rounded,
                  color: accent,
                  size: 19,
                )
              : today
              ? _Pulse(
                  child: Icon(
                    Icons.local_fire_department_outlined,
                    color: accent.withValues(alpha: .7),
                    size: 17,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Three pastel tiles: games played, XP earned and skills practised, all
/// counted for this week only.
class _WeeklyGrowth extends StatelessWidget {
  const _WeeklyGrowth({required this.state});
  final CurioState state;

  @override
  Widget build(BuildContext context) {
    final keys = {for (final day in _thisWeek()) _dateKey(day)};
    final thisWeek = [
      for (final id in state.completedActivities)
        if (keys.any((key) => id.endsWith('_$key'))) activityGame(id),
    ];
    final xp = thisWeek.fold(
      0,
      (sum, game) => sum + (gameRewards[game]?.xp ?? 0),
    );
    final skills = {
      for (final game in thisWeek)
        if (gameRewards[game] case final reward?) reward.skill,
    };

    return CurioStatRow(
      tiles: [
        CurioStatTile(
          value: '${thisWeek.length}',
          label: 'Games played',
          tone: StatTone.gold,
          semanticLabel: '${thisWeek.length} games played this week',
        ),
        CurioStatTile(
          value: '$xp',
          label: 'XP earned',
          tone: StatTone.plum,
          semanticLabel: '$xp XP earned this week',
        ),
        CurioStatTile(
          value: '${skills.length}/${learningSkills.length}',
          label: 'Skills practised',
          tone: StatTone.forest,
          semanticLabel:
              '${skills.length} of ${learningSkills.length} skills practised this week',
        ),
      ],
    );
  }
}
