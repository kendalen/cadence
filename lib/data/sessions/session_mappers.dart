import 'package:drift/drift.dart' show Value;

import '../../domain/sessions/ids.dart';
import '../../domain/sessions/reading.dart';
import '../../domain/sessions/reading_context.dart';
import '../../domain/sessions/session.dart';
import '../database/app_database.dart';

/// Converts a stored row to its domain [Reading].
///
/// `takenAt` is stored as UTC ISO-8601 text, so the returned reading is
/// already in UTC. Context columns hold enum names and are read back with
/// [_enumByName].
Reading toReading(ReadingRow row) => Reading(
  id: ReadingId(row.id),
  systolic: row.systolic,
  diastolic: row.diastolic,
  pulse: row.pulse,
  takenAt: row.takenAt.toUtc(),
  notes: row.notes,
  site: _enumByName(row.site, MeasurementSite.values),
  posture: _enumByName(row.posture, Posture.values),
  medicationTiming: _enumByName(row.medicationTiming, MedicationTiming.values),
);

/// Converts [reading] to the row to insert under [sessionId].
///
/// Context enums are stored by name; a `null` context field stores `null`.
ReadingsCompanion toReadingRow(Reading reading, SessionId sessionId) =>
    ReadingsCompanion.insert(
      id: reading.id.value,
      sessionId: sessionId.value,
      systolic: reading.systolic,
      diastolic: reading.diastolic,
      pulse: Value(reading.pulse),
      takenAt: reading.takenAt,
      notes: Value(reading.notes),
      site: Value(reading.site?.name),
      posture: Value(reading.posture?.name),
      medicationTiming: Value(reading.medicationTiming?.name),
    );

/// Resolves a stored enum [name] back to its value, or `null` when the column
/// was `null`.
///
/// An unrecognised name means the database holds a value the app never wrote —
/// corruption or a bug, not an expected state — so `byName` is left to throw
/// (CLAUDE.md §6). The tolerant path for foreign data is the JSON importer, not
/// here.
T? _enumByName<T extends Enum>(String? name, List<T> values) =>
    name == null ? null : values.byName(name);

/// Converts a stored session and its rows to a domain [Session].
///
/// The readings are ordered oldest first. [readingRows] must not be empty: a
/// session without readings cannot exist (CLAUDE.md §4).
Session toSession(SessionRow row, List<ReadingRow> readingRows) => Session(
  id: SessionId(row.id),
  readings: readingRows.map(toReading).toList()
    ..sort((a, b) => a.takenAt.compareTo(b.takenAt)),
);
