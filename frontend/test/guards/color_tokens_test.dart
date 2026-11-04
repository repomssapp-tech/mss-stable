// spec_design_system.md §8, color_tokens_test.dart. Forbids raw hex Color()
// literals and named Colors.* (grey/red/green/orange/blue/black/white)
// outside AppColors and the §3.5 painter allowlist. Ratcheted: 1608 hex
// literals across 118 files pre-exist.

import 'package:flutter_test/flutter_test.dart';

import 'guard_support.dart';

const _allowedFiles = <String>{'lib/utils/app_colors.dart'};

// §3.5 painter/illustration allowlist (brand colours, decorative gradients).
const _allowedSubstrings = <String>[
  'state_map_painter.dart',
  'login_screen.dart', // _GoogleIconPainter brand colours
  'saarthi_character_header.dart',
  'splash_screen.dart',
  'categories_data.dart',
];

bool _isAllowed(String path) =>
    _allowedFiles.contains(path) ||
    _allowedSubstrings.any((s) => path.contains(s));

final _hexColorPattern = RegExp(r'Color\(0x[0-9A-Fa-f]{6,8}\)');
final _namedColorPattern = RegExp(
  r'Colors\.(grey|red|green|orange|blue|black|white)\b',
);

void main() {
  test('lib/ uses AppColors instead of raw Color()/Colors.* literals', () {
    final actual = <String, int>{};
    for (final file in dartFilesUnder('lib')) {
      final path = relPath(file);
      if (_isAllowed(path) || isDesignCanvas(path)) continue;
      final src = file.readAsStringSync();
      var count = 0;
      for (final line in src.split('\n')) {
        if (line.contains('// color-ok')) continue;
        count += _hexColorPattern.allMatches(line).length;
        count += _namedColorPattern.allMatches(line).length;
      }
      if (count > 0) actual[path] = count;
    }

    expectNoRatchetRegression(
      rule: 'color_tokens',
      actual: actual,
      violationDescription: 'Raw Color()/Colors.* literals',
    );
  });
}
