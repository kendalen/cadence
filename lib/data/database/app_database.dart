import 'package:drift/drift.dart';
// validateDatabaseSchema() ships in drift_dev, which is why drift_dev is a
// runtime dependency here rather than a dev one. The kDebugMode guard below
// keeps the call out of release builds.
import 'package:drift_dev/api/migrations_native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'tables.dart';

part 'app_database.g.dart';

/// The application database.
///
/// The file lives in the application documents directory, never in a cache
/// directory (CLAUDE.md §5); `drift_flutter` puts it there. Timestamps are
/// stored as UTC ISO-8601 text — see `build.yaml`.
@DriftDatabase(tables: [Sessions, Readings, AppSettings])
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database.
  AppDatabase() : super(driftDatabase(name: _databaseName));

  /// Opens a database on the given [executor], for tests.
  AppDatabase.forTesting(super.executor);

  /// Base name of the database file in the documents directory.
  static const String _databaseName = 'cadence';

  @override
  int get schemaVersion => 3;

  /// How the schema is created and migrated.
  ///
  /// Every future bump needs an explicit step here, a committed schema
  /// snapshot, and a passing migration test (CLAUDE.md §5).
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v1 -> v2: the optional reading context (site, posture, medication
      // timing — CLAUDE.md §4). All three are nullable, so existing readings
      // keep their values and gain nulls; no data is at risk.
      if (from < 2) {
        await m.addColumn(readings, readings.site);
        await m.addColumn(readings, readings.posture);
        await m.addColumn(readings, readings.medicationTiming);
      }
      // v2 -> v3: the app-settings key-value table (CLAUDE.md §1 first-run
      // notice, later the deferred preferences). A brand-new table, so no
      // existing diary data is touched.
      if (from < 3) {
        await m.createTable(appSettings);
      }
    },
    beforeOpen: (details) async {
      // Off by default in SQLite, so the cascade on Readings.sessionId only
      // takes effect once this is on. Must be set outside a transaction.
      await customStatement('PRAGMA foreign_keys = ON');
      if (kDebugMode) {
        await validateDatabaseSchema();
      }
    },
  );
}
