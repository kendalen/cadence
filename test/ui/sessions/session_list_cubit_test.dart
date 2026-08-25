import 'dart:convert';

import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/session.dart';
import 'package:cadence/ui/sessions/list/session_list_cubit.dart';
import 'package:cadence/ui/sessions/list/session_list_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_session_repository.dart';

Session sessionOf(String id) => Session(
  id: SessionId(id),
  readings: [
    Reading(
      id: ReadingId('$id-r1'),
      systolic: 132,
      diastolic: 84,
      takenAt: DateTime.utc(2026, 8, 23, 6, 40),
    ),
  ],
);

void main() {
  late FakeSessionRepository repository;
  late SessionListCubit cubit;

  setUp(() {
    repository = FakeSessionRepository();
    cubit = SessionListCubit(repository);
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test('starts out loading, before the store has answered', () {
    expect(cubit.state, const SessionListLoading());
  });

  test('emits what the store reports, including nothing at all', () async {
    final seen = expectLater(
      cubit.stream,
      emitsInOrder([
        const SessionListLoaded([]),
        SessionListLoaded([sessionOf('s1')]),
      ]),
    );

    repository
      ..emit([])
      ..emit([sessionOf('s1')]);

    await seen;
  });

  test('stops listening once closed', () async {
    await cubit.close();

    repository.emit([sessionOf('s1')]);

    expect(cubit.state, const SessionListLoading());
  });

  test('builds a backup JSON of every stored session', () async {
    repository.history = [sessionOf('s1')];

    final json = await cubit.buildBackupJson(now: DateTime.utc(2026, 8, 25));
    final backup = jsonDecode(json) as Map<String, Object?>;

    expect(backup['format'], 'cadence.backup');
    expect(backup['version'], 1);
    expect(backup['exportedAt'], '2026-08-25T00:00:00.000Z');
    expect((backup['sessions'] as List).single, {
      'id': 's1',
      'readings': [
        {
          'id': 's1-r1',
          'systolic': 132,
          'diastolic': 84,
          'takenAt': '2026-08-23T06:40:00.000Z',
        },
      ],
    });
  });
}
