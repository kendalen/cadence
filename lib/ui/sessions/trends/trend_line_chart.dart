import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/sessions/trend_series.dart';
import '../../../l10n/app_localizations.dart';

/// One line on a [TrendLineChart]: a labelled, coloured value read from each
/// trend point.
///
/// [valueOf] returns `null` when a point holds no value for this series — e.g.
/// a bucket in which no occasion recorded a pulse — and that point is simply
/// left off this line. Blood-pressure series never return `null`; the pulse
/// series (T3) does, which is why the whole chart is series-agnostic.
class TrendChartSeries {
  /// Creates a series definition.
  const TrendChartSeries({
    required this.label,
    required this.color,
    required this.valueOf,
  });

  /// Legend and tooltip label (e.g. "Systolic").
  final String label;

  /// The line and dot colour.
  final Color color;

  /// This series' value at a point, or `null` when the point has none.
  final int? Function(TrendPoint) valueOf;
}

/// A time-series line chart: a faint per-day scatter behind a bold averaged
/// line, for one or more [series] sharing an axis.
///
/// This is the one place the app talks to `fl_chart` (CLAUDE.md §8, one way to
/// do a thing). It draws neutral lines only — no threshold, no reference range,
/// no good/bad colour (CLAUDE.md §1). The chart's meaning is left to the reader.
class TrendLineChart extends StatelessWidget {
  /// Draws [series] over the [TrendSeries] point lists.
  const TrendLineChart({super.key, required this.series, required this.data});

  /// The lines to draw (one for a pulse chart, two for blood pressure).
  final List<TrendChartSeries> series;

  /// The daily scatter and averaged line to plot.
  final TrendSeries data;

  /// The x position of a point: its civil date as milliseconds. [TrendPoint]
  /// dates are already DST-free `DateTime.utc` values, so this is stable.
  static double _x(TrendPoint point) =>
      point.localDate.millisecondsSinceEpoch.toDouble();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    final bounds = _Bounds.of(data, series);
    final byX = {for (final point in data.averaged) _x(point): point};
    final oneDayBuckets = data.bucketSize.inDays <= 1;

    // Averaged bars first (indices 0..n-1), daily dots after, so a tooltip's
    // touched spots list the meaningful averaged lines before the faint dots.
    final averagedBars = [
      for (final s in series) _lineBar(s, data.averaged, isAveraged: true),
    ];
    final dailyBars = [
      for (final s in series) _lineBar(s, data.daily, isAveraged: false),
    ];

    return LineChart(
      LineChartData(
        minX: bounds.minX,
        maxX: bounds.maxX,
        minY: bounds.minY,
        maxY: bounds.maxY,
        lineBarsData: [...averagedBars, ...dailyBars],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: bounds.yInterval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: theme.dividerColor, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: bounds.yInterval,
              getTitlesWidget: (value, meta) => Text(
                value.round().toString(),
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: bounds.xInterval,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  DateFormat.Md(locale).format(
                    DateTime.fromMillisecondsSinceEpoch(
                      value.round(),
                      isUtc: true,
                    ),
                  ),
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItems: (spots) =>
                _tooltipItems(spots, byX, l10n, locale, theme, oneDayBuckets),
          ),
        ),
      ),
    );
  }

  /// One line: the averaged line is bold with dots; the daily scatter is faint
  /// dots only (zero-width line). Points where the series has no value are
  /// dropped so a gap never reads as a zero.
  LineChartBarData _lineBar(
    TrendChartSeries s,
    List<TrendPoint> points, {
    required bool isAveraged,
  }) {
    final spots = <FlSpot>[
      for (final point in points)
        if (s.valueOf(point) case final value?)
          FlSpot(_x(point), value.toDouble()),
    ];
    final faint = s.color.withValues(alpha: isAveraged ? 1 : 0.35);
    return LineChartBarData(
      spots: spots,
      color: faint,
      barWidth: isAveraged ? 3 : 0,
      isCurved: false,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: isAveraged ? 3 : 2,
          color: faint,
          strokeWidth: 0,
        ),
      ),
    );
  }

  /// Tooltip lines for the touched [spots]: one "label value" per averaged
  /// series, with the point's date and — when a point averages more than one
  /// occasion — its occasion count on the first line, so an averaged dot is
  /// never mistaken for a single reading (CLAUDE.md §4). Daily dots get no line.
  List<LineTooltipItem?> _tooltipItems(
    List<LineBarSpot> spots,
    Map<double, TrendPoint> byX,
    AppLocalizations l10n,
    String locale,
    ThemeData theme,
    bool oneDayBuckets,
  ) {
    // Averaged bars occupy the first `series.length` bar indices.
    bool isAveraged(LineBarSpot spot) => spot.barIndex < series.length;
    final averagedIndices = [
      for (final spot in spots)
        if (isAveraged(spot)) spot.barIndex,
    ];
    final firstAveraged = averagedIndices.isEmpty
        ? null
        : averagedIndices.reduce((a, b) => a < b ? a : b);

    final onColour = theme.colorScheme.onInverseSurface;
    final headerStyle = theme.textTheme.labelMedium?.copyWith(color: onColour);
    final valueStyle = theme.textTheme.bodySmall?.copyWith(color: onColour);

    return [
      for (final spot in spots)
        if (!isAveraged(spot))
          null
        else
          LineTooltipItem(
            spot.barIndex == firstAveraged
                ? '${_header(byX[spot.x], l10n, locale, oneDayBuckets)}\n'
                      '${_valueLine(spot)}'
                : _valueLine(spot),
            spot.barIndex == firstAveraged ? headerStyle! : valueStyle!,
            children: spot.barIndex == firstAveraged
                ? [TextSpan(text: '\n${_valueLine(spot)}', style: valueStyle)]
                : const [],
          ),
    ];
  }

  String _valueLine(LineBarSpot spot) =>
      '${series[spot.barIndex].label} ${spot.y.round()}';

  String _header(
    TrendPoint? point,
    AppLocalizations l10n,
    String locale,
    bool oneDayBuckets,
  ) {
    if (point == null) return '';
    final date = DateFormat.MMMEd(locale).format(point.localDate);
    if (oneDayBuckets || point.occasionCount <= 1) return date;
    return '$date · ${l10n.trendsTooltipOccasions(point.occasionCount)}';
  }
}

/// The chart's axis bounds, padded so a flat or single-point series still draws.
class _Bounds {
  const _Bounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.xInterval,
    required this.yInterval,
  });

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double xInterval;
  final double yInterval;

  /// Derives padded bounds from every plotted value across [series].
  factory _Bounds.of(TrendSeries data, List<TrendChartSeries> series) {
    final xs = [for (final point in data.daily) TrendLineChart._x(point)];
    final ys = [
      for (final point in data.daily)
        for (final s in series)
          if (s.valueOf(point) case final value?) value.toDouble(),
    ];

    // Empty is handled by the screen (empty state), but stay total.
    var minX = xs.isEmpty ? 0.0 : xs.reduce((a, b) => a < b ? a : b);
    var maxX = xs.isEmpty ? 1.0 : xs.reduce((a, b) => a > b ? a : b);
    var minY = ys.isEmpty ? 0.0 : ys.reduce((a, b) => a < b ? a : b);
    var maxY = ys.isEmpty ? 1.0 : ys.reduce((a, b) => a > b ? a : b);

    const day = 86400000.0; // ms in a day
    if (minX == maxX) {
      minX -= day;
      maxX += day;
    }
    // Pad the value axis so a flat series is not a zero-height range, and lines
    // never touch the top/bottom edge.
    final valuePad = (maxY - minY) * 0.15;
    final pad = valuePad < 4 ? 4.0 : valuePad;
    minY -= pad;
    maxY += pad;

    final yInterval = _niceStep(maxY - minY);
    // Aim for ~4 date labels; keep it a whole number of days.
    final xSteps = ((maxX - minX) / (day * 4)).ceilToDouble();
    final xInterval = xSteps < 1 ? day : xSteps * day;

    return _Bounds(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      xInterval: xInterval,
      yInterval: yInterval,
    );
  }

  /// A readable gridline step for a value [span] (~4 lines), rounded to 5s.
  static double _niceStep(double span) {
    final raw = span / 4;
    if (raw <= 5) return 5;
    return (raw / 5).ceilToDouble() * 5;
  }
}
