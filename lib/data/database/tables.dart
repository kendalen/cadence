import 'package:drift/drift.dart';

/// One measurement occasion.
///
/// The session carries no values of its own: everything measurable lives on its
/// [Readings], and anything derived from them is computed, never stored
/// (CLAUDE.md §4).
@DataClassName('SessionRow')
class Sessions extends Table {
  /// Client-generated UUID v7, stable across export and restore.
  TextColumn get id => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One measurement, belonging to exactly one session.
@DataClassName('ReadingRow')
class Readings extends Table {
  /// Client-generated UUID v7, stable across export and restore.
  TextColumn get id => text()();

  /// The session this reading was taken on. Deleting the session deletes it.
  TextColumn get sessionId =>
      text().references(Sessions, #id, onDelete: KeyAction.cascade)();

  /// Systolic pressure, in mmHg.
  IntColumn get systolic => integer()();

  /// Diastolic pressure, in mmHg.
  IntColumn get diastolic => integer()();

  /// Pulse in beats per minute, absent when the monitor reported none.
  IntColumn get pulse => integer().nullable()();

  /// When the measurement was taken, stored as UTC ISO-8601 text.
  DateTimeColumn get takenAt => dateTime()();

  /// The note the user attached, absent when they wrote none.
  TextColumn get notes => text().nullable()();

  /// Where the cuff was placed, stored as the `MeasurementSite` name; absent
  /// when the user did not record it (CLAUDE.md §4).
  TextColumn get site => text().nullable()();

  /// The body position, stored as the `Posture` name; absent when unrecorded.
  TextColumn get posture => text().nullable()();

  /// Whether the reading was before or after medication, stored as the
  /// `MedicationTiming` name; absent when unrecorded.
  TextColumn get medicationTiming => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
