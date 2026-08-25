// Reproduces the bug where a scroll view's last button (Save / Delete) sat
// under the Android navigation bar: withSystemBottomInset must grow the bottom
// padding by the system inset so the button clears the bar (CLAUDE.md §7 — a
// bug fix starts with a test).

import 'package:cadence/ui/system_insets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<EdgeInsets> resolve(
    WidgetTester tester,
    double bottomInset,
    EdgeInsets base,
  ) async {
    late EdgeInsets result;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(padding: EdgeInsets.only(bottom: bottomInset)),
        child: Builder(
          builder: (context) {
            result = withSystemBottomInset(context, base);
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
    final padding = await resolve(tester, 48, const EdgeInsets.all(16));

    expect(padding, const EdgeInsets.fromLTRB(16, 16, 16, 64));
  });

  testWidgets('leaves the base unchanged when there is no bottom inset', (
    tester,
  ) async {
    final padding = await resolve(tester, 0, const EdgeInsets.all(16));

    expect(padding, const EdgeInsets.all(16));
  });
}
