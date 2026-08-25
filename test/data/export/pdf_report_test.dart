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
