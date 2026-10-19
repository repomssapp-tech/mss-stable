// spec_design_system.md §8, i18n_literals_test.dart. Forbids hardcoded
// Tamil script, capitalized English string literals passed directly to
// Text(), and AppToast.show*(context, '...') calls with a literal string --
// all bypass the ARB/l10n pipeline. Escape with `// i18n-ok` for the
// language-name pickers ('தமிழ்'/'English' labels), which are correctly
// fixed-script regardless of the active locale.

import 'package:flutter_test/flutter_test.dart';

import 'guard_support.dart';

final _tamilScriptPattern = RegExp(r'[஀-௿]');
final _textLiteralPattern = RegExp(r'''Text\(\s*['"][A-Z]''');
final _toastLiteralPattern = RegExp(
  r'''AppToast\.show\w+\(\s*context,\s*['"]''',
);

void main() {
  test(
    'lib/screens and lib/widgets route user-visible strings through ARB/l10n',
    () {
      final actual = <String, int>{};
      for (final file in dartFilesUnder('lib')) {
        final path = relPath(file);
        if (!path.startsWith('lib/screens/') &&
            !path.startsWith('lib/widgets/')) {
          continue;
        }
        final src = file.readAsStringSync();
        var count = 0;
        for (final line in src.split('\n')) {
          if (line.contains('// i18n-ok')) continue;
          count += _tamilScriptPattern.allMatches(line).length;
          count += _textLiteralPattern.allMatches(line).length;
          count += _toastLiteralPattern.allMatches(line).length;
        }
        if (count > 0) actual[path] = count;
      }

      expectNoRatchetRegression(
        rule: 'i18n_literals',
        actual: actual,
        violationDescription:
            'Hardcoded Tamil/English string literals bypassing ARB',
      );
    },
  );
}
