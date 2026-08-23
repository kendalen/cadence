import 'package:drift/drift.dart' show Value;

import '../../domain/sessions/ids.dart';
import '../../domain/sessions/reading.dart';
import '../../domain/sessions/session.dart';
import '../database/app_database.dart';

/// Converts a stored row to its domain [Reading].
///
/// `takenAt` is stored as UTC ISO-8601 text, so the returned reading is
/// already in UTC.
Reading toReading(ReadingRow row) => Reading(
  id: ReadingId(row.id),
  systolic: row.systolic,
  diastolic: row.diastolic,
  pulse: row.pulse,
  takenAt: row.takenAt.toUtc(),
  notes: row.notes,
);

/// Converts [reading] to the row to insert under [sessionId].
ReadingsCompanion toReadingRow(Reading reading, SessionId sessionId) =>
    ReadingsCompanion.insert(
      id: reading.id.value,
      sessionId: sessionId.value,
      systolic: reading.systolic,
      diastolic: reading.diastolic,
      pulse: Value(reading.pulse),
      takenAt: reading.takenAt,
      notes: Value(reading.notes),
    );

/// Converts a stored session and its rows to a domain [Session].
///
/// The readings are ordered oldest first. [readingRows] must not be empty: a
/// session without readings cannot exist (CLAUDE.md §4).
Session toSession(SessionRow row, List<ReadingRow> readingRows) => Session(
  id: SessionId(row.id),
  readings: readingRows.map(toReading).toList()
    ..sort((a, b) => a.takenAt.compareTo(b.takenAt)),
);
