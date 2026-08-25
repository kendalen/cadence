import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/sessions/session.dart';
import '../../../domain/sessions/session_repository.dart';
import '../../../domain/sessions/trend_series.dart';
import '../../../l10n/app_localizations.dart';
import '../../system_insets.dart';
import '../../theme/cadence_colors.dart';
import 'trend_line_chart.dart';

/// A read-only view of the user's readings over time (CLAUDE.md §1: a diary
/// view, not a diagnosis — neutral lines only, no threshold, no verdict).
///
/// Range and time-of-day filter are local widget state; the series is computed
/// in [build] from the live store, mirroring how the coverage card computes in
/// place. The screen watches the repository directly (it is a pushed route and
/// cannot assume the list cubit is in scope) — a read-only [StreamBuilder], so
/// no cubit is needed here.
class TrendsScreen extends StatefulWidget {
  /// Shows trends over the sessions held by the repository provided above.
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  // A month is the default: a week is usually too few points to read as a
  // trend, a quarter buries recent change. The user can widen or narrow it.
  TrendRange _range = TrendRange.month;
  TimeOfDayFilter _filter = TimeOfDayFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repository = context.read<SessionRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trendsTitle)),
      body: StreamBuilder<List<Session>>(
        stream: repository.watchAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final series = buildTrendSeries(
            snapshot.data!,
            range: _range,
            filter: _filter,
            now: DateTime.now(),
          );
          final landscape =
              MediaQuery.orientationOf(context) == Orientation.landscape;
          return landscape ? _landscape(l10n, series) : _portrait(l10n, series);
        },
      ),
    );
  }

  // Portrait: controls stacked above the chart, the whole thing scrollable.
  Widget _portrait(AppLocalizations l10n, TrendSeries series) =>
      SingleChildScrollView(
        padding: withSystemInsets(context, const EdgeInsets.all(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _rangeControl(l10n),
            const SizedBox(height: 12),
            _filterControl(l10n),
            const SizedBox(height: 20),
            if (series.daily.isEmpty)
              _EmptyTrends(l10n.trendsEmpty)
            else
              _bloodPressureChart(l10n, series, fill: false),
          ],
        ),
      );

  // Landscape: controls in a compact side column, the chart taking the rest of
  // the width and the full height (maintainer's call — the short landscape
  // height is precious, so the controls move off the top).
  Widget _landscape(AppLocalizations l10n, TrendSeries series) => Padding(
    padding: withSystemInsets(context, const EdgeInsets.all(16)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rangeControl(l10n),
            const SizedBox(height: 12),
            _filterControl(l10n),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: series.daily.isEmpty
              ? _EmptyTrends(l10n.trendsEmpty)
              : _bloodPressureChart(l10n, series, fill: true),
        ),
      ],
    ),
  );

  Widget _rangeControl(AppLocalizations l10n) => SegmentedButton<TrendRange>(
    showSelectedIcon: false,
    segments: [
      ButtonSegment(value: TrendRange.week, label: Text(l10n.trendsRangeWeek)),
      ButtonSegment(
        value: TrendRange.month,
        label: Text(l10n.trendsRangeMonth),
      ),
      ButtonSegment(
        value: TrendRange.quarter,
        label: Text(l10n.trendsRangeQuarter),
      ),
      ButtonSegment(value: TrendRange.all, label: Text(l10n.trendsRangeAll)),
    ],
    selected: {_range},
    onSelectionChanged: (selection) => setState(() => _range = selection.first),
  );

  Widget _filterControl(AppLocalizations l10n) =>
      SegmentedButton<TimeOfDayFilter>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: TimeOfDayFilter.all,
            label: Text(l10n.trendsFilterAll),
          ),
          ButtonSegment(
            value: TimeOfDayFilter.morning,
            label: Text(l10n.trendsFilterMorning),
          ),
          ButtonSegment(
            value: TimeOfDayFilter.evening,
            label: Text(l10n.trendsFilterEvening),
          ),
        ],
        selected: {_filter},
        onSelectionChanged: (selection) =>
            setState(() => _filter = selection.first),
      );

  /// The blood-pressure chart with its heading and legend. When [fill] the chart
  /// expands to the available height (landscape); otherwise it takes a fixed
  /// height inside the scrolling portrait column.
  Widget _bloodPressureChart(
    AppLocalizations l10n,
    TrendSeries series, {
    required bool fill,
  }) {
    final chartSeries = [
      TrendChartSeries(
        label: l10n.fieldSystolic,
        color: CadenceColors.systolic,
        valueOf: (point) => point.systolic,
      ),
      TrendChartSeries(
        label: l10n.fieldDiastolic,
        color: CadenceColors.diastolic,
        valueOf: (point) => point.diastolic,
      ),
    ];
    final chart = TrendLineChart(series: chartSeries, data: series);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Text(
          l10n.trendsChartBloodPressure,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        _Legend(chartSeries),
        const SizedBox(height: 12),
        if (fill)
          Expanded(child: chart)
        else
          SizedBox(height: 280, child: chart),
      ],
    );
  }
}

/// The legend: a coloured dot and label per series.
class _Legend extends StatelessWidget {
  const _Legend(this.series);

  final List<TrendChartSeries> series;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 4,
    children: [
      for (final s in series)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(s.label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
    ],
  );
}

/// Shown when the chosen range and filter hold no occasions — a calm message,
/// not an empty axis (matching the readings-list empty state).
class _EmptyTrends extends StatelessWidget {
  const _EmptyTrends(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Center(
      child: Text(message, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}
