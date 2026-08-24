import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

import 'data/database/app_database.dart';
import 'data/ids/uuid_id_generator.dart';
import 'data/sessions/drift_session_repository.dart';
import 'ui/app.dart';

/// Composition root: the one place that knows which implementations the app
/// runs on.
void main() {
  _registerBundledFontLicenses();

  final database = AppDatabase();

  // The database is deliberately not closed on teardown. Every write commits
  // in its own transaction, so there is nothing buffered to flush, and Android
  // gives no callback that is guaranteed to run before the process dies —
  // relying on one would be a false guarantee. The export slice adds the
  // wal_checkpoint(TRUNCATE) that copying the file does need (CLAUDE.md §5).
  runApp(
    CadenceApp(
      sessionRepository: DriftSessionRepository(database),
      idGenerator: const UuidIdGenerator(),
    ),
  );
}

/// Registers the licences of the fonts bundled with the app so they appear in
/// the standard Flutter "Licenses" page.
///
/// Hanken Grotesk ships under the SIL Open Font License 1.1, which requires the
/// licence to travel with the font wherever the font is redistributed — and the
/// release APK does redistribute it (assets/fonts/OFL.txt).
void _registerBundledFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Hanken Grotesk'], license);
  });
}
