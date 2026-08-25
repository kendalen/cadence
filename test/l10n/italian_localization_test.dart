// Italian localisation (S10): the app_it.arb strings load, and the tricky bits
// survive generation — the ICU plural forms pick the right Italian, and an
// escaped apostrophe ('') decodes to a single apostrophe at runtime. The wording
// itself is the maintainer's to review; this only guards the mechanics.

import 'package:cadence/l10n/app_localizations.dart';
import 'package:cadence/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<AppLocalizations> loadItalian(WidgetTester tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return l10n;
  }

  testWidgets('Italian is a supported locale', (tester) async {
    expect(AppLocalizations.supportedLocales, contains(const Locale('it')));
  });

  // Regression: app_en.arb once defined "removeReading" twice, so the short
  // entry-form tooltip silently rendered "Remove this reading". The two actions
  // now have distinct keys — the short "Remove" and the long form must not collide.
  test('the two remove-reading strings are distinct', () {
    final en = AppLocalizationsEn();
    expect(en.removeReading, 'Remove');
    expect(en.removeReadingFromOccasion, 'Remove this reading');
  });

  testWidgets('resolves Italian, including plurals and escaped apostrophes', (
    tester,
  ) async {
    final l10n = await loadItalian(tester);

    // A plain string, confirming the locale actually resolved to Italian.
    expect(l10n.addReading, 'Aggiungi una misurazione');

    // Plural forms (=1 vs other).
    expect(l10n.readingCount(1), '1 misurazione');
    expect(l10n.readingCount(4), '4 misurazioni');

    // =0 / =1 / other in the import summary, with feminine agreement.
    expect(
      l10n.importBackupSummary(0),
      'Nessuna nuova occasione da aggiungere.',
    );
    expect(l10n.importBackupSummary(1), 'Aggiunta 1 occasione.');
    expect(l10n.importBackupSummary(5), 'Aggiunte 5 occasioni.');

    // The ARB escapes the elision apostrophe as ''; at runtime it is a single '.
    expect(l10n.addAnotherReading, "Aggiungi un'altra misurazione");
  });
}
