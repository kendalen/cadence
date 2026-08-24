import 'package:equatable/equatable.dart';

import '../../../domain/sessions/reading.dart';
import '../../../domain/sessions/validation_failure.dart';

/// Where the entry form has got to.
///
/// [takenAt] and [bankedReadings] are on the base because every state carries
/// them: the chosen moment and the readings already banked for this occasion
/// both survive submitting, saving, and a failed save.
sealed class SessionEntryState extends Equatable {
  /// Base constructor recording the current form's moment and the readings
  /// already banked for this occasion.
  const SessionEntryState(this.takenAt, {this.bankedReadings = const []});

  /// The moment the user says the current reading was taken, in local time.
  final DateTime takenAt;

  /// The readings already banked for this occasion, oldest first. Empty until
  /// the user banks one with "add another reading".
  final List<Reading> bankedReadings;

  @override
  List<Object?> get props => [takenAt, bankedReadings];
}

/// The user is filling the form in.
final class SessionEntryEditing extends SessionEntryState {
  /// Shows the form, with [failures] marking any fields found invalid on the
  /// last attempt, and [bankedReadings] listing what is already banked.
  const SessionEntryEditing(
    super.takenAt, {
    super.bankedReadings,
    this.failures = const [],
  });

  /// Why the last attempt was rejected; empty before the first one.
  final List<ValidationFailure> failures;

  @override
  List<Object?> get props => [takenAt, bankedReadings, failures];
}

/// A valid occasion is being written.
final class SessionEntrySubmitting extends SessionEntryState {
  /// Marks the write as in flight, keeping the banked readings for display.
  const SessionEntrySubmitting(super.takenAt, {super.bankedReadings});
}

/// The occasion was stored; the screen closes on this.
final class SessionEntrySaved extends SessionEntryState {
  /// Marks the write as done.
  const SessionEntrySaved(super.takenAt);
}

/// The store refused the write.
///
/// Carries no detail: the underlying cause is for diagnosis, never for the
/// user (CLAUDE.md §6). Keeps the banked readings so the user can retry.
final class SessionEntrySaveFailed extends SessionEntryState {
  /// Marks the write as failed, leaving the banked readings in place.
  const SessionEntrySaveFailed(super.takenAt, {super.bankedReadings});
}
