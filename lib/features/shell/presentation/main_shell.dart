import 'package:flutter/material.dart';

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

        return Scaffold(
          extendBody: true,
          body: IndexedStack(index: _index, children: _pages),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: _BottomDock(
              child: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _select,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: _destinations,
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

class _BottomDock extends StatelessWidget {
  const _BottomDock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24102C26),
            blurRadius: 26,
            offset: Offset(0, 11),
          ),
          BoxShadow(
            color: Color(0x0F102C26),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0F6F2), Color(0xFFDDEBE3)],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xE6FFFFFF), width: 1.2),
          ),
          child: child,
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
