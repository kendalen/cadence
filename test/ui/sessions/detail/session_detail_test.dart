// The session detail screen (S4/S5a): shows an occasion's readings and, when it
// holds more than one, their average (CLAUDE.md §4), and lets the whole occasion
// be deleted with a confirm + undo (CLAUDE.md §6). These pump the screen with a
// fixed session and assert on the pressure numbers only — the date and
// per-reading times it also renders are local-timezone-dependent, and are
// deliberately not asserted (the same reason the theme golden pins only the
// timezone-free empty state).

import 'package:cadence/domain/sessions/id_generator.dart';
import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/persistence_failure.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/session.dart';
import 'package:cadence/domain/sessions/session_repository.dart';
import 'package:cadence/l10n/app_localizations.dart';
import 'package:cadence/ui/sessions/detail/session_detail_screen.dart';
import 'package:cadence/ui/theme/cadence_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_id_generator.dart';
import '../../../support/fake_session_repository.dart';

void main() {
  late FakeSessionRepository repository;

  setUp(() => repository = FakeSessionRepository());
  tearDown(() => repository.dispose());

  Reading reading(String id, int systolic, int diastolic, {int? pulse}) =>
      Reading(
        id: ReadingId(id),
        systolic: systolic,
        diastolic: diastolic,
        pulse: pulse,
        takenAt: DateTime.utc(2026, 8, 24, 8),
      );

  Widget wrap(Widget home) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<SessionRepository>.value(value: repository),
      RepositoryProvider<IdGenerator>.value(value: FakeIdGenerator()),
    ],
    child: MaterialApp(
      theme: buildCadenceTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );

  Future<void> pump(WidgetTester tester, Session session) =>
      tester.pumpWidget(wrap(SessionDetailScreen(session)));

  // Pushes the detail screen over a trivial first route, so its own delete can
  // pop back to something and the undo snackbar has a screen to land on.
  Future<void> pumpPushed(WidgetTester tester, Session session) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SessionDetailScreen(session),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

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

  group('delete', () {
    final session = Session(
      id: const SessionId('s1'),
      readings: [reading('r1', 128, 82)],
    );

    testWidgets('tapping delete asks for confirmation first', (tester) async {
      repository.added.add(session);
      await pump(tester, session);

      await tester.tap(find.text('Delete this occasion'));
      await tester.pumpAndSettle();

      expect(find.text('Delete this occasion?'), findsOneWidget);
      // Nothing removed until the user confirms.
      expect(repository.added, contains(session));
    });

    testWidgets('cancelling the dialog keeps the occasion', (tester) async {
      repository.added.add(session);
      await pump(tester, session);

      await tester.tap(find.text('Delete this occasion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.added, contains(session));
      // Still on the detail screen.
      expect(find.text('128/82'), findsOneWidget);
    });

    testWidgets('confirming deletes, leaves the screen, and offers undo', (
      tester,
    ) async {
      repository.added.add(session);
      await pumpPushed(tester, session);

      await tester.tap(find.text('Delete this occasion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete')); // dialog confirm
      await tester.pumpAndSettle();

      expect(repository.added, isEmpty);
      // Back on the first route, with the undo snackbar over it.
      expect(find.text('open'), findsOneWidget);
      expect(find.text('Occasion deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('undo restores the deleted occasion', (tester) async {
      repository.added.add(session);
      await pumpPushed(tester, session);

      await tester.tap(find.text('Delete this occasion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(repository.added, contains(session));
    });

    testWidgets('a failed delete reports it and keeps the occasion', (
      tester,
    ) async {
      repository.added.add(session);
      repository.refuseDeleteWith = WriteFailed(Exception('disk full'));
      await pumpPushed(tester, session);

      await tester.tap(find.text('Delete this occasion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(repository.added, contains(session));
      // Stayed on the detail screen; the error was surfaced.
      expect(find.text('128/82'), findsOneWidget);
      expect(find.textContaining("Couldn't delete"), findsOneWidget);
    });
  });

  group('edit', () {
    testWidgets('correcting a reading saves it under the same id', (
      tester,
    ) async {
      final session = Session(
        id: const SessionId('s1'),
        readings: [reading('r1', 120, 80)],
      );
      repository.added.add(session);
      await pump(tester, session);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Edit reading'), findsOneWidget);

      // Bump systolic 120 -> 121 and save.
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('systolicStepper')),
          matching: find.byIcon(Icons.add),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final stored = repository.added.single.readings.single;
      expect(stored.systolic, 121);
      // Identity preserved: the store updated the reading, not added a new one.
      expect(stored.id, const ReadingId('r1'));
      // The detail screen refreshed to the new value.
      expect(find.text('121/80'), findsOneWidget);
    });

    testWidgets('backing out of the editor changes nothing', (tester) async {
      final session = Session(
        id: const SessionId('s1'),
        readings: [reading('r1', 120, 80)],
      );
      repository.added.add(session);
      await pump(tester, session);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('systolicStepper')),
          matching: find.byIcon(Icons.add),
        ),
      );
      await tester.pump();
      // Leave without saving.
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(repository.added.single.readings.single.systolic, 120);
    });
  });

  group('remove a reading', () {
    Session pair() => Session(
      id: const SessionId('s1'),
      readings: [reading('r1', 120, 80), reading('r2', 118, 78)],
    );

    testWidgets('a single-reading occasion offers no per-reading remove', (
      tester,
    ) async {
      final session = Session(
        id: const SessionId('s1'),
        readings: [reading('r1', 128, 82)],
      );
      await pump(tester, session);

      expect(find.byIcon(Icons.close), findsNothing);
      // It can still be edited, and deleted as a whole occasion.
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.text('Delete this occasion'), findsOneWidget);
    });

    testWidgets('removing one of a pair keeps the other, with undo', (
      tester,
    ) async {
      final session = pair();
      repository.added.add(session);
      await pump(tester, session);

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(repository.added.single.readings, hasLength(1));
      expect(find.text('Reading removed'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(repository.added.single.readings, hasLength(2));
    });
  });
}
