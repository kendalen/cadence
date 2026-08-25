import 'package:file_selector/file_selector.dart';

/// Opens the system file picker (Android SAF) for the user to choose a backup,
/// and returns its contents, or `null` when they cancel.
///
/// The only place `file_selector` is touched, so the rest of the app (and its
/// tests) never depend on it. The file is read as UTF-8 text; parsing and
/// validating it as a backup is `decodeBackup`'s job, not this function's.
Future<String?> pickBackupContents() async {
  const backupFiles = XTypeGroup(
    label: 'Cadence backup',
    extensions: ['json'],
    mimeTypes: ['application/json'],
  );
  final file = await openFile(acceptedTypeGroups: [backupFiles]);
  if (file == null) {
    return null;
  }
  return file.readAsString();
}
