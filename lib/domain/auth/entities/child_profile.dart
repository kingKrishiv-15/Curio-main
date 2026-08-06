/// Pure Dart entity mirroring the `child` table, as returned by the
/// add_child_profile RPC.
class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.parentId,
    required this.displayName,
    required this.avatarKey,
    required this.ageBand,
    required this.preferredLanguage,
    required this.totalXp,
    required this.dragonStage,
    required this.active,
  });

  final String id;
  final String parentId;
  final String displayName;
  final String? avatarKey;
  final String ageBand;
  final String preferredLanguage;
  final int totalXp;
  final int dragonStage;
  final bool active;
}
