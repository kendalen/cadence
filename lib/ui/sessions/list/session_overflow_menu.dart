import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/backup/backup_decoder.dart';
import '../../../data/export/csv_codec.dart';
import '../../../data/export/pdf_report.dart';
import '../../../data/export/reading_export.dart';
import '../../../domain/core/result.dart';
import '../../../domain/sessions/session_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../about/app_about.dart';
import '../backup/pick_backup.dart';
import '../export/export_labels.dart';
import '../export/share_export.dart';
import 'session_list_cubit.dart';
import 'session_list_state.dart';

/// What the overflow menu can do.
enum _MenuAction {
  /// Save the whole diary as a JSON backup and share it.
  export,

  /// Share the readings as a CSV spreadsheet.
  exportCsv,

  /// Share the readings as a PDF document.
  exportPdf,

  /// Restore occasions from a JSON backup file.
  import,

  /// Open the About dialog (the diary-not-a-device note plus licences).
  about,
}

/// One shareable readings format. Both share the same build-and-share path;
/// only the encoder, filename extension and MIME type differ.
enum _ReadingsFormat { csv, pdf }

/// The app-bar overflow (⋮) menu, home of the data in/out actions: JSON backup
/// (restorable), CSV and PDF export (one-way, for handing a clinician the
/// numbers), and import.
///
/// It reads the diary from the [SessionListCubit] provided above it and writes
/// through the [SessionRepository], so it lives beside the list rather than
/// inside the screen widget (which stays focused on laying out the list).
class SessionOverflowMenu extends StatelessWidget {
  /// Creates the overflow menu.
  const SessionOverflowMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<_MenuAction>(
      onSelected: (action) => switch (action) {
        _MenuAction.export => unawaited(_exportBackup(context)),
        _MenuAction.exportCsv => unawaited(
          _exportReadings(context, _ReadingsFormat.csv),
        ),
        _MenuAction.exportPdf => unawaited(
          _exportReadings(context, _ReadingsFormat.pdf),
        ),
        _MenuAction.import => unawaited(_importBackup(context)),
        _MenuAction.about => showAppAbout(context),
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _MenuAction.export,
          child: Text(l10n.exportBackup),
        ),
        PopupMenuItem(
          value: _MenuAction.exportCsv,
          child: Text(l10n.exportCsv),
        ),
        PopupMenuItem(
          value: _MenuAction.exportPdf,
          child: Text(l10n.exportPdf),
        ),
        PopupMenuItem(
          value: _MenuAction.import,
          child: Text(l10n.importBackup),
        ),
        // A divider sets About apart from the data in/out actions above it.
        const PopupMenuDivider(),
        PopupMenuItem(value: _MenuAction.about, child: Text(l10n.aboutMenu)),
      ],
    );
  }

  /// Builds the readings in [format] and opens the share sheet.
  ///
  /// One row per reading, oldest first, with a "diary, not a diagnosis" line
  /// (CLAUDE.md §1). An empty diary shows a note instead of an empty file; any
  /// failure preparing or sharing is reported rather than surfaced raw
  /// (CLAUDE.md §6), and backing out of the share sheet is not a failure. The
  /// current locale drives the headers, context wording and date formatting
  /// (CLAUDE.md §9). The full diary is already in the loaded state (the list
  /// watches every session), so no extra read is needed.
  Future<void> _exportReadings(
    BuildContext context,
    _ReadingsFormat format,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final state = context.read<SessionListCubit>().state;
    final locale = Localizations.localeOf(context).toString();

    if (state is! SessionListLoaded || state.sessions.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportEmpty)));
      return;
    }

    try {
      final now = DateTime.now();
      final labels = exportLabels(l10n);
      final rows = buildReadingRows(state.sessions, labels, locale: locale);
      final bool shared;
      switch (format) {
        case _ReadingsFormat.csv:
          // The disclaimer rides as a one-cell leading row so the whole file is
          // valid CSV; the header row follows, then the readings.
          final csv = encodeCsv([
            [labels.disclaimer],
            labels.columnHeaders,
            ...rows,
          ]);
          shared = await shareExportBytes(
            utf8.encode(csv),
            filename: readingsFilename(now, extension: 'csv'),
            mimeType: 'text/csv',
          );
        case _ReadingsFormat.pdf:
          // Embed the bundled Hanken font so accented Italian text and
          // typographic punctuation render, not the built-in Helvetica's box.
          final font = await rootBundle.load(
            'assets/fonts/HankenGrotesk-VariableFont_wght.ttf',
          );
          final pdf = await buildReadingsPdf(
            title: labels.title,
            headers: labels.columnHeaders,
            rows: rows,
            disclaimer: labels.disclaimer,
            fontBytes: font.buffer.asUint8List(
              font.offsetInBytes,
              font.lengthInBytes,
            ),
          );
          shared = await shareExportBytes(
            pdf,
            filename: readingsFilename(now, extension: 'pdf'),
            mimeType: 'application/pdf',
          );
      }
      if (shared) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.exportReadingsSuccess)),
        );
      }
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportFailed)));
    }
  }

  /// Builds the whole diary as a JSON backup and opens the share sheet.
  ///
  /// A backup with nothing in it is not worth sharing, so an empty diary shows
  /// a note instead. Any failure preparing or sharing the file is reported to
  /// the user rather than surfaced raw (CLAUDE.md §6); a user who backs out of
  /// the share sheet is not a failure. One clock read stamps both the document
  /// and the filename so they always agree.
  Future<void> _exportBackup(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<SessionListCubit>();

    final state = cubit.state;
    if (state is SessionListLoaded && state.sessions.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportBackupEmpty)));
      return;
    }

    try {
      final now = DateTime.now().toUtc();
      final json = await cubit.buildBackupJson(now: now);
      final shared = await shareBackup(json, filename: backupFilename(now));
      if (shared) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.exportBackupSuccess)),
        );
      }
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportBackupFailed)));
    }
  }

  /// Picks a backup file, and — after confirmation — merges its occasions in.
  ///
  /// The file is read and validated before anything is written, so a bad file
  /// is refused with a plain reason (never a raw exception, CLAUDE.md §6) and
  /// the confirm step states what will happen (§6 confirms an import). Merge is
  /// by id and never overwrites (§5), so the confirmation informs rather than
  /// guards against loss; the summary afterwards reports what was added and
  /// notes if anything in the file could not be read (§5, never drop silently).
  Future<void> _importBackup(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final repository = context.read<SessionRepository>();

    final String? contents;
    try {
      contents = await pickBackupContents();
    } on Exception {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.importBackupUnreadable)),
      );
      return;
    }
    if (contents == null) {
      return; // The user cancelled the picker.
    }

    final BackupParsed parsed;
    switch (decodeBackup(contents)) {
      case BackupRejected(:final reason):
        messenger.showSnackBar(
          SnackBar(content: Text(_rejectionMessage(l10n, reason))),
        );
        return;
      case final BackupParsed result:
        parsed = result;
    }

    if (!context.mounted) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importBackupConfirmTitle),
        content: Text(l10n.importBackupConfirmBody(parsed.sessions.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.importBackupConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    switch (await repository.importSessions(parsed.sessions)) {
      case Ok(:final value):
        final message = StringBuffer(l10n.importBackupSummary(value.added));
        if (parsed.skippedReadings > 0 || parsed.skippedSessions > 0) {
          message
            ..write(' ')
            ..write(l10n.importBackupSomeSkipped);
        }
        messenger.showSnackBar(SnackBar(content: Text(message.toString())));
      case Err():
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.importBackupFailed)),
        );
    }
  }

  /// The message for a backup that could not be read at all.
  String _rejectionMessage(
    AppLocalizations l10n,
    BackupRejectedReason reason,
  ) => switch (reason) {
    BackupRejectedReason.notABackup => l10n.importBackupNotABackup,
    BackupRejectedReason.unreadable => l10n.importBackupUnreadable,
    BackupRejectedReason.tooNew => l10n.importBackupTooNew,
  };
}
