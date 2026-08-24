import 'package:equatable/equatable.dart';

import 'ids.dart';
import 'reading.dart';
import 'session_average.dart';

/// One measurement occasion, holding the readings taken on it.
///
/// The session — not the individual reading — is the unit of analysis
/// (CLAUDE.md §4). It always holds at least one reading.
final class Session extends Equatable {
  /// Creates a session from a non-empty list of [readings].
  const Session({required this.id, required this.readings})
    : assert(readings.length > 0, 'a session holds at least one reading');

  /// Identity of this session.
  final SessionId id;

  /// The readings taken on this occasion, in the order they were taken.
  final List<Reading> readings;

  /// When the occasion started: the earliest [Reading.takenAt], in UTC.
  ///
  /// Derived, never stored (CLAUDE.md §4).
  DateTime get occurredAt => readings
      .map((reading) => reading.takenAt)
      .reduce((earliest, other) => other.isBefore(earliest) ? other : earliest);

  /// The mean of this session's [readings] (CLAUDE.md §4).
  ///
  /// Systolic and diastolic are averaged separately, each rounded to the
  /// nearest whole mmHg with a half rounding up. Pulse is the mean of only the
  /// readings that recorded one — rounded the same way — or `null` when none
  /// did. Derived, never stored.
  SessionAverage get average {
    final pulses = readings.map((reading) => reading.pulse).whereType<int>();
    return SessionAverage(
      systolic: _meanRounded(readings.map((reading) => reading.systolic)),
      diastolic: _meanRounded(readings.map((reading) => reading.diastolic)),
      pulse: pulses.isEmpty ? null : _meanRounded(pulses),
    );
  }

  /// Mean of [values], rounded to the nearest whole number with a half rounding
  /// up. [values] must be non-empty.
  ///
  /// `double.round()` rounds a half away from zero; every value here is a
  /// positive measurement, so that is "half up".
  static int _meanRounded(Iterable<int> values) {
    final list = values.toList();
    final sum = list.reduce((total, value) => total + value);
    return (sum / list.length).round();
  }

  @override
  List<Object?> get props => [id, readings];
}
