import '../core/result.dart';
import 'id_generator.dart';
import 'ids.dart';
import 'reading.dart';
import 'validation_failure.dart';

/// The raw, unvalidated values of the reading entry form.
///
/// [validate] is the only way to turn these into a [Reading], so an invalid
/// reading cannot be built by accident.
final class ReadingInput {
  /// Creates an input from the form's raw text and chosen moment.
  const ReadingInput({
    required this.systolic,
    required this.diastolic,
    required this.takenAt,
    this.pulse = '',
    this.notes = '',
  });

  /// Lowest accepted systolic or diastolic value, in mmHg.
  ///
  /// The pressure and pulse bounds are typo guards, not clinical thresholds:
  /// they reject only values no monitor could have shown. The app does not
  /// classify a reading (CLAUDE.md §4).
  static const int minPressure = 10;

  /// Highest accepted systolic or diastolic value, in mmHg.
  static const int maxPressure = 300;

  /// Lowest accepted pulse, in beats per minute.
  static const int minPulse = 20;

  /// Highest accepted pulse, in beats per minute.
  static const int maxPulse = 300;

  /// Systolic pressure as typed, in mmHg. Required.
  final String systolic;

  /// Diastolic pressure as typed, in mmHg. Required.
  final String diastolic;

  /// Pulse as typed, in beats per minute. Blank when the user left it out.
  final String pulse;

  /// Note as typed. Blank when the user wrote none.
  final String notes;

  /// The moment the user says the reading was taken, in any timezone.
  final DateTime takenAt;

  /// Validates these values and, if they hold, builds a [Reading].
  ///
  /// [now] is the moment a future [takenAt] is judged against; it is passed in
  /// so this stays a pure function. On success the reading carries a fresh id
  /// from [idGenerator], a UTC [Reading.takenAt], and `null` notes if the user
  /// wrote none. On failure it reports every failure found, not just the first,
  /// so the form can mark all the bad fields at once.
  Result<Reading, List<ValidationFailure>> validate(
    IdGenerator idGenerator, {
    required DateTime now,
  }) {
    final failures = <ValidationFailure>[];

    final systolicValue = _parseInt(
      systolic,
      ReadingField.systolic,
      min: minPressure,
      max: maxPressure,
      failures: failures,
    );
    // A systolic below the diastolic is deliberately not rejected: real
    // monitors occasionally report one, and refusing it would lose data.
    final diastolicValue = _parseInt(
      diastolic,
      ReadingField.diastolic,
      min: minPressure,
      max: maxPressure,
      failures: failures,
    );
    final pulseValue = pulse.trim().isEmpty
        ? null
        : _parseInt(
            pulse,
            ReadingField.pulse,
            min: minPulse,
            max: maxPulse,
            failures: failures,
          );

    if (takenAt.isAfter(now)) {
      failures.add(const TakenAtInFuture());
    }

    if (failures.isNotEmpty) {
      return Err(List.unmodifiable(failures));
    }

    final trimmedNotes = notes.trim();
    return Ok(
      Reading(
        id: ReadingId(idGenerator.newId()),
        systolic: systolicValue!,
        diastolic: diastolicValue!,
        pulse: pulseValue,
        takenAt: takenAt.toUtc(),
        notes: trimmedNotes.isEmpty ? null : trimmedNotes,
      ),
    );
  }

  /// Parses [raw] as an integer within [min]..[max] inclusive.
  ///
  /// Appends the reason to [failures] and returns `null` if it does not parse
  /// or falls outside the range.
  int? _parseInt(
    String raw,
    ReadingField field, {
    required int min,
    required int max,
    required List<ValidationFailure> failures,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      failures.add(ValueMissing(field));
      return null;
    }
    final value = int.tryParse(trimmed);
    if (value == null) {
      failures.add(ValueNotAnInteger(field));
      return null;
    }
    if (value < min || value > max) {
      failures.add(ValueOutOfRange(field, min: min, max: max));
      return null;
    }
    return value;
  }
}
