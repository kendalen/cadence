import 'reading.dart';
import 'session.dart';
import 'session_average.dart';

/// Which half of the day a measurement occasion falls in, split at local noon.
///
/// Home monitoring takes two occasions a day — morning and evening (§4) — so
/// history is bucketed the same way rather than by the hour, which would be too
/// data-sparse to average. Noon itself counts as [evening].
enum DayBucket {
  /// Before 12:00 local.
  morning,

  /// From 12:00 local onwards.
  evening;

  /// The bucket [localTime] falls in. [localTime] must already be in the user's
  /// local time; only its hour is read.
  static DayBucket ofLocalTime(DateTime localTime) =>
      localTime.hour < 12 ? DayBucket.morning : DayBucket.evening;
}

/// Turns a UTC instant into the user's local wall-clock time.
typedef ToLocal = DateTime Function(DateTime utc);

DateTime _systemToLocal(DateTime utc) => utc.toLocal();

/// A starting estimate for the first reading of a new occasion, drawn from the
/// user's own [history], or `null` when there is nothing to base one on.
///
/// The estimate is the mean of past session averages — the session is the unit
/// of analysis (§4), so a two-reading occasion counts once — taken over the
/// occasions in the same day-bucket as [now]. Readings cluster by time of day,
/// so the morning average is the better opening guess in the morning. When that
/// bucket holds no history, it falls back to the mean over all history; when
/// there is no history at all, it returns `null` and the caller supplies its
/// own neutral default.
///
/// It is a gentle nudge, not a norm or a target: the value shown is the user's
/// own data, editable before it is saved (§4).
///
/// Bucketing is by local wall clock — morning and evening only mean anything
/// there — so [toLocal] converts each occasion's UTC time before its hour is
/// read. It defaults to the system zone; tests inject it so they stay
/// timezone-independent. [now] is already local.
SessionAverage? suggestedFirstReading(
  Iterable<Session> history, {
  required DateTime now,
  ToLocal toLocal = _systemToLocal,
}) {
  final sessions = history.toList();
  if (sessions.isEmpty) {
    return null;
  }

  final target = DayBucket.ofLocalTime(now);
  final inBucket = sessions
      .where(
        (session) =>
            DayBucket.ofLocalTime(toLocal(session.occurredAt)) == target,
      )
      .toList();

  return _meanOfAverages(inBucket.isNotEmpty ? inBucket : sessions);
}

/// The mean of [sessions]' averages, pulse included only where it was recorded.
///
/// [sessions] must be non-empty.
SessionAverage _meanOfAverages(List<Session> sessions) {
  final averages = sessions.map((session) => session.average).toList();
  final pulses = averages.map((average) => average.pulse).whereType<int>();
  return SessionAverage(
    systolic: roundedMean(averages.map((average) => average.systolic)),
    diastolic: roundedMean(averages.map((average) => average.diastolic)),
    pulse: pulses.isEmpty ? null : roundedMean(pulses),
  );
}

/// The single most recently taken reading across [history], or `null` when
/// there is none.
///
/// Used to prefill a new occasion's context from what the user last actually
/// recorded — context is carried from a real reading, never averaged (§4).
Reading? mostRecentReading(Iterable<Session> history) {
  Reading? latest;
  for (final session in history) {
    for (final reading in session.readings) {
      if (latest == null || reading.takenAt.isAfter(latest.takenAt)) {
        latest = reading;
      }
    }
  }
  return latest;
}
