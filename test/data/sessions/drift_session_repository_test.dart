import 'package:cadence/data/database/app_database.dart';
import 'package:cadence/data/sessions/drift_session_repository.dart';
import 'package:cadence/domain/core/result.dart';
import 'package:cadence/domain/core/unit.dart';
import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/persistence_failure.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/reading_context.dart';
import 'package:cadence/domain/sessions/session.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Session sessionOf(String id, List<Reading> readings) =>
    Session(id: SessionId(id), readings: readings);

Reading readingOf(
  String id,
  DateTime takenAt, {
  int systolic = 132,
  int diastolic = 84,
  int? pulse,
  String? notes,
  MeasurementSite? site,
  Posture? posture,
  MedicationTiming? medicationTiming,
}) => Reading(
  id: ReadingId(id),
  systolic: systolic,
  diastolic: diastolic,
  pulse: pulse,
  takenAt: takenAt,
  notes: notes,
  site: site,
  posture: posture,
  medicationTiming: medicationTiming,
);

void main() {
  late AppDatabase database;
  late DriftSessionRepository repository;

  final morning = DateTime.utc(2026, 8, 23, 6, 40);
  final evening = DateTime.utc(2026, 8, 23, 19, 5);

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftSessionRepository(database);
  });

  tearDown(() => database.close());

  test('watchAll emits an empty list when nothing is stored', () {
    expect(repository.watchAll(), emits(isEmpty));
  });

  test('a stored session comes back with every field intact', () async {
    final session = sessionOf('s1', [
      readingOf('r1', morning, pulse: 72, notes: 'after a walk'),
    ]);

    final result = await repository.add(session);

    expect(result, const Ok<Unit, PersistenceFailure>(unit));
    expect(await repository.watchAll().first, [session]);
  });

  test('an absent pulse and note round-trip as null', () async {
    await repository.add(sessionOf('s1', [readingOf('r1', morning)]));

    final stored = (await repository.watchAll().first).single.readings.single;

    expect(stored.pulse, isNull);
    expect(stored.notes, isNull);
  });

  test("a reading's context round-trips intact", () async {
    await repository.add(
      sessionOf('s1', [
        readingOf(
          'r1',
          morning,
          site: MeasurementSite.leftArm,
          posture: Posture.sitting,
          medicationTiming: MedicationTiming.before,
        ),
      ]),
    );

    final stored = (await repository.watchAll().first).single.readings.single;

    expect(stored.site, MeasurementSite.leftArm);
    expect(stored.posture, Posture.sitting);
    expect(stored.medicationTiming, MedicationTiming.before);
  });

  test('unrecorded context round-trips as null', () async {
    await repository.add(sessionOf('s1', [readingOf('r1', morning)]));

    final stored = (await repository.watchAll().first).single.readings.single;

    expect(stored.site, isNull);
    expect(stored.posture, isNull);
    expect(stored.medicationTiming, isNull);
  });

  test('sessions are emitted newest occasion first', () async {
    await repository.add(sessionOf('morning', [readingOf('r1', morning)]));
    await repository.add(sessionOf('evening', [readingOf('r2', evening)]));

    final ids = (await repository.watchAll().first)
        .map((session) => session.id.value)
        .toList();

    expect(ids, ['evening', 'morning']);
  });

  test('the readings of a session are emitted oldest first', () async {
    final second = morning.add(const Duration(minutes: 1));
    await repository.add(
      sessionOf('s1', [
        readingOf('later', second),
        readingOf('first', morning),
      ]),
    );

    final ids = (await repository.watchAll().first).single.readings
        .map((reading) => reading.id.value)
        .toList();

    expect(ids, ['first', 'later']);
  });

  test('watchAll emits again when a session is added', () async {
    final emitted = <int>[];
    final subscription = repository.watchAll().listen(
      (sessions) => emitted.add(sessions.length),
    );
    await pumpEventQueue();

    await repository.add(sessionOf('s1', [readingOf('r1', morning)]));
    await pumpEventQueue();
    await repository.add(sessionOf('s2', [readingOf('r2', evening)]));
    await pumpEventQueue();
    await subscription.cancel();

    expect(emitted, [0, 1, 2]);
  });

  test('add reports a failure instead of throwing on a duplicate id', () async {
    final session = sessionOf('s1', [readingOf('r1', morning)]);
    await repository.add(session);

    final result = await repository.add(session);

    expect(result, isA<Err<Unit, PersistenceFailure>>());
    expect(await repository.watchAll().first, hasLength(1));
  });

  test('deleting a session deletes its readings', () async {
    await repository.add(sessionOf('s1', [readingOf('r1', morning)]));

    await database.delete(database.sessions).go();

    expect(await database.select(database.readings).get(), isEmpty);
  });

  test('recentHistory is empty when nothing is stored', () async {
    expect(await repository.recentHistory(), isEmpty);
  });

  test(
    'recentHistory returns stored sessions, newest occasion first',
    () async {
      await repository.add(sessionOf('morning', [readingOf('r1', morning)]));
      await repository.add(sessionOf('evening', [readingOf('r2', evening)]));

      final ids = (await repository.recentHistory())
          .map((session) => session.id.value)
          .toList();

      expect(ids, ['evening', 'morning']);
    },
  );

  test('recentHistory groups a session\'s readings together', () async {
    final second = morning.add(const Duration(minutes: 1));
    await repository.add(
      sessionOf('s1', [readingOf('r1', morning), readingOf('r2', second)]),
    );

    final history = await repository.recentHistory();

    expect(history.single.readings, hasLength(2));
  });

  test('delete removes the session and its readings', () async {
    await repository.add(sessionOf('s1', [readingOf('r1', morning)]));
    await repository.add(sessionOf('s2', [readingOf('r2', evening)]));

    final result = await repository.delete(const SessionId('s1'));

    expect(result, const Ok<Unit, PersistenceFailure>(unit));
    final remaining = (await repository.watchAll().first)
        .map((session) => session.id.value)
        .toList();
    expect(remaining, ['s2']);
    expect(await database.select(database.readings).get(), hasLength(1));
  });

  test(
    'deleting an absent session succeeds without changing anything',
    () async {
      await repository.add(sessionOf('s1', [readingOf('r1', morning)]));

      final result = await repository.delete(const SessionId('gone'));

      expect(result, const Ok<Unit, PersistenceFailure>(unit));
      expect(await repository.watchAll().first, hasLength(1));
    },
  );

  test('update replaces a reading\'s values in place', () async {
    await repository.add(
      sessionOf('s1', [readingOf('r1', morning, systolic: 120, diastolic: 80)]),
    );

    final edited = sessionOf('s1', [
      readingOf('r1', morning, systolic: 130, diastolic: 85, pulse: 66),
    ]);
    final result = await repository.update(edited);

    expect(result, const Ok<Unit, PersistenceFailure>(unit));
    final stored = (await repository.watchAll().first).single.readings.single;
    expect(stored.systolic, 130);
    expect(stored.diastolic, 85);
    expect(stored.pulse, 66);
  });

  test('update can drop a reading from a session', () async {
    final second = morning.add(const Duration(minutes: 1));
    await repository.add(
      sessionOf('s1', [readingOf('r1', morning), readingOf('r2', second)]),
    );

    await repository.update(sessionOf('s1', [readingOf('r1', morning)]));

    final ids = (await repository.watchAll().first).single.readings
        .map((reading) => reading.id.value)
        .toList();
    expect(ids, ['r1']);
  });

  test('takenAt is stored as UTC ISO-8601 text', () async {
    await repository.add(sessionOf('s1', [readingOf('r1', morning)]));

    final stored = await database
        .customSelect('SELECT typeof(taken_at) AS kind, taken_at FROM readings')
        .getSingle();

    expect(stored.read<String>('kind'), 'text');
    expect(stored.read<String>('taken_at'), startsWith('2026-08-23T06:40'));
  });
}
