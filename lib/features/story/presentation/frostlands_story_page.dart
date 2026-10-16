import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/common/game_kit.dart';
import '../../games/common/game_rewards.dart';
import '../domain/frostlands.dart';

class FrostlandsStoryPage extends StatefulWidget {
  const FrostlandsStoryPage({super.key, this.date});

  /// Unused — the story is the same every night — but every activity page
  /// takes the same arguments.
  final DateTime? date;

  @override
  State<FrostlandsStoryPage> createState() => _FrostlandsStoryPageState();
}

class _FrostlandsStoryPageState extends State<FrostlandsStoryPage> {
  static const _story = 'frostlands_night_1';
  static const _rules = [
    'Read each scene and choose what Ash does next.',
    'Every choice is careful, brave or kind — and nudges how the night ends.',
    'There are four endings. Finishing earns XP once; replay to find the others.',
  ];

  final List<StoryChoice> _path = [];
  bool _alreadyDone = false;

  bool get _complete => _path.length == frostlandsScenes.length;

  void _choose(StoryChoice choice) {
    if (_complete) return;
    HapticFeedback.selectionClick();
    setState(() => _path.add(choice));
    if (_complete) _alreadyDone = awardDaily(context, _story);
  }

  void _replay() => setState(_path.clear);

  @override
  Widget build(BuildContext context) {
    return CurioPage(
      title: 'Frostlands · Night 1',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          _SceneArt(
            icon: _complete
                ? Icons.auto_awesome_rounded
                : const [
                    Icons.flare_rounded,
                    Icons.backpack_rounded,
                    Icons.diamond_rounded,
                  ][_path.length],
          ),
          const SizedBox(height: 18),
          if (!_complete) ..._scene(context) else ..._ending(context),
        ],
      ),
    );
  }

  List<Widget> _scene(BuildContext context) {
    final scene = frostlandsScenes[_path.length];
    final seenBefore = _path.isEmpty && completedAlready(context, _story);
    return [
      CurioEyebrow(
        'Scene ${_path.length + 1} of ${frostlandsScenes.length}',
        color: curioColor(context, CurioColors.blue, CurioColorsLight.blue),
      ),
      const SizedBox(height: 6),
      Semantics(
        header: true,
        child: Text(
          scene.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      const SizedBox(height: 12),
      if (seenBefore) ...[
        const GameNotice(
          message:
              'You’ve finished this story before, so its XP is already yours. Try a different path!',
        ),
        const SizedBox(height: 12),
      ],
      if (_path.isNotEmpty) ...[
        _Recap(choice: _path.last),
        const SizedBox(height: 14),
      ],
      Text(
        scene.body,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.45),
      ),
      const SizedBox(height: 18),
      Text(
        'What should Ash do?',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 10),
      for (var i = 0; i < scene.choices.length; i++) ...[
        _ChoiceButton(
          key: Key('story_choice_$i'),
          label: scene.choices[i].label,
          onTap: () => _choose(scene.choices[i]),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }

  List<Widget> _ending(BuildContext context) {
    final traits = [for (final c in _path) c.trait];
    final ending = frostlandsEnding(traits);
    final tally = traitTally(traits);
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final gold = curioColor(
      context,
      CurioColors.saffronStrong,
      CurioColorsLight.saffronStrong,
    );
    final xp = gameRewards[_story]!.xp;
    return [
      CurioEyebrow(
        'The end of night 1',
        color: curioColor(context, CurioColors.blue, CurioColorsLight.blue),
      ),
      const SizedBox(height: 6),
      Semantics(
        header: true,
        child: Text(
          ending.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      const SizedBox(height: 10),
      if (_path.isNotEmpty) ...[
        _Recap(choice: _path.last),
        const SizedBox(height: 14),
      ],
      Text(
        ending.body,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.45),
      ),
      const SizedBox(height: 18),
      GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your path', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            for (var i = 0; i < _path.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${i + 1}. ${_path[i].label}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TraitChip(trait: _path[i].trait),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            Text(
              [
                for (final t in StoryTrait.values) '${t.label} ${tally[t]}',
              ].join(' · '),
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _alreadyDone
                  ? Icons.check_circle_outline_rounded
                  : Icons.bolt_rounded,
              color: gold,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _alreadyDone
                    ? 'You’ve already earned this story’s XP — this path was for fun.'
                    : '+$xp XP · Aurora discovery unlocked',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        key: const Key('story_replay'),
        onPressed: _replay,
        icon: const Icon(Icons.replay_rounded, size: 18),
        label: const Text('Try a different path'),
      ),
      const SizedBox(height: 10),
      PrimaryButton(
        label: 'Return from Frostlands',
        icon: Icons.home_rounded,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    ];
  }
}

/// The Frostlands night sky: the shared hero gradient, so it suits both
/// themes, with the scene's own icon.
class _SceneArt extends StatelessWidget {
  const _SceneArt({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ice = curioColor(context, CurioColors.ice, CurioColorsLight.ice);
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final gold = curioColor(
      context,
      CurioColors.saffron,
      CurioColorsLight.saffronStrong,
    );
    final snow = curioColor(context, CurioColors.ink, CurioColorsLight.blue);
    return ExcludeSemantics(
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          gradient: dark
              ? CurioColors.heroGradient
              : CurioColorsLight.heroGradient,
          borderRadius: BorderRadius.circular(28),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 14,
              left: 18,
              child: Icon(
                Icons.ac_unit_rounded,
                size: 44,
                color: snow.withValues(alpha: .35),
              ),
            ),
            Positioned(
              top: 64,
              right: 24,
              child: Icon(
                Icons.ac_unit_rounded,
                size: 30,
                color: snow.withValues(alpha: .25),
              ),
            ),
            Positioned(
              bottom: -40,
              child: Icon(
                Icons.landscape_rounded,
                size: 170,
                color: ice.withValues(alpha: .75),
              ),
            ),
            Positioned(
              bottom: 26,
              child: Icon(Icons.pets_rounded, size: 58, color: coral),
            ),
            Positioned(
              top: 18,
              right: 70,
              child: Icon(icon, size: 34, color: gold),
            ),
          ],
        ),
      ),
    );
  }
}

class _Recap extends StatelessWidget {
  const _Recap({required this.choice});
  final StoryChoice choice;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'You chose: ${choice.label}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              _TraitChip(trait: choice.trait),
            ],
          ),
          const SizedBox(height: 6),
          Text(choice.outcome, style: TextStyle(color: muted, height: 1.45)),
        ],
      ),
    );
  }
}

class _TraitChip extends StatelessWidget {
  const _TraitChip({required this.trait});
  final StoryTrait trait;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (trait) {
      StoryTrait.careful => (
        curioColor(context, CurioColors.blue, CurioColorsLight.blue),
        Icons.search_rounded,
      ),
      StoryTrait.brave => (
        curioColor(context, CurioColors.coral, CurioColorsLight.coral),
        Icons.bolt_rounded,
      ),
      StoryTrait.kind => (
        curioColor(context, CurioColors.plum, CurioColorsLight.plum),
        Icons.favorite_rounded,
      ),
    };
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            trait.label,
            style: TextStyle(
              color: ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.onTap, super.key});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final coral = curioColor(
      context,
      CurioColors.coralStrong,
      CurioColorsLight.coralStrong,
    );
    final surface = curioColor(
      context,
      CurioColors.surface,
      CurioColorsLight.surface,
    );
    final outline = curioColor(
      context,
      CurioColors.outline,
      CurioColorsLight.outline,
    );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: outline, width: 1.3),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, color: coral),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
