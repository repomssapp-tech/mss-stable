// spec_design_system.md §8, tap_target_test.dart. Forbids raw
// GestureDetector(onTap:/onTapDown:/onLongPress:) in lib/screens and
// lib/widgets (use AppTappable), and IconButton() calls that collapse their
// own hit area via BoxConstraints() or padding: EdgeInsets.zero without
// compensating with AppSize.tapTarget (use AppIconButton).
//
// D5 (Phase 2 design review): this used to match
// `GestureDetector\(\s*(?:behavior:[^,]+,\s*)?onTap:` LINE BY LINE, so the
// repo's usual formatting (`GestureDetector(` then `onTap: ...` on the next
// line) was invisible to it -- the baseline recorded 4 sites when the real
// count is closer to 41. Now scans the whole file with
// balancedCallsWithOffsets(src, RegExp(r'GestureDetector\(')) so a call's
// onTap:/onTapDown:/onLongPress: can be anywhere inside it, nested parens
// and all, and checks the escape comment on the call's own start line
// (not a re-found, possibly-wrong-duplicate line).

import 'package:flutter_test/flutter_test.dart';

import 'guard_support.dart';

const _allowedFiles = <String>{
  'lib/widgets/common/app_icon_button.dart',
  'lib/widgets/common/app_tappable.dart',
};

final _gestureDetectorStart = RegExp(r'GestureDetector\(');
final _gestureHandlerPattern = RegExp(r'onTap:|onTapDown:|onLongPress:');
final _iconButtonStart = RegExp(r'IconButton\(');

bool _collapsesHitArea(String call) =>
    (call.contains('BoxConstraints()') || call.contains('padding: EdgeInsets.zero')) &&
    !call.contains('AppSize.tapTarget');

void main() {
  test(
    'lib/screens and lib/widgets use AppTappable/AppIconButton instead of '
    'raw GestureDetector(onTap:/onTapDown:/onLongPress:) or a collapsed '
    'IconButton hit area',
    () {
      final actual = <String, int>{};
      for (final file in dartFilesUnder('lib')) {
        final path = relPath(file);
        if (_allowedFiles.contains(path)) continue;
        if (!path.startsWith('lib/screens/') && !path.startsWith('lib/widgets/')) {
          continue;
        }
        final src = file.readAsStringSync();
        final lines = src.split('\n');
        var count = 0;

        for (final call in balancedCallsWithOffsets(src, _gestureDetectorStart)) {
          if (!_gestureHandlerPattern.hasMatch(call.text)) continue;
          final startLine = lineOf(src, call.start);
          if (lines[startLine].contains('// tap-ok')) continue;
          count++;
        }

        for (final call in balancedCallsWithOffsets(src, _iconButtonStart)) {
          if (!_collapsesHitArea(call.text)) continue;
          final startLine = lineOf(src, call.start);
          if (lines[startLine].contains('// tap-ok')) continue;
          count++;
        }

        if (count > 0) actual[path] = count;
      }

      expectNoRatchetRegression(
        rule: 'tap_target',
        actual: actual,
        violationDescription: 'Raw GestureDetector tap handlers/collapsed IconButton hit areas',
      );
    },
  );
}
