import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../discoveries/presentation/discoveries_page.dart';
import '../../home/presentation/home_page.dart';
import '../../learn/presentation/learn_hub_page.dart';
import '../../profile/presentation/profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  late final List<Widget> _pages = <Widget>[
    HomePage(onExplore: () => setState(() => _index = 1)),
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

  void _select(int value) => setState(() => _index = value);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        if (desktop) {
          return Scaffold(
            body: Row(
              children: [
                _CurioRail(index: _index, onSelected: _select),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(index: _index, children: _pages),
                ),
              ],
            ),
          );
        }

        // The old Material `NavigationBar` widget used to set the *OS*
        // system navigation bar colour for us automatically. Our custom
        // floating pill doesn't, so without this the Android system nav
        // bar falls back to a default that reads as a stray green strip
        // behind it. Set it explicitly, matched to whichever tab is up.
        final onDarkHome = _index == 0;
        final overlayStyle = onDarkHome
            ? const SystemUiOverlayStyle(
                systemNavigationBarColor: Color(0xFF05100D),
                systemNavigationBarIconBrightness: Brightness.light,
                systemNavigationBarDividerColor: Colors.transparent,
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              )
            : SystemUiOverlayStyle(
                systemNavigationBarColor: CurioColors.canvas,
                systemNavigationBarIconBrightness: Brightness.dark,
                systemNavigationBarDividerColor: Colors.transparent,
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: Scaffold(
            extendBody: true,
            // Matches the darkest tone of the redesigned Home tab so no
            // lighter theme colour can ever peek through around the
            // floating nav bar, whatever a page underneath is doing.
            backgroundColor: const Color(0xFF05100D),
            body: IndexedStack(index: _index, children: _pages),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: SizedBox(
                height: 64,
                child: Center(
                  child: _FloatingNav(index: _index, onSelected: _select),
                ),
              ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: selected ? 35 : 31,
      height: selected ? 35 : 31,
      decoration: BoxDecoration(
        gradient: selected
            ? CurioColors.brandGradient
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CurioColors.surface, CurioColors.forestMist],
              ),
        borderRadius: BorderRadius.circular(selected ? 13 : 11),
        border: Border.all(
          color: selected
              ? CurioColors.forest
              : CurioColors.forest.withValues(alpha: .11),
        ),
      ),
      child: Icon(
        icon,
        size: selected ? 19 : 17,
        color: selected ? CurioColors.onDark : CurioColors.forestStrong,
      ),
    );
  }
}

/// Floating pill nav: frosted glass, fully rounded, with the active item
/// expanding into an icon + label pill (mirrors the reference bottom bar).
class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  static const _items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.grid_view_rounded, Icons.extension_rounded, 'Games'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Discover'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  static const _borderRadius = BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: _borderRadius,
        boxShadow: [
          BoxShadow(
            color: Color(0x66020504),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF13312A).withValues(alpha: .72),
              borderRadius: _borderRadius,
              border: Border.all(color: Colors.white.withValues(alpha: .12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _items.length; i++)
                  _FloatingNavItem(
                    icon: _items[i].$1,
                    selectedIcon: _items[i].$2,
                    label: _items[i].$3,
                    selected: i == index,
                    onTap: () => onSelected(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  const _FloatingNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _accent = Color(0xFFDCE66A);
  static const _accentInk = Color(0xFF0C221D);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _accent.withValues(alpha: .45),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: 22,
                color: selected
                    ? _accentInk
                    : Colors.white.withValues(alpha: .68),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: _accentInk,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      )
                    : const SizedBox(height: 22),
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
    return Container(
      width: 244,
      decoration: BoxDecoration(
        color: CurioColors.surface.withValues(alpha: .94),
        border: const Border(right: BorderSide(color: CurioColors.outlineSoft)),
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
                  selected: selected,
                  onTap: () => onSelected(itemIndex),
                  leading: Icon(
                    selected
                        ? (item.selectedIcon as _NavGlyph).icon
                        : (item.icon as _NavGlyph).icon,
                  ),
                  title: Text(item.label),
                  selectedColor: CurioColors.coral,
                  iconColor: CurioColors.inkMuted,
                  textColor: CurioColors.inkMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  selectedTileColor: CurioColors.coralSoft,
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
            color: CurioColors.surfaceMuted,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: CurioColors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 7),
                    Expanded(
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
                  value: state.dailyGoalCompleted / 3,
                  height: 7,
                ),
                const SizedBox(height: 7),
                Text(
                  '${state.dailyGoalCompleted} of 3 challenges',
                  style: const TextStyle(
                    color: CurioColors.inkMuted,
                    fontSize: 10,
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
