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
  ///
  /// Throws [ArgumentError] if [readings] is empty: the session is the unit of
  /// analysis and always holds at least one reading (CLAUDE.md §4). The list is
  /// copied and held unmodifiable, so the invariant cannot be broken after
  /// construction — unlike an `assert`, this holds in release builds too.
  Session({required this.id, required List<Reading> readings})
    : readings = List.unmodifiable(readings) {
    if (this.readings.isEmpty) {
      throw ArgumentError.value(
        readings,
        'readings',
        'a session holds at least one reading',
      );
    }
  }

  /// Identity of this session.
  final SessionId id;

  /// The readings taken on this occasion, in the order they were taken. The
  /// list is unmodifiable.
  final List<Reading> readings;

  /// This session's [readings] ordered by [Reading.takenAt], earliest first.
  ///
  /// A new list; [readings] is left untouched. Storage does not guarantee the
  /// order readings are read back in, so ordering for display is done here, in
  /// one tested place.
  List<Reading> get readingsByTime =>
      [...readings]..sort((a, b) => a.takenAt.compareTo(b.takenAt));

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
      systolic: roundedMean(readings.map((reading) => reading.systolic)),
      diastolic: roundedMean(readings.map((reading) => reading.diastolic)),
      pulse: pulses.isEmpty ? null : roundedMean(pulses),
    );
  }

  /// This session with the reading sharing [replacement]'s id swapped for
  /// [replacement], every other reading and the order kept.
  ///
  /// The match is by [Reading.id]: editing changes a reading's values, never
  /// its identity (see [Reading.withId]). Throws [StateError] if no reading has
  /// that id — replacing a reading the session does not hold is a bug, not an
  /// expected outcome.
  Session withReadingReplaced(Reading replacement) {
    if (!readings.any((reading) => reading.id == replacement.id)) {
      throw StateError('no reading ${replacement.id.value} in session');
    }
    return Session(
      id: id,
      readings: readings
          .map(
            (reading) => reading.id == replacement.id ? replacement : reading,
          )
          .toList(),
    );
  }

  /// This session with [reading] appended to its readings, everything else
  /// kept.
  ///
  /// Used to add a reading to an occasion after it was first saved — e.g. the
  /// second reading of a pair the user meant to log but saved too soon.
  Session withReadingAdded(Reading reading) =>
      Session(id: id, readings: [...readings, reading]);

  /// This session without the reading identified by [id], or `null` when that
  /// was its only reading.
  ///
  /// A session always holds at least one reading (CLAUDE.md §4), so removing the
  /// last one is not an empty session but the removal of the occasion itself —
  /// signalled by `null` so the caller deletes it instead. Removing an id the
  /// session does not hold returns it unchanged.
  Session? withoutReading(ReadingId id) {
    final kept = readings.where((reading) => reading.id != id).toList();
    if (kept.isEmpty) {
      return null;
    }
    return Session(id: this.id, readings: kept);
  }

  @override
  List<Object?> get props => [id, readings];
}
