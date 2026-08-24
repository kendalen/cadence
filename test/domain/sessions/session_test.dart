import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/session.dart';
import 'package:cadence/domain/sessions/session_average.dart';
import 'package:flutter_test/flutter_test.dart';

Reading readingAt(String id, DateTime takenAt) =>
    Reading(id: ReadingId(id), systolic: 120, diastolic: 80, takenAt: takenAt);

Reading readingOf({
  String id = 'r',
  int systolic = 120,
  int diastolic = 80,
  int? pulse,
}) => Reading(
  id: ReadingId(id),
  systolic: systolic,
  diastolic: diastolic,
  pulse: pulse,
  takenAt: DateTime.utc(2026, 8, 23, 7, 30),
);

Session sessionOf(List<Reading> readings) =>
    Session(id: const SessionId('s1'), readings: readings);

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

  group('Session.average', () {
    test('is the reading itself for a single-reading session', () {
      final session = sessionOf([
        readingOf(systolic: 128, diastolic: 81, pulse: 60),
      ]);

      expect(
        session.average,
        const SessionAverage(systolic: 128, diastolic: 81, pulse: 60),
      );
    });

    test('has no pulse when the single reading recorded none', () {
      final session = sessionOf([readingOf(systolic: 128, diastolic: 81)]);

      expect(session.average.pulse, isNull);
    });

    test('means systolic and diastolic separately, rounding a half up', () {
      // 128 & 131 -> 129.5 -> 130; 80 & 83 -> 81.5 -> 82.
      final session = sessionOf([
        readingOf(id: 'r1', systolic: 128, diastolic: 80),
        readingOf(id: 'r2', systolic: 131, diastolic: 83),
      ]);

      expect(session.average.systolic, 130);
      expect(session.average.diastolic, 82);
    });

    test(
      'means the pulse of readings that recorded one, rounding a half up',
      () {
        // 60 & 63 -> 61.5 -> 62.
        final session = sessionOf([
          readingOf(id: 'r1', pulse: 60),
          readingOf(id: 'r2', pulse: 63),
        ]);

        expect(session.average.pulse, 62);
      },
    );

    test('ignores readings with no pulse when meaning the pulse', () {
      // Only the reading that recorded a pulse counts: mean of {70} is 70.
      final session = sessionOf([
        readingOf(id: 'r1', pulse: 70),
        readingOf(id: 'r2'),
      ]);

      expect(session.average.pulse, 70);
    });

    test('has no pulse when no reading recorded one', () {
      final session = sessionOf([readingOf(id: 'r1'), readingOf(id: 'r2')]);

      expect(session.average.pulse, isNull);
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
