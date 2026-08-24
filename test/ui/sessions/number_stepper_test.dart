// Behaviour of the number stepper: the big value with a − / + on either side
// used for systolic, diastolic and pulse on the entry form. These assert what
// the control *does* (steps, clamps, clears), not how it is laid out, so they
// are the behaviour tests CLAUDE.md §7 allows rather than the structural widget
// tests it warns against.

import 'package:cadence/ui/sessions/entry/number_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpStepper(
    WidgetTester tester,
    TextEditingController controller, {
    int min = 10,
    int max = 300,
    bool clearable = false,
    int? startWhenEmpty,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NumberStepper(
          controller: controller,
          label: 'Systolic (mmHg)',
          min: min,
          max: max,
          decrementLabel: 'Decrease systolic',
          incrementLabel: 'Increase systolic',
          clearable: clearable,
          clearLabel: 'Clear pulse',
          startWhenEmpty: startWhenEmpty,
        ),
      ),
    ),
  );

  testWidgets('+ increases the value by one', (tester) async {
    final controller = TextEditingController(text: '120');
    addTearDown(controller.dispose);

    await pumpStepper(tester, controller);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(controller.text, '121');
  });

  testWidgets('− decreases the value by one', (tester) async {
    final controller = TextEditingController(text: '120');
    addTearDown(controller.dispose);

    await pumpStepper(tester, controller);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(controller.text, '119');
  });

  testWidgets('+ stops at the maximum', (tester) async {
    final controller = TextEditingController(text: '300');
    addTearDown(controller.dispose);

    await pumpStepper(tester, controller, max: 300);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(controller.text, '300');
  });

  testWidgets('− stops at the minimum', (tester) async {
    final controller = TextEditingController(text: '10');
    addTearDown(controller.dispose);

    await pumpStepper(tester, controller, min: 10);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(controller.text, '10');
  });

  testWidgets('typing a value is not clamped, so the typo guard still runs', (
    tester,
  ) async {
    final controller = TextEditingController(text: '120');
    addTearDown(controller.dispose);

    await pumpStepper(tester, controller, max: 300);
    await tester.enterText(find.byType(TextField), '400');
    await tester.pump();

    // The stepper does not silently correct 400 down to 300: it leaves the
    // out-of-range value in place so ReadingInput.validate can flag the typo.
    expect(controller.text, '400');
  });

  testWidgets('a clearable field can be emptied to "not recorded"', (
    tester,
  ) async {
    final controller = TextEditingController(text: '72');
    addTearDown(controller.dispose);

    await pumpStepper(tester, controller, clearable: true);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(controller.text, '');
  });

  testWidgets('+ on an empty clearable field starts at the empty-start value', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpStepper(tester, controller, clearable: true, startWhenEmpty: 60);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(controller.text, '60');
  });
}
