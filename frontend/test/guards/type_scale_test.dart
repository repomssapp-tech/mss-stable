// spec_design_system.md §8, type_scale_test.dart. Forbids numeric fontSize
// literals, GoogleFonts.* calls, language-dependent sizes, and raw
// textScaleFactor/TextScaler.linear outside main.dart -- all superseded by
// AppTextStyles (app_text.dart) and the single clamp in main.dart's
// MaterialApp.builder. Ratcheted: ~650+ fontSize literals and ~108
// GoogleFonts.* call sites pre-exist; this only blocks new ones.

import 'package:flutter_test/flutter_test.dart';

import 'guard_support.dart';

const _allowedFiles = <String>{
  'lib/utils/app_text.dart',
  'lib/utils/app_theme.dart',
};

bool _isAllowed(String path) =>
    _allowedFiles.contains(path) ||
    path.contains('/painters/') ||
    path.contains('_painter.dart');

final _fontSizePattern = RegExp(r'fontSize:\s*\d');
final _googleFontsPattern = RegExp(r'GoogleFonts\.');
final _langSizePattern = RegExp(r'isTa(?:mil)?\s*\?\s*[\d.]+\s*:\s*[\d.]+');
final _textScalePattern = RegExp(r'textScaleFactor|TextScaler\.linear');

int _countViolations(String path, String src) {
  var count = 0;
  count += _fontSizePattern.allMatches(src).length;
  count += _googleFontsPattern.allMatches(src).length;
  count += _langSizePattern.allMatches(src).length;
  if (!path.endsWith('lib/main.dart')) {
    count += _textScalePattern.allMatches(src).length;
  }
  return count;
}

void main() {
  test('lib/ uses AppTextStyles instead of raw fontSize/GoogleFonts calls', () {
    final actual = <String, int>{};
    for (final file in dartFilesUnder('lib')) {
      final path = relPath(file);
      if (_isAllowed(path)) continue;
      final src = file.readAsStringSync();
      final lines = src.split('\n');
      var count = 0;
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('// type-ok')) continue;
        count += _countViolations(path, lines[i]);
      }
      if (count > 0) actual[path] = count;
    }

    expectNoRatchetRegression(
      rule: 'type_scale',
      actual: actual,
      violationDescription: 'Raw fontSize/GoogleFonts/language-size literals',
    );
  });
}
