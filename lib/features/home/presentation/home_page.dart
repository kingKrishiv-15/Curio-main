import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/evidence/presentation/evidence_detective_page.dart';
import '../../games/link_lab/presentation/link_lab_page.dart';
import '../../games/pattern/presentation/pattern_forge_page.dart';
import '../../games/signal_grid/presentation/signal_grid_page.dart';
import '../../games/squeeze/presentation/squeeze_page.dart';
import '../../parent/presentation/parent_dashboard_page.dart';
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
  static const accentInk = Color(0xFF0C221D);
  static const gold = Color(0xFFE7BE6B);
  static const rose = Color(0xFFE49577);
  static const sky = Color(0xFF8FC3D9);
  static const violet = Color(0xFFBFA6E0);
  static const success = Color(0xFFDCE66A);

  static const cardShadow = [
    BoxShadow(color: Color(0x66020504), blurRadius: 28, offset: Offset(0, 14)),
  ];
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
  static const accentInk = Colors.white;
  static const gold = Color(0xFFDB9A2C);
  static const rose = Color(0xFFDD5D82);
  static const sky = Color(0xFF2E9FD6);
  static const violet = Color(0xFF8467E0);
  static const success = Color(0xFF25A369);

  static const yellowTile = Color(0xFFFFEEBE);
  static const yellowInk = Color(0xFFAD7A0C);

  static const cardShadow = [
    BoxShadow(color: Color(0x1A2E2417), blurRadius: 20, offset: Offset(0, 8)),
  ];
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
    this.lightTint,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? darkTint;
  final Color? lightTint;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);
    if (dark) {
      final tint = darkTint ?? _HomeDark.surface;
      final fill = Color.lerp(tint, Colors.white, .1)!;
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: _HomeDark.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill.withValues(alpha: .58),
              borderRadius: borderRadius,
              border: Border.all(color: Colors.white.withValues(alpha: .2)),
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
                            Colors.white.withValues(alpha: .14),
                            Colors.white.withValues(alpha: 0),
                          ],
                          stops: const [0, .6],
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
      );
    }
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: lightTint ?? _HomeLight.surface,
        borderRadius: borderRadius,
        border: Border.all(color: _HomeLight.line),
        boxShadow: _HomeLight.cardShadow,
      ),
      child: child,
    );
  }
}

/// A gentle looping scale pulse — used on "live" streak flames so they read
/// as active rather than static icons.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child, super.key});
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
  const _FadeSlideIn({required this.child, this.delay = Duration.zero, super.key});
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

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
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

Color _skillColor(BuildContext context, String skill) {
  switch (skill) {
    case 'Number sense':
      return _hc(context, _HomeDark.gold, _HomeLight.gold);
    case 'Patterns':
      return _hc(context, _HomeDark.rose, _HomeLight.rose);
    case 'Evidence':
      return _hc(context, _HomeDark.sky, _HomeLight.sky);
    case 'Reasoning':
      return _hc(context, _HomeDark.violet, _HomeLight.violet);
    default:
      return _hc(context, _HomeDark.accent, _HomeLight.accent);
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
  /// vivid gradient + icon placeholder so the layout works either way.
  final String? imageAsset;
}

/// Illustrated banner area for a game card: a fully-opaque, vivid two-tone
/// gradient (never a low-alpha tint) so it reads as bright, playful banner
/// art rather than a muted wash, plus a white icon on top. Vivid in both
/// modes — this is "content that represents play," not chrome.
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

  static LinearGradient _vividGradient(Color color) {
    final hsl = HSLColor.fromColor(color);
    final start = hsl
        .withLightness((hsl.lightness + .1).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + .08).clamp(0.0, 1.0))
        .toColor();
    final end = hsl
        .withHue((hsl.hue + 26) % 360)
        .withLightness((hsl.lightness - .1).clamp(0.0, 1.0))
        .toColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [start, end],
    );
  }

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
                decoration: BoxDecoration(gradient: _vividGradient(color)),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: -height * .2,
                      bottom: -height * .24,
                      child: Icon(
                        icon,
                        size: height * .95,
                        color: Colors.white.withValues(alpha: .18),
                      ),
                    ),
                    Icon(
                      icon,
                      size: height * .38,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Color(0x40000000), blurRadius: 6),
                      ],
                    ),
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
      backgroundColor: _hc(context, _HomeDark.bgBottom, _HomeLight.bgBottom),
      body: Stack(
        children: [
          const Positioned.fill(child: _HomeBackdrop()),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 940),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: _hc(context, _HomeDark.ink, _HomeLight.ink)),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
                    children: [
                      _Header(
                        name: state.childName,
                        streak: state.streak,
                        onParentTap: () =>
                            openPage(context, const ParentDashboardPage()),
                      ),
                      const SizedBox(height: 26),
                      _FadeSlideIn(
                        child: _Opening(
                          greeting: greeting,
                          name: state.childName,
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
                        child: _TodayPicksShelf(games: games, state: state),
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
                        child: _AdventurePicker(state: state, games: games),
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
    final grain = Paint()..color = grainColor.withValues(alpha: dark ? .022 : .014);
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
        border: Border.all(color: _hc(context, _HomeDark.line, _HomeLight.lineStrong)),
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
    final ink = _hc(context, _HomeDark.ink, _HomeLight.ink);
    final inkMuted = _hc(context, _HomeDark.inkMuted, _HomeLight.inkMuted);
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
                color: ink,
                fontSize: compact ? 40 : 56,
                height: .88,
                letterSpacing: compact ? -2.3 : -3,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'A small challenge can change the way you see a big idea.',
              style: TextStyle(color: inkMuted, fontSize: 13.5, height: 1.45),
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
    final ink = _hc(context, _HomeDark.ink, _HomeLight.ink);
    final inkMuted = _hc(context, _HomeDark.inkMuted, _HomeLight.inkMuted);
    final accent = _hc(context, _HomeDark.accent, _HomeLight.accent);
    return SizedBox(
      width: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$completed / 3',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: ink),
          ),
          const SizedBox(height: 5),
          Text(
            'DAILY GOAL',
            style: TextStyle(
              color: inkMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 9),
          CurioProgressBar(value: completed / 3, color: accent, height: 5),
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
    final sunday = now.subtract(Duration(days: now.weekday % 7));
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
    final surfaceRaised = dark ? _HomeDark.surfaceRaised : _HomeLight.surfaceSunken;
    final surfaceSunken = dark ? _HomeDark.surfaceSunken : _HomeLight.surfaceSunken;
    final flameColor = dark ? _HomeDark.gold : _HomeLight.yellowInk;
    final practicedFill = dark ? _HomeDark.gold : _HomeLight.accent;
    final practicedCheck = dark ? _HomeDark.surfaceSunken : Colors.white;

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
                          ?.copyWith(color: ink, fontSize: 21),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      remaining == 0
                          ? 'Weekly goal reached — amazing focus!'
                          : 'Just $remaining more day${remaining == 1 ? '' : 's'} to hit your goal',
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
                          ? Icon(Icons.check_rounded, color: practicedCheck, size: 16)
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = _skillColor(context, game.skill);
    final ink = dark ? _HomeDark.ink : _HomeLight.ink;
    final inkMuted = dark ? _HomeDark.inkMuted : _HomeLight.inkMuted;
    final questAccent = dark ? _HomeDark.accent : _HomeLight.accent;
    final questInk = dark ? _HomeDark.accentInk : _HomeLight.accentInk;
    final successColor = dark ? _HomeDark.success : _HomeLight.success;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: game.onTap,
        borderRadius: BorderRadius.circular(24),
        child: _GlassPanel(
          radius: 24,
          darkTint: _HomeDark.surface,
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
                    const Positioned(
                      left: 8,
                      top: 8,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 22,
                        shadows: [Shadow(color: Color(0x40000000), blurRadius: 4)],
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
                          color: questAccent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'QUEST',
                          style: TextStyle(
                            color: questInk,
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
                          ?.copyWith(color: ink, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: inkMuted, fontSize: 10.5, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      completed
                          ? 'DONE TODAY'
                          : '${game.skill.toUpperCase()} · ${game.duration}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: completed ? successColor : accent,
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
                    color: _skillColor(context, skill),
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
          color: _skillColor(context, _selected),
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
              color: selected ? (color.computeLuminance() > .5 ? ink : color) : inkMuted,
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
              Icon(Icons.arrow_forward_rounded, color: ink.withValues(alpha: .5)),
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
    final ink = _hc(context, _HomeDark.ink, _HomeLight.ink);
    final inkMuted = _hc(context, _HomeDark.inkMuted, _HomeLight.inkMuted);
    final accent = _skillColor(context, game.skill);
    final successColor = _hc(context, _HomeDark.success, _HomeLight.success);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: game.onTap,
        borderRadius: BorderRadius.circular(24),
        child: _GlassPanel(
          radius: 24,
          darkTint: _HomeDark.surface,
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
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: ink, fontSize: 19),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: inkMuted, fontSize: 11.5, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        completed
                            ? 'COMPLETED TODAY'
                            : '${game.duration} · +${game.xp} XP',
                        style: TextStyle(
                          color: completed ? successColor : accent,
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
                  color: ink.withValues(alpha: .5),
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
    final accent = _hc(context, _HomeDark.accent, _HomeLight.accent);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 24, height: 1, color: accent),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
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
