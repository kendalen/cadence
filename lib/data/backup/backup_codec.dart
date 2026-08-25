import '../../domain/sessions/reading.dart';
import '../../domain/sessions/session.dart';

/// Identifies a JSON document as a Cadence backup.
///
/// Written at the top level so the importer (S7b) can reject an unrelated JSON
/// file up front rather than partly consuming it (CLAUDE.md §5).
const String backupFormatId = 'cadence.backup';

/// The version of the backup format this build writes.
///
/// The backup carries its own version, independent of the database
/// `schemaVersion` (CLAUDE.md §5). Bump this only for a deliberate,
/// documented change to the shape below — the exact-map test in
/// `backup_codec_test.dart` guards against changing it by accident.
const int backupFormatVersion = 1;

/// Serialises [sessions] to the backup's top-level JSON object.
///
/// The result is a plain `Map`/`List` tree ready for `jsonEncode`; encoding is
/// always done with `dart:convert` so notes containing quotes, backslashes or
/// newlines are escaped correctly. [exportedAt] is stamped into the document as
/// UTC ISO-8601 and is passed in (not read from the clock here) so this stays a
/// pure function (CLAUDE.md §3).
///
/// Only raw stored fields are written. Derived values — session average, MAP,
/// pulse pressure — are computed, never stored (CLAUDE.md §4), so they are
/// never in a backup.
///
/// The backup is built from domain [Session]s read through the repository, not
/// by copying the SQLite file; §5's `wal_checkpoint(TRUNCATE)` rule concerns a
/// file copy and does not apply here.
Map<String, Object?> encodeBackup(
  List<Session> sessions, {
  required DateTime exportedAt,
}) => {
  'format': backupFormatId,
  'version': backupFormatVersion,
  'exportedAt': exportedAt.toUtc().toIso8601String(),
  'sessions': sessions.map(_encodeSession).toList(),
};

Map<String, Object?> _encodeSession(Session session) => {
  'id': session.id.value,
  'readings': session.readings.map(_encodeReading).toList(),
};

/// An optional field is omitted entirely when unrecorded rather than written as
/// `null`: a smaller file, and the importer supplies defaults for missing keys
/// anyway (CLAUDE.md §5). Enums are written by `.name`, the same stored contract
/// the database uses (`reading_context.dart`).
Map<String, Object?> _encodeReading(Reading reading) => {
  'id': reading.id.value,
  'systolic': reading.systolic,
  'diastolic': reading.diastolic,
  if (reading.pulse != null) 'pulse': reading.pulse,
  'takenAt': reading.takenAt.toUtc().toIso8601String(),
  if (reading.notes != null) 'notes': reading.notes,
  if (reading.site != null) 'site': reading.site!.name,
  if (reading.posture != null) 'posture': reading.posture!.name,
  if (reading.medicationTiming != null)
    'medicationTiming': reading.medicationTiming!.name,
};
