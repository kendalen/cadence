import 'package:equatable/equatable.dart';

import 'session.dart';
import 'session_average.dart';

/// How many occasions the 7-2-2 home-monitoring protocol expects in a week:
/// two a day (morning and evening) over seven days (CLAUDE.md §4).
const int expectedWeeklyOccasions = 14;

/// How many distinct days the 7-2-2 protocol spans — the "7" in 7-2-2.
const int expectedMonitoringDays = 7;

/// How well the last seven days keep to the 7-2-2 protocol (CLAUDE.md §4).
///
/// Coverage is a first-class output: it reports occasions *logged* against
/// occasions *expected*, so an average can be read against how much data backs
/// it. This is a diary's honesty about its own completeness — never a verdict
/// on the numbers (CLAUDE.md §1).
final class MonitoringCoverage extends Equatable {
  /// Creates a coverage report.
  const MonitoringCoverage({
    required this.occasionsLogged,
    required this.daysLogged,
    required this.periodAverage,
    this.occasionsExpected = expectedWeeklyOccasions,
    this.daysExpected = expectedMonitoringDays,
  });

  /// Occasions recorded within the window. The true count — not capped at
  /// [occasionsExpected] — so a user who logs more than the protocol asks sees
  /// it honestly.
  final int occasionsLogged;

  /// Occasions the protocol expects over the window ([expectedWeeklyOccasions]).
  final int occasionsExpected;

  /// Distinct calendar days within the window on which at least one occasion
  /// was recorded.
  ///
  /// A second dimension of coverage beside [occasionsLogged]: the 7-2-2 protocol
  /// wants readings *spread over* seven days, so nine occasions bunched into two
  /// days is not the same as nine across the week (CLAUDE.md §4).
  final int daysLogged;

  /// Days the protocol spans ([expectedMonitoringDays]).
  final int daysExpected;

  /// The mean of the in-window occasions' [Session.average]s, or `null` when no
  /// occasion falls in the window.
  ///
  /// Each occasion weighs equally regardless of how many readings it holds —
  /// the session, not the reading, is the unit of analysis (CLAUDE.md §4). Its
  /// meaning is always read alongside [occasionsLogged]: an average is never
  /// shown without the count of occasions behind it.
  final SessionAverage? periodAverage;

  @override
  List<Object?> get props => [
    occasionsLogged,
    occasionsExpected,
    daysLogged,
    daysExpected,
    periodAverage,
  ];
}

/// Coverage of the last seven days ending at [now], over [sessions].
///
/// "Last 7 days" means the local calendar day of [now] and the six days before
/// it — an occasion counts when its local date is on or after the start of that
/// window. Anchoring to local midnight (not a rolling 168-hour cutoff) keeps the
/// window exactly seven dates wide, so [MonitoringCoverage.daysLogged] can never
/// exceed seven — a rolling cutoff straddles eight calendar days when [now] is
/// mid-day (CLAUDE.md §4). [now] is supplied by the caller so this stays a pure
/// function. [toLocal] converts a stored UTC instant to the local time whose
/// calendar day it belongs to — injected so the window is testable regardless of
/// the machine's timezone; it defaults to [DateTime.toLocal].
MonitoringCoverage weeklyCoverage(
  List<Session> sessions, {
  required DateTime now,
  DateTime Function(DateTime)? toLocal,
}) {
  final toLocalDate = toLocal ?? (utc) => utc.toLocal();
  final today = toLocalDate(now);
  // Local midnight of the earliest day in the window. Building the date from
  // its parts (not subtracting a Duration) lands on midnight regardless of any
  // DST shift between then and today.
  final windowStart = DateTime(
    today.year,
    today.month,
    today.day - (expectedMonitoringDays - 1),
  );
  final inWindow = sessions
      .where(
        (session) => !_localDate(session, toLocalDate).isBefore(windowStart),
      )
      .toList();

  return MonitoringCoverage(
    occasionsLogged: inWindow.length,
    daysLogged: _distinctDays(inWindow, toLocalDate),
    periodAverage: inWindow.isEmpty ? null : _averageOf(inWindow),
  );
}

/// The local calendar day an occasion falls on, under [toLocal] — the shared
/// notion of "which day" used both to filter the window and to count days, so
/// the two never disagree.
DateTime _localDate(Session session, DateTime Function(DateTime) toLocal) {
  final local = toLocal(session.occurredAt);
  return DateTime(local.year, local.month, local.day);
}

/// How many distinct local calendar days [sessions] fall on, under [toLocal].
int _distinctDays(
  List<Session> sessions,
  DateTime Function(DateTime) toLocal,
) => sessions.map((session) => _localDate(session, toLocal)).toSet().length;

/// The mean of [sessions]' averages, each session weighing once (§4). Pulse is
/// meaned over only the sessions whose average recorded one, or `null` when
/// none did. Reuses [roundedMean] so it rounds as a single session's average.
SessionAverage _averageOf(List<Session> sessions) {
  final averages = sessions.map((session) => session.average);
  final pulses = averages.map((average) => average.pulse).whereType<int>();
  return SessionAverage(
    systolic: roundedMean(averages.map((average) => average.systolic)),
    diastolic: roundedMean(averages.map((average) => average.diastolic)),
    pulse: pulses.isEmpty ? null : roundedMean(pulses),
  );
}
