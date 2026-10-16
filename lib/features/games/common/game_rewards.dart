/// What finishing each activity earns. This mirrors `public.activity_rewards`
/// (supabase/migrations/202610080001_launch_hardening.sql) exactly — the
/// server recomputes XP from its own table, so a mismatch would make XP jump
/// after a reload. A test parses the migration and compares.
class GameReward {
  const GameReward(this.xp, this.skill, this.factId, {this.dated = true});

  final int xp;

  /// One of [learningSkills].
  final String skill;
  final String factId;

  /// Daily activities are recorded once per date ("squeeze_20261008");
  /// one-offs like the Frostlands story once ever.
  final bool dated;
}

/// The four skills every game feeds, in display order.
const learningSkills = ['Number sense', 'Patterns', 'Evidence', 'Reasoning'];

const gameRewards = <String, GameReward>{
  'squeeze': GameReward(80, 'Number sense', 'prime_numbers'),
  'link_lab': GameReward(90, 'Reasoning', 'classification_science'),
  'signal_grid': GameReward(100, 'Reasoning', 'binary_patterns'),
  'pattern_forge': GameReward(60, 'Patterns', 'fibonacci_nature'),
  'evidence_garden': GameReward(70, 'Evidence', 'weather_evidence'),
  'frostlands_night_1': GameReward(
    50,
    'Reasoning',
    'aurora_lights',
    dated: false,
  ),
  'odd_cluster': GameReward(100, 'Reasoning', 'giant_rings'),
  'sequence': GameReward(80, 'Patterns', 'triangular_numbers'),
  'bridge': GameReward(80, 'Number sense', 'order_matters'),
  'cascade': GameReward(90, 'Evidence', 'traffic_evaporation'),
  'loophole': GameReward(70, 'Evidence', 'sample_size'),
  'scale': GameReward(80, 'Number sense', 'equal_fractions'),
  'mirror': GameReward(80, 'Patterns', 'mirror_symmetry'),
  'verdict': GameReward(80, 'Evidence', 'correlation'),
  'whos_who': GameReward(100, 'Reasoning', 'logic_grid'),
};

final _dateSuffix = RegExp(r'_[0-9]{8}$');

/// The game an activity id belongs to ("squeeze_20261009" → "squeeze").
String activityGame(String activityId) =>
    activityId.replaceFirst(_dateSuffix, '');
