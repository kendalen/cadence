import 'dart:io';

import 'package:cadence/data/export/pdf_report.dart';
import 'package:flutter_test/flutter_test.dart';

const _headers = ['Date', 'Systolic', 'Diastolic'];

String _magic(List<int> bytes) => String.fromCharCodes(bytes.take(5));

void main() {
  group('buildReadingsPdf', () {
    test('produces a valid, non-empty PDF for a table of readings', () async {
      final bytes = await buildReadingsPdf(
        title: 'Readings',
        headers: _headers,
        rows: [
          ['25 Aug 2026', '120', '80'],
          ['25 Aug 2026', '128', '84'],
        ],
        disclaimer: 'Not a diagnosis',
      );

      expect(bytes, isNotEmpty);
      expect(_magic(bytes), '%PDF-');
    });

    test('embeds a supplied font, rendering accents and punctuation', () async {
      // The real bundled font, so the embed path (used for Italian text) is
      // exercised end to end, not just the Helvetica fallback.
      final font = File('assets/fonts/HankenGrotesk-VariableFont_wght.ttf')
          .readAsBytesSync();

      final bytes = await buildReadingsPdf(
        title: 'Readings',
        headers: _headers,
        rows: [
          ['25/8/2026', '138', '87'],
        ],
        disclaimer: 'Self-recorded diary — l’ho misurato: àèéìòù',
        fontBytes: font,
      );

      expect(_magic(bytes), '%PDF-');
    });

    test('handles an empty table without throwing', () async {
      final bytes = await buildReadingsPdf(
        title: 'Readings',
        headers: _headers,
        rows: const [],
        disclaimer: 'Not a diagnosis',
      );

      expect(_magic(bytes), '%PDF-');
    });
  });
}
