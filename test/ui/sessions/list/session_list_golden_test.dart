// Golden test pinning the readings list in the warm "design foundation" theme
// (STATUS.md, 2026-08-24). Golden tests are the one kind of UI test CLAUDE.md §7
// asks for — a key screen, not assertions about widget structure.
//
// The empty state is chosen deliberately: it exercises the theme's chrome (the
// paper background, the app bar, the two text styles, the clay "Add a reading"
// FAB) while rendering no timestamps. A populated list would show
// `occurredAt.toLocal()`, whose text differs between the maintainer's machine
// and the UTC CI runner and would make the image environment-dependent. The
// suite-wide tolerant comparator (test/flutter_test_config.dart) absorbs the
// remaining cross-platform anti-aliasing.

import 'package:cadence/domain/sessions/session_repository.dart';
import 'package:cadence/l10n/app_localizations.dart';
import 'package:cadence/ui/sessions/list/session_list_screen.dart';
import 'package:cadence/ui/theme/cadence_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_session_repository.dart';

void main() {
  setUpAll(() async {
    // Draw the golden with the real bundled font rather than the test
    // framework's blank fallback, so the image is stable and legible.
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('HankenGrotesk')
      ..addFont(
        rootBundle.load('assets/fonts/HankenGrotesk-VariableFont_wght.ttf'),
      );
    await loader.load();
  });

  testWidgets('readings list — empty state in the warm theme', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeSessionRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      RepositoryProvider<SessionRepository>.value(
        value: repository,
        child: MaterialApp(
          theme: buildCadenceTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SessionListScreen(),
        ),
      ),
    );

    // The list starts on a loading spinner and shows the empty state once the
    // store answers; the fake's stream only speaks when told to.
    repository.emit(const []);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SessionListScreen),
      matchesGoldenFile('goldens/session_list_empty.png'),
    );
  });
}
