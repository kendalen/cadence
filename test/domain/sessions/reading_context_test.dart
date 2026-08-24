import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/reading_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final takenAt = DateTime.utc(2026, 8, 23, 7, 30);

  Reading readingWith({
    MeasurementSite? site,
    Posture? posture,
    MedicationTiming? medicationTiming,
  }) => Reading(
    id: const ReadingId('r1'),
    systolic: 120,
    diastolic: 80,
    takenAt: takenAt,
    site: site,
    posture: posture,
    medicationTiming: medicationTiming,
  );

  group('Reading context', () {
    test('defaults every context field to null', () {
      final reading = Reading(
        id: const ReadingId('r1'),
        systolic: 120,
        diastolic: 80,
        takenAt: takenAt,
      );

      expect(reading.site, isNull);
      expect(reading.posture, isNull);
      expect(reading.medicationTiming, isNull);
    });

    test('compares by value, including its context', () {
      expect(
        readingWith(site: MeasurementSite.leftArm),
        readingWith(site: MeasurementSite.leftArm),
      );
      expect(
        readingWith(site: MeasurementSite.leftArm),
        isNot(readingWith(site: MeasurementSite.rightWrist)),
      );
      expect(
        readingWith(posture: Posture.sitting),
        isNot(readingWith(posture: Posture.standing)),
      );
      expect(
        readingWith(medicationTiming: MedicationTiming.before),
        isNot(readingWith(medicationTiming: MedicationTiming.after)),
      );
    });
  });

  // The enum identifier names are the stored contract: drift persists `.name`
  // and reads it back with `values.byName` (see reading_context.dart). Renaming
  // a value would silently orphan data written under the old name, so pin the
  // strings here — this test is the guard that forces a migration instead.
  group('context enums persist by name', () {
    test('MeasurementSite names are stable', () {
      expect(MeasurementSite.leftArm.name, 'leftArm');
      expect(MeasurementSite.rightArm.name, 'rightArm');
      expect(MeasurementSite.leftWrist.name, 'leftWrist');
      expect(MeasurementSite.rightWrist.name, 'rightWrist');
    });

    test('Posture names are stable', () {
      expect(Posture.sitting.name, 'sitting');
      expect(Posture.standing.name, 'standing');
      expect(Posture.lying.name, 'lying');
    });

    test('MedicationTiming names are stable', () {
      expect(MedicationTiming.before.name, 'before');
      expect(MedicationTiming.after.name, 'after');
    });

    test('every value round-trips through values.byName', () {
      for (final site in MeasurementSite.values) {
        expect(MeasurementSite.values.byName(site.name), site);
      }
      for (final posture in Posture.values) {
        expect(Posture.values.byName(posture.name), posture);
      }
      for (final timing in MedicationTiming.values) {
        expect(MedicationTiming.values.byName(timing.name), timing);
      }
    });
  });
}
