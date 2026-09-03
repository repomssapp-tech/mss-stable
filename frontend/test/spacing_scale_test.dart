// Phase 6 enforcement: padding / margin / gap values across lib/ must be
// expressed through `AppSpacing` (lib/utils/app_spacing.dart), not a bare
// numeric literal. This keeps the spacing scale from drifting back out of
// sync one screen at a time.
//
// Only values that ARE on the scale are enforced: an `EdgeInsets.all(16)` is
// a violation (should be `AppSpacing.lg`), but a `SizedBox(height: 48)` for a
// fixed control size is a real measurement, not a spacing step, and is left
// alone.
//
// Escape hatch: put `// spacing-ok` on the same line as the value for an
// on-scale literal that is deliberately raw (e.g. a centering counterweight).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The values that must go through AppSpacing when used as a gap/pad.
const _scaleValues = <int>{0, 2, 4, 6, 8, 12, 16, 20, 24, 32};

// A spacing call site. `[^()]*` also spans newlines, so multi-line
// EdgeInsets/SizedBox calls are covered too.
final _edgeCall =
    RegExp(r'EdgeInsets\.(?:all|symmetric|only|fromLTRB)\(([^()]*)\)');
final _sizedBoxCall = RegExp(r'SizedBox\(([^()]*?(?:width|height):[^()]*?)\)');
final _numToken = RegExp(r'(?<![\w.])(\d+)(?:\.0)?(?![\w.\d])');

Iterable<File> _dartFiles(Directory dir) sync* {
  for (final e in dir.listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart')) yield e;
  }
}

void main() {
  test('lib/ uses AppSpacing for on-scale padding/margin/gap literals', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue);

    final offenders = <String>[];

    for (final file in _dartFiles(libDir)) {
      final path = file.path.replaceAll('\\', '/');
      if (path.endsWith('lib/utils/app_spacing.dart')) continue;

      final src = file.readAsStringSync();
      // Precompute line-start offsets for offset -> line number.
      final lineStarts = <int>[0];
      for (var i = 0; i < src.length; i++) {
        if (src[i] == '\n') lineStarts.add(i + 1);
      }
      int lineOf(int offset) {
        var lo = 0, hi = lineStarts.length - 1;
        while (lo < hi) {
          final mid = (lo + hi + 1) >> 1;
          if (lineStarts[mid] <= offset) {
            lo = mid;
          } else {
            hi = mid - 1;
          }
        }
        return lo; // 0-based
      }

      for (final call in [
        ..._edgeCall.allMatches(src),
        ..._sizedBoxCall.allMatches(src),
      ]) {
        final args = call.group(1)!;
        final onScale = _numToken
            .allMatches(args)
            .map((m) => int.parse(m.group(1)!))
            .where(_scaleValues.contains);
        if (onScale.isEmpty) continue;

        final startLine = lineOf(call.start);
        final endLine = lineOf(call.end);
        final srcLines = src.split('\n');
        final hasMarker = [
          for (var l = startLine; l <= endLine && l < srcLines.length; l++)
            srcLines[l],
        ].any((l) => l.contains('// spacing-ok'));
        if (hasMarker) continue;

        offenders.add(
          '$path:${startLine + 1}: '
          '${srcLines[startLine].trim()}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use AppSpacing.* for these on-scale padding/margin/gap values '
          '(or add `// spacing-ok` if the raw literal is deliberate):\n'
          '${offenders.join('\n')}',
    );
  });

  test('AppSpacing scale is the documented set of steps', () {
    // Guards against silently widening the scale.
    final expected = <double>{0, 2, 4, 6, 8, 12, 16, 20, 24, 32};
    final src = File('lib/utils/app_spacing.dart').readAsStringSync();
    final declared = RegExp(r'static const double \w+ = (\d+);')
        .allMatches(src)
        .map((m) => double.parse(m.group(1)!))
        .toSet();
    expect(declared, expected);
  });
}
