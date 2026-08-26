/// The civil (midnight, DST-free) local calendar date [instant] falls on, under
/// [toLocal].
///
/// A `DateTime.utc` at midnight, so day arithmetic and comparison are exact
/// regardless of any daylight-saving shift. [toLocal] converts a stored UTC
/// instant to the local time whose calendar day it belongs to.
DateTime civilLocalDate(DateTime instant, DateTime Function(DateTime) toLocal) {
  final local = toLocal(instant);
  return DateTime.utc(local.year, local.month, local.day);
}

/// An inclusive window of local calendar dates, ending on "today".
///
/// The one shared notion of "the last N days" across coverage, ranged export,
/// and trends (CLAUDE.md §8) — with both a lower **and** an upper bound. The
/// upper bound matters: a session dated in the future (which can enter through
/// the tolerant backup import, §5) must not stretch the window past today, or
/// coverage could exceed its own span and a "last 30 days" export could leak a
/// tomorrow-dated reading.
///
/// Dates are civil (midnight, DST-free) values from [civilLocalDate].
class DateWindow {
  const DateWindow._(this.start, this.end);

  /// Midnight of the earliest date in the window (inclusive), or `null` for an
  /// open start — every past date up to and including [end] ("all time").
  final DateTime? start;

  /// Midnight of the latest date in the window (inclusive): the local day of the
  /// `now` it was built from. Dates after this are excluded.
  final DateTime end;

  /// The window of the [days] calendar dates ending on the local day of [now]:
  /// that day and the [days] − 1 days before it.
  ///
  /// [days] must be positive; a zero or negative window has no meaning and is a
  /// caller bug, so it throws rather than silently returning nothing.
  factory DateWindow.lastDays(
    int days,
    DateTime now,
    DateTime Function(DateTime) toLocal,
  ) {
    if (days < 1) {
      throw ArgumentError.value(days, 'days', 'must be positive');
    }
    final today = civilLocalDate(now, toLocal);
    final start = DateTime.utc(today.year, today.month, today.day - (days - 1));
    return DateWindow._(start, today);
  }

  /// A window with an open start ending on the local day of [now]: every date up
  /// to and including today, still excluding the future ("all time").
  factory DateWindow.upToToday(
    DateTime now,
    DateTime Function(DateTime) toLocal,
  ) => DateWindow._(null, civilLocalDate(now, toLocal));

  /// Whether the local calendar date of [instant] falls within this window —
  /// on or after [start] (when bounded) and on or before [end].
  bool contains(DateTime instant, DateTime Function(DateTime) toLocal) {
    final date = civilLocalDate(instant, toLocal);
    if (start != null && date.isBefore(start!)) {
      return false;
    }
    return !date.isAfter(end);
  }
}
