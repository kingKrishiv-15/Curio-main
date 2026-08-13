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
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.extension_outlined),
      selectedIcon: Icon(Icons.extension_rounded),
      label: 'Games',
    ),
    NavigationDestination(
      icon: Icon(Icons.auto_stories_outlined),
      selectedIcon: Icon(Icons.auto_stories_rounded),
      label: 'Discoveries',
    ),
    NavigationDestination(
      icon: Icon(Icons.face_outlined),
      selectedIcon: Icon(Icons.face_rounded),
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
            child: GlassSurface(
              radius: 24,
              blur: 22,
              opacity: .7,
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

class _CurioRail extends StatelessWidget {
  const _CurioRail({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    return Container(
      width: 224,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        border: const Border(right: BorderSide(color: CurioColors.creamDeep)),
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
                        ? (item.selectedIcon as Icon).icon
                        : (item.icon as Icon).icon,
                  ),
                  title: Text(item.label),
                  selectedColor: CurioColors.coralDark,
                  iconColor: CurioColors.navyMuted,
                  textColor: CurioColors.navyMuted,
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
                LinearProgressIndicator(
                  value: state.dailyGoalCompleted / 3,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(99),
                  color: CurioColors.coral,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 7),
                Text(
                  '${state.dailyGoalCompleted} of 3 challenges',
                  style: const TextStyle(
                    color: CurioColors.navyMuted,
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
