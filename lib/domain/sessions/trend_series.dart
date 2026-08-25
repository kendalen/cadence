import 'package:equatable/equatable.dart';

import 'first_reading_suggestion.dart';
import 'session.dart';
import 'session_average.dart';

/// How wide a time window a trend covers, ending today.
enum TrendRange {
  /// Last 7 days.
  week(7),

  /// Last 30 days.
  month(30),

  /// Last 90 days.
  quarter(90),

  /// The whole diary — no lower bound.
  all(null);

  const TrendRange(this.days);

  /// Days back from today the window spans, or `null` for unbounded.
  final int? days;
}

/// Which occasions feed a trend: all of them, or only one half of the day.
enum TimeOfDayFilter {
  /// All occasions.
  all,

  /// Morning occasions only.
  morning,

  /// Evening occasions only.
  evening,
}

/// One plotted point: a civil date and the mean blood pressure (and pulse,
/// when recorded) of the occasions in that point's time bucket.
///
/// [localDate] is a DST-free civil value; read its fields for the axis — do not
/// convert it with `toLocal` again. For a bucketed point it is a date at
/// midnight (`DateTime.utc(y, m, d)`); for a per-occasion point (the 7-day view)
/// it also carries the occasion's hour/minute so same-day occasions separate.
final class TrendPoint extends Equatable {
  /// Creates a trend point.
  const TrendPoint({
    required this.localDate,
    required this.systolic,
    required this.diastolic,
    required this.occasionCount,
    this.pulse,
  });

  /// The point's position on the time axis, as a DST-free civil value: a date
  /// at midnight for a bucketed point, or the occasion's local time for a
  /// per-occasion point (see the class doc).
  final DateTime localDate;

  /// Mean systolic pressure of the bucket, in mmHg.
  final int systolic;

  /// Mean diastolic pressure of the bucket, in mmHg.
  final int diastolic;

  /// Mean pulse of the bucket in bpm, or `null` when no occasion recorded one.
  final int? pulse;

  /// How many occasions this point averages — labels the tooltip so an averaged
  /// dot is never read as a single reading (CLAUDE.md §4).
  final int occasionCount;

  @override
  List<Object?> get props => [
    localDate,
    systolic,
    diastolic,
    pulse,
    occasionCount,
  ];
}

/// The full series a chart draws: a per-day scatter and an adaptive averaged
/// line. The two are identical when the data span is one bucket wide.
final class TrendSeries extends Equatable {
  /// Creates a trend series.
  const TrendSeries({
    required this.daily,
    required this.averaged,
    required this.bucketSize,
  });

  /// One point per calendar day — the faint scatter.
  final List<TrendPoint> daily;

  /// Adaptive-bucket points — the bold line. Equals [daily] when [bucketSize]
  /// is one day.
  final List<TrendPoint> averaged;

  /// How wide each [averaged] bucket is (1, 7, or 30 days), or [Duration.zero]
  /// when points are per occasion rather than bucketed (the 7-day view).
  final Duration bucketSize;

  @override
  List<Object?> get props => [daily, averaged, bucketSize];
}

/// Turns [sessions] into a [TrendSeries] for [range] and [filter], as of [now].
///
/// Every point is a mean of [Session.average]s (session-as-unit, §4), never of
/// raw readings. Day logic runs through [toLocal] (defaulting to
/// [DateTime.toLocal]) so it is timezone-independent; dates are normalised to
/// civil `DateTime.utc` values so counting days is DST-proof.
TrendSeries buildTrendSeries(
  List<Session> sessions, {
  required TrendRange range,
  required TimeOfDayFilter filter,
  required DateTime now,
  DateTime Function(DateTime)? toLocal,
}) {
  final toLocalTime = toLocal ?? (utc) => utc.toLocal();

  final today = _civilDate(toLocalTime(now));
  final days = range.days;
  final windowStart = days == null
      ? null
      : DateTime.utc(today.year, today.month, today.day - (days - 1));

  final byTimeOfDay = sessions.where(
    (session) => _matchesFilter(session, filter, toLocalTime),
  );

  final inWindow = byTimeOfDay
      .where(
        (session) =>
            windowStart == null ||
            !_localDate(session, toLocalTime).isBefore(windowStart),
      )
      .toList();

  // The 7-day view shows every occasion as its own point rather than a daily
  // mean: over a week the morning/evening split (the 7-2-2 protocol's two
  // occasions a day, §4) is the whole point, and collapsing to one point per day
  // would hide it. Points sit at their local time so same-day occasions
  // separate on the axis. A zero bucket flags "per occasion" to the chart.
  if (range == TrendRange.week) {
    final perOccasion = _pointsPerOccasion(inWindow, toLocalTime);
    return TrendSeries(
      daily: perOccasion,
      averaged: perOccasion,
      bucketSize: Duration.zero,
    );
  }

  final daily = _pointsByBucket(inWindow, toLocalTime, bucketDays: 1);

  final bucketDays = _bucketDaysForSpan(inWindow, toLocalTime, now);
  final averaged = bucketDays == 1
      ? daily
      : _pointsByBucket(
          inWindow,
          toLocalTime,
          bucketDays: bucketDays,
          anchor: windowStart,
        );

  return TrendSeries(
    daily: daily,
    averaged: averaged,
    bucketSize: Duration(days: bucketDays),
  );
}

/// One point per occasion, at its local time so occasions on the same day
/// separate on the axis (the 7-day view). Each point is a single
/// [Session.average] (session-as-unit, §4), never a cross-occasion mean.
/// Returned in time order.
List<TrendPoint> _pointsPerOccasion(
  List<Session> sessions,
  DateTime Function(DateTime) toLocal,
) {
  final sorted = [...sessions]
    ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  return [
    for (final session in sorted)
      _occasionPoint(_civilDateTime(toLocal(session.occurredAt)), session),
  ];
}

/// A single occasion's point at civil-local [at], carrying its [Session.average]
/// as-is (occasionCount 1).
TrendPoint _occasionPoint(DateTime at, Session session) {
  final average = session.average;
  return TrendPoint(
    localDate: at,
    systolic: average.systolic,
    diastolic: average.diastolic,
    pulse: average.pulse,
    occasionCount: 1,
  );
}

/// The civil calendar date (no time, no DST) of [local].
DateTime _civilDate(DateTime local) =>
    DateTime.utc(local.year, local.month, local.day);

/// [local] as a DST-free civil date-time — keeps the hour/minute so per-occasion
/// points on the same day sit apart on the axis, without a timezone offset.
DateTime _civilDateTime(DateTime local) =>
    DateTime.utc(local.year, local.month, local.day, local.hour, local.minute);

/// The civil date an occasion falls on, under [toLocal].
DateTime _localDate(Session session, DateTime Function(DateTime) toLocal) =>
    _civilDate(toLocal(session.occurredAt));

/// Groups [sessions] into consecutive [bucketDays]-wide buckets and averages
/// each into a [TrendPoint]. Buckets are anchored at [anchor], or the earliest
/// occasion's date when [anchor] is null. Returns date-sorted points.
List<TrendPoint> _pointsByBucket(
  List<Session> sessions,
  DateTime Function(DateTime) toLocal, {
  required int bucketDays,
  DateTime? anchor,
}) {
  if (sessions.isEmpty) return const [];

  final anchorDate =
      anchor ??
      sessions
          .map((session) => _localDate(session, toLocal))
          .reduce((a, b) => a.isBefore(b) ? a : b);

  final groups = <DateTime, List<Session>>{};
  for (final session in sessions) {
    final date = _localDate(session, toLocal);
    final index = date.difference(anchorDate).inDays ~/ bucketDays;
    final bucketDate = DateTime.utc(
      anchorDate.year,
      anchorDate.month,
      anchorDate.day + index * bucketDays,
    );
    (groups[bucketDate] ??= []).add(session);
  }

  final dates = groups.keys.toList()..sort();
  return [for (final date in dates) _pointOf(date, groups[date]!)];
}

/// One point at [date] from [sessions]: the mean of their [Session.average]s.
/// Pulse means only the occasions that recorded one (§4), like coverage's.
TrendPoint _pointOf(DateTime date, List<Session> sessions) {
  final averages = sessions.map((session) => session.average).toList();
  final pulses = averages.map((average) => average.pulse).whereType<int>();
  return TrendPoint(
    localDate: date,
    systolic: roundedMean(averages.map((average) => average.systolic)),
    diastolic: roundedMean(averages.map((average) => average.diastolic)),
    pulse: pulses.isEmpty ? null : roundedMean(pulses),
    occasionCount: sessions.length,
  );
}

/// Whether [session] belongs in [filter], by the local-noon [DayBucket] of its
/// start. Reuses the one split rule the app already uses (§8, no second way).
bool _matchesFilter(
  Session session,
  TimeOfDayFilter filter,
  DateTime Function(DateTime) toLocal,
) {
  switch (filter) {
    case TimeOfDayFilter.all:
      return true;
    case TimeOfDayFilter.morning:
      return DayBucket.ofLocalTime(toLocal(session.occurredAt)) ==
          DayBucket.morning;
    case TimeOfDayFilter.evening:
      return DayBucket.ofLocalTime(toLocal(session.occurredAt)) ==
          DayBucket.evening;
  }
}

/// The averaged-bucket width for [sessions]' actual span (oldest occasion to
/// [now]): daily up to 30 days, 7-day up to 90, else 30-day. Keyed off the data,
/// not the chosen range, so "All" with little history still shows daily points.
int _bucketDaysForSpan(
  List<Session> sessions,
  DateTime Function(DateTime) toLocal,
  DateTime now,
) {
  if (sessions.isEmpty) return 1;
  final oldest = sessions
      .map((session) => _localDate(session, toLocal))
      .reduce((a, b) => a.isBefore(b) ? a : b);
  final spanDays = _civilDate(toLocal(now)).difference(oldest).inDays;
  if (spanDays <= 30) return 1;
  if (spanDays <= 90) return 7;
  return 30;
}
