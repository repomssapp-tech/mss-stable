import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A close (X) icon button has no visible text, so without a tooltip a screen
/// reader announces it as an unnamed button (device audit 1.8).
void main() {
  test('every IconButton that shows Icons.close has a tooltip', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final match in RegExp(r'IconButton\(').allMatches(source)) {
        // The button's own argument list: up to the next IconButton or 600
        // characters, whichever comes first.
        final next = source.indexOf('IconButton(', match.end);
        final end = (next == -1 ? source.length : next).clamp(
          match.end,
          match.end + 600,
        );
        final body = source.substring(match.start, end);
        if (body.contains('Icons.close') && !body.contains('tooltip:')) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length;
          offenders.add('${file.path}:${line + 1}');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Close buttons without tooltip: $offenders');
  });
}
