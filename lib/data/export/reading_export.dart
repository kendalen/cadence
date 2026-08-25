import 'package:intl/intl.dart';

import '../../domain/sessions/reading.dart';
import '../../domain/sessions/reading_context.dart';
import '../../domain/sessions/session.dart';

/// The localised text an export needs, gathered once and passed to the pure
/// builders below.
///
/// Wording — the document title, the disclaimer, the column headers, and the
/// label for each context enum value — is a presentation concern, so it is
/// resolved in the UI layer from the ARB and handed down here (CLAUDE.md §3,
/// §9). That keeps [buildReadingRows] (and the CSV/PDF encoders) free of Flutter
/// and of any one language, so they can be unit-tested with plain strings.
class ExportLabels {
  /// Creates the label bundle. [columnHeaders] must have [exportColumnCount]
  /// entries, in the order [buildReadingRows] emits cells.
  ExportLabels({
    required this.title,
    required this.disclaimer,
    required this.columnHeaders,
    required this.site,
    required this.posture,
    required this.medication,
  }) : assert(
         columnHeaders.length == exportColumnCount,
         'one header per exported column',
       );

  /// Title shown at the top of the PDF document.
  final String title;

  /// The "diary, not a diagnosis" line shown on both exports (CLAUDE.md §1).
  final String disclaimer;

  /// One header per column, in the order [buildReadingRows] emits cells.
  final List<String> columnHeaders;

  /// The label shown for each [MeasurementSite].
  final Map<MeasurementSite, String> site;

  /// The label shown for each [Posture].
  final Map<Posture, String> posture;

  /// The label shown for each [MedicationTiming].
  final Map<MedicationTiming, String> medication;
}

/// The number of columns a reading row carries: date, time, occasion number,
/// systolic, diastolic, pulse, where, position, medication, note.
const int exportColumnCount = 10;

/// Turns [sessions] into one string-cell row per reading, for CSV or PDF.
///
/// One row per reading (not per occasion) so a clinician sees the raw numbers;
/// derived values such as the session average are never included (CLAUDE.md §4).
/// Occasions are ordered oldest-first and numbered from 1 — a printed log reads
/// forward in time, the reverse of the newest-first list in the app — and the
/// number lets a reader see which readings were taken on the same occasion
/// without exposing the internal id. Readings within an occasion are ordered by
/// time ([Session.readingsByTime]). An unrecorded optional field becomes an
/// empty cell.
///
/// [locale] drives date and time formatting. [toLocal] converts a reading's UTC
/// [Reading.takenAt] to the reader's wall-clock time; it is injected so tests
/// are timezone-independent, defaulting to [DateTime.toLocal].
List<List<String>> buildReadingRows(
  List<Session> sessions,
  ExportLabels labels, {
  required String locale,
  DateTime Function(DateTime) toLocal = _toLocal,
}) {
  final dateFormat = DateFormat.yMMMd(locale);
  final timeFormat = DateFormat.jm(locale);
  final ordered = [...sessions]
    ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

  final rows = <List<String>>[];
  for (var index = 0; index < ordered.length; index++) {
    final occasion = '${index + 1}';
    for (final reading in ordered[index].readingsByTime) {
      final at = toLocal(reading.takenAt);
      rows.add([
        dateFormat.format(at),
        timeFormat.format(at),
        occasion,
        '${reading.systolic}',
        '${reading.diastolic}',
        reading.pulse?.toString() ?? '',
        _label(reading.site, labels.site),
        _label(reading.posture, labels.posture),
        _label(reading.medicationTiming, labels.medication),
        reading.notes ?? '',
      ]);
    }
  }
  return rows;
}

String _label<T>(T? value, Map<T, String> labels) =>
    value == null ? '' : labels[value]!;

DateTime _toLocal(DateTime value) => value.toLocal();
