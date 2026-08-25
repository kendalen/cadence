import 'dart:convert';

import 'package:cadence/data/backup/backup_codec.dart';
import 'package:cadence/data/backup/backup_decoder.dart';
import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/reading_context.dart';
import 'package:cadence/domain/sessions/session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [readings] as one backup document's JSON string.
String _backupJson(List<Map<String, Object?>> readings) => jsonEncode({
  'format': backupFormatId,
  'version': backupFormatVersion,
  'exportedAt': '2026-08-25T14:03:00.000Z',
  'sessions': [
    {'id': 's1', 'readings': readings},
  ],
});

void main() {
  group('decodeBackup', () {
    test('round-trips what encodeBackup wrote, losing nothing', () {
      final sessions = [
        Session(
          id: const SessionId('s1'),
          readings: [
            Reading(
              id: const ReadingId('r1'),
              systolic: 132,
              diastolic: 84,
              pulse: 66,
              takenAt: DateTime.utc(2026, 8, 25, 6, 30),
              notes: 'after coffee',
              site: MeasurementSite.leftArm,
              posture: Posture.sitting,
              medicationTiming: MedicationTiming.before,
            ),
          ],
        ),
        Session(
          id: const SessionId('s2'),
          readings: [
            Reading(
              id: const ReadingId('r2'),
              systolic: 118,
              diastolic: 76,
              takenAt: DateTime.utc(2026, 8, 25, 19, 5),
            ),
          ],
        ),
      ];

      final json = jsonEncode(
        encodeBackup(sessions, exportedAt: DateTime.utc(2026, 8, 25)),
      );
      final parse = decodeBackup(json);

      expect(parse, isA<BackupParsed>());
      final parsed = parse as BackupParsed;
      expect(parsed.sessions, sessions);
      expect(parsed.skippedReadings, 0);
      expect(parsed.skippedSessions, 0);
    });

    test('rejects JSON that is not a Cadence backup', () {
      expect(
        decodeBackup('{"hello":1}'),
        isA<BackupRejected>().having(
          (r) => r.reason,
          'reason',
          BackupRejectedReason.notABackup,
        ),
      );
      expect(
        decodeBackup('[]'),
        isA<BackupRejected>().having(
          (r) => r.reason,
          'reason',
          BackupRejectedReason.notABackup,
        ),
      );
    });

    test('rejects a file that is not valid JSON', () {
      expect(
        decodeBackup('not json {'),
        isA<BackupRejected>().having(
          (r) => r.reason,
          'reason',
          BackupRejectedReason.unreadable,
        ),
      );
    });

    test('rejects a backup from a newer format version', () {
      final json = jsonEncode({
        'format': backupFormatId,
        'version': backupFormatVersion + 1,
        'sessions': <Object?>[],
      });

      expect(
        decodeBackup(json),
        isA<BackupRejected>().having(
          (r) => r.reason,
          'reason',
          BackupRejectedReason.tooNew,
        ),
      );
    });

    test('ignores unknown fields it does not recognise', () {
      final json = jsonEncode({
        'format': backupFormatId,
        'version': backupFormatVersion,
        'wibble': 'ignored',
        'sessions': [
          {
            'id': 's1',
            'wobble': true,
            'readings': [
              {
                'id': 'r1',
                'systolic': 120,
                'diastolic': 80,
                'takenAt': '2026-08-25T06:30:00.000Z',
                'unknown': 42,
              },
            ],
          },
        ],
      });

      final parsed = decodeBackup(json) as BackupParsed;
      expect(parsed.sessions.single.readings.single.id.value, 'r1');
      expect(parsed.skippedReadings, 0);
    });

    test('skips a reading missing a required field but keeps its siblings', () {
      final json = _backupJson([
        {
          'id': 'r1',
          'systolic': 120,
          'diastolic': 80,
          'takenAt': '2026-08-25T06:30:00.000Z',
        },
        // No systolic: cannot be trusted, so it is skipped and counted.
        {'id': 'r2', 'diastolic': 80, 'takenAt': '2026-08-25T06:31:00.000Z'},
      ]);

      final parsed = decodeBackup(json) as BackupParsed;
      expect(parsed.sessions.single.readings.map((r) => r.id.value), ['r1']);
      expect(parsed.skippedReadings, 1);
      expect(parsed.skippedSessions, 0);
    });

    test(
      'keeps a reading with an unknown enum value, dropping only that field',
      () {
        final json = _backupJson([
          {
            'id': 'r1',
            'systolic': 120,
            'diastolic': 80,
            'takenAt': '2026-08-25T06:30:00.000Z',
            'site': 'foot',
          },
        ]);

        final reading = (decodeBackup(
          json,
        ) as BackupParsed).sessions.single.readings.single;
        expect(reading.site, isNull);
        expect(reading.systolic, 120);
      },
    );

    test('skips a session whose readings are all unusable', () {
      final json = _backupJson([
        {'id': 'r1', 'takenAt': '2026-08-25T06:30:00.000Z'},
      ]);

      final parsed = decodeBackup(json) as BackupParsed;
      expect(parsed.sessions, isEmpty);
      expect(parsed.skippedSessions, 1);
      expect(parsed.skippedReadings, 1);
    });

    test('reads an empty backup as no sessions', () {
      final json = jsonEncode({
        'format': backupFormatId,
        'version': backupFormatVersion,
        'sessions': <Object?>[],
      });

      final parsed = decodeBackup(json) as BackupParsed;
      expect(parsed.sessions, isEmpty);
      expect(parsed.skippedSessions, 0);
      expect(parsed.skippedReadings, 0);
    });
  });
}
