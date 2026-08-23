import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/session.dart';
import 'package:flutter_test/flutter_test.dart';

Reading readingAt(String id, DateTime takenAt) =>
    Reading(id: ReadingId(id), systolic: 120, diastolic: 80, takenAt: takenAt);

void main() {
  final earlier = DateTime.utc(2026, 8, 23, 7, 30);
  final later = DateTime.utc(2026, 8, 23, 7, 31);

  group('Session.occurredAt', () {
    test('is the only reading takenAt for a single-reading session', () {
      final session = Session(
        id: const SessionId('s1'),
        readings: [readingAt('r1', earlier)],
      );

      expect(session.occurredAt, earlier);
    });

    test('is the earliest reading takenAt, whatever the list order', () {
      final inOrder = Session(
        id: const SessionId('s1'),
        readings: [readingAt('r1', earlier), readingAt('r2', later)],
      );
      final reversed = Session(
        id: const SessionId('s1'),
        readings: [readingAt('r1', later), readingAt('r2', earlier)],
      );

      expect(inOrder.occurredAt, earlier);
      expect(reversed.occurredAt, earlier);
    });
  });

  group('Session', () {
    test('rejects an empty reading list', () {
      expect(
        () => Session(id: const SessionId('s1'), readings: const []),
        throwsA(isA<AssertionError>()),
      );
    });

    test('compares by value, including its readings', () {
      final one = Session(
        id: const SessionId('s1'),
        readings: [readingAt('r1', earlier)],
      );
      final same = Session(
        id: const SessionId('s1'),
        readings: [readingAt('r1', earlier)],
      );
      final otherReadings = Session(
        id: const SessionId('s1'),
        readings: [readingAt('r1', later)],
      );

      expect(one, same);
      expect(one, isNot(otherReadings));
    });
  });

  group('Reading', () {
    test('compares by value', () {
      expect(readingAt('r1', earlier), readingAt('r1', earlier));
      expect(readingAt('r1', earlier), isNot(readingAt('r2', earlier)));
    });

    test('rejects a takenAt that is not UTC', () {
      expect(
        () => readingAt('r1', DateTime(2026, 8, 23, 7, 30)),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
