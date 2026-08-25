import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Hands export [bytes] to the system share sheet as a file named [filename]
/// with the given [mimeType].
///
/// The one place share_plus is touched, so the rest of the app (and its tests)
/// never depend on it. Every export — JSON backup, CSV, PDF — shares through
/// here (CLAUDE.md §8). The bytes are passed in memory via [XFile.fromData], so
/// no temporary file is written. [XFile]'s own `name` is ignored on Android, so
/// the filename is supplied through `fileNameOverrides` instead, otherwise the
/// shared file arrives with an opaque cache name.
///
/// Returns the share_plus [ShareResult]; a [ShareResultStatus.dismissed] means
/// the user backed out of the share sheet, which is not an error.
Future<ShareResult> shareExportBytes(
  List<int> bytes, {
  required String filename,
  required String mimeType,
}) => SharePlus.instance.share(
  ShareParams(
    files: [XFile.fromData(Uint8List.fromList(bytes), mimeType: mimeType)],
    fileNameOverrides: [filename],
  ),
);

/// Shares a JSON backup [json] as `application/json`.
Future<ShareResult> shareBackup(String json, {required String filename}) =>
    shareExportBytes(
      utf8.encode(json),
      filename: filename,
      mimeType: 'application/json',
    );

/// The share filename for a backup exported at [exportedAt], e.g.
/// `cadence-backup-2026-08-25.json`.
///
/// A plain date so a person scanning their files can tell backups apart; the
/// precise instant lives inside the document (`exportedAt`).
String backupFilename(DateTime exportedAt) =>
    _exportFilename('backup', 'json', exportedAt);

/// The share filename for a readings export made at [exportedAt] in the given
/// [extension] (e.g. `csv`, `pdf`), e.g. `cadence-readings-2026-08-25.csv`.
String readingsFilename(DateTime exportedAt, {required String extension}) =>
    _exportFilename('readings', extension, exportedAt);

String _exportFilename(String stem, String extension, DateTime at) {
  final date = at.toUtc();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return 'cadence-$stem-${date.year}-$month-$day.$extension';
}
