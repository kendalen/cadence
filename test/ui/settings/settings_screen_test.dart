// The Settings screen's behaviour (CLAUDE.md §7): it offers the export ranges
// and, when the diary is empty, refuses to write an empty file. The actual
// build-and-share of a non-empty export goes through the native share sheet
// (share_plus) and is left untested, the same boundary as the JSON backup and
// the old overflow-menu export.

import 'package:cadence/domain/sessions/session_repository.dart';
import 'package:cadence/domain/settings/app_theme_mode.dart';
import 'package:cadence/l10n/app_localizations.dart';
import 'package:cadence/ui/settings/settings_screen.dart';
import 'package:cadence/ui/theme/theme_mode_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_session_repository.dart';
import '../../support/fake_settings_repository.dart';

void main() {
  late FakeSessionRepository repository;
  late FakeSettingsRepository settings;

  setUp(() {
    repository = FakeSessionRepository();
    settings = FakeSettingsRepository();
  });
  tearDown(() => repository.dispose());

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryProvider<SessionRepository>.value(
        value: repository,
        child: BlocProvider(
          create: (_) => ThemeModeCubit(settings, AppThemeMode.system),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final l10n = lookupAppLocalizations(const Locale('en'));

  testWidgets('offers every export range and the About entry', (tester) async {
    await pumpSettings(tester);

    expect(find.text(l10n.settingsExportRangeLast7), findsOneWidget);
    expect(find.text(l10n.settingsExportRangeLast30), findsOneWidget);
    expect(find.text(l10n.settingsExportRangeLast90), findsOneWidget);
    expect(find.text(l10n.settingsExportRangeAll), findsOneWidget);
    // The export buttons and About sit lower down; scroll them into view (the
    // list grew once the Appearance and Reference sections were added above).
    await tester.scrollUntilVisible(find.text(l10n.exportCsv), 200);
    expect(find.text(l10n.exportCsv), findsOneWidget);
    expect(find.text(l10n.exportPdf), findsOneWidget);
    await tester.scrollUntilVisible(find.text(l10n.aboutMenu), 200);
    expect(find.text(l10n.aboutMenu), findsOneWidget);
  });

  testWidgets('offers the three theme options', (tester) async {
    await pumpSettings(tester);

    expect(find.text(l10n.settingsThemeSystem), findsOneWidget);
    expect(find.text(l10n.settingsThemeLight), findsOneWidget);
    expect(find.text(l10n.settingsThemeDark), findsOneWidget);
  });

  testWidgets('picking a theme persists the choice', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text(l10n.settingsThemeDark));
    await tester.pumpAndSettle();

    expect(await settings.themeMode(), AppThemeMode.dark);
  });

  testWidgets('exporting an empty diary reports it instead of sharing', (
    tester,
  ) async {
    // history stays empty, so the range filter yields nothing to export.
    await pumpSettings(tester);

    await tester.scrollUntilVisible(find.text(l10n.exportCsv), 200);
    await tester.tap(find.text(l10n.exportCsv));
    await tester.pump(); // fire the async handler
    await tester.pump(); // recentHistory() resolves, snackbar shows

    expect(find.text(l10n.exportEmpty), findsOneWidget);
  });
}
