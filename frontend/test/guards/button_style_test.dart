// spec_design_system.md §8, button_style_test.dart. Forbids per-call
// (Elevated|Outlined|Text|Filled)Button.styleFrom(...) overrides of
// backgroundColor:/shape:/minimumSize:/padding: outside AppTheme.light --
// those belong in the theme's button themes, not scattered across screens.
// Ratcheted: pre-existing hand-styled buttons (audit_design.md G6).

import 'package:flutter_test/flutter_test.dart';

import 'guard_support.dart';

const _allowedFiles = <String>{'lib/utils/app_theme.dart'};

final _styleFromStart = RegExp(
  r'(?:Elevated|Outlined|Text|Filled)Button\.styleFrom\(',
);
final _overriddenProp = RegExp(
  r'backgroundColor:|shape:|minimumSize:|padding:',
);

void main() {
  test('lib/ does not override button backgroundColor/shape/minimumSize/padding '
      'via styleFrom outside AppTheme.light', () {
    final actual = <String, int>{};
    for (final file in dartFilesUnder('lib')) {
      final path = relPath(file);
      if (_allowedFiles.contains(path) || isDesignCanvas(path)) continue;
      final src = file.readAsStringSync();
      final lines = src.split('\n');
      var count = 0;

      for (final call in balancedCallsWithOffsets(src, _styleFromStart)) {
        if (!_overriddenProp.hasMatch(call.text)) continue;
        final startLine = lineOf(src, call.start);
        if (lines[startLine].contains('// style-ok')) continue;
        count++;
      }

      if (count > 0) actual[path] = count;
    }

    expectNoRatchetRegression(
      rule: 'button_style',
      actual: actual,
      violationDescription:
          'Hand-styled ButtonStyle.styleFrom() overrides outside AppTheme.light',
    );
  });
}
