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
  // "now" as UTC; every call below injects [identity] as toLocal so the window
  // is computed from these exact wall-clock dates regardless of the test
  // machine's timezone (the fix anchors the window to the *local* calendar day
  // of now, so an un-injected toLocal would make these tests timezone-flaky).
  final nowUtc = DateTime.utc(2026, 8, 24, 8);

  // Treat the stored UTC instant as the local time, so the day-grouping and
  // window tests are timezone-independent (same trick as the first-reading
  // suggestion tests).
  DateTime identity(DateTime utc) => utc;

  /// Coverage over [history] at [nowUtc], with [toLocal] defaulting to identity.
  MonitoringCoverage cover(
    List<Session> history, {
    DateTime Function(DateTime)? toLocal,
  }) => weeklyCoverage(history, now: nowUtc, toLocal: toLocal ?? identity);

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

  group('weeklyCoverage', () {
    test('expects 14 occasions — the 7-2-2 shape, 2 a day over 7 days', () {
      expect(expectedWeeklyOccasions, 14);
      expect(cover(const []).occasionsExpected, 14);
    });

    test('expects 7 days — the 7-2-2 span', () {
      expect(expectedMonitoringDays, 7);
      expect(cover(const []).daysExpected, 7);
    });

    test('is empty with no history', () {
      final coverage = cover(const []);
      expect(coverage.occasionsLogged, 0);
      expect(coverage.periodAverage, isNull);
    });

    test('counts occasions logged in the last 7 days', () {
      final history = [daysAgo(1), daysAgo(3), daysAgo(6)];
      expect(cover(history).occasionsLogged, 3);
    });

    test('excludes occasions outside the 7-day window', () {
      final history = [daysAgo(1), daysAgo(8), daysAgo(30)];
      expect(cover(history).occasionsLogged, 1);
    });

    test('includes an occasion on the first day of the window (6 days back)', () {
      // The window is today and the six days before it, so six days back is the
      // earliest day still inside it.
      expect(cover([daysAgo(6)]).occasionsLogged, 1);
    });

    test('excludes an occasion the day before the window (7 days back)', () {
      // Seven calendar days back is the first day *outside* the window — this is
      // the boundary the old rolling cutoff got wrong (STATUS: "8 of 7 days").
      expect(cover([daysAgo(7)]).occasionsLogged, 0);
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
        expect(cover(history).periodAverage!.systolic, 150);
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
        cover(history).periodAverage,
        const SessionAverage(systolic: 140, diastolic: 90),
      );
    });

    test('means the pulse only over occasions that recorded one', () {
      final history = [daysAgo(1, pulse: 60), daysAgo(2)];
      expect(cover(history).periodAverage!.pulse, 60);
    });

    test('has no period average when nothing falls in the window', () {
      expect(cover([daysAgo(30)]).periodAverage, isNull);
    });

    test('reports the true count when more than expected were logged', () {
      // A keen user who over-logs sees the honest count, not a cap at 14.
      final history = [for (var day = 0; day < 16; day++) daysAgo(0)];
      expect(cover(history).occasionsLogged, 16);
    });

    test('never counts more than 7 distinct days (regression: 8 of 7)', () {
      // A 168-hour rolling cutoff straddles 8 calendar days (STATUS known
      // issue): now Aug 25 12:00 -> cutoff Aug 18 12:00, so a reading on the
      // evening of Aug 18 is inside the rolling window but on the 8th calendar
      // day. "Last 7 days" must mean 7 calendar days, capping daysLogged at 7.
      final now = DateTime.utc(2026, 8, 25, 12);
      final history = [
        occasion(takenAt: DateTime.utc(2026, 8, 18, 20)),
        for (var d = 0; d < 7; d++)
          occasion(takenAt: DateTime.utc(2026, 8, 19 + d, 9)),
      ];
      final coverage = weeklyCoverage(history, now: now, toLocal: identity);
      expect(coverage.daysLogged, 7);
      expect(coverage.occasionsLogged, 7);
    });

    test('excludes a future-dated occasion (CQ-04 upper bound)', () {
      // A tomorrow-dated occasion must not inflate the count or push the window
      // past today's 7 days.
      final now = DateTime.utc(2026, 8, 25, 12);
      final coverage = weeklyCoverage(
        [occasion(takenAt: DateTime.utc(2026, 8, 26, 9))],
        now: now,
        toLocal: identity,
      );
      expect(coverage.occasionsLogged, 0);
      expect(coverage.daysLogged, 0);
    });
  });

  group('weeklyCoverage days', () {
    test('is 0 with no history', () {
      expect(cover(const []).daysLogged, 0);
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
      final coverage = cover(history);
      expect(coverage.occasionsLogged, 9);
      expect(coverage.daysLogged, 2);
    });

    test('counts occasions on the same day but different times as one day', () {
      final morning = DateTime.utc(2026, 8, 24, 7);
      final evening = DateTime.utc(2026, 8, 24, 20);
      final history = [occasion(takenAt: morning), occasion(takenAt: evening)];
      expect(cover(history).daysLogged, 1);
    });

    test('counts only days within the window', () {
      final history = [daysAgo(1), daysAgo(2), daysAgo(30)];
      expect(cover(history).daysLogged, 2);
    });

    test('groups by local calendar day, not UTC', () {
      // Two occasions on the same UTC day; a +5h local shift pushes the late
      // one into the next local day, so the local-day count rises from 1 to 2.
      final early = DateTime.utc(2026, 8, 23, 3);
      final late = DateTime.utc(2026, 8, 23, 21);
      final history = [occasion(takenAt: early), occasion(takenAt: late)];
      DateTime plusFive(DateTime utc) => utc.add(const Duration(hours: 5));

      expect(cover(history).daysLogged, 1);
      expect(cover(history, toLocal: plusFive).daysLogged, 2);
    });
  });

  group('weeklyCoverage hasSufficientDays', () {
    test('is false below the four-day cutoff, however many occasions', () {
      // Three distinct days, but doubled up — still under-sampled: sufficiency
      // is about spread, not volume (§4).
      final history = [daysAgo(0), daysAgo(0), daysAgo(1), daysAgo(2)];
      final coverage = cover(history);

      expect(coverage.daysLogged, 3);
      expect(coverage.occasionsLogged, 4);
      expect(coverage.hasSufficientDays, isFalse);
    });

    test('is true at four distinct days', () {
      final history = [daysAgo(0), daysAgo(1), daysAgo(2), daysAgo(3)];
      final coverage = cover(history);

      expect(coverage.daysLogged, 4);
      expect(coverage.hasSufficientDays, isTrue);
    });

    test('is false with no history', () {
      expect(cover(const []).hasSufficientDays, isFalse);
    });
  });
}
