import 'package:flutter/material.dart';

import '../../../core/theme/curio_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        backgroundColor: Colors.white,
        indicatorColor: CurioColors.tealSoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            selectedIcon: Icon(Icons.home_rounded, color: CurioColors.tealDark),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(
              Icons.grid_view_rounded,
              color: CurioColors.tealDark,
            ),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_rounded),
            selectedIcon: Icon(
              Icons.auto_stories_rounded,
              color: CurioColors.tealDark,
            ),
            label: 'Discoveries',
          ),
          NavigationDestination(
            icon: Icon(Icons.face_rounded),
            selectedIcon: Icon(Icons.face_rounded, color: CurioColors.tealDark),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
