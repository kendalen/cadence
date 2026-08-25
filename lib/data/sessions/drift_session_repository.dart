import 'package:drift/drift.dart';

import '../../domain/core/result.dart';
import '../../domain/core/unit.dart';
import '../../domain/sessions/ids.dart';
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
  Future<Result<Unit, PersistenceFailure>> update(Session session) async {
    try {
      // Replace the whole reading set in one transaction: the session row's
      // only column is its id, so there is nothing to update on it — the change
      // is always to which readings it owns.
      await _database.transaction(() async {
        await (_database.delete(
          _database.readings,
        )..where((reading) => reading.sessionId.equals(session.id.value))).go();
        await _database.batch(
          (batch) => batch.insertAll(
            _database.readings,
            session.readings.map((r) => toReadingRow(r, session.id)),
          ),
        );
      });
      return const Ok(unit);
    } on Exception catch (error) {
      // Broad for the same reason as add: every way sqlite can refuse a write
      // is an expected failure, not a bug. The cause is kept; Error propagates.
      return Err(WriteFailed(error));
    }
  }

  @override
  Future<Result<Unit, PersistenceFailure>> delete(SessionId id) async {
    try {
      // Readings go with it via the schema's cascade (CLAUDE.md §4: a session
      // owns its readings). A no-match delete affects zero rows and still
      // succeeds — the caller's goal already holds.
      await (_database.delete(
        _database.sessions,
      )..where((session) => session.id.equals(id.value))).go();
      return const Ok(unit);
    } on Exception catch (error) {
      // Broad for the same reason as add: every way sqlite can refuse a write
      // is an expected failure the user must be told about, not a bug to crash
      // on. The cause is kept; Error still propagates.
      return Err(WriteFailed(error));
    }
  }

  @override
  Stream<List<Session>> watchAll() =>
      _sessionsWithReadings().watch().map(_toSessions);

  @override
  Future<List<Session>> recentHistory() async =>
      _toSessions(await _sessionsWithReadings().get());

  /// Every session joined to its readings, one row per reading.
  ///
  /// Shared by the reactive [watchAll] and the one-shot [recentHistory] so both
  /// read the same shape; grouping the rows into sessions is done in
  /// [_toSessions].
  Selectable<TypedResult> _sessionsWithReadings() =>
      _database.select(_database.sessions).join([
        innerJoin(
          _database.readings,
          _database.readings.sessionId.equalsExp(_database.sessions.id),
        ),
      ]);

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
