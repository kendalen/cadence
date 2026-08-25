/// Encodes rows of already-formatted string cells as RFC 4180 CSV text.
///
/// This is deliberately dumb: it knows nothing about readings, columns or
/// language. The caller builds the rows (localised headers, localised values —
/// see `reading_export.dart`) and this turns them into a correctly-escaped CSV
/// document. Keeping the escaping here, in one tested place, is why the app
/// grows no second, hand-rolled way to join cells with commas (CLAUDE.md §8).
///
/// Records are separated by CRLF and fields by comma, per RFC 4180. A field is
/// quoted only when it has to be — when it contains a comma, a double quote, or
/// a line break — and an embedded double quote is doubled. Rows may be ragged
/// (a leading one-cell disclaimer row alongside the wider data rows is valid).
String encodeCsv(List<List<String>> rows) => rows.map(_encodeRow).join('\r\n');

String _encodeRow(List<String> cells) => cells.map(_encodeField).join(',');

String _encodeField(String value) {
  if (value.contains(_needsQuoting)) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

final _needsQuoting = RegExp('["\r\n,]');
