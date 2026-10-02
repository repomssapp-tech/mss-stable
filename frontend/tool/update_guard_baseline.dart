// Rewrites test/guards/baseline/<rule>.json to the CURRENT violation counts
// for every ratcheted guard (spec_design_system.md §8). Run after
// deliberately fixing (lowering) violations in a file, or when adding a
// guard for the first time. Never increases a count by itself -- it always
// reflects what's in lib/ right now, and the guard tests are what stop a
// future PR from raising it back up.
//
// Usage: dart run tool/update_guard_baseline.dart

import 'dart:convert';
import 'dart:io';

Iterable<File> _dartFilesUnder(String dirPath) sync* {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return;
  for (final e in dir.listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart')) yield e;
  }
}

String _relPath(File file) => file.path.replaceAll('\\', '/');

int _lineOf(String src, int charOffset) =>
    src.substring(0, charOffset).split('\n').length - 1;

List<({int start, String text})> _balancedCalls(String src, RegExp callStart) {
  final out = <({int start, String text})>[];
  for (final m in callStart.allMatches(src)) {
    var depth = 1;
    var i = m.end;
    while (i < src.length && depth > 0) {
      if (src[i] == '(') depth++;
      if (src[i] == ')') depth--;
      i++;
    }
    out.add((start: m.start, text: src.substring(m.start, i)));
  }
  return out;
}

void _writeBaseline(String rule, Map<String, int> counts) {
  final file = File('test/guards/baseline/$rule.json');
  final sorted = Map.fromEntries(
    counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(sorted)}\n');
  final total = counts.values.fold(0, (a, b) => a + b);
  // ignore: avoid_print
  print('$rule: ${counts.length} files, $total total violations');
}

// ── type_scale ──────────────────────────────────────────────────────────
final _fontSizePattern = RegExp(r'fontSize:\s*\d');
final _googleFontsPattern = RegExp(r'GoogleFonts\.');
final _langSizePattern = RegExp(r'isTa(?:mil)?\s*\?\s*[\d.]+\s*:\s*[\d.]+');
final _textScalePattern = RegExp(r'textScaleFactor|TextScaler\.linear');
const _typeScaleAllowedFiles = {
  'lib/utils/app_text.dart',
  'lib/utils/app_theme.dart',
};

void _updateTypeScale() {
  final counts = <String, int>{};
  for (final file in _dartFilesUnder('lib')) {
    final path = _relPath(file);
    if (_typeScaleAllowedFiles.contains(path) ||
        path.contains('/painters/') ||
        path.contains('_painter.dart')) {
      continue;
    }
    final src = file.readAsStringSync();
    var count = 0;
    for (final line in src.split('\n')) {
      if (line.contains('// type-ok')) continue;
      count += _fontSizePattern.allMatches(line).length;
      count += _googleFontsPattern.allMatches(line).length;
      count += _langSizePattern.allMatches(line).length;
      if (!path.endsWith('lib/main.dart')) {
        count += _textScalePattern.allMatches(line).length;
      }
    }
    if (count > 0) counts[path] = count;
  }
  _writeBaseline('type_scale', counts);
}

// ── color_tokens ────────────────────────────────────────────────────────
final _hexColorPattern = RegExp(r'Color\(0x[0-9A-Fa-f]{6,8}\)');
final _namedColorPattern = RegExp(r'Colors\.(grey|red|green|orange|blue|black|white)\b');
const _colorAllowedSubstrings = [
  'state_map_painter.dart',
  'voice_edge_painter.dart',
  'login_screen.dart',
  'regular_voice_backdrop.dart',
  'companion_voice_header.dart',
  'saarthi_character_header.dart',
  'splash_screen.dart',
  'anti_gravity_hero_section.dart',
  'categories_data.dart',
];

void _updateColorTokens() {
  final counts = <String, int>{};
  for (final file in _dartFilesUnder('lib')) {
    final path = _relPath(file);
    if (path == 'lib/utils/app_colors.dart') continue;
    if (_colorAllowedSubstrings.any((s) => path.contains(s))) continue;
    final src = file.readAsStringSync();
    var count = 0;
    for (final line in src.split('\n')) {
      if (line.contains('// color-ok')) continue;
      count += _hexColorPattern.allMatches(line).length;
      count += _namedColorPattern.allMatches(line).length;
    }
    if (count > 0) counts[path] = count;
  }
  _writeBaseline('color_tokens', counts);
}

// ── radius_tokens ───────────────────────────────────────────────────────
final _radiusPattern = RegExp(r'(?:BorderRadius|Radius)\.circular\(\s*\d');

void _updateRadiusTokens() {
  final counts = <String, int>{};
  for (final file in _dartFilesUnder('lib')) {
    final path = _relPath(file);
    if (path == 'lib/utils/app_radius.dart') continue;
    if (path.contains('/painters/') || path.contains('_painter.dart')) continue;
    final src = file.readAsStringSync();
    var count = 0;
    for (final line in src.split('\n')) {
      if (line.contains('// radius-ok')) continue;
      count += _radiusPattern.allMatches(line).length;
    }
    if (count > 0) counts[path] = count;
  }
  _writeBaseline('radius_tokens', counts);
}

// ── tap_target ──────────────────────────────────────────────────────────
final _gestureDetectorStart = RegExp(r'GestureDetector\(');
final _gestureHandlerPattern = RegExp(r'onTap:|onTapDown:|onLongPress:');
final _iconButtonStart = RegExp(r'IconButton\(');
const _tapAllowedFiles = {
  'lib/widgets/common/app_icon_button.dart',
  'lib/widgets/common/app_tappable.dart',
};

bool _collapsesHitArea(String call) =>
    (call.contains('BoxConstraints()') || call.contains('padding: EdgeInsets.zero')) &&
    !call.contains('AppSize.tapTarget');

void _updateTapTarget() {
  final counts = <String, int>{};
  for (final file in _dartFilesUnder('lib')) {
    final path = _relPath(file);
    if (_tapAllowedFiles.contains(path)) continue;
    if (!path.startsWith('lib/screens/') && !path.startsWith('lib/widgets/')) continue;
    final src = file.readAsStringSync();
    final lines = src.split('\n');
    var count = 0;

    // D5 (2.7 design review): was line-by-line, so the repo's usual
    // GestureDetector(\n  onTap: ...) formatting was invisible to it.
    for (final call in _balancedCalls(src, _gestureDetectorStart)) {
      if (!_gestureHandlerPattern.hasMatch(call.text)) continue;
      final startLine = _lineOf(src, call.start);
      if (lines[startLine].contains('// tap-ok')) continue;
      count++;
    }

    for (final call in _balancedCalls(src, _iconButtonStart)) {
      final startLine = _lineOf(src, call.start);
      if (lines[startLine].contains('// tap-ok')) continue;
      if (_collapsesHitArea(call.text)) count++;
    }
    if (count > 0) counts[path] = count;
  }
  _writeBaseline('tap_target', counts);
}

// ── i18n_literals ───────────────────────────────────────────────────────
final _tamilScriptPattern = RegExp(r'[஀-௿]');
final _textLiteralPattern = RegExp(r'''Text\(\s*['"][A-Z]''');
final _toastLiteralPattern = RegExp(r'''AppToast\.show\w+\(\s*context,\s*['"]''');

void _updateI18nLiterals() {
  final counts = <String, int>{};
  for (final file in _dartFilesUnder('lib')) {
    final path = _relPath(file);
    if (!path.startsWith('lib/screens/') && !path.startsWith('lib/widgets/')) continue;
    final src = file.readAsStringSync();
    var count = 0;
    for (final line in src.split('\n')) {
      if (line.contains('// i18n-ok')) continue;
      count += _tamilScriptPattern.allMatches(line).length;
      count += _textLiteralPattern.allMatches(line).length;
      count += _toastLiteralPattern.allMatches(line).length;
    }
    if (count > 0) counts[path] = count;
  }
  _writeBaseline('i18n_literals', counts);
}

// ── spacing_scale ───────────────────────────────────────────────────────
final _edgeCallStart = RegExp(r'EdgeInsets\.(?:all|symmetric|only|fromLTRB)\(');
final _sizedBoxStart = RegExp(r'SizedBox\(');
final _spacingNumToken = RegExp(r'(?<![\w.])(\d+)(?:\.0)?(?![\w.\d])');

bool _isSizedBoxWithDimension(String call) =>
    RegExp(r'\b(?:width|height):').hasMatch(call);

void _updateSpacingScale() {
  final counts = <String, int>{};
  for (final file in _dartFilesUnder('lib')) {
    final path = _relPath(file);
    if (path == 'lib/utils/app_spacing.dart') continue;
    final src = file.readAsStringSync();
    final lines = src.split('\n');
    var count = 0;

    final calls = [
      ..._balancedCalls(src, _edgeCallStart),
      ..._balancedCalls(
        src,
        _sizedBoxStart,
      ).where((c) => _isSizedBoxWithDimension(c.text)),
    ];

    for (final call in calls) {
      if (!_spacingNumToken.hasMatch(call.text)) continue;
      final startLine = _lineOf(src, call.start);
      final endLine = startLine + call.text.split('\n').length - 1;
      final hasMarker = [
        for (var l = startLine; l <= endLine && l < lines.length; l++) lines[l],
      ].any((l) => l.contains('// spacing-ok'));
      if (hasMarker) continue;
      count++;
    }

    if (count > 0) counts[path] = count;
  }
  _writeBaseline('spacing_scale', counts);
}

// ── button_style ───────────────────────────────────────────────────────
final _styleFromStart = RegExp(r'(?:Elevated|Outlined|Text|Filled)Button\.styleFrom\(');
final _overriddenProp = RegExp(r'backgroundColor:|shape:|minimumSize:|padding:');
const _buttonStyleAllowedFiles = {
  'lib/utils/app_theme.dart',
};

void _updateButtonStyle() {
  final counts = <String, int>{};
  for (final file in _dartFilesUnder('lib')) {
    final path = _relPath(file);
    if (_buttonStyleAllowedFiles.contains(path)) continue;
    final src = file.readAsStringSync();
    final lines = src.split('\n');
    var count = 0;
    for (final call in _balancedCalls(src, _styleFromStart)) {
      if (!_overriddenProp.hasMatch(call.text)) continue;
      final startLine = _lineOf(src, call.start);
      if (lines[startLine].contains('// style-ok')) continue;
      count++;
    }
    if (count > 0) counts[path] = count;
  }
  _writeBaseline('button_style', counts);
}

// ── fixed_height_text ──────────────────────────────────────────────────
final _boxStart = RegExp(r'(?:SizedBox|Container)\(');
final _heightArg = RegExp(r'\bheight:\s*\d');
final _textCall = RegExp(r'Text\(');

void _updateFixedHeightText() {
  final counts = <String, int>{};
  for (final file in _dartFilesUnder('lib')) {
    final path = _relPath(file);
    final src = file.readAsStringSync();
    final lines = src.split('\n');
    var count = 0;
    for (final call in _balancedCalls(src, _boxStart)) {
      if (!_heightArg.hasMatch(call.text)) continue;
      final startLine = _lineOf(src, call.start);
      if (lines[startLine].contains('// height-ok')) continue;
      final within6 = [
        for (var l = startLine; l <= startLine + 6 && l < lines.length; l++) lines[l],
      ].join('\n');
      if (!_textCall.hasMatch(within6)) continue;
      count++;
    }
    if (count > 0) counts[path] = count;
  }
  _writeBaseline('fixed_height_text', counts);
}

// ── fit_one_line ───────────────────────────────────────────────────────
final _fitStart = RegExp(r'(?:FitOneLine|FittedBox)\(');

void _updateFitOneLine() {
  final counts = <String, int>{};
  for (final file in _dartFilesUnder('lib')) {
    final path = _relPath(file);
    final src = file.readAsStringSync();
    final lines = src.split('\n');
    var count = 0;
    for (final call in _balancedCalls(src, _fitStart)) {
      if (!_textCall.hasMatch(call.text)) continue;
      final startLine = _lineOf(src, call.start);
      if (lines[startLine].contains('// type-ok: numeric')) continue;
      count++;
    }
    if (count > 0) counts[path] = count;
  }
  _writeBaseline('fit_one_line', counts);
}

void main() {
  _updateTypeScale();
  _updateColorTokens();
  _updateRadiusTokens();
  _updateTapTarget();
  _updateI18nLiterals();
  _updateSpacingScale();
  _updateButtonStyle();
  _updateFixedHeightText();
  _updateFitOneLine();
  // ignore: avoid_print
  print('Done. contrast_test.dart, type_scale_floor_test.dart and '
      'semantics_test.dart have no baseline -- they are strict, not '
      'ratcheted.');
}
