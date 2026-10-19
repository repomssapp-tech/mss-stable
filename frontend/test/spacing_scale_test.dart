// Phase 6 enforcement: padding / margin / gap values across lib/ must be
// expressed through `AppSpacing` (lib/utils/app_spacing.dart), not a bare
// numeric literal.
//
// Phase 2 (2.5) widened this guard to close two blind spots found in
// production review:
// 1. It used to only flag a literal that happened to match an on-scale
//    AppSpacing value (e.g. a bare `16`). An off-scale literal (`28`, `22`,
//    `9`, `85`, ...) was invisible to it entirely -- which is exactly how
//    ~37 off-scale raw EdgeInsets/SizedBox literals across 18 files slipped
//    past this test undetected (see _manager/audit_engineering.md §4). Now
//    ANY numeric literal in a padding/margin/gap position is a violation,
//    ratcheted via test/guards/baseline/spacing_scale.json since going
//    straight to strict would fail on ~1,600 pre-existing sites.
// 2. Its regex used `[^()]*`, which stops at the first inner `)` -- so a
//    call like `EdgeInsets.only(top: Theme.of(context).padding.top + 16)`
//    was truncated before the real closing paren and silently skipped (the
//    bug mss-app-32 flagged: "the spacing guard misses EdgeInsets calls with
//    nested parentheses", citing scheme_bottom_action_bar.dart:33-36). Now
//    uses guards/guard_support.dart's balancedCalls(), a manual paren-depth
//    scan that handles arbitrary nesting.
//
// Escape hatch: put `// spacing-ok` on the same line as the value for a
// literal that is deliberately raw (e.g. a centering counterweight, or a
// real fixed measurement rather than a spacing step).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'guards/guard_support.dart';

// The values that must go through AppSpacing when used as a gap/pad.
const _scaleValues = <int>{0, 2, 4, 6, 8, 12, 16, 20, 24, 32};

final _edgeCallStart = RegExp(r'EdgeInsets\.(?:all|symmetric|only|fromLTRB)\(');
final _sizedBoxStart = RegExp(r'SizedBox\(');
final _numToken = RegExp(r'(?<![\w.])(\d+)(?:\.0)?(?![\w.\d])');

/// SizedBox(...) only counts as a spacing call if it sets width/height --
/// the balancedCalls() match already has the full args text to check.
bool _isSizedBoxWithDimension(String call) =>
    RegExp(r'\b(?:width|height):').hasMatch(call);

void main() {
  test('lib/ uses AppSpacing for padding/margin/gap literals (ratcheted)', () {
    final actual = <String, int>{};

    for (final file in dartFilesUnder('lib')) {
      final path = relPath(file);
      if (path == 'lib/utils/app_spacing.dart') continue;

      final src = file.readAsStringSync();
      final lines = src.split('\n');
      var count = 0;

      final calls = [
        ...balancedCallsWithOffsets(src, _edgeCallStart),
        ...balancedCallsWithOffsets(
          src,
          _sizedBoxStart,
        ).where((c) => _isSizedBoxWithDimension(c.text)),
      ];

      for (final call in calls) {
        final hasNumericLiteral = _numToken.hasMatch(call.text);
        if (!hasNumericLiteral) continue;

        // D5 (2.7 design review): use the call's own start offset instead
        // of re-finding it with src.indexOf(call.text), which silently
        // picks the FIRST identical-looking call in the file when two
        // sites share the same text (e.g. two `SizedBox(height: 16)`).
        final startLine = lineOf(src, call.start);
        final endLine = startLine + call.text.split('\n').length - 1;
        final hasMarker = [
          for (var l = startLine; l <= endLine && l < lines.length; l++)
            lines[l],
        ].any((l) => l.contains('// spacing-ok'));
        if (hasMarker) continue;

        count++;
      }

      if (count > 0) actual[path] = count;
    }

    expectNoRatchetRegression(
      rule: 'spacing_scale',
      actual: actual,
      violationDescription:
          'Raw numeric padding/margin/gap literals (on- or off-scale)',
    );
  });

  // Kept from before Phase 2: still flags the narrower on-scale case with a
  // precise file:line list, for anyone fixing violations incrementally.
  test('on-scale literals are called out by file:line for quick fixing', () {
    final offenders = <String>[];

    for (final file in dartFilesUnder('lib')) {
      final path = relPath(file);
      if (path == 'lib/utils/app_spacing.dart') continue;

      final src = file.readAsStringSync();
      final lines = src.split('\n');

      final calls = [
        ...balancedCallsWithOffsets(src, _edgeCallStart),
        ...balancedCallsWithOffsets(
          src,
          _sizedBoxStart,
        ).where((c) => _isSizedBoxWithDimension(c.text)),
      ];

      for (final call in calls) {
        final onScale = _numToken
            .allMatches(call.text)
            .map((m) => int.parse(m.group(1)!))
            .where(_scaleValues.contains);
        if (onScale.isEmpty) continue;

        final startLine = lineOf(src, call.start);
        final endLine = startLine + call.text.split('\n').length - 1;
        final hasMarker = [
          for (var l = startLine; l <= endLine && l < lines.length; l++)
            lines[l],
        ].any((l) => l.contains('// spacing-ok'));
        if (hasMarker) continue;

        offenders.add('$path:${startLine + 1}: ${lines[startLine].trim()}');
      }
    }

    // Informational list only -- the ratchet test above is what actually
    // gates a regression. This one documents today's on-scale offenders
    // without needing a second baseline file.
    // ignore: avoid_print
    if (offenders.isNotEmpty) print(offenders.join('\n'));
  });

  test('AppSpacing scale is the documented set of steps', () {
    // Guards against silently widening the scale.
    final expected = <double>{0, 2, 4, 6, 8, 12, 16, 20, 24, 32};
    final src = File('lib/utils/app_spacing.dart').readAsStringSync();
    final declared = RegExp(
      r'static const double \w+ = (\d+);',
    ).allMatches(src).map((m) => double.parse(m.group(1)!)).toSet();
    expect(declared, expected);
  });
}
