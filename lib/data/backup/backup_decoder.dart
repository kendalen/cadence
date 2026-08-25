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
  });

  /// The sessions successfully read, in the order the document listed them.
  final List<Session> sessions;

  /// Readings that were skipped because a required field was missing or of the
  /// wrong type.
  final int skippedReadings;

  /// Sessions that were skipped because none of their readings could be read
  /// (a session cannot be empty — CLAUDE.md §4).
  final int skippedSessions;
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
/// Otherwise it reads every session it can: unknown fields are ignored, an
/// unknown enum value is treated as unrecorded, and a reading missing a required
/// field is skipped and counted (never dropped silently). A session left with no
/// usable readings is skipped and counted.
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
    );
  }
  if (rawSessions is! List) {
    return const BackupRejected(BackupRejectedReason.notABackup);
  }

  final sessions = <Session>[];
  var skippedReadings = 0;
  var skippedSessions = 0;

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
      final reading = _decodeReading(rawReading);
      if (reading == null) {
        skippedReadings++;
      } else {
        readings.add(reading);
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
  );
}

/// Reads one reading, or `null` when a required field is missing or malformed.
///
/// Required: `id`, `systolic`, `diastolic`, `takenAt`. Optional fields default
/// to unrecorded; an unknown enum value is treated as unrecorded rather than
/// rejecting the reading.
Reading? _decodeReading(Object? raw) {
  if (raw is! Map<String, dynamic>) {
    return null;
  }

  final id = raw['id'];
  final systolic = raw['systolic'];
  final diastolic = raw['diastolic'];
  final rawTakenAt = raw['takenAt'];
  if (id is! String || systolic is! int || diastolic is! int) {
    return null;
  }
  if (rawTakenAt is! String) {
    return null;
  }
  final takenAt = DateTime.tryParse(rawTakenAt);
  if (takenAt == null) {
    return null;
  }

  final pulse = raw['pulse'];
  final notes = raw['notes'];
  return Reading(
    id: ReadingId(id),
    systolic: systolic,
    diastolic: diastolic,
    pulse: pulse is int ? pulse : null,
    takenAt: takenAt.toUtc(),
    notes: notes is String ? notes : null,
    site: _enumByName(raw['site'], MeasurementSite.values),
    posture: _enumByName(raw['posture'], Posture.values),
    medicationTiming: _enumByName(
      raw['medicationTiming'],
      MedicationTiming.values,
    ),
  );
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
