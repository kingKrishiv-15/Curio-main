import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../core/widgets/curio_gloss.dart';
import '../../discoveries/presentation/discoveries_page.dart';
import '../../home/presentation/home_page.dart';
import '../../learn/presentation/learn_hub_page.dart';
import '../../profile/presentation/profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  double _direction = 1;
  late final AnimationController _tabTransition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  @override
  void dispose() {
    _tabTransition.dispose();
    super.dispose();
  }

  Widget _content() {
    final curve = _tabTransition.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      key: const Key('tab_transition'),
      opacity: Tween<double>(begin: .65, end: 1).animate(curve),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(.018 * _direction, 0),
          end: Offset.zero,
        ).animate(curve),
        child: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < _pages.length; i++)
              TickerMode(enabled: i == _index, child: _pages[i]),
          ],
        ),
      ),
    );
  }

  late final List<Widget> _pages = <Widget>[
    HomePage(onExplore: () => _select(1), onProfile: () => _select(3)),
    const LearnHubPage(),
    const DiscoveriesPage(),
    const ProfilePage(),
  ];

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: _NavGlyph(icon: Icons.home_outlined),
      selectedIcon: _NavGlyph(icon: Icons.home_rounded, selected: true),
      label: 'Home',
    ),
    NavigationDestination(
      icon: _NavGlyph(icon: Icons.grid_view_rounded),
      selectedIcon: _NavGlyph(icon: Icons.extension_rounded, selected: true),
      label: 'Games',
    ),
    NavigationDestination(
      icon: _NavGlyph(icon: Icons.explore_outlined),
      selectedIcon: _NavGlyph(icon: Icons.explore_rounded, selected: true),
      label: 'Discoveries',
    ),
    NavigationDestination(
      icon: _NavGlyph(icon: Icons.person_outline_rounded),
      selectedIcon: _NavGlyph(icon: Icons.person_rounded, selected: true),
      label: 'Profile',
    ),
  ];

  void _select(int value) {
    if (_index == value) return;
    setState(() {
      _direction = value > _index ? 1 : -1;
      _index = value;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _tabTransition.value = 1;
    } else {
      _tabTransition.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Android back on another tab returns Home instead of closing the app.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: _shell(),
    );
  }

  Widget _shell() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        if (desktop) {
          return Scaffold(
            body: Row(
              children: [
                _CurioRail(index: _index, onSelected: _select),
                const VerticalDivider(width: 1),
                Expanded(child: _content()),
              ],
            ),
          );
        }

        // Paint content behind the system gesture area; no opaque navigation
        // bar or contrast scrim should create a seam below the floating dock.
        final light = Theme.of(context).brightness == Brightness.light;
        final overlayStyle = light
            ? const SystemUiOverlayStyle(
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: Brightness.dark,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarContrastEnforced: false,
                systemStatusBarContrastEnforced: false,
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              )
            : const SystemUiOverlayStyle(
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: Brightness.light,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarContrastEnforced: false,
                systemStatusBarContrastEnforced: false,
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              );

        // No `bottomNavigationBar` slot at all: Scaffold gives that slot its
        // own background no matter what widget lives in it, which is what
        // kept reading as a bar behind the pill. Instead the nav is just a
        // `Positioned` overlay inside the same Stack as the page content,
        // so the page's own background is *literally* the layer behind it
        // — nothing else can ever paint there.
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: Scaffold(
            backgroundColor: light
                ? const Color(0xFFFDF1E2)
                : const Color(0xFF05100D),
            body: Stack(
              children: [
                Positioned.fill(child: _content()),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 10),
                    child: Center(
                      child: _FloatingNav(
                        index: _index,
                        light: light,
                        onSelected: _select,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavGlyph extends StatelessWidget {
  const _NavGlyph({required this.icon, this.selected = false});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final forest = dark ? CurioColors.forest : CurioColorsLight.forest;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: selected ? 35 : 31,
      height: selected ? 35 : 31,
      decoration: BoxDecoration(
        gradient: selected
            ? (dark
                  ? CurioColors.brandGradient
                  : CurioColorsLight.brandGradient)
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  dark ? CurioColors.surface : CurioColorsLight.surface,
                  dark ? CurioColors.forestMist : CurioColorsLight.forestMist,
                ],
              ),
        borderRadius: BorderRadius.circular(selected ? 13 : 11),
        border: Border.all(
          color: selected ? forest : forest.withValues(alpha: .11),
        ),
      ),
      child: Icon(
        icon,
        size: selected ? 19 : 17,
        color: selected
            ? (dark ? CurioColors.onDark : CurioColorsLight.onDark)
            : (dark ? CurioColors.forestStrong : CurioColorsLight.forestStrong),
      ),
    );
  }
}

/// A compact glass capsule with one sliding selection lens. Its dimensions
/// stay fixed as destinations change, so the dock never jumps or stretches.
class _FloatingNav extends StatelessWidget {
  const _FloatingNav({
    required this.index,
    required this.onSelected,
    required this.light,
  });
  final int index;
  final ValueChanged<int> onSelected;
  final bool light;
  static const _items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.grid_view_outlined, Icons.extension_rounded, 'Games'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Discover'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = light ? CurioColorsLight.coralStrong : CurioColors.forest;
    final ink = light ? CurioColorsLight.inkSoft : CurioColors.inkSoft;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280);
    final textScale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final itemHeight = 52.0 + (textScale > 1.3 ? (textScale - 1.3) * 12 : 0);
    return ConstrainedBox(
      key: const Key('bottom_capsule'),
      constraints: const BoxConstraints(maxWidth: 304),
      child: CurioGloss(
        radius: 32,
        blur: true,
        padding: const EdgeInsets.all(5),
        child: SizedBox(
          height: itemHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedAlign(
                    key: const Key('capsule_selection'),
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment(-1 + index * 2 / 3, 0),
                    child: FractionallySizedBox(
                      widthFactor: .25,
                      heightFactor: 1,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(
                                accent,
                                Colors.white,
                                light ? .6 : .2,
                              )!.withValues(alpha: light ? .35 : .3),
                              accent.withValues(alpha: light ? .14 : .13),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: light ? .65 : .16,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: .09),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: Semantics(
                        label: _items[i].$3,
                        selected: i == index,
                        button: true,
                        child: Tooltip(
                          message: _items[i].$3,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              key: Key('nav_${_items[i].$3}'),
                              borderRadius: BorderRadius.circular(26),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onSelected(i);
                              },
                              child: SizedBox(
                                height: itemHeight,
                                child: ExcludeSemantics(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedScale(
                                        scale: i == index ? 1.06 : 1,
                                        duration: duration,
                                        curve: Curves.easeOutCubic,
                                        child: AnimatedSwitcher(
                                          duration: duration,
                                          child: Icon(
                                            i == index
                                                ? _items[i].$2
                                                : _items[i].$1,
                                            key: ValueKey('${i == index}'),
                                            size: 21,
                                            color: i == index ? accent : ink,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      AnimatedDefaultTextStyle(
                                        duration: duration,
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 9.5,
                                          fontWeight: i == index
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: i == index ? accent : ink,
                                        ),
                                        child: Text(
                                          _items[i].$3,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurioRail extends StatelessWidget {
  const _CurioRail({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? CurioColors.surface : CurioColorsLight.surface;
    final outlineSoft = dark
        ? CurioColors.outlineSoft
        : CurioColorsLight.outlineSoft;
    final coral = dark ? CurioColors.coral : CurioColorsLight.coral;
    final coralSoft = dark ? CurioColors.coralSoft : CurioColorsLight.coralSoft;
    final inkMuted = dark ? CurioColors.inkMuted : CurioColorsLight.inkMuted;
    final surfaceMuted = dark
        ? CurioColors.surfaceMuted
        : CurioColorsLight.surfaceMuted;
    final orange = dark ? CurioColors.orange : CurioColorsLight.orange;
    return Container(
      width: 244,
      decoration: BoxDecoration(
        color: surface.withValues(alpha: .94),
        border: Border(right: BorderSide(color: outlineSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 25, 16, 20),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 9),
            child: Align(alignment: Alignment.centerLeft, child: CurioBrand()),
          ),
          const SizedBox(height: 30),
          ...List.generate(_MainShellState._destinations.length, (itemIndex) {
            final item = _MainShellState._destinations[itemIndex];
            final selected = itemIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  key: Key('nav_${item.label}'),
                  selected: selected,
                  onTap: () => onSelected(itemIndex),
                  leading: Icon(
                    selected
                        ? (item.selectedIcon as _NavGlyph).icon
                        : (item.icon as _NavGlyph).icon,
                  ),
                  title: Text(item.label),
                  selectedColor: coral,
                  iconColor: inkMuted,
                  textColor: inkMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  selectedTileColor: coralSoft,
                  titleTextStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          CurioCard(
            elevation: false,
            color: surfaceMuted,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: orange,
                      size: 20,
                    ),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text(
                        'Daily momentum',
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CurioProgressBar(
                  value: state.dailyGoalCompleted / state.dailyGoal,
                  height: 7,
                ),
                const SizedBox(height: 7),
                Text(
                  '${state.dailyGoalCompleted} of ${state.dailyGoal} challenges',
                  style: TextStyle(color: inkMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
