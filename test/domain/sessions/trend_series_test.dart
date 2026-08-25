import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/session.dart';
import 'package:cadence/domain/sessions/trend_series.dart';
import 'package:flutter_test/flutter_test.dart';

int _seq = 0;

Reading _readingOf({
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

/// A one-reading occasion at [takenAt] (UTC).
Session _occasion({
  int systolic = 120,
  int diastolic = 80,
  int? pulse,
  required DateTime takenAt,
}) => Session(
  id: SessionId('s${_seq++}'),
  readings: [
    _readingOf(
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      takenAt: takenAt,
    ),
  ],
);

void main() {
  // Treat the stored UTC instant as local time, so day-grouping and the window
  // are timezone-independent (same trick as weekly_coverage_test).
  DateTime identity(DateTime utc) => utc;

  TrendSeries build(
    List<Session> sessions, {
    TrendRange range = TrendRange.all,
    TimeOfDayFilter filter = TimeOfDayFilter.all,
    required DateTime now,
  }) => buildTrendSeries(
    sessions,
    range: range,
    filter: filter,
    now: now,
    toLocal: identity,
  );

  group('daily aggregation', () {
    test('one point per calendar day, mean of session averages (§4)', () {
      // Two occasions on the same day → one point at their mean; each occasion
      // weighs once regardless of reading count.
      final now = DateTime.utc(2026, 8, 24, 20);
      final series = build([
        _occasion(
          systolic: 120,
          diastolic: 80,
          takenAt: DateTime.utc(2026, 8, 24, 8),
        ),
        _occasion(
          systolic: 130,
          diastolic: 90,
          takenAt: DateTime.utc(2026, 8, 24, 19),
        ),
      ], now: now);

      expect(series.daily, hasLength(1));
      expect(series.daily.single.systolic, 125);
      expect(series.daily.single.diastolic, 85);
      expect(series.daily.single.occasionCount, 2);
      expect(series.daily.single.localDate, DateTime.utc(2026, 8, 24));
    });

    test('points are date-sorted ascending', () {
      final now = DateTime.utc(2026, 8, 24, 20);
      final series = build([
        _occasion(takenAt: DateTime.utc(2026, 8, 24, 8)),
        _occasion(takenAt: DateTime.utc(2026, 8, 22, 8)),
        _occasion(takenAt: DateTime.utc(2026, 8, 23, 8)),
      ], now: now);

      expect(series.daily.map((p) => p.localDate), [
        DateTime.utc(2026, 8, 22),
        DateTime.utc(2026, 8, 23),
        DateTime.utc(2026, 8, 24),
      ]);
    });

    test(
      'pulse is the mean of only occasions that recorded one, else null',
      () {
        final now = DateTime.utc(2026, 8, 24, 20);
        final series = build([
          _occasion(pulse: 70, takenAt: DateTime.utc(2026, 8, 24, 8)),
          _occasion(takenAt: DateTime.utc(2026, 8, 24, 19)), // no pulse
        ], now: now);
        expect(series.daily.single.pulse, 70);

        final none = build([
          _occasion(takenAt: DateTime.utc(2026, 8, 24, 8)),
        ], now: now);
        expect(none.daily.single.pulse, isNull);
      },
    );

    test('empty diary → empty series, bucketSize one day', () {
      final series = build([], now: DateTime.utc(2026, 8, 24, 20));
      expect(series.daily, isEmpty);
      expect(series.averaged, isEmpty);
      expect(series.bucketSize, const Duration(days: 1));
    });
  });

  group('range window', () {
    test('week keeps today and the six prior days, drops older', () {
      final now = DateTime.utc(2026, 8, 24, 8); // window start = 2026-08-18
      final series = build(
        [
          _occasion(
            takenAt: DateTime.utc(2026, 8, 18, 8),
          ), // included (boundary)
          _occasion(
            takenAt: DateTime.utc(2026, 8, 17, 23),
          ), // excluded (day before)
        ],
        range: TrendRange.week,
        now: now,
      );

      expect(series.daily.map((p) => p.localDate), [DateTime.utc(2026, 8, 18)]);
    });

    test('all keeps everything', () {
      final now = DateTime.utc(2026, 8, 24, 8);
      final series = build(
        [
          _occasion(takenAt: DateTime.utc(2025, 1, 1, 8)),
          _occasion(takenAt: DateTime.utc(2026, 8, 24, 8)),
        ],
        range: TrendRange.all,
        now: now,
      );
      expect(series.daily, hasLength(2));
    });
  });

  group('time-of-day filter (noon split)', () {
    final now = DateTime.utc(2026, 8, 24, 20);

    test('morning keeps only before-noon occasions', () {
      final series = build(
        [
          _occasion(
            systolic: 118,
            takenAt: DateTime.utc(2026, 8, 24, 8),
          ), // morning
          _occasion(
            systolic: 140,
            takenAt: DateTime.utc(2026, 8, 24, 19),
          ), // evening
        ],
        filter: TimeOfDayFilter.morning,
        now: now,
      );

      expect(series.daily, hasLength(1));
      expect(series.daily.single.systolic, 118);
    });

    test('evening keeps only from-noon occasions; noon itself is evening', () {
      final series = build(
        [
          _occasion(
            systolic: 118,
            takenAt: DateTime.utc(2026, 8, 24, 8),
          ), // morning
          _occasion(
            systolic: 140,
            takenAt: DateTime.utc(2026, 8, 24, 12),
          ), // noon → evening
        ],
        filter: TimeOfDayFilter.evening,
        now: now,
      );

      expect(series.daily, hasLength(1));
      expect(series.daily.single.systolic, 140);
    });

    test('all keeps both halves', () {
      final series = build(
        [
          _occasion(takenAt: DateTime.utc(2026, 8, 24, 8)),
          _occasion(takenAt: DateTime.utc(2026, 8, 24, 19)),
        ],
        filter: TimeOfDayFilter.all,
        now: now,
      );
      expect(series.daily.single.occasionCount, 2);
    });
  });
}
