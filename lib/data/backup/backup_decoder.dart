import 'dart:convert';

import '../../domain/sessions/ids.dart';
import '../../domain/sessions/reading.dart';
import '../../domain/sessions/reading_context.dart';
import '../../domain/sessions/session.dart';
import 'backup_codec.dart';

/// The outcome of decoding a JSON backup document.
///
/// Either the document was accepted ([BackupParsed], possibly with parts it
/// could not use, all counted) or it was refused up front ([BackupRejected]).
/// This is the tolerant reader §5 requires: it defaults missing optional fields,
/// ignores unknown ones, and never drops anything without counting it.
sealed class BackupParse {
  const BackupParse();
}

/// A backup that was read, with any unusable parts counted rather than dropped
/// silently (CLAUDE.md §5).
final class BackupParsed extends BackupParse {
  /// Records the [sessions] read and how many parts had to be left out.
  const BackupParsed({
    required this.sessions,
    required this.skippedReadings,
    required this.skippedSessions,
    required this.readingsWithDroppedDetails,
  });

  /// The sessions successfully read, in the order the document listed them.
  final List<Session> sessions;

  /// Readings that were skipped because a required field was missing or of the
  /// wrong type.
  final int skippedReadings;

  /// Sessions that were skipped because none of their readings could be read
  /// (a session cannot be empty — CLAUDE.md §4).
  final int skippedSessions;

  /// Readings that *were* imported but had a supplied optional field dropped
  /// because it was malformed — an unknown enum value, a non-numeric pulse, a
  /// non-text note. Counted so the drop is reported, not hidden (CLAUDE.md §5);
  /// an *absent* optional is simply unrecorded and is not counted here.
  final int readingsWithDroppedDetails;
}

/// A document that could not be treated as a backup at all; nothing was read.
final class BackupRejected extends BackupParse {
  /// Records why the document was [reason].
  const BackupRejected(this.reason);

  /// Why the document was rejected, for the caller to turn into a message.
  final BackupRejectedReason reason;
}

/// Why a backup document was rejected outright.
enum BackupRejectedReason {
  /// Valid JSON, but not a Cadence backup (wrong or missing `format`).
  notABackup,

  /// The file could not be parsed as JSON at all.
  unreadable,

  /// A backup written by a newer version of the format than this build reads.
  tooNew,
}

/// Reads [source] as a Cadence JSON backup.
///
/// Rejects a file that is not parseable JSON ([BackupRejectedReason.unreadable]),
/// is not a Cadence backup ([BackupRejectedReason.notABackup]), or was written
/// in a newer format version than this build understands
/// ([BackupRejectedReason.tooNew]) — the format's own version field exists so a
/// future shape is refused rather than guessed at (CLAUDE.md §5).
///
/// Otherwise it reads every session it can: unknown fields are ignored, a
/// reading missing a required field is skipped and counted, and a session left
/// with no usable readings is skipped and counted (never dropped silently). A
/// reading whose *optional* field is present but malformed (an unknown enum, a
/// non-numeric pulse) is still imported, with that detail dropped and counted in
/// [BackupParsed.readingsWithDroppedDetails] — report-only, so a slightly broken
/// backup still restores what it can while telling the user what it lost (§5).
BackupParse decodeBackup(String source) {
  final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    return const BackupRejected(BackupRejectedReason.unreadable);
  }

  if (decoded is! Map<String, dynamic>) {
    return const BackupRejected(BackupRejectedReason.notABackup);
  }
  if (decoded['format'] != backupFormatId) {
    return const BackupRejected(BackupRejectedReason.notABackup);
  }

  final version = decoded['version'];
  if (version is! int) {
    return const BackupRejected(BackupRejectedReason.notABackup);
  }
  if (version > backupFormatVersion) {
    return const BackupRejected(BackupRejectedReason.tooNew);
  }

  final rawSessions = decoded['sessions'];
  if (rawSessions == null) {
    return const BackupParsed(
      sessions: [],
      skippedReadings: 0,
      skippedSessions: 0,
      readingsWithDroppedDetails: 0,
    );
  }
  if (rawSessions is! List) {
    return const BackupRejected(BackupRejectedReason.notABackup);
  }

  final sessions = <Session>[];
  var skippedReadings = 0;
  var skippedSessions = 0;
  var readingsWithDroppedDetails = 0;

  for (final rawSession in rawSessions) {
    if (rawSession is! Map<String, dynamic>) {
      skippedSessions++;
      continue;
    }
    final id = rawSession['id'];
    final rawReadings = rawSession['readings'];
    if (id is! String || rawReadings is! List) {
      skippedSessions++;
      continue;
    }

    final readings = <Reading>[];
    for (final rawReading in rawReadings) {
      final (reading, droppedDetail) = _decodeReading(rawReading);
      if (reading == null) {
        skippedReadings++;
      } else {
        readings.add(reading);
        if (droppedDetail) {
          readingsWithDroppedDetails++;
        }
      }
    }

    if (readings.isEmpty) {
      // A session must hold at least one reading (CLAUDE.md §4); with none
      // usable there is no session to keep.
      skippedSessions++;
      continue;
    }
    sessions.add(Session(id: SessionId(id), readings: readings));
  }

  return BackupParsed(
    sessions: sessions,
    skippedReadings: skippedReadings,
    skippedSessions: skippedSessions,
    readingsWithDroppedDetails: readingsWithDroppedDetails,
  );
}

/// Reads one reading, and reports whether a *supplied* optional field had to be
/// dropped because it was malformed.
///
/// Required: `id`, `systolic`, `diastolic`, `takenAt` — the reading is `null`
/// (unreadable) when any is missing or of the wrong type. Optional fields
/// (`pulse`, `notes`, `site`, `posture`, `medicationTiming`) default to
/// unrecorded; a value that is *present but unusable* (an unknown enum name, a
/// pulse that is not a number, a note that is not text) is dropped and the
/// returned `droppedDetail` flag is set so the caller can report it (§5). An
/// *absent* optional is not a dropped detail.
(Reading? reading, bool droppedDetail) _decodeReading(Object? raw) {
  if (raw is! Map<String, dynamic>) {
    return (null, false);
  }

  final id = raw['id'];
  final systolic = raw['systolic'];
  final diastolic = raw['diastolic'];
  final rawTakenAt = raw['takenAt'];
  if (id is! String || systolic is! int || diastolic is! int) {
    return (null, false);
  }
  if (rawTakenAt is! String) {
    return (null, false);
  }
  final takenAt = DateTime.tryParse(rawTakenAt);
  if (takenAt == null) {
    return (null, false);
  }

  // A supplied-but-unusable optional is a reported drop; an absent one (null)
  // is simply unrecorded and is not.
  var droppedDetail = false;
  int? optionalInt(Object? value) {
    if (value is int) return value;
    if (value != null) droppedDetail = true;
    return null;
  }

  String? optionalString(Object? value) {
    if (value is String) return value;
    if (value != null) droppedDetail = true;
    return null;
  }

  T? optionalEnum<T extends Enum>(Object? value, List<T> values) {
    final resolved = _enumByName(value, values);
    if (resolved == null && value != null) droppedDetail = true;
    return resolved;
  }

  final reading = Reading(
    id: ReadingId(id),
    systolic: systolic,
    diastolic: diastolic,
    pulse: optionalInt(raw['pulse']),
    takenAt: takenAt.toUtc(),
    notes: optionalString(raw['notes']),
    site: optionalEnum(raw['site'], MeasurementSite.values),
    posture: optionalEnum(raw['posture'], Posture.values),
    medicationTiming: optionalEnum(
      raw['medicationTiming'],
      MedicationTiming.values,
    ),
  );
  return (reading, droppedDetail);
}

/// Resolves [raw] to the enum value of that name, or `null` when it is missing
/// or unrecognised.
///
/// Unlike the storage mapper (`session_mappers.dart`), an unknown name here is
/// tolerated — a backup is foreign data, and §5 makes this the forgiving path.
T? _enumByName<T extends Enum>(Object? raw, List<T> values) {
  if (raw is! String) {
    return null;
  }
  for (final value in values) {
    if (value.name == raw) {
      return value;
    }
  }
  return null;
}
