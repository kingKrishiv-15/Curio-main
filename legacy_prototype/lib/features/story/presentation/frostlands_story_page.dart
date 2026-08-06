import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';

class _Scene {
  const _Scene(this.title, this.body, this.choices);
  final String title;
  final String body;
  final List<String> choices;
}

const _scenes = <_Scene>[
  _Scene(
    'The frozen signal',
    'Ash stops beside three paths. A blue light flickers beyond the trees, but the lake ice is beginning to crack.',
    [
      'Follow the blue light',
      'Test the ice with a branch',
      'Rush across before it breaks',
    ],
  ),
  _Scene(
    'Tracks in the snow',
    'Small tracks circle an abandoned pack. One trail is fresh; the other is already filling with snow.',
    [
      'Follow the fresh trail',
      'Open the pack first',
      'Call loudly for its owner',
    ],
  ),
  _Scene(
    'The warm cave',
    'You find a traveller sheltering beside a crystal that warms the cave. They offer to guide you home for some food.',
    [
      'Share food and ask questions',
      'Take the crystal',
      'Leave without speaking',
    ],
  ),
];

class FrostlandsStoryPage extends StatefulWidget {
  const FrostlandsStoryPage({super.key});

  @override
  State<FrostlandsStoryPage> createState() => _FrostlandsStoryPageState();
}

class _FrostlandsStoryPageState extends State<FrostlandsStoryPage> {
  int _scene = 0;
  final List<String> _path = [];

  void _choose(String choice) {
    _path.add(choice);
    if (_scene == _scenes.length - 1) {
      CurioScope.of(context).completeActivity(
        id: 'frostlands_night_1',
        xp: 50,
        skill: 'Reasoning',
        factId: 'aurora_lights',
      );
      setState(() => _scene++);
    } else {
      setState(() => _scene++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final complete = _scene >= _scenes.length;
    return Scaffold(
      backgroundColor: CurioColors.frostDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Frostlands · Night 1',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF274468), Color(0xFF0A1626)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: Icon(
                    Icons.ac_unit_rounded,
                    color: Colors.white.withValues(alpha: .22),
                    size: 80,
                  ),
                ),
                Positioned(
                  top: 110,
                  right: 20,
                  child: Icon(
                    Icons.ac_unit_rounded,
                    color: Colors.white.withValues(alpha: .13),
                    size: 54,
                  ),
                ),
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                  children: [
                    Container(
                      height: 210,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            bottom: 25,
                            child: Icon(
                              Icons.landscape_rounded,
                              color: Color(0xFF6C93B8),
                              size: 180,
                            ),
                          ),
                          Icon(
                            Icons.pets_rounded,
                            color: CurioColors.coral,
                            size: 82,
                          ),
                          Positioned(
                            top: 28,
                            right: 60,
                            child: Icon(
                              Icons.auto_awesome,
                              color: CurioColors.gold,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (!complete) ...[
                      Text(
                        _scenes[_scene].title.toUpperCase(),
                        style: const TextStyle(
                          color: CurioColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _scenes[_scene].body,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._scenes[_scene].choices.map(
                        (choice) => Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: Material(
                            color: Colors.white.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: () => _choose(choice),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(17),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        choice,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: CurioColors.teal,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'SAFE PASSAGE',
                        style: TextStyle(
                          color: CurioColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ash trusted your decisions and you found a thoughtful way home.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Your path: ${_path.join(' → ')}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .7),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '+50 XP · Aurora discovery unlocked',
                        style: TextStyle(
                          color: CurioColors.teal,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Return from Frostlands',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
