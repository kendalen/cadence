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
}
