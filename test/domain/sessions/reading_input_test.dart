import 'package:cadence/domain/core/result.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/reading_context.dart';
import 'package:cadence/domain/sessions/reading_input.dart';
import 'package:cadence/domain/sessions/validation_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_id_generator.dart';

void main() {
  final now = DateTime.utc(2026, 8, 23, 18);
  final takenAt = DateTime.utc(2026, 8, 23, 7, 30);

  ReadingInput inputWith({
    String systolic = '132',
    String diastolic = '84',
    String pulse = '',
    String notes = '',
    DateTime? at,
    MeasurementSite? site,
    Posture? posture,
    MedicationTiming? medicationTiming,
  }) => ReadingInput(
    systolic: systolic,
    diastolic: diastolic,
    pulse: pulse,
    notes: notes,
    takenAt: at ?? takenAt,
    site: site,
    posture: posture,
    medicationTiming: medicationTiming,
  );

  Reading validated(ReadingInput input) {
    final result = input.validate(FakeIdGenerator(), now: now);
    expect(result, isA<Ok<Reading, List<ValidationFailure>>>());
    return (result as Ok<Reading, List<ValidationFailure>>).value;
  }

  List<ValidationFailure> failures(ReadingInput input) {
    final result = input.validate(FakeIdGenerator(), now: now);
    expect(result, isA<Err<Reading, List<ValidationFailure>>>());
    return (result as Err<Reading, List<ValidationFailure>>).error;
  }

  group('ReadingInput.validate — accepted input', () {
    test('builds a reading from systolic and diastolic alone', () {
      final reading = validated(inputWith());

      expect(reading.systolic, 132);
      expect(reading.diastolic, 84);
      expect(reading.pulse, isNull);
      expect(reading.notes, isNull);
      expect(reading.takenAt, takenAt);
    });

    test('takes its id from the generator', () {
      final reading = validated(inputWith());

      expect(reading.id.value, 'id-0');
    });

    test('keeps a pulse when one was typed', () {
      expect(validated(inputWith(pulse: '72')).pulse, 72);
    });

    test('trims surrounding whitespace before parsing', () {
      final reading = validated(inputWith(systolic: ' 132 ', pulse: ' 72 '));

      expect(reading.systolic, 132);
      expect(reading.pulse, 72);
    });

    test('trims notes, and turns blank notes into null', () {
      expect(
        validated(inputWith(notes: '  after a walk ')).notes,
        'after a walk',
      );
      expect(validated(inputWith(notes: '   ')).notes, isNull);
    });

    test('stores takenAt as UTC when a local time was chosen', () {
      final local = DateTime(2026, 8, 23, 7, 30);

      final reading = validated(inputWith(at: local));

      expect(reading.takenAt.isUtc, isTrue);
      expect(reading.takenAt, local.toUtc());
    });

    test('accepts a takenAt exactly at now', () {
      expect(validated(inputWith(at: now)).takenAt, now);
    });

    test('accepts the bounds themselves', () {
      final low = validated(
        inputWith(
          systolic: '${ReadingInput.minPressure}',
          diastolic: '${ReadingInput.minPressure}',
          pulse: '${ReadingInput.minPulse}',
        ),
      );
      final high = validated(
        inputWith(
          systolic: '${ReadingInput.maxPressure}',
          diastolic: '${ReadingInput.maxPressure}',
          pulse: '${ReadingInput.maxPulse}',
        ),
      );

      expect(low.systolic, ReadingInput.minPressure);
      expect(high.pulse, ReadingInput.maxPulse);
    });

    test('accepts a systolic below the diastolic', () {
      // Real monitors occasionally report one; refusing it would lose data.
      final reading = validated(inputWith(systolic: '80', diastolic: '120'));

      expect(reading.systolic, 80);
      expect(reading.diastolic, 120);
    });
  });

  group('ReadingInput.validate — rejected input', () {
    test('reports a blank systolic and diastolic as missing', () {
      expect(failures(inputWith(systolic: '', diastolic: '   ')), const [
        ValueMissing(ReadingField.systolic),
        ValueMissing(ReadingField.diastolic),
      ]);
    });

    test('reports text that is not a whole number', () {
      expect(failures(inputWith(systolic: '12o', diastolic: '84.5')), const [
        ValueNotAnInteger(ReadingField.systolic),
        ValueNotAnInteger(ReadingField.diastolic),
      ]);
    });

    test('reports a pressure below the low bound', () {
      expect(failures(inputWith(systolic: '9')), const [
        ValueOutOfRange(
          ReadingField.systolic,
          min: ReadingInput.minPressure,
          max: ReadingInput.maxPressure,
        ),
      ]);
    });

    test('reports a pressure above the high bound', () {
      expect(failures(inputWith(diastolic: '301')), const [
        ValueOutOfRange(
          ReadingField.diastolic,
          min: ReadingInput.minPressure,
          max: ReadingInput.maxPressure,
        ),
      ]);
    });

    test('reports a pulse outside its bounds', () {
      expect(failures(inputWith(pulse: '19')), const [
        ValueOutOfRange(
          ReadingField.pulse,
          min: ReadingInput.minPulse,
          max: ReadingInput.maxPulse,
        ),
      ]);
      expect(failures(inputWith(pulse: '301')), hasLength(1));
    });

    test('reports a takenAt in the future', () {
      expect(
        failures(inputWith(at: now.add(const Duration(minutes: 1)))),
        const [TakenAtInFuture()],
      );
    });

    test('reports every bad field at once, not just the first', () {
      final reported = failures(
        inputWith(
          systolic: '',
          diastolic: 'x',
          pulse: '5',
          at: now.add(const Duration(days: 1)),
        ),
      );

      expect(reported.map((failure) => failure.field), const [
        ReadingField.systolic,
        ReadingField.diastolic,
        ReadingField.pulse,
        ReadingField.takenAt,
      ]);
    });
  });

  group('ReadingInput.validate — context', () {
    test('carries the context through to the built reading', () {
      final reading = validated(
        inputWith(
          site: MeasurementSite.leftArm,
          posture: Posture.sitting,
          medicationTiming: MedicationTiming.before,
        ),
      );

      expect(reading.site, MeasurementSite.leftArm);
      expect(reading.posture, Posture.sitting);
      expect(reading.medicationTiming, MedicationTiming.before);
    });

    test('leaves context null when none was chosen', () {
      final reading = validated(inputWith());

      expect(reading.site, isNull);
      expect(reading.posture, isNull);
      expect(reading.medicationTiming, isNull);
    });
  });
}
