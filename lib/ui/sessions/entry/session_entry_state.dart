import 'package:equatable/equatable.dart';

import '../../../domain/sessions/validation_failure.dart';

/// Where the entry form has got to.
///
/// [takenAt] is on the base because every state shows it: the field keeps its
/// value while the form is submitting and after it has saved.
sealed class SessionEntryState extends Equatable {
  /// Base constructor recording the moment currently chosen in the form.
  const SessionEntryState(this.takenAt);

  /// The moment the user says the reading was taken, in local time.
  final DateTime takenAt;

  @override
  List<Object?> get props => [takenAt];
}

/// The user is filling the form in.
final class SessionEntryEditing extends SessionEntryState {
  /// Shows the form, with [failures] marking any fields found invalid on the
  /// last attempt to save.
  const SessionEntryEditing(super.takenAt, {this.failures = const []});

  /// Why the last attempt to save was rejected; empty before the first one.
  final List<ValidationFailure> failures;

  @override
  List<Object?> get props => [takenAt, failures];
}

/// The reading is valid and is being written.
final class SessionEntrySubmitting extends SessionEntryState {
  /// Marks the write as in flight.
  const SessionEntrySubmitting(super.takenAt);
}

/// The reading was stored; the screen closes on this.
final class SessionEntrySaved extends SessionEntryState {
  /// Marks the write as done.
  const SessionEntrySaved(super.takenAt);
}

/// The store refused the write.
///
/// Carries no detail: the underlying cause is for diagnosis, never for the
/// user (CLAUDE.md §6).
final class SessionEntrySaveFailed extends SessionEntryState {
  /// Marks the write as failed, leaving the typed values in place.
  const SessionEntrySaveFailed(super.takenAt);
}
