// spec_design_system.md §8, fit_one_line_test.dart. Forbids `FitOneLine(` /
// `FittedBox(` wrapping a `Text(` -- shrinking text to fit defeats the
// type-scale floor and clips Tamil at larger text-scale settings. The
// escape hatch is for genuinely numeric displays (counters, prices) where
// shrink-to-fit is intentional, not a layout-overflow workaround.
// Ratcheted: pre-existing shrink-to-fit text across the screen sweep.

import 'package:flutter_test/flutter_test.dart';

import 'guard_support.dart';

final _fitStart = RegExp(r'(?:FitOneLine|FittedBox)\(');
final _textCall = RegExp(r'Text\(');

void main() {
  test(
    'lib/ does not wrap Text( in FitOneLine()/FittedBox()',
    () {
      final actual = <String, int>{};
      for (final file in dartFilesUnder('lib')) {
        final path = relPath(file);
        final src = file.readAsStringSync();
        final lines = src.split('\n');
        var count = 0;

        for (final call in balancedCallsWithOffsets(src, _fitStart)) {
          if (!_textCall.hasMatch(call.text)) continue;
          final startLine = lineOf(src, call.start);
          if (lines[startLine].contains('// type-ok: numeric')) continue;
          count++;
        }

        if (count > 0) actual[path] = count;
      }

      expectNoRatchetRegression(
        rule: 'fit_one_line',
        actual: actual,
        violationDescription: 'FitOneLine()/FittedBox() shrinking a Text(',
      );
    },
  );
}
