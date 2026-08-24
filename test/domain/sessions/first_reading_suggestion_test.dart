import 'package:cadence/domain/sessions/first_reading_suggestion.dart';
import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/session.dart';
import 'package:cadence/domain/sessions/session_average.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps every generated reading id distinct without the tests having to name
/// them; identity does not matter to any function under test.
int _seq = 0;

Reading readingOf({
  int systolic = 120,
  int diastolic = 80,
  int? pulse,
  required DateTime takenAt,
}) => Reading(
  id: ReadingId('r${_seq++}'),
  systolic: systolic,
  diastolic: diastolic,
  pulse: pulse,
  takenAt: takenAt,
);

Session sessionOf(List<Reading> readings) =>
    Session(id: SessionId('s${_seq++}'), readings: readings);

/// A one-reading occasion, the common shape in these tests.
Session occasion({
  int systolic = 120,
  int diastolic = 80,
  int? pulse,
  required DateTime takenAt,
}) => sessionOf([
  readingOf(
    systolic: systolic,
    diastolic: diastolic,
    pulse: pulse,
    takenAt: takenAt,
  ),
]);

/// Bucketing uses only the hour, so a converter that leaves UTC untouched lets
/// a test drive the bucket straight from the times it picks.
DateTime identity(DateTime utc) => utc;

void main() {
  // Local wall-clock "now"; only its hour is read, to pick the day bucket.
  final morningNow = DateTime(2026, 8, 24, 8);
  final eveningNow = DateTime(2026, 8, 24, 20);

  // UTC occasion times, deterministically bucketed under [identity].
  final morningUtc = DateTime.utc(2026, 8, 23, 7);
  final eveningUtc = DateTime.utc(2026, 8, 23, 19);

  group('DayBucket.ofLocalTime', () {
    test('is morning just before noon', () {
      expect(
        DayBucket.ofLocalTime(DateTime(2026, 8, 24, 11, 59)),
        DayBucket.morning,
      );
    });

    test('is evening at noon exactly', () {
      expect(
        DayBucket.ofLocalTime(DateTime(2026, 8, 24, 12)),
        DayBucket.evening,
      );
    });
  });

  group('suggestedFirstReading', () {
    test('is null when there is no history', () {
      expect(
        suggestedFirstReading(const [], now: morningNow, toLocal: identity),
        isNull,
      );
    });

    test('is the mean of the current bucket, rounding a half up', () {
      // Two morning occasions: 128 & 131 -> 129.5 -> 130; 80 & 83 -> 81.5 -> 82.
      final history = [
        occasion(systolic: 128, diastolic: 80, takenAt: morningUtc),
        occasion(systolic: 131, diastolic: 83, takenAt: morningUtc),
      ];

      expect(
        suggestedFirstReading(history, now: morningNow, toLocal: identity),
        const SessionAverage(systolic: 130, diastolic: 82),
      );
    });

    test('uses only occasions in the same bucket as now', () {
      final history = [
        occasion(systolic: 120, diastolic: 80, takenAt: morningUtc),
        occasion(systolic: 140, diastolic: 90, takenAt: eveningUtc),
      ];

      expect(
        suggestedFirstReading(history, now: morningNow, toLocal: identity),
        const SessionAverage(systolic: 120, diastolic: 80),
      );
    });

    test('falls back to all history when the current bucket is empty', () {
      // Only morning history, but it is evening now: use the overall mean
      // rather than nothing.
      final history = [
        occasion(systolic: 120, diastolic: 80, takenAt: morningUtc),
        occasion(systolic: 140, diastolic: 90, takenAt: morningUtc),
      ];

      expect(
        suggestedFirstReading(history, now: eveningNow, toLocal: identity),
        const SessionAverage(systolic: 130, diastolic: 85),
      );
    });

    test('means each occasion once, not each reading', () {
      // Session-as-unit (§4): a two-reading occasion averaging 120 weighs the
      // same as a one-reading occasion of 180 -> (120 + 180) / 2 = 150, not the
      // per-reading (120 + 120 + 180) / 3 = 140.
      final history = [
        sessionOf([
          readingOf(systolic: 120, takenAt: morningUtc),
          readingOf(systolic: 120, takenAt: morningUtc),
        ]),
        occasion(systolic: 180, takenAt: morningUtc),
      ];

      expect(
        suggestedFirstReading(
          history,
          now: morningNow,
          toLocal: identity,
        )!.systolic,
        150,
      );
    });

    test('means the pulse only over occasions that recorded one', () {
      final history = [
        occasion(pulse: 60, takenAt: morningUtc),
        occasion(takenAt: morningUtc),
      ];

      expect(
        suggestedFirstReading(
          history,
          now: morningNow,
          toLocal: identity,
        )!.pulse,
        60,
      );
    });

    test('has no pulse when no occasion recorded one', () {
      final history = [
        occasion(takenAt: morningUtc),
        occasion(takenAt: morningUtc),
      ];

      expect(
        suggestedFirstReading(
          history,
          now: morningNow,
          toLocal: identity,
        )!.pulse,
        isNull,
      );
    });

    test('buckets by local wall clock, not by UTC', () {
      // A late-UTC and an early-UTC occasion. Under [identity] the late one is
      // evening and only the early one is morning; shift +2h and both land in
      // the morning, changing the answer. Proves the converter drives bucketing.
      final lateUtc = DateTime.utc(2026, 8, 23, 23, 30); // +2h -> 01:30 local
      final earlyUtc = DateTime.utc(2026, 8, 23, 6); // +2h -> 08:00 local
      final history = [
        occasion(systolic: 110, diastolic: 70, takenAt: lateUtc),
        occasion(systolic: 150, diastolic: 94, takenAt: earlyUtc),
      ];
      DateTime plusTwo(DateTime utc) => utc.add(const Duration(hours: 2));

      // Identity: morning bucket is just the early occasion.
      expect(
        suggestedFirstReading(history, now: morningNow, toLocal: identity),
        const SessionAverage(systolic: 150, diastolic: 94),
      );
      // +2h: both are morning -> 110 & 150 -> 130; 70 & 94 -> 82.
      expect(
        suggestedFirstReading(history, now: morningNow, toLocal: plusTwo),
        const SessionAverage(systolic: 130, diastolic: 82),
      );
    });
  });

  group('suggestedFirstReading recency window', () {
    // now as UTC so the 14-day cutoff is exact regardless of the test
    // machine's timezone; under [identity] its hour (08 -> morning) also
    // drives the bucket.
    final nowUtc = DateTime.utc(2026, 8, 24, 8);

    Session morningDaysAgo(
      int days, {
      int systolic = 120,
      int diastolic = 80,
    }) => occasion(
      systolic: systolic,
      diastolic: diastolic,
      takenAt: nowUtc.subtract(Duration(days: days)),
    );

    test('averages only occasions within the last 14 days', () {
      // Recent 140/90 vs a month-old 120/80: an all-time mean would be 130/85,
      // so returning 140/90 proves the old occasion is excluded.
      final history = [
        morningDaysAgo(5, systolic: 140, diastolic: 90),
        morningDaysAgo(30, systolic: 120, diastolic: 80),
      ];

      expect(
        suggestedFirstReading(history, now: nowUtc, toLocal: identity),
        const SessionAverage(systolic: 140, diastolic: 90),
      );
    });

    test('includes an occasion exactly 14 days old', () {
      // The window boundary is inclusive.
      final history = [morningDaysAgo(14, systolic: 134, diastolic: 86)];

      expect(
        suggestedFirstReading(history, now: nowUtc, toLocal: identity),
        const SessionAverage(systolic: 134, diastolic: 86),
      );
    });

    test('prefers older same-bucket history over recent other-bucket', () {
      // Nothing recent in the morning bucket: an old morning occasion is a
      // better guess for a morning reading than a recent evening one, because
      // time of day drives the value.
      final oldMorning = DateTime.utc(2026, 7, 20, 7); // ~35 days ago, morning
      final recentEvening = DateTime.utc(
        2026,
        8,
        22,
        20,
      ); // 2 days ago, evening
      final history = [
        occasion(systolic: 118, diastolic: 78, takenAt: oldMorning),
        occasion(systolic: 150, diastolic: 95, takenAt: recentEvening),
      ];

      expect(
        suggestedFirstReading(history, now: nowUtc, toLocal: identity),
        const SessionAverage(systolic: 118, diastolic: 78),
      );
    });
  });

  group('mostRecentReading', () {
    test('is null when there is no history', () {
      expect(mostRecentReading(const []), isNull);
    });

    test('is the reading with the latest takenAt, across all occasions', () {
      final latest = readingOf(takenAt: DateTime.utc(2026, 8, 23, 19));
      final history = [
        sessionOf([readingOf(takenAt: DateTime.utc(2026, 8, 23, 7)), latest]),
        occasion(takenAt: DateTime.utc(2026, 8, 22, 20)),
      ];

      expect(mostRecentReading(history), latest);
    });
  });
}
