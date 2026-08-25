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
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

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

  test('a fresh database matches the committed v2 snapshot', () async {
    final connection = await verifier.startAt(2);
    final database = AppDatabase.forTesting(connection);

    await verifier.migrateAndValidate(database, 2);

    await database.close();
  });

  test('a fresh database matches the committed v3 snapshot', () async {
    final connection = await verifier.startAt(3);
    final database = AppDatabase.forTesting(connection);

    await verifier.migrateAndValidate(database, 3);

    await database.close();
  });

  test(
    'migrating v2 to v3 keeps existing readings and adds the settings table',
    () async {
      // A reading written before the settings table existed must survive the
      // upgrade untouched, and the new table must be present and usable.
      final schema = await verifier.schemaAt(2);
      final oldDatabase = v2.DatabaseAtV2(schema.newConnection());
      await oldDatabase.customStatement(
        "INSERT INTO sessions (id) VALUES ('s1')",
      );
      await oldDatabase.customStatement(
        "INSERT INTO readings (id, session_id, systolic, diastolic, taken_at) "
        "VALUES ('r1', 's1', 128, 84, '2026-08-24T07:10:00.000Z')",
      );
      await oldDatabase.close();

      final database = AppDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(database, 3);

      final reading = await database
          .customSelect("SELECT systolic FROM readings WHERE id = 'r1'")
          .getSingle();
      expect(reading.read<int>('systolic'), 128);

      // The new table exists and takes a row.
      await database.customStatement(
        "INSERT INTO app_settings (setting_key, setting_value) "
        "VALUES ('disclaimerAcknowledged', 'true')",
      );
      final setting = await database
          .customSelect(
            "SELECT setting_value FROM app_settings "
            "WHERE setting_key = 'disclaimerAcknowledged'",
          )
          .getSingle();
      expect(setting.read<String>('setting_value'), 'true');

      await database.close();
    },
  );

  test(
    'migrating v1 to v2 keeps existing readings and leaves context null',
    () async {
      // A reading written before the context fields existed must survive the
      // upgrade untouched, with the three new columns defaulting to null.
      final schema = await verifier.schemaAt(1);
      final oldDatabase = v1.DatabaseAtV1(schema.newConnection());
      await oldDatabase.customStatement(
        "INSERT INTO sessions (id) VALUES ('s1')",
      );
      await oldDatabase.customStatement(
        "INSERT INTO readings (id, session_id, systolic, diastolic, taken_at) "
        "VALUES ('r1', 's1', 120, 80, '2026-08-23T06:40:00.000Z')",
      );
      await oldDatabase.close();

      final database = AppDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(database, 2);

      final row = await database
          .customSelect(
            "SELECT systolic, site, posture, medication_timing "
            "FROM readings WHERE id = 'r1'",
          )
          .getSingle();

      expect(row.read<int>('systolic'), 120);
      expect(row.readNullable<String>('site'), isNull);
      expect(row.readNullable<String>('posture'), isNull);
      expect(row.readNullable<String>('medication_timing'), isNull);

      await database.close();
    },
  );
}
