import 'package:cadence/data/database/app_database.dart';
import 'package:cadence/data/settings/drift_settings_repository.dart';
import 'package:cadence/domain/settings/app_theme_mode.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftSettingsRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftSettingsRepository(database);
  });

  tearDown(() => database.close());

  test('the disclaimer is not acknowledged on a fresh database', () async {
    expect(await repository.isDisclaimerAcknowledged(), isFalse);
  });

  test('acknowledging the disclaimer makes it acknowledged', () async {
    await repository.acknowledgeDisclaimer();

    expect(await repository.isDisclaimerAcknowledged(), isTrue);
  });

  test('acknowledging twice is idempotent, not an error', () async {
    await repository.acknowledgeDisclaimer();
    await repository.acknowledgeDisclaimer();

    expect(await repository.isDisclaimerAcknowledged(), isTrue);
  });

  // A storage failure must default to the safe answer (§1): "not acknowledged",
  // so the mandatory first-run notice is shown rather than silently skipped by
  // an unhandled exception. A closed database is a stand-in for any read/write
  // failure at the storage boundary.
  test('a read failure defaults to not-acknowledged, never throws', () async {
    await database.close();

    expect(await repository.isDisclaimerAcknowledged(), isFalse);
  });

  test('a write failure is swallowed, never throws', () async {
    await database.close();

    await expectLater(repository.acknowledgeDisclaimer(), completes);
  });

  test('the theme mode is system on a fresh database', () async {
    expect(await repository.themeMode(), AppThemeMode.system);
  });

  test('a stored theme mode round-trips', () async {
    await repository.setThemeMode(AppThemeMode.dark);

    expect(await repository.themeMode(), AppThemeMode.dark);
  });

  test('a later choice overwrites the earlier one', () async {
    await repository.setThemeMode(AppThemeMode.dark);
    await repository.setThemeMode(AppThemeMode.light);

    expect(await repository.themeMode(), AppThemeMode.light);
  });

  // A stored value that no longer maps to a known mode (e.g. an enum renamed in
  // a later version) falls back to system rather than throwing.
  test('an unknown stored value falls back to system', () async {
    await database
        .into(database.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            settingKey: 'themeMode',
            settingValue: 'sepia',
          ),
        );

    expect(await repository.themeMode(), AppThemeMode.system);
  });

  test('a theme read failure defaults to system, never throws', () async {
    await database.close();

    expect(await repository.themeMode(), AppThemeMode.system);
  });
}
