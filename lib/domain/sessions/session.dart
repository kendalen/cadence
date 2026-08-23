import 'package:equatable/equatable.dart';

import 'ids.dart';
import 'reading.dart';

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

  @override
  List<Object?> get props => [id, readings];
}
