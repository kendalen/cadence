import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/backup/backup_decoder.dart';
import '../../../data/export/csv_codec.dart';
import '../../../data/export/pdf_report.dart';
import '../../../data/export/reading_export.dart';
import '../../../domain/core/result.dart';
import '../../../domain/sessions/session.dart';
import '../../../domain/sessions/session_repository.dart';
import '../../../domain/sessions/weekly_coverage.dart';
import '../../../l10n/app_localizations.dart';
import '../../system_insets.dart';
import '../backup/pick_backup.dart';
import '../detail/session_detail_screen.dart';
import '../entry/session_entry_screen.dart';
import '../export/export_labels.dart';
import '../export/share_export.dart';
import '../pressure_text.dart';
import 'session_list_cubit.dart';
import 'session_list_state.dart';
import 'weekly_coverage_card.dart';

/// The recorded readings, newest first.
///
/// The list itself is read-only: an occasion is opened, edited, and deleted on
/// the [SessionDetailScreen] a tap away, not from here.
class SessionListScreen extends StatelessWidget {
  /// Shows the sessions held by the repository provided above this widget.
  const SessionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) => SessionListCubit(context.read<SessionRepository>()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          actions: const [_OverflowMenu()],
        ),
        body: BlocBuilder<SessionListCubit, SessionListState>(
          builder: (context, state) => switch (state) {
            SessionListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            SessionListLoaded(:final sessions) when sessions.isEmpty =>
              const _EmptyList(),
            SessionListLoaded(:final sessions) => Column(
              children: [
                // The week's coverage stays pinned while the occasions scroll,
                // so the older audience never loses the "am I keeping up?"
                // summary. The clock lives here, keeping weeklyCoverage pure.
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: WeeklyCoverageCard(
                    weeklyCoverage(sessions, now: DateTime.now()),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    // Room at the end so the last card can scroll clear of the
                    // floating "Add a reading" button (and the nav bar) instead
                    // of hiding behind it.
                    padding: withSystemBottomInset(
                      context,
                      const EdgeInsets.only(bottom: 88),
                    ),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) =>
                        _SessionTile(sessions[index]),
                  ),
                ),
              ],
            ),
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEntryForm(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.addReading),
        ),
      ),
    );
  }

  void _openEntryForm(BuildContext context) {
    // The list needs no result back: it is watching the store, so a saved
    // session arrives through the stream.
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const SessionEntryScreen()),
    );
  }
}

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
}

/// One shareable readings format. Both share the same build-and-share path;
/// only the encoder, filename extension and MIME type differ.
enum _ReadingsFormat { csv, pdf }

/// The app-bar overflow (⋮) menu, home of the data in/out actions: JSON backup
/// (restorable), CSV and PDF export (one-way, for handing a clinician the
/// numbers), and import.
class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<_MenuAction>(
      onSelected: (action) => unawaited(switch (action) {
        _MenuAction.export => _exportBackup(context),
        _MenuAction.exportCsv => _exportReadings(context, _ReadingsFormat.csv),
        _MenuAction.exportPdf => _exportReadings(context, _ReadingsFormat.pdf),
        _MenuAction.import => _importBackup(context),
      }),
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
      switch (format) {
        case _ReadingsFormat.csv:
          // The disclaimer rides as a one-cell leading row so the whole file is
          // valid CSV; the header row follows, then the readings.
          final csv = encodeCsv([
            [labels.disclaimer],
            labels.columnHeaders,
            ...rows,
          ]);
          await shareExportBytes(
            utf8.encode(csv),
            filename: readingsFilename(now, extension: 'csv'),
            mimeType: 'text/csv',
          );
        case _ReadingsFormat.pdf:
          final pdf = await buildReadingsPdf(
            title: labels.title,
            headers: labels.columnHeaders,
            rows: rows,
            disclaimer: labels.disclaimer,
          );
          await shareExportBytes(
            pdf,
            filename: readingsFilename(now, extension: 'pdf'),
            mimeType: 'application/pdf',
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
      await shareBackup(json, filename: backupFilename(now));
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

/// What the list shows before anything has been recorded.
class _EmptyList extends StatelessWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.sessionListEmpty, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.sessionListEmptyHint, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// One occasion in the list, shown as the average of its readings (CLAUDE.md §4).
///
/// The average of a single reading is that reading, so a one-off entry reads as
/// itself; a badge marks the occasions holding more than one so the averaged row
/// is never mistaken for a single measurement. Tapping the row opens the
/// occasion in full ([SessionDetailScreen]) — the one place its individual
/// readings, context and notes are shown.
class _SessionTile extends StatelessWidget {
  const _SessionTile(this.session);

  final Session session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final average = session.average;
    final readingCount = session.readings.length;
    final locale = Localizations.localeOf(context).toString();
    final takenAt = DateFormat.yMMMd(locale)
        .add_jm()
        .format(session.occurredAt.toLocal());

    // A card per occasion, matching the approved visual design; the card's
    // colour, border, radius and spacing come from the theme's cardTheme.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        title: Row(
          children: [
            PressureText(average.systolic, average.diastolic),
            if (readingCount > 1) ...[
              const SizedBox(width: 8),
              _ReadingCountBadge(readingCount),
            ],
            const Spacer(),
            if (average.pulse != null) Text(l10n.readingPulse(average.pulse!)),
          ],
        ),
        subtitle: Text(takenAt),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => SessionDetailScreen(session),
          ),
        ),
      ),
    );
  }
}

/// A small pill showing how many readings an occasion holds.
///
/// The count is a numeral; the word "readings" lives in the accessible label
/// and tooltip, so screen-reader and long-press users hear "N readings" while
/// the row stays compact.
class _ReadingCountBadge extends StatelessWidget {
  const _ReadingCountBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = l10n.readingCount(count);
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
