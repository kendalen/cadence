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

      // The week view is per-occasion, so the point carries the occasion's time.
      expect(series.daily.map((p) => p.localDate), [
        DateTime.utc(2026, 8, 18, 8),
      ]);
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

  group('week view is per occasion, not per day', () {
    test('two same-day occasions stay two points, each its own average', () {
      // A morning and an evening occasion on the same day. Daily bucketing would
      // merge them into one point at their mean; the week view keeps both.
      final now = DateTime.utc(2026, 8, 24, 21);
      final series = build(
        [
          _occasion(
            systolic: 120,
            diastolic: 80,
            takenAt: DateTime.utc(2026, 8, 24, 8),
          ),
          _occasion(
            systolic: 140,
            diastolic: 90,
            takenAt: DateTime.utc(2026, 8, 24, 20),
          ),
        ],
        range: TrendRange.week,
        now: now,
      );

      expect(series.bucketSize, Duration.zero);
      expect(series.averaged, series.daily);
      expect(series.daily, hasLength(2));
      // Each point is its own occasion average, not the two blended together.
      expect(series.daily.map((p) => p.systolic), [120, 140]);
      expect(series.daily.map((p) => p.diastolic), [80, 90]);
      expect(series.daily.every((p) => p.occasionCount == 1), isTrue);
      // Positioned at their local times so they separate on the axis.
      expect(series.daily.map((p) => p.localDate), [
        DateTime.utc(2026, 8, 24, 8),
        DateTime.utc(2026, 8, 24, 20),
      ]);
    });

    test('points are time-sorted ascending', () {
      final now = DateTime.utc(2026, 8, 24, 21);
      final series = build(
        [
          _occasion(takenAt: DateTime.utc(2026, 8, 24, 20)),
          _occasion(takenAt: DateTime.utc(2026, 8, 20, 8)),
          _occasion(takenAt: DateTime.utc(2026, 8, 24, 8)),
        ],
        range: TrendRange.week,
        now: now,
      );

      expect(series.daily.map((p) => p.localDate), [
        DateTime.utc(2026, 8, 20, 8),
        DateTime.utc(2026, 8, 24, 8),
        DateTime.utc(2026, 8, 24, 20),
      ]);
    });

    test('the time-of-day filter still applies (morning only)', () {
      final now = DateTime.utc(2026, 8, 24, 21);
      final series = build(
        [
          _occasion(systolic: 118, takenAt: DateTime.utc(2026, 8, 24, 8)),
          _occasion(systolic: 140, takenAt: DateTime.utc(2026, 8, 24, 20)),
        ],
        range: TrendRange.week,
        filter: TimeOfDayFilter.morning,
        now: now,
      );

      expect(series.daily, hasLength(1));
      expect(series.daily.single.systolic, 118);
    });
  });

  group('adaptive bucketing (keyed off data span)', () {
    // now anchors "today"; spans are measured oldest-occasion → today.
    final now = DateTime.utc(2026, 8, 24, 8);

    test('span <= 30 days → daily buckets; averaged == daily', () {
      final series = build([
        _occasion(takenAt: DateTime.utc(2026, 8, 4, 8)), // 20 days back
        _occasion(takenAt: DateTime.utc(2026, 8, 24, 8)),
      ], now: now);

      expect(series.bucketSize, const Duration(days: 1));
      expect(series.averaged, series.daily);
    });

    test('31–90 day span → 7-day buckets', () {
      // Oldest 45 days back → span 45 → weekly. Two occasions in one 7-day
      // bucket average together into a single averaged point; daily keeps both.
      final series = build([
        _occasion(
          systolic: 120,
          takenAt: DateTime.utc(2026, 7, 10, 8),
        ), // 45d back
        _occasion(
          systolic: 130,
          takenAt: DateTime.utc(2026, 7, 12, 8),
        ), // same week
        _occasion(systolic: 110, takenAt: DateTime.utc(2026, 8, 24, 8)),
      ], now: now);

      expect(series.bucketSize, const Duration(days: 7));
      expect(series.daily, hasLength(3));
      // First weekly bucket (anchored at 2026-07-10) holds the first two.
      final firstBucket = series.averaged.first;
      expect(firstBucket.localDate, DateTime.utc(2026, 7, 10));
      expect(firstBucket.systolic, 125); // mean(120,130)
      expect(firstBucket.occasionCount, 2);
    });

    test('span > 90 days → 30-day buckets', () {
      final series = build([
        _occasion(takenAt: DateTime.utc(2026, 1, 1, 8)), // ~235d back
        _occasion(takenAt: DateTime.utc(2026, 8, 24, 8)),
      ], now: now);
      expect(series.bucketSize, const Duration(days: 30));
    });

    test(
      'bucket size follows real span, not the preset (new user on "all")',
      () {
        // Only 12 days of data but range=all → still daily, not a lonely point.
        final series = build(
          [
            _occasion(takenAt: DateTime.utc(2026, 8, 12, 8)),
            _occasion(takenAt: DateTime.utc(2026, 8, 24, 8)),
          ],
          range: TrendRange.all,
          now: now,
        );
        expect(series.bucketSize, const Duration(days: 1));
      },
    );
  });

  group('bounded range anchors averaged buckets at window start', () {
    test('quarter with an ~85-day span → weekly buckets anchored at window '
        'start, not the earliest datum', () {
      // window start = today − 89 days = 2026-05-27; the oldest occasion is 85
      // days back, so the span is weekly-bucketed even under the 90-day preset.
      final now = DateTime.utc(2026, 8, 24, 8);
      final series = build(
        [
          _occasion(
            systolic: 120,
            takenAt: DateTime.utc(2026, 5, 31, 8),
          ), // 85d back, in window
          _occasion(
            systolic: 130,
            takenAt: DateTime.utc(2026, 6, 2, 8),
          ), // same weekly bucket
          _occasion(
            systolic: 110,
            takenAt: DateTime.utc(2026, 8, 24, 8),
          ), // recent
        ],
        range: TrendRange.quarter,
        now: now,
      );

      // Span 85 days (oldest → now) → weekly buckets, even though the preset
      // window is 90 days.
      expect(series.bucketSize, const Duration(days: 7));
      expect(series.daily, hasLength(3));
      expect(series.averaged, hasLength(2));

      // The first averaged bucket anchors at the window start (2026-05-27), not
      // at the earliest datum (2026-05-31): bounded ranges tile from
      // windowStart. It holds the two close occasions.
      final first = series.averaged.first;
      expect(first.localDate, DateTime.utc(2026, 5, 27));
      expect(first.occasionCount, 2);
      expect(first.systolic, 125); // mean(120, 130)
    });
  });
}
