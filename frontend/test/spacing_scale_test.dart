// Phase 6 enforcement: the Discover and Profile flows must express every
// padding / margin / gap through `AppSpacing` (lib/utils/app_spacing.dart)
// rather than a bare numeric literal. This keeps the spacing scale from
// drifting back out of sync one screen at a time.
//
// Scope is intentionally limited to the migrated flows. To roll the rule out
// further, add files to `_enforcedFiles`.
//
// Escape hatch: put `// spacing-ok` on the line for a value that is a genuine
// layout measurement rather than a spacing step (e.g. a centering
// counterweight).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _enforcedFiles = <String>[
  'lib/screens/regular_mode/categories_screen.dart',
  'lib/screens/regular_mode/search_results_screen.dart',
  'lib/screens/regular_mode/basic_profile_screen.dart',
  'lib/screens/regular_mode/location_profile_screen.dart',
  'lib/screens/regular_mode/about_you_profile_screen.dart',
  'lib/screens/regular_mode/eligibility_profile_screen.dart',
  'lib/screens/regular_mode/eligibility_results_screen.dart',
];

// EdgeInsets.all/symmetric/only/fromLTRB( ... <digit> ... )  or
// SizedBox( width|height: <digit> ... )
final _bareSpacing = RegExp(
  r'EdgeInsets\.(?:all|symmetric|only|fromLTRB)\([^)]*\d[^)]*\)'
  r'|SizedBox\(\s*(?:width|height):\s*\d',
);

void main() {
  test('Discover + Profile flows use AppSpacing, not bare spacing literals', () {
    final offenders = <String>[];

    for (final rel in _enforcedFiles) {
      final file = File(rel);
      expect(file.existsSync(), isTrue, reason: 'missing $rel');

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('// spacing-ok')) continue;
        if (_bareSpacing.hasMatch(line)) {
          offenders.add('$rel:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use AppSpacing.* for padding/margin/gaps in these flows '
          '(or add `// spacing-ok` if the value is a real layout measurement):'
          '\n${offenders.join('\n')}',
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
