import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/sync_queue_table.dart';

part 'app_database.g.dart';

/// The app's offline/local database. Currently just the sync queue skeleton
/// (see sync_queue_table.dart) - cached content tables (for offline reads)
/// land in a later phase as their own Drift tables here, alongside a schema
/// migration when the version bumps.
@DriftDatabase(tables: [SyncQueueItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'curio.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
