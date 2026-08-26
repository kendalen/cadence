import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/reading_context.dart';
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
  DateTime? takenAt,
  MeasurementSite? site,
  Posture? posture,
  MedicationTiming? medicationTiming,
  String? notes,
}) => Reading(
  id: ReadingId(id),
  systolic: systolic,
  diastolic: diastolic,
  pulse: pulse,
  takenAt: takenAt ?? DateTime.utc(2026, 8, 23, 7, 30),
  site: site,
  posture: posture,
  medicationTiming: medicationTiming,
  notes: notes,
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
      // Throws (not asserts) so the invariant holds in release builds too (§4).
      expect(
        () => Session(id: const SessionId('s1'), readings: const []),
        throwsArgumentError,
      );
    });

    test('holds its readings unmodifiable', () {
      final session = Session(
        id: const SessionId('s1'),
        readings: [readingAt('r1', DateTime.utc(2026, 8, 23, 7))],
      );

      expect(
        () =>
            session.readings.add(readingAt('r2', DateTime.utc(2026, 8, 23, 8))),
        throwsUnsupportedError,
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

  group('Session.readingsByTime', () {
    test(
      'is the readings in ascending time order, whatever the list order',
      () {
        final first = readingOf(
          id: 'r1',
          takenAt: DateTime.utc(2026, 8, 23, 7),
        );
        final second = readingOf(
          id: 'r2',
          takenAt: DateTime.utc(2026, 8, 23, 8),
        );
        final third = readingOf(
          id: 'r3',
          takenAt: DateTime.utc(2026, 8, 23, 9),
        );
        final session = sessionOf([third, first, second]);

        expect(session.readingsByTime, [first, second, third]);
      },
    );

    test('leaves the original readings list untouched', () {
      final later = readingOf(id: 'r1', takenAt: DateTime.utc(2026, 8, 23, 9));
      final earlier = readingOf(
        id: 'r2',
        takenAt: DateTime.utc(2026, 8, 23, 7),
      );
      final readings = [later, earlier];
      final session = sessionOf(readings);

      session.readingsByTime;

      expect(readings, [later, earlier]);
    });
  });

  group('Session.withReadingReplaced', () {
    test('swaps in the reading with the matching id, keeping the rest', () {
      final original = readingOf(id: 'r1', systolic: 120, diastolic: 80);
      final other = readingOf(id: 'r2', systolic: 118, diastolic: 78);
      final session = sessionOf([original, other]);

      final edited = readingOf(id: 'r1', systolic: 130, diastolic: 85);
      final result = session.withReadingReplaced(edited);

      expect(result.readings, [edited, other]);
      expect(result.id, session.id);
    });

    test('throws when no reading has the replacement id', () {
      final session = sessionOf([readingOf(id: 'r1')]);

      expect(
        () => session.withReadingReplaced(readingOf(id: 'unknown')),
        throwsStateError,
      );
    });
  });

  group('Session.withReadingAdded', () {
    test('appends the reading, keeping the id and the existing ones', () {
      final first = readingOf(id: 'r1');
      final session = sessionOf([first]);

      final added = readingOf(id: 'r2');
      final result = session.withReadingAdded(added);

      expect(result.readings, [first, added]);
      expect(result.id, session.id);
    });
  });

  group('Session.withoutReading', () {
    test('drops the reading with the id, keeping the others in order', () {
      final first = readingOf(id: 'r1');
      final second = readingOf(id: 'r2');
      final third = readingOf(id: 'r3');
      final session = sessionOf([first, second, third]);

      final result = session.withoutReading(const ReadingId('r2'));

      expect(result?.readings, [first, third]);
      expect(result?.id, session.id);
    });

    test('returns null when removing the only reading would empty it', () {
      final session = sessionOf([readingOf(id: 'r1')]);

      // A session must hold at least one reading (CLAUDE.md §4), so removing
      // the last one is "delete the occasion", signalled by null.
      expect(session.withoutReading(const ReadingId('r1')), isNull);
    });

    test('returns the session unchanged when the id is not present', () {
      final session = sessionOf([readingOf(id: 'r1'), readingOf(id: 'r2')]);

      expect(session.withoutReading(const ReadingId('gone')), session);
    });
  });

  group('Reading.withId', () {
    test('copies the reading under a new id, all else identical', () {
      final reading = readingOf(
        id: 'fresh',
        systolic: 130,
        diastolic: 85,
        pulse: 66,
        notes: 'note',
        site: MeasurementSite.leftArm,
      );

      final result = reading.withId(const ReadingId('original'));

      expect(result.id, const ReadingId('original'));
      expect(result, reading.withId(const ReadingId('original')));
      expect(result.systolic, 130);
      expect(result.diastolic, 85);
      expect(result.pulse, 66);
      expect(result.notes, 'note');
      expect(result.site, MeasurementSite.leftArm);
      expect(result.takenAt, reading.takenAt);
    });
  });

  group('Reading', () {
    test('compares by value', () {
      expect(readingAt('r1', earlier), readingAt('r1', earlier));
      expect(readingAt('r1', earlier), isNot(readingAt('r2', earlier)));
    });

    test('rejects a takenAt that is not UTC', () {
      // Throws (not asserts) so the invariant holds in release builds too (§4).
      expect(
        () => readingAt('r1', DateTime(2026, 8, 23, 7, 30)),
        throwsArgumentError,
      );
    });

    test('hasContext is false when no context was recorded', () {
      expect(readingOf().hasContext, isFalse);
    });

    test('hasContext is true when the site was recorded', () {
      expect(readingOf(site: MeasurementSite.leftArm).hasContext, isTrue);
    });

    test('hasContext is true when the posture was recorded', () {
      expect(readingOf(posture: Posture.sitting).hasContext, isTrue);
    });

    test('hasContext is true when the medication timing was recorded', () {
      expect(
        readingOf(medicationTiming: MedicationTiming.before).hasContext,
        isTrue,
      );
    });

    test('hasContext ignores notes: a note alone is not context', () {
      expect(readingOf(notes: 'felt fine').hasContext, isFalse);
    });
  });
}
