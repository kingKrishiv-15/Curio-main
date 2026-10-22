import 'package:flutter/material.dart';

/// Each game's banner colour: one bold, solid colour, kept within its
/// skill's family (number sense oranges and golds, patterns reds and pinks,
/// evidence blues and teals, reasoning violets) so a skill still reads at a
/// glance, but no two games share a colour.
const _gameColors = <String, Color>{
  'memory_match': Color(0xFF9B65D6),
  'memory_trail': Color(0xFF735DD8),
  'word_wise': Color(0xFF218C92),
  'word_builder': Color(0xFF3286C2),
  // Number sense
  'squeeze': Color(0xFFFF8A34),
  'bridge': Color(0xFFF2A527),
  'scale': Color(0xFFE0735A),
  // Patterns
  'sequence': Color(0xFFF25F7A),
  'pattern_forge': Color(0xFFFF7EB3),
  'mirror': Color(0xFFD65DB1),
  // Evidence
  'cascade': Color(0xFF3B82F6),
  'loophole': Color(0xFF14B8A6),
  'evidence_garden': Color(0xFF22A6D8),
  'verdict': Color(0xFF4F5BD5),
  // Reasoning
  'odd_cluster': Color(0xFF8B5CF6),
  'link_lab': Color(0xFFA66CFF),
  'signal_grid': Color(0xFF6A4CE0),
  'whos_who': Color(0xFFB24BD8),
  // The story: a night sky.
  'frostlands_night_1': Color(0xFF2F4BA8),
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
    ? Color.lerp(color, Colors.black, .1)!
    : color;
