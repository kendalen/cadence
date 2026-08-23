import 'package:equatable/equatable.dart';

/// The field of the entry form a [ValidationFailure] refers to.
enum ReadingField {
  /// Systolic pressure, in mmHg.
  systolic,

  /// Diastolic pressure, in mmHg.
  diastolic,

  /// Pulse, in beats per minute.
  pulse,

  /// The moment the reading was taken.
  takenAt,
}

/// A reason a typed-in reading could not be accepted.
///
/// Every failure names the [field] it belongs to, so the form can show it in
/// place. These are input-quality failures only: the app never judges a reading
/// clinically (CLAUDE.md §4).
sealed class ValidationFailure extends Equatable {
  /// Base constructor recording the [field] the failure belongs to.
  const ValidationFailure(this.field);

  /// The form field this failure belongs to.
  final ReadingField field;
}

/// A required field was left blank.
final class ValueMissing extends ValidationFailure {
  /// Reports that [field] is required but empty.
  const ValueMissing(super.field);

  @override
  List<Object?> get props => [field];
}

/// The text in a field is not a whole number.
final class ValueNotAnInteger extends ValidationFailure {
  /// Reports that [field] does not parse as an integer.
  const ValueNotAnInteger(super.field);

  @override
  List<Object?> get props => [field];
}

/// The number in a field lies outside the range a monitor could report.
///
/// The bounds are typo guards, not clinical thresholds.
final class ValueOutOfRange extends ValidationFailure {
  /// Reports that [field] must lie between [min] and [max], inclusive.
  const ValueOutOfRange(super.field, {required this.min, required this.max});

  /// Lowest accepted value, inclusive.
  final int min;

  /// Highest accepted value, inclusive.
  final int max;

  @override
  List<Object?> get props => [field, min, max];
}

/// The chosen moment lies in the future.
final class TakenAtInFuture extends ValidationFailure {
  /// Reports that a reading cannot have been taken in the future.
  const TakenAtInFuture() : super(ReadingField.takenAt);

  @override
  List<Object?> get props => [field];
}
