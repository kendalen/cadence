import 'package:equatable/equatable.dart';

import '../../../domain/sessions/session.dart';

/// What the readings list is showing.
sealed class SessionListState extends Equatable {
  /// Const base constructor for the variants.
  const SessionListState();

  @override
  List<Object?> get props => const [];
}

/// The store has not produced its first result yet.
final class SessionListLoading extends SessionListState {
  /// The state the list starts in.
  const SessionListLoading();
}

/// The stored sessions, newest occasion first.
///
/// An empty [sessions] list means nothing has been recorded yet; the screen
/// shows its empty message for it.
final class SessionListLoaded extends SessionListState {
  /// Holds the [sessions] last read from the store.
  const SessionListLoaded(this.sessions);

  /// The sessions to show, newest occasion first.
  final List<Session> sessions;

  @override
  List<Object?> get props => [sessions];
}
