import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/curio_tokens.dart';
import '../../discoveries/presentation/discoveries_page.dart';
import '../../home/presentation/home_page.dart';
import '../../profile/presentation/profile_page.dart';

/// The three places in Curio: Home, Discover, Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon, selectedIcon;
}

const _tabs = [
  _Tab('Home', Icons.home_outlined, Icons.home_rounded),
  _Tab('Discover', Icons.explore_outlined, Icons.explore_rounded),
  _Tab('Profile', Icons.person_outline_rounded, Icons.person_rounded),
];

class _MainShellState extends State<MainShell> {
  int _index = 0;

  late final List<Widget> _pages = <Widget>[
    HomePage(onProfile: () => _select(2)),
    const DiscoveriesPage(),
    const ProfilePage(),
  ];

  void _select(int value) {
    if (_index == value) return;
    HapticFeedback.selectionClick();
    setState(() => _index = value);
  }

  @override
  Widget build(BuildContext context) {
    final content = IndexedStack(
      key: const Key('tab_transition'),
      index: _index,
      children: [
        for (var i = 0; i < _pages.length; i++)
          TickerMode(enabled: i == _index, child: _pages[i]),
      ],
    );
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
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
                          index: _index,
                          onSelected: _select,
                          vertical: true,
                        ),
                        Expanded(child: content),
                      ],
                    )
                  : content,
              bottomNavigationBar: wide
                  ? null
                  : _Bar(index: _index, onSelected: _select),
            ),
          );
        },
      ),
    );
  }
}

/// Flat navigation: a rule, three labelled icons, no capsule and no shadow.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.index,
    required this.onSelected,
    this.vertical = false,
  });

  final int index;
  final ValueChanged<int> onSelected;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (var i = 0; i < _tabs.length; i++)
        _BarItem(
          key: Key('nav_${_tabs[i].label}'),
          tab: _tabs[i],
          selected: i == index,
          onTap: () => onSelected(i),
        ),
    ];
    const rule = BorderSide(color: CurioTokens.border);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CurioTokens.base,
        border: vertical ? const Border(right: rule) : const Border(top: rule),
      ),
      child: SafeArea(
        top: vertical,
        right: !vertical,
        child: vertical
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  width: 96,
                  child: Column(
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: item,
                        ),
                    ],
                  ),
                ),
              )
            : Row(children: [for (final item in items) Expanded(child: item)]),
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
    final color = selected ? CurioTokens.accent : CurioTokens.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? tab.selectedIcon : tab.icon, color: color),
              const SizedBox(height: 4),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CurioTokens.label.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
