// The session detail screen (S4): shows an occasion's readings and, when it
// holds more than one, their average (CLAUDE.md §4). These pump the screen
// directly with a fixed session and assert on the pressure numbers only — the
// date and per-reading times it also renders are local-timezone-dependent, and
// are deliberately not asserted (the same reason the theme golden pins only the
// timezone-free empty state).

import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/session.dart';
import 'package:cadence/l10n/app_localizations.dart';
import 'package:cadence/ui/sessions/detail/session_detail_screen.dart';
import 'package:cadence/ui/theme/cadence_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Reading reading(String id, int systolic, int diastolic, {int? pulse}) =>
      Reading(
        id: ReadingId(id),
        systolic: systolic,
        diastolic: diastolic,
        pulse: pulse,
        takenAt: DateTime.utc(2026, 8, 24, 8),
      );

  Future<void> pump(WidgetTester tester, Session session) => tester.pumpWidget(
    MaterialApp(
      theme: buildCadenceTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SessionDetailScreen(session),
    ),
  );

  testWidgets('a multi-reading occasion shows the average and each reading', (
    tester,
  ) async {
    final session = Session(
      id: const SessionId('s1'),
      readings: [
        reading('r1', 120, 80, pulse: 70),
        reading('r2', 118, 78, pulse: 72),
      ],
    );

    await pump(tester, session);

    // The average block: the mean of the two readings, labelled and counted.
    expect(find.text('Average'), findsOneWidget);
    expect(find.text('119/79'), findsOneWidget);
    expect(find.text('2 readings'), findsOneWidget);

    // The readings behind it, each shown in full.
    expect(find.text('Readings'), findsOneWidget);
    expect(find.text('120/80'), findsOneWidget);
    expect(find.text('118/78'), findsOneWidget);
  });

  testWidgets('a single-reading occasion shows no average block', (
    tester,
  ) async {
    final session = Session(
      id: const SessionId('s1'),
      readings: [reading('r1', 128, 82)],
    );

    await pump(tester, session);

    // The average of one reading is that reading, so the block would only
    // repeat it: it is not shown, and neither is the "Readings" header.
    expect(find.text('Average'), findsNothing);
    expect(find.text('Readings'), findsNothing);
    expect(find.text('128/82'), findsOneWidget);
  });
}
