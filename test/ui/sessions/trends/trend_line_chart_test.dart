// The chart widget itself is not tested (fl_chart pixels are platform-variable;
// see the trends design spec). What is worth pinning is the pure selection
// logic behind the pinned tooltip: resolving the tapped x to each series' OWN
// spot list, so a gappy series (pulse is optional) is never indexed past the
// end of its shorter list — the CQ-13 crash.

import 'package:cadence/domain/sessions/trend_series.dart';
import 'package:cadence/ui/sessions/trends/trend_line_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TrendPoint pointAt(DateTime date, {int? pulse}) => TrendPoint(
    localDate: date,
    systolic: 120,
    diastolic: 80,
    occasionCount: 1,
    pulse: pulse,
  );

  double x(TrendPoint point) =>
      point.localDate.millisecondsSinceEpoch.toDouble();

  final pulseSeries = TrendChartSeries(
    label: 'Pulse',
    color: const Color(0xFF556B7A),
    valueOf: (point) => point.pulse,
  );

  test('resolves the selected x to the series own (filtered) spot index', () {
    // First bucket has no pulse, second does. The pulse line plots one spot;
    // tapping that spot must resolve to index 0 in the one-element list — not
    // index 1 from the full point list, which used to overrun and crash.
    final noPulse = pointAt(DateTime.utc(2026, 8, 20));
    final withPulse = pointAt(DateTime.utc(2026, 8, 21), pulse: 70);
    final points = [noPulse, withPulse];

    expect(selectedSpotIndex(pulseSeries, points, x(withPulse)), 0);
  });

  test('a selected x where the series has no value resolves to null', () {
    final noPulse = pointAt(DateTime.utc(2026, 8, 20));
    final withPulse = pointAt(DateTime.utc(2026, 8, 21), pulse: 70);

    expect(
      selectedSpotIndex(pulseSeries, [noPulse, withPulse], x(noPulse)),
      isNull,
    );
  });

  test('no selection resolves to null', () {
    expect(
      selectedSpotIndex(pulseSeries, [
        pointAt(DateTime.utc(2026, 8, 20)),
      ], null),
      isNull,
    );
  });

  test('a gapless series resolves to the plain point index', () {
    final points = [
      pointAt(DateTime.utc(2026, 8, 20), pulse: 60),
      pointAt(DateTime.utc(2026, 8, 21), pulse: 65),
      pointAt(DateTime.utc(2026, 8, 22), pulse: 70),
    ];

    expect(selectedSpotIndex(pulseSeries, points, x(points[2])), 2);
  });
}
