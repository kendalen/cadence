import 'package:flutter/widgets.dart';

import 'data/database/app_database.dart';
import 'data/ids/uuid_id_generator.dart';
import 'data/sessions/drift_session_repository.dart';
import 'ui/app.dart';

/// Composition root: the one place that knows which implementations the app
/// runs on.
void main() {
  final database = AppDatabase();

  // The database is deliberately not closed on teardown. Every write commits
  // in its own transaction, so there is nothing buffered to flush, and Android
  // gives no callback that is guaranteed to run before the process dies —
  // relying on one would be a false guarantee. The export slice adds the
  // wal_checkpoint(TRUNCATE) that copying the file does need (CLAUDE.md §5).
  runApp(
    CadenceApp(
      sessionRepository: DriftSessionRepository(database),
      idGenerator: const UuidIdGenerator(),
    ),
  );
}
