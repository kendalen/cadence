import 'dart:convert';

import 'package:cadence/data/backup/backup_codec.dart';
import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/reading_context.dart';
import 'package:cadence/domain/sessions/session.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fixed instant so the tests never read the wall clock.
final _exportedAt = DateTime.utc(2026, 8, 25, 14, 3);

Reading _reading(
  String id, {
  int systolic = 120,
  int diastolic = 80,
  int? pulse,
  String? notes,
  MeasurementSite? site,
  Posture? posture,
  MedicationTiming? medicationTiming,
  DateTime? takenAt,
}) => Reading(
  id: ReadingId(id),
  systolic: systolic,
  diastolic: diastolic,
  pulse: pulse,
  takenAt: takenAt ?? DateTime.utc(2026, 8, 25, 6, 30),
  notes: notes,
  site: site,
  posture: posture,
  medicationTiming: medicationTiming,
);

void main() {
  group('encodeBackup', () {
    test('wraps sessions with the format id, version and export time', () {
      final backup = encodeBackup([
        Session(id: const SessionId('s1'), readings: [_reading('r1')]),
      ], exportedAt: _exportedAt);

      expect(backup['format'], 'cadence.backup');
      expect(backup['version'], 1);
      expect(backup['exportedAt'], '2026-08-25T14:03:00.000Z');
      expect(backup['sessions'], isA<List<Object?>>());
    });

    test('encodes an empty diary as a valid backup with no sessions', () {
      final backup = encodeBackup([], exportedAt: _exportedAt);

      expect(backup['format'], 'cadence.backup');
      expect(backup['version'], 1);
      expect(backup['sessions'], isEmpty);
    });

    test('encodes a fully populated reading to the exact expected map', () {
      final backup = encodeBackup([
        Session(
          id: const SessionId('s1'),
          readings: [
            _reading(
              'r1',
              systolic: 132,
              diastolic: 84,
              pulse: 66,
              notes: 'after coffee',
              site: MeasurementSite.leftArm,
              posture: Posture.sitting,
              medicationTiming: MedicationTiming.before,
              takenAt: DateTime.utc(2026, 8, 25, 6, 30),
            ),
          ],
        ),
      ], exportedAt: _exportedAt);

      // Freezes the format: any accidental change to a key name or shape
      // breaks this and forces a deliberate version bump (CLAUDE.md §5).
      expect((backup['sessions'] as List).single, {
        'id': 's1',
        'readings': [
          {
            'id': 'r1',
            'systolic': 132,
            'diastolic': 84,
            'pulse': 66,
            'takenAt': '2026-08-25T06:30:00.000Z',
            'notes': 'after coffee',
            'site': 'leftArm',
            'posture': 'sitting',
            'medicationTiming': 'before',
          },
        ],
      });
    });

    test('omits optional reading fields that were never recorded', () {
      final backup = encodeBackup([
        Session(id: const SessionId('s1'), readings: [_reading('r1')]),
      ], exportedAt: _exportedAt);

      final session = (backup['sessions'] as List).single as Map;
      final reading = (session['readings'] as List).first as Map;
      expect(
        reading.keys,
        containsAll(['id', 'systolic', 'diastolic', 'takenAt']),
      );
      expect(
        reading.keys,
        isNot(
          anyElement(
            isIn(['pulse', 'notes', 'site', 'posture', 'medicationTiming']),
          ),
        ),
      );
    });

    test('escapes a note containing quotes, backslashes and newlines', () {
      // The reason jsonEncode is used instead of hand-built strings: a stray
      // quote in a note must not break the file.
      const tricky = 'said "hi"\\done\nnext line';
      final backup = encodeBackup([
        Session(
          id: const SessionId('s1'),
          readings: [_reading('r1', notes: tricky)],
        ),
      ], exportedAt: _exportedAt);

      final json = jsonEncode(backup);
      final decoded = jsonDecode(json) as Map<String, Object?>;
      final session = (decoded['sessions'] as List).single as Map;
      final reading = (session['readings'] as List).first as Map;
      expect(reading['notes'], tricky);
    });
  });
}
