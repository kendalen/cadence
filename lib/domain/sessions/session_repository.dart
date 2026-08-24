import '../core/result.dart';
import '../core/unit.dart';
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
}
