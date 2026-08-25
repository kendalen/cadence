import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/core/result.dart';
import '../../../domain/core/unit.dart';
import '../../../domain/sessions/persistence_failure.dart';
import '../../../domain/sessions/session.dart';
import '../../../domain/sessions/session_repository.dart';

/// Holds the occasion shown on the detail screen and acts on it.
///
/// The state is the current [Session]. It starts from the snapshot the list
/// handed over and then tracks the store, so an edit's new values appear
/// without the screen holding a stale copy (CLAUDE.md §3 — the UI reaches the
/// store through a cubit). It is the one place the shown occasion is written.
class SessionDetailCubit extends Cubit<Session> {
  /// Shows [session], reading and writing through [_repository].
  SessionDetailCubit(this._repository, super.session) {
    _subscription = _repository.watchAll().listen(_refreshFromStore);
  }

  final SessionRepository _repository;
  late final StreamSubscription<List<Session>> _subscription;

  /// Re-emits this occasion whenever the store reports a new version of it.
  ///
  /// When the occasion is no longer stored — its last reading removed, or the
  /// whole occasion deleted — the screen is already leaving on the action that
  /// caused it, so the absence is ignored rather than emitted as an empty
  /// state the screen would have to model.
  void _refreshFromStore(List<Session> sessions) {
    for (final session in sessions) {
      if (session.id == state.id) {
        emit(session);
        return;
      }
    }
  }

  /// Removes this occasion and all its readings.
  ///
  /// Returns the store's [Result] so the screen can leave and offer an undo on
  /// success, or report the failure and stay put — nothing was removed then.
  Future<Result<Unit, PersistenceFailure>> delete() =>
      _repository.delete(state.id);

  /// Stores [next] in place of the shown occasion — an edited or reduced set of
  /// readings. [next] keeps this occasion's id; the store change flows back in
  /// through [watchAll] and refreshes the display.
  Future<Result<Unit, PersistenceFailure>> save(Session next) =>
      _repository.update(next);

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
