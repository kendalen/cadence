// The trends screen (T2): a read-only blood-pressure chart with range and
// time-of-day controls. The chart's pixels are fl_chart's and too
// platform-variable to golden; these assert the observable behaviour instead —
// that changing a control re-runs the aggregation and re-renders — plus one
// golden on the (timezone-free) empty state. No assertions on widget structure
// (CLAUDE.md §7).

import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/session.dart';
import 'package:cadence/domain/sessions/session_repository.dart';
import 'package:cadence/l10n/app_localizations.dart';
import 'package:cadence/ui/sessions/trends/trends_screen.dart';
import 'package:cadence/ui/theme/cadence_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_session_repository.dart';

int _seq = 0;

/// A one-reading occasion at [takenAtUtc] (readings are stored UTC).
Session _occasion(DateTime takenAtUtc) => Session(
  id: SessionId('s${_seq++}'),
  readings: [
    Reading(
      id: ReadingId('r${_seq++}'),
      systolic: 128,
      diastolic: 82,
      takenAt: takenAtUtc,
    ),
  ],
);

void main() {
  late FakeSessionRepository repository;

  setUp(() => repository = FakeSessionRepository());
  tearDown(() => repository.dispose());

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    RepositoryProvider<SessionRepository>.value(
      value: repository,
      child: MaterialApp(
        theme: buildCadenceTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TrendsScreen(),
      ),
    ),
  );

  // A UTC instant whose *local* time is [hour]:00, N days before today — so the
  // occasion lands in a known range window and morning/evening bucket whatever
  // the machine's timezone (build local, store UTC; the screen's toLocal undoes
  // it). The screen is fed a real clock, so times are relative to now.
  DateTime daysAgo(int days, {int hour = 9}) {
    final base = DateTime.now().subtract(Duration(days: days));
    return DateTime(base.year, base.month, base.day, hour).toUtc();
  }

  testWidgets('narrowing the range past the data shows the empty state', (
    tester,
  ) async {
    // One occasion 15 days back: inside the default 30-day window, outside 7.
    await pump(tester);
    repository.emit([_occasion(daysAgo(15))]);
    await tester.pumpAndSettle();

    expect(find.text('Blood pressure'), findsOneWidget);
    expect(find.text('No readings in this range yet.'), findsNothing);

    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();

    expect(find.text('No readings in this range yet.'), findsOneWidget);
    expect(find.text('Blood pressure'), findsNothing);
  });

  testWidgets('filtering to morning past the data shows the empty state', (
    tester,
  ) async {
    // One evening occasion (20:00) inside the default window.
    await pump(tester);
    repository.emit([_occasion(daysAgo(10, hour: 20))]);
    await tester.pumpAndSettle();

    expect(find.text('Blood pressure'), findsOneWidget);

    await tester.tap(find.text('Morning'));
    await tester.pumpAndSettle();

    expect(find.text('No readings in this range yet.'), findsOneWidget);
    expect(find.text('Blood pressure'), findsNothing);
  });

  testWidgets('empty diary golden', (tester) async {
    // The default test window is landscape-shaped (800x600); force a portrait
    // window so the golden captures the primary (stacked) empty-state layout.
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pump(tester);
    repository.emit(const []);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(TrendsScreen),
      matchesGoldenFile('goldens/trends_empty.png'),
    );
  });
}
