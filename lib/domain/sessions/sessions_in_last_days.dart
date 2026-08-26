import 'date_window.dart';
import 'session.dart';

/// The sessions whose local calendar day falls within the last [days] days
/// ending at [now] — the day of [now] and the [days] − 1 days before it.
///
/// Used to bound a readings export to a recent window (e.g. "Last 30 days") so a
/// clinician is handed only the period of interest. The window is the shared
/// [DateWindow.lastDays] — the same "which day" notion coverage and trends use
/// (CLAUDE.md §8), bounded at both ends so a future-dated session cannot slip in.
///
/// [days] must be positive. [now] is supplied by the caller so this stays a pure
/// function. [toLocal] converts a stored UTC instant to the local time whose
/// calendar day it belongs to; it is injected so the window is testable
/// regardless of the machine's timezone, defaulting to [DateTime.toLocal]. Input
/// order is preserved.
List<Session> sessionsInLastDays(
  List<Session> sessions, {
  required int days,
  required DateTime now,
  DateTime Function(DateTime)? toLocal,
}) {
  final toLocalDate = toLocal ?? (utc) => utc.toLocal();
  final window = DateWindow.lastDays(days, now, toLocalDate);
  return sessions
      .where((session) => window.contains(session.occurredAt, toLocalDate))
      .toList();
}
