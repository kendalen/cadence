// The first-run gate is behaviour, not layout (CLAUDE.md §7): it decides whether
// the one-time "diary, not a device" notice (§1) is shown, and records the
// acknowledgement when the user dismisses it. These tests pin that decision, not
// how the notice looks.

import 'package:cadence/domain/sessions/session_repository.dart';
import 'package:cadence/domain/settings/settings_repository.dart';
import 'package:cadence/l10n/app_localizations.dart';
import 'package:cadence/ui/first_run_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_session_repository.dart';
import '../support/fake_settings_repository.dart';

void main() {
  Future<void> pumpGate(
    WidgetTester tester,
    SettingsRepository settings,
  ) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<SessionRepository>.value(
            value: FakeSessionRepository(),
          ),
          RepositoryProvider<SettingsRepository>.value(value: settings),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FirstRunGate(),
        ),
      ),
    );
    // Bounded pumps rather than pumpAndSettle: the list underneath shows an
    // endless progress spinner, which never settles.
    await tester.pump(); // fires the post-frame callback
    await tester.pump(const Duration(milliseconds: 50)); // async read resolves
    await tester.pump(const Duration(milliseconds: 300)); // dialog fades in
  }

  testWidgets('shows the notice on first run and records acknowledgement', (
    tester,
  ) async {
    final settings = FakeSettingsRepository();

    await pumpGate(tester, settings);

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pump(); // process the tap
    await tester.pump(const Duration(seconds: 1)); // close animation

    expect(find.byType(AlertDialog), findsNothing);
    expect(settings.acknowledgeCount, 1);
  });

  testWidgets('does not show the notice once acknowledged', (tester) async {
    final settings = FakeSettingsRepository(acknowledged: true);

    await pumpGate(tester, settings);

    expect(find.byType(AlertDialog), findsNothing);
    expect(settings.acknowledgeCount, 0);
  });
}
