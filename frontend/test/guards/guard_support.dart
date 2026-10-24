// Shared infrastructure for test/guards/*_test.dart (spec_design_system.md
// §8). Each guard scans lib/**/*.dart for a forbidden pattern and checks the
// per-file violation count against a ratchet baseline in
// test/guards/baseline/<rule>.json: a file's count may only go down (or stay
// the same), never up, and a file absent from the baseline must have zero
// violations. This lets ~1,600 pre-existing violations be fixed
// incrementally without blocking on a single all-or-nothing pass.
//
// `dart run tool/update_guard_baseline.dart` rewrites a baseline to the
// current counts. When a rule's baseline is all zeros, delete the baseline
// file and the rule becomes strict (zero violations anywhere, forever).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> dartFilesUnder(String dirPath) sync* {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return;
  for (final e in dir.listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart')) yield e;
  }
}

/// Normalizes a File path to the forward-slash, repo-relative form used as
/// baseline JSON keys (so baselines are portable across Windows/POSIX).
String relPath(File file) => file.path.replaceAll('\\', '/');

/// Scans `src` for occurrences of `callStart` (which must end just after the
/// call's opening `(`, e.g. `RegExp(r'EdgeInsets\.only\(')`) and returns the
/// full call text (including arbitrarily nested parens) for each one. This
/// is what `[^()]*`-style regexes in the older spacing guard get wrong --
/// they stop at the first inner `)`, truncating calls like
/// `EdgeInsets.only(top: Theme.of(context).padding.top + 16)`.
List<String> balancedCalls(String src, RegExp callStart) =>
    balancedCallsWithOffsets(src, callStart).map((c) => c.text).toList();

/// Same scan as [balancedCalls], but also returns each call's start offset
/// in `src`. Needed to find each call's *own* line correctly: a consumer
/// that instead re-finds a call's position with `src.indexOf(call.text)`
/// silently picks the position of the FIRST identical-looking call in the
/// file (e.g. two `IconButton(icon: Icons.close)` sites with the same
/// text), checking the wrong line's `// xxx-ok` escape and attributing the
/// violation to the wrong line number (found during the 2.7 design
/// review, D5).
List<({int start, String text})> balancedCallsWithOffsets(
  String src,
  RegExp callStart,
) {
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

/// 0-based line number of byte offset `charOffset` within `src`.
int lineOf(String src, int charOffset) =>
    src.substring(0, charOffset).split('\n').length - 1;

/// Loads `test/guards/baseline/<rule>.json`, or an empty map if the rule has
/// gone strict (baseline deleted).
Map<String, int> loadBaseline(String rule) {
  final file = File('test/guards/baseline/$rule.json');
  if (!file.existsSync()) return const {};
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return decoded.map((k, v) => MapEntry(k, v as int));
}

/// Asserts the ratchet: every file's current violation count must be <= its
/// baseline count (0 if absent from the baseline). Fails with a clear,
/// per-file diff otherwise so a regression is easy to locate.
void expectNoRatchetRegression({
  required String rule,
  required Map<String, int> actual,
  required String violationDescription,
}) {
  final baseline = loadBaseline(rule);
  final regressions = <String>[];

  for (final entry in actual.entries) {
    final allowed = baseline[entry.key] ?? 0;
    if (entry.value > allowed) {
      regressions.add(
        '${entry.key}: ${entry.value} now vs $allowed allowed by baseline',
      );
    }
  }

  expect(
    regressions,
    isEmpty,
    reason:
        '$violationDescription increased in these files (lower it, or if '
        'the baseline is stale run `dart run tool/update_guard_baseline.dart`):\n'
        '${regressions.join('\n')}',
  );
}

/// The v2 illustrated design screens (onboarding, the new Saarthi UI) are
/// hand-laid-out on the designer's 360pt canvas and scaled by screen width,
/// like the splash and the painters: their positions, sizes, radii and
/// brand colours are the artwork, not spacing/colour tokens. The layout,
/// colour, radius, type-scale, tap-target and fixed-height guards skip them;
/// the i18n guard does not.
bool isDesignCanvas(String path) => path.startsWith('lib/design_v2/');
