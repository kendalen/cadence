import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/export/csv_codec.dart';
import '../../data/export/pdf_report.dart';
import '../../data/export/reading_export.dart';
import '../../domain/sessions/session.dart';
import '../../domain/sessions/session_repository.dart';
import '../../domain/sessions/sessions_in_last_days.dart';
import '../../l10n/app_localizations.dart';
import '../about/app_about.dart';
import '../sessions/export/export_labels.dart';
import '../sessions/export/share_export.dart';
import '../system_insets.dart';

/// The app's Settings screen, reached from the gear icon in the readings list.
///
/// Home of the date-bounded readings export (CSV / PDF for handing a clinician a
/// recent window) and the About dialog. It reads the diary through the
/// [SessionRepository] provided at the app root, so it stands on its own as a
/// pushed route rather than depending on the list's cubit.
class SettingsScreen extends StatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// How far back a readings export reaches. [days] is `null` for "all readings",
/// which skips the date filter entirely.
enum _ExportRange {
  last7(7),
  last30(30),
  last90(90),
  all(null);

  const _ExportRange(this.days);

  /// The number of calendar days to keep, or `null` for every reading.
  final int? days;

  String label(AppLocalizations l10n) => switch (this) {
    _ExportRange.last7 => l10n.settingsExportRangeLast7,
    _ExportRange.last30 => l10n.settingsExportRangeLast30,
    _ExportRange.last90 => l10n.settingsExportRangeLast90,
    _ExportRange.all => l10n.settingsExportRangeAll,
  };
}

/// One shareable readings format; only the encoder, extension and MIME differ.
enum _ReadingsFormat { csv, pdf }

class _SettingsScreenState extends State<SettingsScreen> {
  // Defaults to the last 30 days — the same default the trends screen opens on,
  // a useful window without dumping years of history into one file.
  _ExportRange _range = _ExportRange.last30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: withSystemInsets(
          context,
          const EdgeInsets.symmetric(vertical: 8),
        ),
        children: [
          _SectionHeading(l10n.settingsExportHeading),
          // A RadioGroup ancestor manages the selection; the tiles themselves
          // just declare their value (the groupValue/onChanged on RadioListTile
          // were deprecated after Flutter 3.32).
          RadioGroup<_ExportRange>(
            groupValue: _range,
            onChanged: (value) => setState(() => _range = value!),
            child: Column(
              children: [
                for (final range in _ExportRange.values)
                  RadioListTile<_ExportRange>(
                    value: range,
                    title: Text(range.label(l10n)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _export(_ReadingsFormat.csv),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: Text(l10n.exportCsv),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _export(_ReadingsFormat.pdf),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l10n.exportPdf),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutMenu),
            onTap: () => showAppAbout(context),
          ),
        ],
      ),
    );
  }

  /// Builds the readings in [format], bounded to the chosen range, and opens the
  /// share sheet.
  ///
  /// One row per reading, oldest first, with a "diary, not a diagnosis" line
  /// (CLAUDE.md §1). The full diary is read once, then narrowed to the selected
  /// window; an empty result shows a note instead of an empty file. Any failure
  /// preparing or sharing is reported rather than surfaced raw (CLAUDE.md §6),
  /// and backing out of the share sheet is not a failure. The current locale
  /// drives headers, context wording and date formatting (CLAUDE.md §9).
  Future<void> _export(_ReadingsFormat format) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final locale = Localizations.localeOf(context).toString();
    final repository = context.read<SessionRepository>();

    final now = DateTime.now();
    final all = await repository.recentHistory();
    final days = _range.days;
    final List<Session> sessions = days == null
        ? all
        : sessionsInLastDays(all, days: days, now: now);

    if (sessions.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportEmpty)));
      return;
    }

    try {
      final labels = exportLabels(l10n);
      final rows = buildReadingRows(sessions, labels, locale: locale);
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
}

/// A padded section heading in the settings list.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
