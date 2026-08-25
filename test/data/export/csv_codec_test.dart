import 'package:cadence/data/export/csv_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('encodeCsv', () {
    test('joins plain fields with commas and rows with CRLF', () {
      expect(
        encodeCsv([
          ['Date', 'Systolic', 'Diastolic'],
          ['2026-08-25', '120', '80'],
        ]),
        'Date,Systolic,Diastolic\r\n2026-08-25,120,80',
      );
    });

    test('quotes a field containing a comma', () {
      expect(
        encodeCsv([
          ['felt dizzy, then rested'],
        ]),
        '"felt dizzy, then rested"',
      );
    });

    test('quotes and doubles an embedded double quote', () {
      expect(
        encodeCsv([
          ['said "fine"'],
        ]),
        '"said ""fine"""',
      );
    });

    test('quotes a field containing a newline', () {
      expect(
        encodeCsv([
          ['line one\nline two'],
        ]),
        '"line one\nline two"',
      );
    });

    test('leaves an empty field empty and does not quote it', () {
      expect(
        encodeCsv([
          ['120', '', '80'],
        ]),
        '120,,80',
      );
    });

    test('allows ragged rows (a one-cell disclaimer above wide data)', () {
      expect(
        encodeCsv([
          ['Not a diagnosis'],
          ['Date', 'Systolic'],
          ['2026-08-25', '120'],
        ]),
        'Not a diagnosis\r\nDate,Systolic\r\n2026-08-25,120',
      );
    });

    test('encodes no rows as the empty string', () {
      expect(encodeCsv([]), '');
    });
  });
}
