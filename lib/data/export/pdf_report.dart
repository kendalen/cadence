import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders the readings [rows] as a printable PDF document and returns its
/// bytes, ready to hand to the share sheet.
///
/// The layout is deliberately plain — a title, one table (paginated
/// automatically by [pw.MultiPage] for a long diary), and the [disclaimer] as a
/// footer on every page. The page is **landscape** so the ten columns have room
/// to breathe. The footer keeps Cadence's "diary, not a diagnosis" boundary
/// visible on the most official-looking thing the app produces (CLAUDE.md §1).
///
/// [fontBytes], when given, is a TrueType font embedded as the document's base
/// font — the app passes the bundled Hanken Grotesk so accented Italian text and
/// typographic punctuation (—, ’) render correctly; the built-in Helvetica is a
/// Latin-only fallback that shows a box for anything outside its encoding. The
/// caller supplies already-localised [headers], [rows], [title] and
/// [disclaimer] (CLAUDE.md §9).
Future<Uint8List> buildReadingsPdf({
  required String title,
  required List<String> headers,
  required List<List<String>> rows,
  required String disclaimer,
  Uint8List? fontBytes,
}) async {
  // One variable font file serves both slots: this maps every text style
  // (including the header row) onto Hanken so nothing falls back to the
  // Latin-only built-in Helvetica and boxes an accent. dart_pdf does not apply
  // the weight axis, so "bold" renders at the file's default weight — the
  // headers therefore read at body weight (a noted follow-up to make them
  // heavier needs a real bold font instance, see docs/ROADMAP.md).
  final theme = fontBytes == null
      ? null
      : pw.ThemeData.withFont(
          base: pw.Font.ttf(ByteData.sublistView(fontBytes)),
          bold: pw.Font.ttf(ByteData.sublistView(fontBytes)),
        );
  final document = pw.Document(theme: theme);
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
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
