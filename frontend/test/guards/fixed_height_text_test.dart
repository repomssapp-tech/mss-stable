// spec_design_system.md §8, fixed_height_text_test.dart. Forbids a
// `SizedBox(height: N` / `Container(height: N` whose child subtree contains
// a `Text(` within the next 6 lines -- a fixed pixel height around text
// clips Tamil/scaled text instead of letting the row grow. Ratcheted:
// pre-existing fixed-height text containers across the screen sweep.

import 'package:flutter_test/flutter_test.dart';

import 'guard_support.dart';

final _boxStart = RegExp(r'(?:SizedBox|Container)\(');
final _heightArg = RegExp(r'\bheight:\s*\d');
final _textCall = RegExp(r'Text\(');

void main() {
  test(
    'lib/ does not wrap Text( in a fixed-height SizedBox/Container',
    () {
      final actual = <String, int>{};
      for (final file in dartFilesUnder('lib')) {
        final path = relPath(file);
        final src = file.readAsStringSync();
        final lines = src.split('\n');
        var count = 0;

        for (final call in balancedCallsWithOffsets(src, _boxStart)) {
          if (!_heightArg.hasMatch(call.text)) continue;
          final startLine = lineOf(src, call.start);
          if (lines[startLine].contains('// height-ok')) continue;

          final within6 = [
            for (var l = startLine; l <= startLine + 6 && l < lines.length; l++) lines[l],
          ].join('\n');
          if (!_textCall.hasMatch(within6)) continue;

          count++;
        }

        if (count > 0) actual[path] = count;
      }

      expectNoRatchetRegression(
        rule: 'fixed_height_text',
        actual: actual,
        violationDescription: 'Fixed-height SizedBox/Container wrapping a Text( within 6 lines',
      );
    },
  );
}
