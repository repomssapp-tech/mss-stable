/// Splits a comma-separated catalog field (category, scheme type, sector) into
/// card chips.
///
/// A comma inside brackets belongs to one phrase -- "Food processing (micro
/// enterprises, trading, services)" is one chip, not three fragments like
/// "services)". Empty parts and the "Pending official verification"
/// placeholder are dropped. A bracket that never closes keeps the rest of the
/// text as one chip instead of swallowing later items silently.
List<String> splitChipList(String value) {
  final parts = <String>[];
  final buffer = StringBuffer();
  var depth = 0;
  for (final rune in value.runes) {
    final ch = String.fromCharCode(rune);
    if (ch == '(') {
      depth++;
    } else if (ch == ')' && depth > 0) {
      depth--;
    }
    if (ch == ',' && depth == 0) {
      parts.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(ch);
    }
  }
  parts.add(buffer.toString());
  return [
    for (final p in parts)
      if (p.trim().isNotEmpty &&
          p.trim().toLowerCase() != 'pending official verification')
        p.trim(),
  ];
}
