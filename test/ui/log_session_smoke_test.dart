// End-to-end wiring for the log-session slice: type a reading, save it, see it
// in the list. This is not a widget test in the sense CLAUDE.md §7 warns about
// — it asserts nothing about how the screens are laid out, only that the parts
// are connected: navigation, the providers, validation, the drift write, and
// the stream that feeds the list back. S3a adds the stepper wiring: default and
// carried-over values, and that a stepped number is what gets stored.

import 'package:cadence/data/database/app_database.dart';
import 'package:cadence/data/ids/uuid_id_generator.dart';
import 'package:cadence/data/sessions/drift_session_repository.dart';
import 'package:cadence/ui/app.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  // The three number fields, found by the key on their stepper.
  const systolicStepper = Key('systolicStepper');
  const diastolicStepper = Key('diastolicStepper');
  const pulseStepper = Key('pulseStepper');

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

  /// The text field inside the stepper carrying [key].
  Finder stepperField(Key key) =>
      find.descendant(of: find.byKey(key), matching: find.byType(TextField));

  // The form's own ListView scrollable, named by key so it is never confused
  // with the internal scroll area each stepper's text field creates.
  Finder formScrollable() => find
      .descendant(
        of: find.byKey(const Key('entryFormList')),
        matching: find.byType(Scrollable),
      )
      .first;

  /// Scrolls the stepper carrying [key] back into the lazy ListView, which
  /// disposes it once it leaves the viewport (e.g. banking a reading scrolls the
  /// form down). Negative delta scrolls toward the top fields; a no-op when the
  /// stepper is already built.
  Future<void> bringIntoView(WidgetTester tester, Key key) => tester
      .scrollUntilVisible(find.byKey(key), -120, scrollable: formScrollable());

  /// The value currently shown in the stepper carrying [key].
  String fieldText(WidgetTester tester, Key key) =>
      tester.widget<TextField>(stepperField(key)).controller!.text;

  /// Brings the stepper carrying [key] into view, then reads its value.
  Future<String> readField(WidgetTester tester, Key key) async {
    await bringIntoView(tester, key);
    await settle(tester);
    return fieldText(tester, key);
  }

  /// Types [value] into the stepper carrying [key], replacing what is there.
  Future<void> setValue(WidgetTester tester, Key key, String value) async {
    await bringIntoView(tester, key);
    await tester.enterText(stepperField(key), value);
  }

  /// Taps + on the stepper carrying [key].
  Future<void> increment(WidgetTester tester, Key key) async {
    await tester.tap(
      find.descendant(of: find.byKey(key), matching: find.byIcon(Icons.add)),
    );
    await settle(tester);
  }

  Future<void> save(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Save');
    // The form is a lazy ListView; extra content (banked readings, expanded
    // context fields) can leave Save unbuilt below the viewport, where a plain
    // tap would miss it. scrollUntilVisible scrolls the form until Save is
    // built and shown (a no-op when it is already on-screen); ensureVisible
    // then guarantees it is fully in view before the tap lands.
    await tester.scrollUntilVisible(button, 100, scrollable: formScrollable());
    await tester.ensureVisible(button);
    await settle(tester);
    await tester.tap(button);
    await settle(tester);
  }

  Future<void> addAnother(WidgetTester tester) async {
    // Taller steppers can push this button below the viewport of the lazy
    // ListView; scroll it into view first, the same way save() reaches Save.
    final button = find.widgetWithText(OutlinedButton, 'Add another reading');
    await tester.scrollUntilVisible(button, 100, scrollable: formScrollable());
    await tester.ensureVisible(button);
    await settle(tester);
    await tester.tap(button);
    await settle(tester);
  }

  Future<void> chooseSite(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const Key('siteDropdown')));
    await settle(tester);
    await tester.tap(find.text(label).last);
    await settle(tester);
  }

  testWidgets('a saved reading appears in the list', (tester) async {
    await pumpApp(tester);
    expect(find.text('No readings yet.'), findsOneWidget);

    await openEntryForm(tester);
    await setValue(tester, systolicStepper, '132');
    await setValue(tester, diastolicStepper, '84');
    await setValue(tester, pulseStepper, '72');
    await save(tester);

    expect(find.text('132/84'), findsOneWidget);
    expect(find.text('72 bpm'), findsOneWidget);
    expect(find.text('No readings yet.'), findsNothing);

    await disposeApp(tester);
  });

  testWidgets('a new occasion starts at the default reading', (tester) async {
    await pumpApp(tester);
    await openEntryForm(tester);

    // The steppers open on a neutral default so there is always something to
    // step from; pulse stays empty because it is optional (CLAUDE.md §4).
    expect(fieldText(tester, systolicStepper), '120');
    expect(fieldText(tester, diastolicStepper), '80');
    expect(fieldText(tester, pulseStepper), '');

    await disposeApp(tester);
  });

  testWidgets('a new occasion is pre-filled from the user history', (
    tester,
  ) async {
    await pumpApp(tester);
    await openEntryForm(tester);

    // Log a reading well away from the neutral 120/80 default.
    await setValue(tester, systolicStepper, '145');
    await setValue(tester, diastolicStepper, '95');
    await setValue(tester, pulseStepper, '77');
    await save(tester);

    // A fresh occasion now opens on the user's own numbers, not 120/80: the
    // first reading is seeded from history (ROADMAP S3b).
    await openEntryForm(tester);
    expect(await readField(tester, systolicStepper), '145');
    expect(await readField(tester, diastolicStepper), '95');
    expect(await readField(tester, pulseStepper), '77');

    await disposeApp(tester);
  });

  testWidgets('a stepped value is what gets saved', (tester) async {
    await pumpApp(tester);
    await openEntryForm(tester);

    // One tap on + takes the default systolic 120 to 121; diastolic stays 80.
    await increment(tester, systolicStepper);
    await save(tester);

    expect(find.text('121/80'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('the next reading is pre-filled from the one just banked', (
    tester,
  ) async {
    await pumpApp(tester);
    await openEntryForm(tester);

    await setValue(tester, systolicStepper, '145');
    await setValue(tester, diastolicStepper, '95');
    await setValue(tester, pulseStepper, '77');
    await addAnother(tester);

    // Readings a minute apart cluster, so the second starts where the first
    // landed — no re-typing (ROADMAP ease-of-use principle).
    expect(await readField(tester, systolicStepper), '145');
    expect(await readField(tester, diastolicStepper), '95');
    expect(await readField(tester, pulseStepper), '77');

    await disposeApp(tester);
  });

  testWidgets('the reading survives the app being rebuilt', (tester) async {
    await pumpApp(tester);
    await openEntryForm(tester);
    await setValue(tester, systolicStepper, '132');
    await setValue(tester, diastolicStepper, '84');
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
    await setValue(tester, systolicStepper, '400');
    // Clear the prefilled diastolic so the "every failure is reported" path is
    // still exercised: an out-of-range systolic and a blank diastolic together.
    await setValue(tester, diastolicStepper, '');
    await save(tester);

    // Saving scrolls to the Save button; scroll back up to the fields whose
    // errors we are checking. Still on the form, both bad fields marked.
    await bringIntoView(tester, systolicStepper);
    await settle(tester);
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

    await setValue(tester, systolicStepper, '120');
    await setValue(tester, diastolicStepper, '80');
    await addAnother(tester);

    await setValue(tester, systolicStepper, '118');
    await setValue(tester, diastolicStepper, '79');
    await save(tester);

    // One occasion in the list, holding two reading rows in storage.
    final sessions = await database.select(database.sessions).get();
    final readings = await database.select(database.readings).get();
    expect(sessions, hasLength(1));
    expect(readings, hasLength(2));

    await disposeApp(tester);
  });

  testWidgets('tapping an occasion opens its detail screen', (tester) async {
    await pumpApp(tester);
    await openEntryForm(tester);

    await setValue(tester, systolicStepper, '120');
    await setValue(tester, diastolicStepper, '80');
    await addAnother(tester);

    await setValue(tester, systolicStepper, '118');
    await setValue(tester, diastolicStepper, '79');
    await save(tester);

    // The list shows only the average (mean of 120/80 and 118/79); the
    // individual readings are not on the list itself.
    expect(find.text('119/80'), findsOneWidget);
    expect(find.text('120/80'), findsNothing);
    expect(find.text('118/79'), findsNothing);

    // Tapping the row opens the occasion in full: the average, and each
    // reading behind it.
    await tester.tap(find.text('119/80'));
    await settle(tester);

    expect(find.text('Average'), findsOneWidget);
    expect(find.text('120/80'), findsOneWidget);
    expect(find.text('118/79'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('a reading keeps the context chosen for it', (tester) async {
    await pumpApp(tester);
    await openEntryForm(tester);
    await setValue(tester, systolicStepper, '120');
    await setValue(tester, diastolicStepper, '80');

    await tester.tap(find.text('Add details (optional)'));
    await settle(tester);
    await chooseSite(tester, 'Left arm');
    await save(tester);

    final readings = await database.select(database.readings).get();
    expect(readings.single.site, 'leftArm');

    await disposeApp(tester);
  });
}
