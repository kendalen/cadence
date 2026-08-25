import 'package:cadence/data/export/reading_export.dart';
import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/reading_context.dart';
import 'package:cadence/domain/sessions/session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed wording so the tests never depend on the ARB or a locale.
final _labels = ExportLabels(
  title: 'Readings',
  disclaimer: 'Not a diagnosis',
  columnHeaders: [
    'Date',
    'Time',
    'Occasion',
    'Systolic',
    'Diastolic',
    'Pulse',
    'Where',
    'Position',
    'Medication',
    'Note',
  ],
  site: {MeasurementSite.leftArm: 'Left arm'},
  posture: {Posture.sitting: 'Sitting'},
  medication: {MedicationTiming.before: 'Before medication'},
);

Reading _reading(
  String id, {
  int systolic = 120,
  int diastolic = 80,
  int? pulse,
  String? notes,
  MeasurementSite? site,
  Posture? posture,
  MedicationTiming? medicationTiming,
  required DateTime takenAt,
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

/// Identity so the date/time cells are deterministic regardless of the machine
/// timezone (the builder's [toLocal] hook is what the app fills with real
/// local time).
DateTime _asLocal(DateTime value) => value;

List<List<String>> _rows(List<Session> sessions) =>
    buildReadingRows(sessions, _labels, locale: 'en_US', toLocal: _asLocal);

void main() {
  group('buildReadingRows', () {
    test('emits one row per reading with a header per column', () {
      final rows = _rows([
        Session(
          id: const SessionId('s1'),
          readings: [_reading('r1', takenAt: DateTime.utc(2026, 8, 25, 6, 30))],
        ),
      ]);

      expect(rows, hasLength(1));
      expect(rows.first, hasLength(exportColumnCount));
      expect(_labels.columnHeaders, hasLength(exportColumnCount));
    });

    test('writes the raw values in column order, blank when unrecorded', () {
      final rows = _rows([
        Session(
          id: const SessionId('s1'),
          readings: [
            _reading(
              'r1',
              systolic: 128,
              diastolic: 84,
              pulse: 72,
              notes: 'after coffee',
              site: MeasurementSite.leftArm,
              posture: Posture.sitting,
              medicationTiming: MedicationTiming.before,
              takenAt: DateTime.utc(2026, 8, 25, 6, 30),
            ),
          ],
        ),
      ]);

      final row = rows.single;
      expect(row[2], '1'); // occasion number
      expect(row[3], '128'); // systolic
      expect(row[4], '84'); // diastolic
      expect(row[5], '72'); // pulse
      expect(row[6], 'Left arm');
      expect(row[7], 'Sitting');
      expect(row[8], 'Before medication');
      expect(row[9], 'after coffee');
      expect(row[0], isNotEmpty); // date, locale-formatted
      expect(row[1], isNotEmpty); // time, locale-formatted
    });

    test('leaves pulse, context and note blank when unrecorded', () {
      final rows = _rows([
        Session(
          id: const SessionId('s1'),
          readings: [_reading('r1', takenAt: DateTime.utc(2026, 8, 25, 6, 30))],
        ),
      ]);

      final row = rows.single;
      expect(row[5], ''); // pulse
      expect(row[6], ''); // site
      expect(row[7], ''); // posture
      expect(row[8], ''); // medication
      expect(row[9], ''); // note
    });

    test('orders occasions oldest-first and numbers them from 1', () {
      final older = Session(
        id: const SessionId('older'),
        readings: [_reading('a', takenAt: DateTime.utc(2026, 8, 24, 8))],
      );
      final newer = Session(
        id: const SessionId('newer'),
        readings: [_reading('b', takenAt: DateTime.utc(2026, 8, 25, 8))],
      );

      // Passed newest-first (as the app list holds them) to prove the builder
      // sorts rather than trusting input order.
      final rows = _rows([newer, older]);

      expect(rows.map((row) => row[2]).toList(), ['1', '2']);
      expect(rows[0][3], '120'); // older occasion is row 1
    });

    test('shares one occasion number across its readings, ordered by time', () {
      final rows = _rows([
        Session(
          id: const SessionId('s1'),
          readings: [
            _reading(
              'late',
              systolic: 130,
              takenAt: DateTime.utc(2026, 8, 25, 6, 31),
            ),
            _reading(
              'early',
              systolic: 120,
              takenAt: DateTime.utc(2026, 8, 25, 6, 30),
            ),
          ],
        ),
      ]);

      expect(rows.map((row) => row[2]).toList(), ['1', '1']);
      expect(rows.map((row) => row[3]).toList(), ['120', '130']); // by time
    });

    test('formats the date numerically for the locale', () {
      final rows = _rows([
        Session(
          id: const SessionId('s1'),
          readings: [_reading('r1', takenAt: DateTime.utc(2026, 8, 25, 6, 30))],
        ),
      ]);

      // en_US numeric date (M/d/yyyy): digits and slashes only, no month name.
      expect(rows.single[0], matches(RegExp(r'^[\d/]+$')));
      expect(rows.single[0], contains('2026'));
    });

    test('encodes an empty diary as no rows', () {
      expect(_rows([]), isEmpty);
    });
  });
}
