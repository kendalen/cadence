// The migration harness (CLAUDE.md §5). Every schemaVersion bump adds a case
// here and a committed snapshot under lib/data/schema/; a schema change without
// a passing test in this file does not get merged.
//
// Regenerate the helpers in generated/ after dumping a new snapshot:
//   dart run drift_dev schema dump lib/data/database/app_database.dart lib/data/schema/
//   dart run drift_dev schema generate lib/data/schema/ test/data/schema/generated/

import 'package:cadence/data/database/app_database.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('a fresh database matches the committed v1 snapshot', () async {
    final connection = await verifier.startAt(1);
    final database = AppDatabase.forTesting(connection);

    await verifier.migrateAndValidate(database, 1);

    await database.close();
  });
}
