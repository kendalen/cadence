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
}
