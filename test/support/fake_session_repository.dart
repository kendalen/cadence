import 'dart:async';

import 'package:cadence/domain/core/result.dart';
import 'package:cadence/domain/core/unit.dart';
import 'package:cadence/domain/sessions/persistence_failure.dart';
import 'package:cadence/domain/sessions/session.dart';
import 'package:cadence/domain/sessions/session_repository.dart';

/// An in-memory [SessionRepository] that records what it was asked to store
/// and can be told to refuse the next write.
class FakeSessionRepository implements SessionRepository {
  final _sessions = StreamController<List<Session>>.broadcast();

  /// Every session [add] accepted, oldest first.
  final List<Session> added = [];

  /// When set, [add] reports this instead of storing.
  PersistenceFailure? refuseWith;

  @override
  Future<Result<Unit, PersistenceFailure>> add(Session session) async {
    final refusal = refuseWith;
    if (refusal != null) {
      return Err(refusal);
    }
    added.add(session);
    _sessions.add(List.of(added));
    return const Ok(unit);
  }

  @override
  Stream<List<Session>> watchAll() => _sessions.stream;

  /// Sessions seeded for a history read to return, newest occasion first. Tests
  /// that care about the seed set this; it is independent of what [add] records.
  List<Session> history = [];

  @override
  Future<List<Session>> recentHistory() async => List.of(history);

  /// Pushes [sessions] to everyone watching, as a store change would.
  void emit(List<Session> sessions) => _sessions.add(sessions);

  /// Closes the stream; call from tearDown.
  Future<void> dispose() => _sessions.close();
}
