import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/sessions/session.dart';
import '../../../domain/sessions/session_repository.dart';
import 'session_list_state.dart';

/// Keeps the readings list in step with the store.
///
/// Subscribes on creation and emits a [SessionListLoaded] for every change, so
/// a session saved on the entry screen appears without the list asking again.
class SessionListCubit extends Cubit<SessionListState> {
  /// Starts watching [repository].
  SessionListCubit(SessionRepository repository)
    : super(const SessionListLoading()) {
    _subscription = repository.watchAll().listen(
      (sessions) => emit(SessionListLoaded(sessions)),
    );
  }

  late final StreamSubscription<List<Session>> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
