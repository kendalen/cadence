import 'package:cadence/domain/sessions/persistence_failure.dart';
import 'package:cadence/domain/sessions/validation_failure.dart';
import 'package:cadence/ui/sessions/entry/session_entry_cubit.dart';
import 'package:cadence/ui/sessions/entry/session_entry_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_id_generator.dart';
import '../../support/fake_session_repository.dart';

void main() {
  final now = DateTime(2026, 8, 23, 18);

  late FakeSessionRepository repository;
  late SessionEntryCubit cubit;

  setUp(() {
    repository = FakeSessionRepository();
    cubit = SessionEntryCubit(repository, FakeIdGenerator(), now: () => now);
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  Future<void> saveValid() =>
      cubit.save(systolic: '132', diastolic: '84', pulse: '72', notes: '');

  test('opens on now, with nothing marked wrong', () {
    expect(cubit.state, SessionEntryEditing(now));
  });

  test('stores a valid reading as a one-reading session', () async {
    await saveValid();

    final session = repository.added.single;
    expect(session.readings, hasLength(1));
    expect(session.readings.single.systolic, 132);
    expect(session.readings.single.pulse, 72);
    expect(session.id.value, isNot(session.readings.single.id.value));
  });

  test('reports the write in flight, then done', () async {
    final seen = expectLater(
      cubit.stream,
      emitsInOrder([SessionEntrySubmitting(now), SessionEntrySaved(now)]),
    );

    await saveValid();

    await seen;
  });

  test(
    'marks the bad fields and stores nothing when input is invalid',
    () async {
      await cubit.save(systolic: '', diastolic: '400', pulse: '', notes: '');

      expect(
        cubit.state,
        SessionEntryEditing(
          now,
          failures: const [
            ValueMissing(ReadingField.systolic),
            ValueOutOfRange(ReadingField.diastolic, min: 10, max: 300),
          ],
        ),
      );
      expect(repository.added, isEmpty);
    },
  );

  test('reports a refused write without losing what was typed', () async {
    repository.refuseWith = const WriteFailed('disk full');

    await saveValid();

    expect(cubit.state, SessionEntrySaveFailed(now));
  });

  test('changing the moment clears the failures already shown', () async {
    await cubit.save(systolic: '', diastolic: '', pulse: '', notes: '');
    final earlier = now.subtract(const Duration(hours: 2));

    cubit.takenAtChanged(earlier);

    expect(cubit.state, SessionEntryEditing(earlier));
  });

  test('the stored reading carries the chosen moment, in UTC', () async {
    final earlier = now.subtract(const Duration(hours: 2));
    cubit.takenAtChanged(earlier);

    await saveValid();

    final stored = repository.added.single.readings.single;
    expect(stored.takenAt.isUtc, isTrue);
    expect(stored.takenAt, earlier.toUtc());
  });

  test('ignores a second save while the first is still in flight', () async {
    final first = saveValid();
    final second = saveValid();
    await Future.wait([first, second]);

    expect(repository.added, hasLength(1));
  });

  test(
    'adds a valid reading to the banked list and clears the form of errors',
    () async {
      final earlier = now.subtract(const Duration(hours: 2));
      cubit.takenAtChanged(earlier);

      cubit.addReading(
        systolic: '120',
        diastolic: '80',
        pulse: '70',
        notes: '',
      );

      final state = cubit.state as SessionEntryEditing;
      expect(state.bankedReadings, hasLength(1));
      expect(state.bankedReadings.single.systolic, 120);
      expect(state.failures, isEmpty);
    },
  );

  test(
    'resets the moment to one minute after the reading just banked',
    () async {
      final earlier = now.subtract(const Duration(hours: 2));
      cubit.takenAtChanged(earlier);

      cubit.addReading(systolic: '120', diastolic: '80', pulse: '', notes: '');

      expect(cubit.state.takenAt, earlier.add(const Duration(minutes: 1)));
    },
  );

  test('never resets the moment past now', () async {
    // takenAt defaults to now; +1 minute would be in the future, so it clamps.
    cubit.addReading(systolic: '120', diastolic: '80', pulse: '', notes: '');

    expect(cubit.state.takenAt, now);
  });

  test('an invalid reading is not banked and its errors are shown', () async {
    cubit.addReading(systolic: '', diastolic: '400', pulse: '', notes: '');

    final state = cubit.state as SessionEntryEditing;
    expect(state.bankedReadings, isEmpty);
    expect(state.failures, isNotEmpty);
  });

  test('changing the moment keeps the banked readings', () async {
    cubit.addReading(systolic: '120', diastolic: '80', pulse: '', notes: '');
    final banked = cubit.state.bankedReadings;

    cubit.takenAtChanged(now.subtract(const Duration(hours: 1)));

    expect(cubit.state.bankedReadings, banked);
  });
}
