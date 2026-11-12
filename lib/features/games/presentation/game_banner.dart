import 'package:flutter/material.dart';
import 'package:curio/theme/curio_tokens.dart';

/// Each game's banner colour: one bold, solid colour, kept within its
/// skill's family (number sense oranges and golds, patterns reds and pinks,
/// evidence blues and teals, reasoning violets) so a skill still reads at a
/// glance, but no two games share a colour.
const _gameColors = <String, Color>{
  'memory_match': CurioTokens.tintThinking,
  'memory_trail': CurioTokens.tintThinking,
  'memory_grid': CurioTokens.tintLogic,
  'word_wise': CurioTokens.tintLogic,
  'word_builder': CurioTokens.tintLogic,
  'word_trails': CurioTokens.accent,
  // Number sense
  'squeeze': CurioTokens.tintMaths,
  'bridge': CurioTokens.tintMaths,
  'scale': CurioTokens.wrong,
  'number_hunt': CurioTokens.tintMaths,
  // Patterns
  'sequence': CurioTokens.wrong,
  'pattern_forge': CurioTokens.wrong,
  'mirror': CurioTokens.tintThinking,
  // Evidence
  'cascade': CurioTokens.tintLogic,
  'loophole': CurioTokens.accent,
  'evidence_garden': CurioTokens.tintLogic,
  'verdict': CurioTokens.tintLogic,
  // Reasoning
  'odd_cluster': CurioTokens.tintThinking,
  'link_lab': CurioTokens.tintThinking,
  'signal_grid': CurioTokens.tintThinking,
  'whos_who': CurioTokens.tintThinking,
  'crowns': CurioTokens.tintThinking,
  // The story: a night sky.
  'frostlands_night_1': CurioTokens.tintLogic,
};

/// [id]'s banner colour, or [fallback] (its skill colour) for a game that
/// hasn't been given one yet.
Color gameColor(String id, Color fallback) => _gameColors[id] ?? fallback;

/// A skill's solid colour, matching its first game, for skill tiles.
Color skillSolidColor(String skill, Color fallback) => switch (skill) {
  'Number sense' => _gameColors['squeeze']!,
  'Patterns' => _gameColors['sequence']!,
  'Evidence' => _gameColors['cascade']!,
  'Reasoning' => _gameColors['odd_cluster']!,
  _ => fallback,
};

/// [color] as it should be painted: as is in light mode, settled a touch in
/// dark mode so a bright block doesn't glare on a dark page.
Color bannerFill(BuildContext context, Color color) =>
    Theme.of(context).brightness == Brightness.dark
    ? Color.lerp(color, CurioTokens.base, .1)!
    : color;
