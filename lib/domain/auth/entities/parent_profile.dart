/// Pure Dart entity - no Supabase/Flutter types. Mirrors the `profile` table
/// for a parent, plus their consent record, as returned by the
/// create_parent_profile RPC.
class ParentProfile {
  const ParentProfile({
    required this.id,
    required this.displayName,
    required this.preferredLanguage,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String preferredLanguage;
  final String status;
  final DateTime createdAt;
}
