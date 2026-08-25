import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders the readings [rows] as a printable PDF document and returns its
/// bytes, ready to hand to the share sheet.
///
/// The layout is deliberately plain — a title, one table (paginated
/// automatically by [pw.MultiPage] for a long diary), and the [disclaimer] as a
/// footer on every page. The footer keeps Cadence's "diary, not a diagnosis"
/// boundary visible on the most official-looking thing the app produces
/// (CLAUDE.md §1). Built-in Helvetica is used (no font asset), which covers
/// Latin-1 including Italian accents; the caller supplies already-localised
/// [headers], [rows], [title] and [disclaimer] (CLAUDE.md §9).
Future<Uint8List> buildReadingsPdf({
  required String title,
  required List<String> headers,
  required List<List<String>> rows,
  required String disclaimer,
}) async {
  // ponytail: built-in Helvetica (WinAnsi encoding) — covers Latin-1 incl.
  // Italian accents, so no font asset is loaded. Embed the already-bundled
  // Hanken Grotesk TTF (assets/fonts/) if a note ever needs glyphs outside
  // Latin-1 (e.g. non-Latin scripts, emoji), which Helvetica would drop.
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Header(level: 0, text: title),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerLeft,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          disclaimer,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ),
    ),
  );
  return document.save();
}
