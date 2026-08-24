// End-to-end wiring for the log-session slice: type a reading, save it, see it
// in the list. This is not a widget test in the sense CLAUDE.md §7 warns about
// — it asserts nothing about how the screens are laid out, only that the parts
// are connected: navigation, the providers, validation, the drift write, and
// the stream that feeds the list back.

import 'package:cadence/data/database/app_database.dart';
import 'package:cadence/data/ids/uuid_id_generator.dart';
import 'package:cadence/data/sessions/drift_session_repository.dart';
import 'package:cadence/ui/app.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  /// Lets drift finish, then draws the result.
  ///
  /// `pumpAndSettle` is deliberately not used anywhere in this file. The list
  /// shows a `CircularProgressIndicator` until the store answers, and settling
  /// waits on that animation until it times out. Two separate problems are at
  /// work: the query needs the real event loop, which the fake clock inside
  /// `testWidgets` does not run — hence `runAsync` — and the pumping afterwards
  /// has to be bounded so a regression fails the test instead of hanging it.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    for (var frame = 0; frame < 40; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      CadenceApp(
        sessionRepository: DriftSessionRepository(database),
        idGenerator: const UuidIdGenerator(),
      ),
    );
    await settle(tester);
  }

  /// Tears the tree down inside the test body.
  ///
  /// Cancelling drift's query stream schedules a zero-duration timer, and the
  /// framework fails any test that ends with a timer pending. Disposing here
  /// rather than leaving it to the framework gives that timer a frame to fire.
  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // The timer is scheduled during the unmount above, so firing it needs a
    // frame that actually advances the clock — a bare pump() elapses nothing.
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> openEntryForm(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
  }

  Future<void> enter(WidgetTester tester, String label, String value) async {
    await tester.enterText(
      find.ancestor(of: find.text(label), matching: find.byType(TextField)),
      value,
    );
  }

  Future<void> save(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Save');
    // The banked-readings list can push Save below the test viewport; scroll it
    // into view first so the tap lands (a no-op when it is already visible).
    await tester.ensureVisible(button);
    await settle(tester);
    await tester.tap(button);
    await settle(tester);
  }

  Future<void> addAnother(WidgetTester tester) async {
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Add another reading'),
    );
    await settle(tester);
  }

  testWidgets('a saved reading appears in the list', (tester) async {
    await pumpApp(tester);
    expect(find.text('No readings yet.'), findsOneWidget);

    await openEntryForm(tester);
    await enter(tester, 'Systolic (mmHg)', '132');
    await enter(tester, 'Diastolic (mmHg)', '84');
    await enter(tester, 'Pulse (bpm, optional)', '72');
    await save(tester);

    expect(find.text('132/84'), findsOneWidget);
    expect(find.text('72 bpm'), findsOneWidget);
    expect(find.text('No readings yet.'), findsNothing);

    await disposeApp(tester);
  });

  testWidgets('the reading survives the app being rebuilt', (tester) async {
    await pumpApp(tester);
    await openEntryForm(tester);
    await enter(tester, 'Systolic (mmHg)', '132');
    await enter(tester, 'Diastolic (mmHg)', '84');
    await save(tester);

    // Same database, a fresh widget tree: what the list shows came back out of
    // storage, not out of the state it was saved from.
    await pumpApp(tester);

    expect(find.text('132/84'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('an invalid reading is refused and nothing is stored', (
    tester,
  ) async {
    await pumpApp(tester);
    await openEntryForm(tester);
    await enter(tester, 'Systolic (mmHg)', '400');
    await save(tester);

    // Still on the form, with the bad field and the blank one both marked.
    expect(find.text('Enter a number between 10 and 300.'), findsOneWidget);
    expect(find.text('Enter a value.'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.text('No readings yet.'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('an occasion can hold two readings', (tester) async {
    await pumpApp(tester);
    await openEntryForm(tester);

    await enter(tester, 'Systolic (mmHg)', '120');
    await enter(tester, 'Diastolic (mmHg)', '80');
    await addAnother(tester);

    await enter(tester, 'Systolic (mmHg)', '118');
    await enter(tester, 'Diastolic (mmHg)', '79');
    await save(tester);

    // One occasion in the list, holding two reading rows in storage.
    final sessions = await database.select(database.sessions).get();
    final readings = await database.select(database.readings).get();
    expect(sessions, hasLength(1));
    expect(readings, hasLength(2));

    await disposeApp(tester);
  });
}
