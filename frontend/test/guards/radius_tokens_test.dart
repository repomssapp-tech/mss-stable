// spec_design_system.md §8, radius_tokens_test.dart. Forbids numeric
// BorderRadius.circular()/Radius.circular() literals outside AppRadius and
// painters. Ratcheted: 376 uses across 18 distinct radii pre-exist.

import 'package:flutter_test/flutter_test.dart';

import 'guard_support.dart';

const _allowedFiles = <String>{'lib/utils/app_radius.dart'};

bool _isAllowed(String path) =>
    _allowedFiles.contains(path) ||
    path.contains('/painters/') ||
    path.contains('_painter.dart');

final _radiusPattern = RegExp(r'(?:BorderRadius|Radius)\.circular\(\s*\d');

void main() {
  test('lib/ uses AppRadius instead of numeric circular() literals', () {
    final actual = <String, int>{};
    for (final file in dartFilesUnder('lib')) {
      final path = relPath(file);
      if (_isAllowed(path) || isDesignCanvas(path)) continue;
      final src = file.readAsStringSync();
      var count = 0;
      for (final line in src.split('\n')) {
        if (line.contains('// radius-ok')) continue;
        count += _radiusPattern.allMatches(line).length;
      }
      if (count > 0) actual[path] = count;
    }

    expectNoRatchetRegression(
      rule: 'radius_tokens',
      actual: actual,
      violationDescription:
          'Numeric BorderRadius.circular()/Radius.circular() literals',
    );
  });
}
