import 'dart:convert';

import 'package:share_plus/share_plus.dart';

/// Hands [json] to the system share sheet as a `.json` file named [filename].
///
/// The only place share_plus is touched, so the rest of the app (and its tests)
/// never depend on it. The backup is passed as in-memory bytes via
/// [XFile.fromData] — no temporary file is written. [XFile]'s own `name` is
/// ignored on Android, so the filename is supplied through `fileNameOverrides`
/// instead, otherwise the shared file arrives with an opaque cache name.
///
/// Returns the share_plus [ShareResult]; a [ShareResultStatus.dismissed] means
/// the user backed out of the share sheet, which is not an error.
Future<ShareResult> shareBackup(String json, {required String filename}) {
  final bytes = utf8.encode(json);
  return SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'application/json')],
      fileNameOverrides: [filename],
    ),
  );
}

/// The share filename for a backup exported at [exportedAt], e.g.
/// `cadence-backup-2026-08-25.json`.
///
/// A plain date so a person scanning their files can tell backups apart; the
/// precise instant lives inside the document (`exportedAt`).
String backupFilename(DateTime exportedAt) {
  final date = exportedAt.toUtc();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return 'cadence-backup-${date.year}-$month-$day.json';
}
