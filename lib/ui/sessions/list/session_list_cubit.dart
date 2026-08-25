import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/backup/backup_codec.dart';
import '../../../domain/sessions/session.dart';
import '../../../domain/sessions/session_repository.dart';
import 'session_list_state.dart';

/// Keeps the readings list in step with the store.
///
/// Subscribes on creation and emits a [SessionListLoaded] for every change, so
/// a session saved on the entry screen appears without the list asking again.
class SessionListCubit extends Cubit<SessionListState> {
  /// Starts watching [repository].
  SessionListCubit(this._repository) : super(const SessionListLoading()) {
    _subscription = _repository.watchAll().listen(
      (sessions) => emit(SessionListLoaded(sessions)),
    );
  }

  final SessionRepository _repository;

  late final StreamSubscription<List<Session>> _subscription;

  /// The whole diary encoded as a JSON backup string, ready to share.
  ///
  /// Reads every stored session (a one-shot [SessionRepository.recentHistory]
  /// snapshot) and encodes it with [encodeBackup]; [now] stamps the export time
  /// and defaults to the current UTC instant. Returns an empty-diary backup
  /// when nothing is stored — the caller decides whether that is worth sharing.
  Future<String> buildBackupJson({DateTime? now}) async {
    final sessions = await _repository.recentHistory();
    return jsonEncode(
      encodeBackup(sessions, exportedAt: now ?? DateTime.now().toUtc()),
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
