import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/curio_clay.dart';
import '../../../theme/curio_tokens.dart';
import '../../discoveries/presentation/discoveries_page.dart';
import '../../games/presentation/today_games.dart';
import '../../home/presentation/home_page.dart';
import '../../profile/presentation/profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

enum _Tab {
  home('Home', Icons.home_outlined, Icons.home_rounded),
  games('Games', Icons.sports_esports_outlined, Icons.sports_esports_rounded),
  discover('Discover', Icons.explore_outlined, Icons.explore_rounded),
  profile('Profile', Icons.person_outline_rounded, Icons.person_rounded);

  const _Tab(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon, selectedIcon;
}

class _MainShellState extends State<MainShell> {
  _Tab _selected = _Tab.home;

  late final _pages = <_Tab, Widget>{
    _Tab.home: HomePage(onProfile: () => _select(_Tab.profile)),
    _Tab.games: const TodayGamesPage(),
    _Tab.discover: DiscoveriesPage(onHome: () => _select(_Tab.home)),
    _Tab.profile: const ProfilePage(),
  };

  void _select(_Tab tab) {
    if (_selected == tab) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = tab);
  }

  @override
  Widget build(BuildContext context) {
    final content = IndexedStack(
      key: const Key('tab_transition'),
      index: _selected.index,
      children: [
        for (final tab in _Tab.values)
          TickerMode(enabled: tab == _selected, child: _pages[tab]!),
      ],
    );
    return PopScope(
      canPop: _selected == _Tab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(_Tab.home);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              systemNavigationBarColor: CurioTokens.base,
              systemNavigationBarIconBrightness: Brightness.dark,
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
            child: Scaffold(
              backgroundColor: CurioTokens.base,
              body: wide
                  ? Row(
                      children: [
                        _Bar(
                          selected: _selected,
                          onSelected: _select,
                          vertical: true,
                        ),
                        Expanded(child: content),
                      ],
                    )
                  : content,
              bottomNavigationBar: wide
                  ? null
                  : _Bar(selected: _selected, onSelected: _select),
            ),
          );
        },
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.selected,
    required this.onSelected,
    this.vertical = false,
  });

  final _Tab selected;
  final ValueChanged<_Tab> onSelected;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final tab in _Tab.values)
        _BarItem(
          key: Key('nav_${tab.label}'),
          tab: tab,
          selected: tab == selected,
          onTap: () => onSelected(tab),
        ),
    ];
    if (vertical) {
      return SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 0, 16),
          child: SizedBox(
            width: 96,
            child: CurioClay(
              padding: const EdgeInsets.all(4),
              child: Column(mainAxisSize: MainAxisSize.min, children: items),
            ),
          ),
        ),
      );
    }
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: CurioClay(
            radius: CurioTokens.radiusPill,
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [for (final item in items) Expanded(child: item)],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.tab,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? CurioTokens.textPrimary
        : CurioTokens.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: CurioTokens.pillShape,
        child: AnimatedContainer(
          duration: CurioTokens.motion(context),
          curve: CurioTokens.curve,
          decoration: BoxDecoration(
            color: selected ? CurioTokens.wash(CurioTokens.accent, .20) : null,
            borderRadius: CurioTokens.pillShape,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  selected ? tab.selectedIcon : tab.icon,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                textAlign: TextAlign.center,
                style: CurioTokens.label.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
