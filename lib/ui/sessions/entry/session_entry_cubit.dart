import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/core/result.dart';
import '../../../domain/sessions/id_generator.dart';
import '../../../domain/sessions/ids.dart';
import '../../../domain/sessions/reading.dart';
import '../../../domain/sessions/reading_input.dart';
import '../../../domain/sessions/session.dart';
import '../../../domain/sessions/session_repository.dart';
import '../../../domain/sessions/validation_failure.dart';
import 'session_entry_state.dart';

/// Drives the entry form: validate, then store as a one-reading session.
///
/// This slice records exactly one reading per occasion; the schema already
/// holds many, so multi-reading entry is a later, additive change.
class SessionEntryCubit extends Cubit<SessionEntryState> {
  /// Starts the form with its moment defaulting to the reading of [now].
  ///
  /// Stores through the given repository and takes identities from the given
  /// generator.
  SessionEntryCubit(
    this._repository,
    this._idGenerator, {
    DateTime Function() now = DateTime.now,
  }) : _now = now,
       super(SessionEntryEditing(now()));

  final SessionRepository _repository;
  final IdGenerator _idGenerator;

  /// The clock, injected so tests can pin "now" and the future check with it.
  final DateTime Function() _now;

  /// Records the moment picked in the date and time pickers.
  ///
  /// Clears any failures shown, since the form has changed since they were
  /// reported.
  void takenAtChanged(DateTime takenAt) =>
      emit(SessionEntryEditing(takenAt.toLocal()));

  /// Validates the typed values and, if they hold, stores the reading.
  ///
  /// Emits [SessionEntryEditing] with the failures if validation rejects the
  /// input, and [SessionEntrySaved] or [SessionEntrySaveFailed] once the write
  /// has been attempted. Does nothing while a write is already in flight.
  Future<void> save({
    required String systolic,
    required String diastolic,
    required String pulse,
    required String notes,
  }) async {
    if (state is SessionEntrySubmitting) {
      return;
    }

    final takenAt = state.takenAt;
    final input = ReadingInput(
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      notes: notes,
      takenAt: takenAt,
    );

    final validated = input.validate(_idGenerator, now: _now());
    if (validated case Err<Reading, List<ValidationFailure>>(:final error)) {
      emit(SessionEntryEditing(takenAt, failures: error));
      return;
    }

    final reading = (validated as Ok<Reading, List<ValidationFailure>>).value;
    emit(SessionEntrySubmitting(takenAt));

    final session = Session(
      id: SessionId(_idGenerator.newId()),
      readings: [reading],
    );
    final stored = await _repository.add(session);

    emit(switch (stored) {
      Ok() => SessionEntrySaved(takenAt),
      Err() => SessionEntrySaveFailed(takenAt),
    });
  }
}
