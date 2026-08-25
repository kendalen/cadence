// Reproduces the bug where a scroll view's content sat under an Android system
// bar: withSystemInsets must grow the padding by the system inset on the sides
// and bottom so a Save button or a card's border clears the bar — including the
// landscape case where the bar (or cutout) moves to a side edge (CLAUDE.md §7 —
// a bug fix starts with a test).

import 'package:cadence/ui/system_insets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<EdgeInsets> resolve(
    WidgetTester tester,
    EdgeInsets systemPadding,
    EdgeInsets base,
  ) async {
    late EdgeInsets result;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(padding: systemPadding),
        child: Builder(
          builder: (context) {
            result = withSystemInsets(context, base);
            return const SizedBox();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('adds the system bottom inset to the base padding', (
    tester,
  ) async {
    final padding = await resolve(
      tester,
      const EdgeInsets.only(bottom: 48),
      const EdgeInsets.all(16),
    );

    expect(padding, const EdgeInsets.fromLTRB(16, 16, 16, 64));
  });

  testWidgets('adds a landscape side inset so content clears a side bar', (
    tester,
  ) async {
    // Bar and cutout on the two sides, nothing at the bottom (a common
    // landscape arrangement): the base grows left and right, not the bottom.
    final padding = await resolve(
      tester,
      const EdgeInsets.only(left: 24, right: 40),
      const EdgeInsets.all(16),
    );

    expect(padding, const EdgeInsets.fromLTRB(40, 16, 56, 16));
  });

  testWidgets('leaves the top to the app bar', (tester) async {
    final padding = await resolve(
      tester,
      const EdgeInsets.only(top: 30),
      const EdgeInsets.all(16),
    );

    expect(padding, const EdgeInsets.all(16));
  });

  testWidgets('leaves the base unchanged when there is no system inset', (
    tester,
  ) async {
    final padding = await resolve(
      tester,
      EdgeInsets.zero,
      const EdgeInsets.all(16),
    );

    expect(padding, const EdgeInsets.all(16));
  });
}
