import 'package:cadence/data/database/app_database.dart';
import 'package:cadence/data/settings/drift_settings_repository.dart';
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
}
