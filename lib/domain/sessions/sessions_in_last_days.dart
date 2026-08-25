import 'session.dart';

/// The sessions whose local calendar day falls within the last [days] days
/// ending at [now] — the day of [now] and the [days] − 1 days before it.
///
/// Used to bound a readings export to a recent window (e.g. "Last 30 days") so a
/// clinician is handed only the period of interest. "Last N days" means N
/// calendar dates, the same meaning the coverage card's window uses, so there is
/// one notion of "which day" across the app (CLAUDE.md §8) — not a rolling
/// N × 24-hour cutoff, which straddles N + 1 dates when [now] is mid-day.
///
/// [now] is supplied by the caller so this stays a pure function. [toLocal]
/// converts a stored UTC instant to the local time whose calendar day it belongs
/// to; it is injected so the window is testable regardless of the machine's
/// timezone, defaulting to [DateTime.toLocal]. Input order is preserved.
List<Session> sessionsInLastDays(
  List<Session> sessions, {
  required int days,
  required DateTime now,
  DateTime Function(DateTime)? toLocal,
}) {
  final toLocalDate = toLocal ?? (utc) => utc.toLocal();
  final today = toLocalDate(now);
  // Local midnight of the earliest day in the window. Building the date from its
  // parts (not subtracting a Duration) lands on midnight regardless of any DST
  // shift between then and today.
  final windowStart = DateTime(today.year, today.month, today.day - (days - 1));
  return sessions.where((session) {
    final local = toLocalDate(session.occurredAt);
    final date = DateTime(local.year, local.month, local.day);
    return !date.isBefore(windowStart);
  }).toList();
}
