import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_motion.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../core/widgets/parental_gate.dart';
import '../../games/common/game_rewards.dart';
import '../../games/game_catalog.dart';
import '../../games/presentation/game_card.dart';
import '../../../core/widgets/curio_gloss.dart';
import '../../parent/presentation/parent_dashboard_page.dart';
import '../../family/presentation/family_inbox_page.dart';
import '../../skills/presentation/skill_quest_page.dart';

/// Home's dark mode: a deep, textured evergreen backdrop with neutral-slate
/// cards (deliberately not another shade of green) and a lime "this is
/// live right now" accent.
abstract final class _HomeDark {
  static const bgTop = Color(0xFF0E211B);
  static const bgBottom = Color(0xFF05100D);

  static const surface = Color(0xFF2B3032);
  static const surfaceRaised = Color(0xFF3C4346);
  static const surfaceSunken = Color(0xFF15191A);

  static const line = Color(0x26FFFFFF);
  static const lineStrong = Color(0x3DFFFFFF);
  static const ink = Color(0xFFF4FAF6);
  static const inkMuted = Color(0xFFC4CDC9);
  static const inkFaint = Color(0xFF8D948F);

  static const accent = Color(0xFFDCE66A);
  static const gold = Color(0xFFE7BE6B);
  static const sky = Color(0xFF8FC3D9);
}

/// Home's light mode: a bright, warm cream backdrop with white cards and a
/// saturated coral "this is live right now" accent — kid-friendly and
/// vibrant rather than moody.
abstract final class _HomeLight {
  static const bgTop = Color(0xFFFFF8EE);
  static const bgBottom = Color(0xFFFDF1E2);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFF3E9D8);

  static const line = Color(0xFFF0E4D0);
  static const lineStrong = Color(0xFFE7D7BC);
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

/// A card surface: translucent dark glass in dark mode, a plain white card
/// with a soft shadow in light mode. See design.md §5 for why dark mode
/// avoids a real `BackdropFilter` blur here.
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 22,
    this.darkTint,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? darkTint;
  @override
  Widget build(BuildContext context) => CurioGloss(
    padding: padding,
    radius: radius,
    tint: Theme.of(context).brightness == Brightness.dark ? darkTint : null,
    child: child,
  );
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

class HomePage extends StatelessWidget {
  const HomePage({required this.onExplore, super.key});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final now = DateTime.now();

    // One catalog for every screen; Home shows a rotating handful as today's
    // picks (the first is the featured quest) and every game by skill below.
    final featured = featuredGame();
    final picks = todaysPicks();

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
                      96 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    children: [
                      _Header(
                        name: state.childName,
                        streak: state.streak,
                        onParentTap: () => ParentalGate.open(
                          context,
                          const ParentDashboardPage(),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _FadeSlideIn(
                        child: _Opening(
                          onExplore: onExplore,
                          completed: state.dailyGoalCompleted,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: _WeekPracticeCard(state: state),
                      ),
                      const SizedBox(height: 28),
                      _FadeSlideIn(
                        delay: const Duration(milliseconds: 180),
                        child: _SectionTitle(
                          title: 'Today’s picks',
                          subtitle:
                              '${_dateLabel(now)} · Small puzzles, designed for a satisfying finish.',
                          action: 'See all',
                          onAction: onExplore,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: _TodayPicksShelf(
                          games: picks,
                          featuredId: featured.id,
                          state: state,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _FadeSlideIn(
                        delay: const Duration(milliseconds: 260),
                        child: const _SectionTitle(
                          title: 'Pick your next adventure',
                          subtitle:
                              'Choose a skill, then dive into a focused challenge.',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        child: _AdventurePicker(state: state),
                      ),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final trimmed = name.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF1F6B50), Color(0xFF49BB8C)]
              : const [_HomeLight.accent, Color(0xFFD8362B)],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: _hc(context, _HomeDark.line, _HomeLight.line),
          width: 1.4,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontFamily: 'Fraunces',
          color: Colors.white,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = dark ? _HomeDark.surfaceRaised : _HomeLight.yellowTile;
    final flameColor = dark ? _HomeDark.gold : _HomeLight.yellowInk;
    final textColor = dark ? _HomeDark.ink : _HomeLight.yellowInk;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: _hc(context, _HomeDark.line, _HomeLight.lineStrong),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Pulse(
            child: Icon(
              Icons.local_fire_department_rounded,
              color: flameColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$streak',
            style: TextStyle(
              color: textColor,
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
    final ink = _hc(context, _HomeDark.ink, _HomeLight.ink);
    final inkMuted = _hc(context, _HomeDark.inkMuted, _HomeLight.inkMuted);
    final surface = _hc(context, _HomeDark.surfaceRaised, _HomeLight.surface);
    final line = _hc(context, _HomeDark.line, _HomeLight.line);
    return Row(
      children: [
        _Avatar(name: name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HELLO THERE',
                style: TextStyle(
                  color: inkMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  color: ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => openPage(context, const FamilyInboxPage()),
          icon: const Icon(Icons.notifications_outlined),
        ),
        _StreakChip(streak: streak),
        const SizedBox(width: 10),
        IconButton(
          tooltip: 'Family dashboard',
          onPressed: onParentTap,
          style: IconButton.styleFrom(
            minimumSize: const Size(42, 42),
            backgroundColor: surface,
            foregroundColor: ink,
            side: BorderSide(color: line),
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.family_restroom_outlined, size: 19),
        ),
      ],
    );
  }
}

class _Opening extends StatelessWidget {
  const _Opening({required this.completed, required this.onExplore});
  final int completed;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final goal = CurioScope.of(context).dailyGoal;
    final accent = _hc(context, _HomeDark.accent, _HomeLight.accent);
    return CurioGloss(
      key: const Key('daily_goal_banner'),
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const MascotBadge(size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A little discovery today?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 22, height: 1.15),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completed of $goal daily activities complete',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                CurioProgressBar(
                  value: completed / goal,
                  color: accent,
                  height: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Choose an activity',
            onPressed: onExplore,
            style: IconButton.styleFrom(
              backgroundColor: accent.withValues(alpha: .14),
              foregroundColor: accent,
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          ),
        ],
      ),
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
    // Calendar days, not 24-hour durations, so DST changes can't skip a day.
    final sunday = DateTime(now.year, now.month, now.day - now.weekday % 7);
    return List.generate(7, (i) {
      final day = DateTime(sunday.year, sunday.month, sunday.day + i);
      final suffix = _dateKey(day);
      return state.completedActivities.any((id) => id.endsWith('_$suffix'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? _HomeDark.ink : _HomeLight.ink;
    final inkMuted = dark ? _HomeDark.inkMuted : _HomeLight.inkMuted;
    final inkFaint = dark ? _HomeDark.inkFaint : _HomeLight.inkFaint;
    final lineStrong = dark ? _HomeDark.lineStrong : _HomeLight.lineStrong;
    final surfaceRaised = dark
        ? _HomeDark.surfaceRaised
        : _HomeLight.surfaceSunken;
    final surfaceSunken = dark
        ? _HomeDark.surfaceSunken
        : _HomeLight.surfaceSunken;
    final flameColor = dark ? _HomeDark.gold : _HomeLight.yellowInk;
    final practicedFill = dark ? _HomeDark.gold : _HomeLight.accent;
    final practicedCheck = dark ? _HomeDark.surfaceSunken : Colors.white;

    final days = _practicedDays();
    final count = days.where((d) => d).length;
    final remaining = (_goal - count).clamp(0, _goal);
    final todayIndex = DateTime.now().weekday % 7;
    // Days still playable this week (today counts if not yet practised), so
    // we never ask for five more days on a Friday.
    final available = [
      for (var i = todayIndex; i < 7; i++) !days[i],
    ].where((open) => open).length;
    final message = remaining == 0
        ? 'Weekly goal reached — amazing focus!'
        : remaining <= available
        ? 'Just $remaining more day${remaining == 1 ? '' : 's'} to hit your goal'
        : available == 0
        ? 'Great week. A fresh one starts on Sunday.'
        : '$available day${available == 1 ? '' : 's'} left this week — every one counts.';

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
                          ?.copyWith(color: ink, fontSize: 21),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(color: inkMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: surfaceSunken,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lineStrong),
                ),
                child: Icon(Icons.calendar_today_rounded, color: ink, size: 16),
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
                            ? practicedFill
                            : (isToday ? surfaceRaised : surfaceSunken),
                        border: Border.all(
                          color: practiced ? Colors.transparent : lineStrong,
                          width: 1.3,
                        ),
                      ),
                      child: practiced
                          ? Icon(
                              Icons.check_rounded,
                              color: practicedCheck,
                              size: 16,
                            )
                          : isToday
                          ? _Pulse(
                              child: Icon(
                                Icons.local_fire_department_rounded,
                                color: flameColor,
                                size: 16,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _labels[i],
                      style: TextStyle(
                        color: isToday ? ink : inkFaint,
                        fontSize: 9.5,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
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
    final ink = _hc(context, _HomeDark.ink, _HomeLight.ink);
    final inkMuted = _hc(context, _HomeDark.inkMuted, _HomeLight.inkMuted);
    final accent = _hc(context, _HomeDark.accent, _HomeLight.accent);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: ink, fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: inkMuted, fontSize: 11.5)),
            ],
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: accent),
            child: Text(action!.toUpperCase()),
          ),
      ],
    );
  }
}

bool _isDone(CurioState state, GameEntry game) => game.isDaily
    ? state.completedToday(game.id)
    : state.completedActivities.contains(game.id);

class _TodayPicksShelf extends StatelessWidget {
  const _TodayPicksShelf({
    required this.games,
    required this.featuredId,
    required this.state,
  });
  final List<GameEntry> games;
  final String featuredId;
  final CurioState state;

  @override
  Widget build(BuildContext context) {
    // A scrolling Row (not a fixed-height ListView) so cards grow with the
    // reader's text size; IntrinsicHeight keeps them the same height.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < games.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              SizedBox(
                width: 196,
                child: GameCard(
                  game: games[i],
                  featured: games[i].id == featuredId,
                  done: _isDone(state, games[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdventurePicker extends StatefulWidget {
  const _AdventurePicker({required this.state});
  final CurioState state;

  @override
  State<_AdventurePicker> createState() => _AdventurePickerState();
}

class _AdventurePickerState extends State<_AdventurePicker> {
  String _selected = learningSkills.first;

  @override
  Widget build(BuildContext context) {
    final skills = learningSkills;
    final matches = gameCatalog
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
                    color: skillColor(context, skill),
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
          color: skillColor(context, _selected),
        ),
        for (final game in matches) ...[
          const SizedBox(height: 12),
          GameCard(
            game: game,
            style: GameCardStyle.row,
            done: _isDone(widget.state, game),
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
    final surface = _hc(context, _HomeDark.surface, _HomeLight.surface);
    final line = _hc(context, _HomeDark.line, _HomeLight.line);
    final inkMuted = _hc(context, _HomeDark.inkMuted, _HomeLight.inkMuted);
    final ink = _hc(context, _HomeDark.ink, _HomeLight.ink);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: .16) : surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? color : line),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? (color.computeLuminance() > .5 ? ink : color)
                  : inkMuted,
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
    final ink = _hc(context, _HomeDark.ink, _HomeLight.ink);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => openPage(context, const SkillQuestPage()),
        borderRadius: BorderRadius.circular(22),
        child: _GlassPanel(
          radius: 22,
          darkTint: _HomeDark.surfaceRaised,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .16),
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
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(color: ink),
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
                color: ink.withValues(alpha: .5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
