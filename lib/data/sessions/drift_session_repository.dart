import 'package:drift/drift.dart';

import '../../domain/core/result.dart';
import '../../domain/core/unit.dart';
import '../../domain/sessions/persistence_failure.dart';
import '../../domain/sessions/session.dart';
import '../../domain/sessions/session_repository.dart';
import '../database/app_database.dart';
import 'session_mappers.dart';

/// The drift-backed [SessionRepository].
///
/// Returns domain types only; no drift type appears in a signature outside
/// this layer (CLAUDE.md §3).
class DriftSessionRepository implements SessionRepository {
  /// Reads and writes sessions in [_database].
  DriftSessionRepository(this._database);

  final AppDatabase _database;

  @override
  Future<Result<Unit, PersistenceFailure>> add(Session session) async {
    try {
      await _database.transaction(() async {
        await _database
            .into(_database.sessions)
            .insert(SessionsCompanion.insert(id: session.id.value));
        await _database.batch(
          (batch) => batch.insertAll(
            _database.readings,
            session.readings.map((r) => toReadingRow(r, session.id)),
          ),
        );
      });
      return const Ok(unit);
    } on Exception catch (error) {
      // Deliberately broad: every way sqlite can refuse a write (locked file,
      // full disk, constraint) is an expected failure the user must be told
      // about, and drift wraps them in several unrelated exception types. The
      // cause is kept, not swallowed, and Error still propagates as a bug.
      return Err(WriteFailed(error));
    }
  }

  @override
  Stream<List<Session>> watchAll() {
    final query = _database.select(_database.sessions).join([
      innerJoin(
        _database.readings,
        _database.readings.sessionId.equalsExp(_database.sessions.id),
      ),
    ]);
    return query.watch().map(_toSessions);
  }

  /// Groups joined rows into sessions, newest occasion first.
  ///
  /// The join returns one row per reading, so the grouping happens here rather
  /// than in SQL.
  // ponytail: reads every session on each change. A diary holds thousands of
  // rows at most; add a windowed query if that stops being true.
  List<Session> _toSessions(List<TypedResult> rows) {
    final readingsBySession = <String, List<ReadingRow>>{};
    final sessionRows = <String, SessionRow>{};

    for (final row in rows) {
      final sessionRow = row.readTable(_database.sessions);
      sessionRows[sessionRow.id] = sessionRow;
      readingsBySession
          .putIfAbsent(sessionRow.id, () => [])
          .add(row.readTable(_database.readings));
    }

    return sessionRows.entries
        .map((entry) => toSession(entry.value, readingsBySession[entry.key]!))
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }
}
