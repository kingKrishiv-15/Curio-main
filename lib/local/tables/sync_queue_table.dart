import 'package:drift/drift.dart';

/// A pending write the app made while offline (or that hasn't been confirmed
/// by the server yet). `idempotencyKey` is the same key sent to the server
/// RPC/table insert, so replaying a queued action after reconnecting is safe
/// to retry - the server-side idempotency_key uniqueness is what actually
/// prevents duplication; this queue just tracks "have I sent this yet."
///
/// No sync engine reads from or writes to this table yet - that's a later
/// phase. It's defined now so the local/ layer and its generated code exist
/// and compile from Phase 0 onward.
class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Matches the idempotency_key sent to the server for this action.
  TextColumn get idempotencyKey => text().unique()();

  /// e.g. "learning_session.insert", "response.insert" - identifies which
  /// repository method to replay.
  TextColumn get actionType => text()();

  /// JSON-encoded payload for the action.
  TextColumn get payloadJson => text()();

  TextColumn get status => text().withDefault(const Constant('pending'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get lastAttemptedAt => dateTime().nullable()();
}
