import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/core/result.dart';
import '../../../domain/core/unit.dart';
import '../../../domain/sessions/persistence_failure.dart';
import '../../../domain/sessions/session.dart';
import '../../../domain/sessions/session_repository.dart';

/// Holds the occasion shown on the detail screen and removes it on request.
///
/// The state is the [Session] itself: the screen was handed a snapshot by the
/// list, and this cubit is the one place from which that occasion is acted on
/// (CLAUDE.md §3 — the UI reaches the store through a cubit, not directly).
class SessionDetailCubit extends Cubit<Session> {
  /// Shows [session], reading and writing through [_repository].
  SessionDetailCubit(this._repository, super.session);

  final SessionRepository _repository;

  /// Removes this occasion and all its readings.
  ///
  /// Returns the store's [Result] so the screen can leave and offer an undo on
  /// success, or report the failure and stay put — nothing was removed then.
  Future<Result<Unit, PersistenceFailure>> delete() =>
      _repository.delete(state.id);
}
