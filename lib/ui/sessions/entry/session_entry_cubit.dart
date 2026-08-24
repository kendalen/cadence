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

/// Drives the entry form: build up an occasion of one or more readings, then
/// store it as a single session.
///
/// Readings are validated one at a time and banked in the state; saving writes
/// the banked readings plus the reading currently in the form, if one has been
/// started.
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

  /// Records the moment picked in the date and time pickers, keeping any
  /// readings already banked and clearing failures shown for the old form.
  void takenAtChanged(DateTime takenAt) => emit(
    SessionEntryEditing(
      takenAt.toLocal(),
      bankedReadings: state.bankedReadings,
    ),
  );

  /// Validates the typed values and banks the reading for this occasion.
  ///
  /// On valid input the reading joins [SessionEntryState.bankedReadings], the
  /// form is cleared of errors, and the moment resets to one minute after the
  /// banked reading — but never past [now], so the prefilled time is never
  /// already in the future. On invalid input nothing is banked and the
  /// failures are reported so the form can mark the bad fields.
  void addReading({
    required String systolic,
    required String diastolic,
    required String pulse,
    required String notes,
  }) {
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
      emit(
        SessionEntryEditing(
          takenAt,
          bankedReadings: state.bankedReadings,
          failures: error,
        ),
      );
      return;
    }

    final reading = (validated as Ok<Reading, List<ValidationFailure>>).value;
    final nextMoment = takenAt.add(const Duration(minutes: 1));
    final clockNow = _now();
    emit(
      SessionEntryEditing(
        nextMoment.isAfter(clockNow) ? clockNow : nextMoment,
        bankedReadings: [...state.bankedReadings, reading],
      ),
    );
  }

  /// Drops the banked reading with [id] from this occasion.
  ///
  /// Used to correct a reading banked by mistake before the occasion is saved;
  /// editing or deleting an already-stored reading is a separate concern.
  void removeBankedReading(ReadingId id) => emit(
    SessionEntryEditing(
      state.takenAt,
      bankedReadings: state.bankedReadings
          .where((reading) => reading.id != id)
          .toList(),
    ),
  );

  /// Validates and writes the occasion: the banked readings plus the reading
  /// currently in the form, if one has been started.
  ///
  /// The form is "started" when a systolic or diastolic has been typed; a
  /// started form is validated and included, so logging a single reading stays
  /// one action (fill, save). Emits [SessionEntryEditing] with failures if a
  /// started form is invalid or there is nothing to save; [SessionEntrySaved]
  /// or [SessionEntrySaveFailed] once the write has been attempted. Does
  /// nothing while a write is already in flight.
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
    final banked = state.bankedReadings;
    final started = systolic.trim().isNotEmpty || diastolic.trim().isNotEmpty;

    final readings = [...banked];
    if (started || banked.isEmpty) {
      final input = ReadingInput(
        systolic: systolic,
        diastolic: diastolic,
        pulse: pulse,
        notes: notes,
        takenAt: takenAt,
      );
      final validated = input.validate(_idGenerator, now: _now());
      if (validated case Err<Reading, List<ValidationFailure>>(:final error)) {
        emit(
          SessionEntryEditing(takenAt, bankedReadings: banked, failures: error),
        );
        return;
      }
      readings.add((validated as Ok<Reading, List<ValidationFailure>>).value);
    }

    emit(SessionEntrySubmitting(takenAt, bankedReadings: banked));

    final session = Session(
      id: SessionId(_idGenerator.newId()),
      readings: readings,
    );
    final stored = await _repository.add(session);

    emit(switch (stored) {
      Ok() => SessionEntrySaved(takenAt),
      Err() => SessionEntrySaveFailed(takenAt, bankedReadings: banked),
    });
  }
}
