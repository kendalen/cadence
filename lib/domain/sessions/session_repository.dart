import '../core/result.dart';
import '../core/unit.dart';
import 'ids.dart';
import 'import_summary.dart';
import 'persistence_failure.dart';
import 'session.dart';

/// The store of recorded sessions, as the rest of the app sees it.
///
/// Implementations return domain types only; no storage-engine type appears in
/// these signatures (CLAUDE.md §3).
abstract interface class SessionRepository {
  /// Stores [session] and its readings as one unit.
  ///
  /// Returns [WriteFailed] if the store rejected the write, in which case
  /// nothing was written — not even part of the session.
  Future<Result<Unit, PersistenceFailure>> add(Session session);

  /// Emits every stored session, newest [Session.occurredAt] first, and emits
  /// again on every change.
  ///
  /// Emits an empty list when nothing is stored.
  Stream<List<Session>> watchAll();

  /// A one-shot snapshot of every stored session, newest [Session.occurredAt]
  /// first; an empty list when nothing is stored.
  ///
  /// The non-reactive read behind history-aware features such as seeding the
  /// entry form; use [watchAll] for anything that must track later changes.
  Future<List<Session>> recentHistory();

  /// Removes the session with [id] and all its readings, as one unit.
  ///
  /// Deleting a session that is not stored is not an error: the outcome the
  /// caller wants — no session with that id — already holds, so it returns
  /// [Ok]. Returns [WriteFailed] only if the store rejected the delete.
  Future<Result<Unit, PersistenceFailure>> delete(SessionId id);

  /// Replaces the readings of the already-stored session with [session]'s, as
  /// one unit.
  ///
  /// Used to correct or remove readings on an existing occasion: the session
  /// keeps its identity, its readings become exactly the ones given. The
  /// session must already be stored — this does not create a new one; use [add]
  /// for that. Returns [WriteFailed] if the store rejected the write, in which
  /// case nothing changed.
  Future<Result<Unit, PersistenceFailure>> update(Session session);

  /// Merges [sessions] into the store by id, as one unit, and reports the
  /// split.
  ///
  /// A session whose id is not yet stored is added; a session whose id is
  /// already stored is left exactly as it is (local data wins on a clash —
  /// import never overwrites). Used to restore a JSON backup (CLAUDE.md §5).
  /// Returns an [ImportSummary] of how many were added versus already present,
  /// or [WriteFailed] if the store rejected the write, in which case nothing
  /// was imported.
  Future<Result<ImportSummary, PersistenceFailure>> importSessions(
    List<Session> sessions,
  );
}
