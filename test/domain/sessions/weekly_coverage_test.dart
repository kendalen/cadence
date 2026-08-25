import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/session.dart';
import 'package:cadence/domain/sessions/session_average.dart';
import 'package:cadence/domain/sessions/weekly_coverage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps every generated id distinct without the tests having to name them;
/// identity does not matter to any function under test.
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

void main() {
  // "now" as UTC so the 7-day cutoff is exact regardless of the test machine's
  // timezone.
  final nowUtc = DateTime.utc(2026, 8, 24, 8);

  Session daysAgo(
    int days, {
    int systolic = 120,
    int diastolic = 80,
    int? pulse,
  }) => occasion(
    systolic: systolic,
    diastolic: diastolic,
    pulse: pulse,
    takenAt: nowUtc.subtract(Duration(days: days)),
  );

  // Bucket local dates straight from UTC so the day-grouping tests are
  // timezone-independent (same trick as the first-reading suggestion tests).
  DateTime identity(DateTime utc) => utc;

  group('weeklyCoverage', () {
    test('expects 14 occasions — the 7-2-2 shape, 2 a day over 7 days', () {
      expect(expectedWeeklyOccasions, 14);
      expect(weeklyCoverage(const [], now: nowUtc).occasionsExpected, 14);
    });

    test('expects 7 days — the 7-2-2 span', () {
      expect(expectedMonitoringDays, 7);
      expect(weeklyCoverage(const [], now: nowUtc).daysExpected, 7);
    });

    test('is empty with no history', () {
      final coverage = weeklyCoverage(const [], now: nowUtc);
      expect(coverage.occasionsLogged, 0);
      expect(coverage.periodAverage, isNull);
    });

    test('counts occasions logged in the last 7 days', () {
      final history = [daysAgo(1), daysAgo(3), daysAgo(6)];
      expect(weeklyCoverage(history, now: nowUtc).occasionsLogged, 3);
    });

    test('excludes occasions older than 7 days', () {
      final history = [daysAgo(1), daysAgo(8), daysAgo(30)];
      expect(weeklyCoverage(history, now: nowUtc).occasionsLogged, 1);
    });

    test('includes an occasion exactly 7 days old (inclusive boundary)', () {
      expect(weeklyCoverage([daysAgo(7)], now: nowUtc).occasionsLogged, 1);
    });

    test(
      'averages the in-window occasions, session-as-unit not per-reading',
      () {
        // A two-reading occasion averaging 120 weighs the same as a one-reading
        // occasion of 180 -> (120 + 180) / 2 = 150, not the per-reading
        // (120 + 120 + 180) / 3 = 140 (§4).
        final history = [
          sessionOf([
            readingOf(
              systolic: 120,
              takenAt: nowUtc.subtract(const Duration(days: 1)),
            ),
            readingOf(
              systolic: 120,
              takenAt: nowUtc.subtract(const Duration(days: 1)),
            ),
          ]),
          daysAgo(2, systolic: 180),
        ];
        expect(
          weeklyCoverage(history, now: nowUtc).periodAverage!.systolic,
          150,
        );
      },
    );

    test('averages only in-window occasions', () {
      // Recent 140/90 vs an old 120/80: an all-time mean would be 130/85, so
      // 140/90 proves the old occasion is excluded from the average too.
      final history = [
        daysAgo(2, systolic: 140, diastolic: 90),
        daysAgo(30, systolic: 120, diastolic: 80),
      ];
      expect(
        weeklyCoverage(history, now: nowUtc).periodAverage,
        const SessionAverage(systolic: 140, diastolic: 90),
      );
    });

    test('means the pulse only over occasions that recorded one', () {
      final history = [daysAgo(1, pulse: 60), daysAgo(2)];
      expect(weeklyCoverage(history, now: nowUtc).periodAverage!.pulse, 60);
    });

    test('has no period average when nothing falls in the window', () {
      expect(weeklyCoverage([daysAgo(30)], now: nowUtc).periodAverage, isNull);
    });

    test('reports the true count when more than expected were logged', () {
      // A keen user who over-logs sees the honest count, not a cap at 14.
      final history = [for (var day = 0; day < 16; day++) daysAgo(0)];
      expect(weeklyCoverage(history, now: nowUtc).occasionsLogged, 16);
    });
  });

  group('weeklyCoverage days', () {
    test('is 0 with no history', () {
      expect(weeklyCoverage(const [], now: nowUtc).daysLogged, 0);
    });

    test('counts each calendar day once, however many occasions it holds', () {
      // Nine occasions but only two distinct days: coverage is about spread
      // across the 7-day span, not raw volume (7-2-2, §4).
      final day1 = DateTime.utc(2026, 8, 24, 8);
      final day2 = DateTime.utc(2026, 8, 23, 8);
      final history = [
        for (var i = 0; i < 5; i++) occasion(takenAt: day1),
        for (var i = 0; i < 4; i++) occasion(takenAt: day2),
      ];
      final coverage = weeklyCoverage(history, now: nowUtc, toLocal: identity);
      expect(coverage.occasionsLogged, 9);
      expect(coverage.daysLogged, 2);
    });

    test('counts occasions on the same day but different times as one day', () {
      final morning = DateTime.utc(2026, 8, 24, 7);
      final evening = DateTime.utc(2026, 8, 24, 20);
      final history = [occasion(takenAt: morning), occasion(takenAt: evening)];
      expect(
        weeklyCoverage(history, now: nowUtc, toLocal: identity).daysLogged,
        1,
      );
    });

    test('counts only days within the window', () {
      final history = [daysAgo(1), daysAgo(2), daysAgo(30)];
      expect(
        weeklyCoverage(history, now: nowUtc, toLocal: identity).daysLogged,
        2,
      );
    });

    test('groups by local calendar day, not UTC', () {
      // Two occasions on the same UTC day; a +5h local shift pushes the late
      // one into the next local day, so the local-day count rises from 1 to 2.
      final early = DateTime.utc(2026, 8, 23, 3);
      final late = DateTime.utc(2026, 8, 23, 21);
      final history = [occasion(takenAt: early), occasion(takenAt: late)];
      DateTime plusFive(DateTime utc) => utc.add(const Duration(hours: 5));

      expect(
        weeklyCoverage(history, now: nowUtc, toLocal: identity).daysLogged,
        1,
      );
      expect(
        weeklyCoverage(history, now: nowUtc, toLocal: plusFive).daysLogged,
        2,
      );
    });
  });
}
