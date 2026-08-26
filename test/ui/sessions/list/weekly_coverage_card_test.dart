// The weekly coverage card (S6): shows occasions logged vs expected and, when
// the window holds any, the week's average with the count behind it
// (CLAUDE.md §4). The card is a pure function of a MonitoringCoverage, so these
// pump it directly with a fixed coverage — no repository or clock.

import 'package:cadence/domain/sessions/session_average.dart';
import 'package:cadence/domain/sessions/weekly_coverage.dart';
import 'package:cadence/l10n/app_localizations.dart';
import 'package:cadence/ui/sessions/list/weekly_coverage_card.dart';
import 'package:cadence/ui/theme/cadence_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, MonitoringCoverage coverage) =>
      tester.pumpWidget(
        MaterialApp(
          theme: buildCadenceTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: WeeklyCoverageCard(coverage)),
        ),
      );

  final l10n = lookupAppLocalizations(const Locale('en'));

  testWidgets('shows occasions logged against the 14 expected', (tester) async {
    await pump(
      tester,
      const MonitoringCoverage(
        occasionsLogged: 9,
        daysLogged: 4,
        periodAverage: SessionAverage(systolic: 128, diastolic: 82),
      ),
    );

    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('9 of 14 occasions'), findsOneWidget);
    expect(find.text('4 of 7 days'), findsOneWidget);
  });

  testWidgets('shows the period average', (tester) async {
    await pump(
      tester,
      const MonitoringCoverage(
        occasionsLogged: 9,
        daysLogged: 4,
        periodAverage: SessionAverage(systolic: 128, diastolic: 82),
      ),
    );

    expect(find.text('Average'), findsOneWidget);
    expect(find.text('128/82'), findsOneWidget);
  });

  testWidgets('stacks onto multiple lines in portrait', (tester) async {
    // The default test window is landscape-shaped (800x600), which exercises the
    // one-line layout; force a tall, narrow window for the stacked portrait one.
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pump(
      tester,
      const MonitoringCoverage(
        occasionsLogged: 9,
        daysLogged: 4,
        periodAverage: SessionAverage(systolic: 128, diastolic: 82),
      ),
    );

    // Same content in the narrow layout — all present, and nothing overflows (a
    // RenderFlex overflow throws and fails the test).
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('9 of 14 occasions'), findsOneWidget);
    expect(find.text('4 of 7 days'), findsOneWidget);
    expect(find.text('Average'), findsOneWidget);
    expect(find.text('128/82'), findsOneWidget);
  });

  testWidgets('omits the average when nothing falls in the window', (
    tester,
  ) async {
    await pump(
      tester,
      const MonitoringCoverage(
        occasionsLogged: 0,
        daysLogged: 0,
        periodAverage: null,
      ),
    );

    expect(find.text('0 of 14 occasions'), findsOneWidget);
    expect(find.text('Average'), findsNothing);
  });

  testWidgets('tags the average as partial below four logged days', (
    tester,
  ) async {
    // Three distinct days back the average — under the four-day cutoff (§4).
    await pump(
      tester,
      const MonitoringCoverage(
        occasionsLogged: 5,
        daysLogged: 3,
        periodAverage: SessionAverage(systolic: 128, diastolic: 82),
      ),
    );

    expect(find.text('128/82'), findsOneWidget);
    expect(find.text('based on partial data'), findsOneWidget);
  });

  testWidgets('shows no partial tag at four or more logged days', (
    tester,
  ) async {
    await pump(
      tester,
      const MonitoringCoverage(
        occasionsLogged: 5,
        daysLogged: 4,
        periodAverage: SessionAverage(systolic: 128, diastolic: 82),
      ),
    );

    expect(find.text('based on partial data'), findsNothing);
  });

  testWidgets('offers the info button, text hidden, when reliable', (
    tester,
  ) async {
    await pump(
      tester,
      const MonitoringCoverage(
        occasionsLogged: 8,
        daysLogged: 5, // >= 4 → sufficient
        periodAverage: SessionAverage(systolic: 138, diastolic: 85),
      ),
    );

    // The button is offered, but the comparison starts hidden.
    expect(find.byTooltip(l10n.referenceInfoLabel), findsOneWidget);
    expect(find.text(l10n.referenceAtOrAbove), findsNothing);
  });

  testWidgets('tapping the info button reveals the at-or-above comparison', (
    tester,
  ) async {
    await pump(
      tester,
      const MonitoringCoverage(
        occasionsLogged: 8,
        daysLogged: 5,
        periodAverage: SessionAverage(systolic: 138, diastolic: 85),
      ),
    );

    await tester.tap(find.byTooltip(l10n.referenceInfoLabel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.referenceAtOrAbove), findsOneWidget);
    expect(find.text(l10n.exportDisclaimer), findsOneWidget);
  });

  testWidgets('reveals the below comparison for a sub-reference average', (
    tester,
  ) async {
    await pump(
      tester,
      const MonitoringCoverage(
        occasionsLogged: 8,
        daysLogged: 5,
        periodAverage: SessionAverage(systolic: 122, diastolic: 78),
      ),
    );

    await tester.tap(find.byTooltip(l10n.referenceInfoLabel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.referenceBelow), findsOneWidget);
  });

  testWidgets('tapping the info button again hides the comparison', (
    tester,
  ) async {
    await pump(
      tester,
      const MonitoringCoverage(
        occasionsLogged: 8,
        daysLogged: 5,
        periodAverage: SessionAverage(systolic: 138, diastolic: 85),
      ),
    );

    await tester.tap(find.byTooltip(l10n.referenceInfoLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.referenceInfoLabel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.referenceAtOrAbove), findsNothing);
  });

  testWidgets('offers no info button when days are insufficient', (
    tester,
  ) async {
    await pump(
      tester,
      const MonitoringCoverage(
        occasionsLogged: 3,
        daysLogged: 2, // < 4 → partial
        periodAverage: SessionAverage(systolic: 138, diastolic: 85),
      ),
    );

    expect(find.byTooltip(l10n.referenceInfoLabel), findsNothing);
  });

  testWidgets('revealing does not change the card width (landscape)', (
    tester,
  ) async {
    // The default test window is landscape-shaped (800x600). Revealing the
    // reference block must grow the card's height only, never its width.
    await pump(
      tester,
      const MonitoringCoverage(
        occasionsLogged: 8,
        daysLogged: 5,
        periodAverage: SessionAverage(systolic: 138, diastolic: 85),
      ),
    );

    final widthBefore = tester.getSize(find.byType(Card)).width;
    await tester.tap(find.byTooltip(l10n.referenceInfoLabel));
    await tester.pumpAndSettle();
    final widthAfter = tester.getSize(find.byType(Card)).width;

    expect(widthAfter, widthBefore);
  });

  testWidgets('offers no info button when nothing falls in the window', (
    tester,
  ) async {
    await pump(
      tester,
      const MonitoringCoverage(
        occasionsLogged: 0,
        daysLogged: 0,
        periodAverage: null,
      ),
    );

    expect(find.byTooltip(l10n.referenceInfoLabel), findsNothing);
  });
}
