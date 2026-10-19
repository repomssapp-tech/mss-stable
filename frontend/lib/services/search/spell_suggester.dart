/// "Did you mean" for search queries: proposes the catalog's own words in
/// place of unknown ones ("laon" -> "loan", "கடண்" -> "கடன்").
///
/// Deterministic and offline -- plain edit distance against a dictionary of
/// real catalog terms, no model. It works on Unicode code points, so Hindi
/// (Devanagari) and Tamil words are corrected the same way as English ones.
class SpellSuggester {
  SpellSuggester(Map<String, int> dictionary, {RegExp? tokenPattern})
    : _tokenPattern =
          tokenPattern ??
          RegExp(r'[A-Za-z][A-Za-z0-9&-]{1,}|[஀-௿]{2,}|[ऀ-ॿ]{2,}') {
    for (final entry in dictionary.entries) {
      final term = entry.key.toLowerCase();
      if (!_isCorrectable(term)) continue;
      final runes = term.runes.toList(growable: false);
      if (runes.length < _minLength) continue;
      _terms.putIfAbsent(term, () => _Term(term, runes, entry.value));
    }
  }

  /// Words shorter than this are never corrected: one edit changes too large
  /// a share of them, so suggestions would be guesses.
  static const int _minLength = 3;

  final RegExp _tokenPattern;
  final Map<String, _Term> _terms = {};

  // Ids and codes ("cen2026-001", "pmegp-2") are not words.
  static bool _isCorrectable(String s) => !RegExp(r'[0-9&-]').hasMatch(s);

  /// Whether [word] is a term the catalog already knows (plural / singular
  /// forms count), so it must be left alone.
  bool isKnown(String word) {
    final w = word.toLowerCase();
    if (_terms.containsKey(w)) return true;
    if (w.endsWith('s') && _terms.containsKey(w.substring(0, w.length - 1))) {
      return true;
    }
    return _terms.containsKey('${w}s');
  }

  /// [query] with each unknown word replaced by its closest catalog word, or
  /// null when nothing needed or could be corrected.
  String? suggest(String query) {
    final out = StringBuffer();
    var last = 0;
    var changed = false;
    for (final m in _tokenPattern.allMatches(query)) {
      final replacement = _correct(m.group(0)!.toLowerCase());
      if (replacement == null) continue;
      out.write(query.substring(last, m.start));
      out.write(replacement);
      last = m.end;
      changed = true;
    }
    if (!changed) return null;
    out.write(query.substring(last));
    final corrected = out.toString();
    return corrected == query ? null : corrected;
  }

  String? _correct(String token) {
    if (!_isCorrectable(token) || isKnown(token)) return null;
    final runes = token.runes.toList(growable: false);
    if (runes.length < _minLength) return null;

    // One edit for short words, two for longer ones (typos are mostly 1-2
    // keystrokes; allowing more starts proposing different words).
    final maxDistance = runes.length <= 5 ? 1 : 2;

    _Term? best;
    var bestDistance = maxDistance + 1;
    for (final term in _terms.values) {
      if ((term.runes.length - runes.length).abs() > maxDistance) continue;
      final d = _distance(runes, term.runes, maxDistance);
      if (d > maxDistance) continue;
      // A two-edit match must still start with the same letter: people
      // rarely mistype the first one, and it screens out unrelated words.
      if (d == 2 && runes.first != term.runes.first) continue;
      final better =
          best == null ||
          d < bestDistance ||
          (d == bestDistance &&
              (term.frequency > best.frequency ||
                  (term.frequency == best.frequency &&
                      term.text.compareTo(best.text) < 0)));
      if (better) {
        best = term;
        bestDistance = d;
      }
    }
    return best?.text;
  }

  /// Optimal-string-alignment distance (insert, delete, substitute, and swap
  /// of two adjacent characters each cost 1), abandoned early once it must
  /// exceed [limit].
  static int _distance(List<int> a, List<int> b, int limit) {
    final n = a.length;
    final m = b.length;
    if ((n - m).abs() > limit) return limit + 1;
    var prev2 = List<int>.filled(m + 1, 0);
    var prev = List<int>.generate(m + 1, (j) => j);
    for (var i = 1; i <= n; i++) {
      final cur = List<int>.filled(m + 1, 0)..[0] = i;
      var rowMin = cur[0];
      for (var j = 1; j <= m; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        var v = prev[j - 1] + cost;
        if (prev[j] + 1 < v) v = prev[j] + 1;
        if (cur[j - 1] + 1 < v) v = cur[j - 1] + 1;
        if (i > 1 &&
            j > 1 &&
            a[i - 1] == b[j - 2] &&
            a[i - 2] == b[j - 1] &&
            prev2[j - 2] + 1 < v) {
          v = prev2[j - 2] + 1;
        }
        cur[j] = v;
        if (v < rowMin) rowMin = v;
      }
      if (rowMin > limit) return limit + 1;
      prev2 = prev;
      prev = cur;
    }
    return prev[m];
  }
}

class _Term {
  const _Term(this.text, this.runes, this.frequency);

  final String text;
  final List<int> runes;
  final int frequency;
}
