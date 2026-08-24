import 'package:equatable/equatable.dart';

/// The mean of a session's readings.
///
/// The session — not the individual reading — is the unit of analysis
/// (CLAUDE.md §4), so its average is a value in its own right. [systolic] and
/// [diastolic] are the means of the readings' systolic and diastolic values,
/// each rounded to the nearest whole mmHg with a half rounding up. [pulse] is
/// the mean of only the readings that recorded a pulse, rounded the same way,
/// or `null` when no reading recorded one.
///
/// Derived, never stored (CLAUDE.md §4).
final class SessionAverage extends Equatable {
  /// Creates a session average from already-computed whole numbers.
  const SessionAverage({
    required this.systolic,
    required this.diastolic,
    this.pulse,
  });

  /// Mean systolic pressure, in mmHg.
  final int systolic;

  /// Mean diastolic pressure, in mmHg.
  final int diastolic;

  /// Mean pulse in beats per minute, or `null` when no reading recorded one.
  final int? pulse;

  @override
  List<Object?> get props => [systolic, diastolic, pulse];
}
