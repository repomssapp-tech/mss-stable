/// Finds which of a fixed set of keywords occur in a text, in one pass over
/// the text (Aho-Corasick automaton over UTF-16 code units).
///
/// `matcher.matchesIn(text).contains(i)` is exactly `text.contains(keywords[i])`
/// for every keyword (overlapping and nested keywords included), but costs one
/// scan of the text instead of one scan per keyword.
class MultiKeywordMatcher {
  MultiKeywordMatcher(List<String> keywords) {
    _addNode();
    for (var k = 0; k < keywords.length; k++) {
      final word = keywords[k];
      if (word.isEmpty) {
        // ''.contains is true for every text.
        _always.add(k);
        continue;
      }
      var node = 0;
      for (var i = 0; i < word.length; i++) {
        node = _next[node][word.codeUnitAt(i)] ??= _addNode();
      }
      _out[node].add(k);
    }
    // Breadth-first, so a node's failure link (always shallower) is complete
    // before the node's own outputs are merged from it.
    final queue = <int>[..._next[0].values];
    for (var q = 0; q < queue.length; q++) {
      final parent = queue[q];
      _next[parent].forEach((unit, child) {
        queue.add(child);
        var f = _fail[parent];
        while (f != 0 && !_next[f].containsKey(unit)) {
          f = _fail[f];
        }
        final link = _next[f][unit] ?? 0;
        _fail[child] = link;
        _out[child].addAll(_out[link]);
      });
    }
  }

  final List<Map<int, int>> _next = [];
  final List<int> _fail = [];
  final List<List<int>> _out = [];
  final List<int> _always = [];

  int _addNode() {
    _next.add(<int, int>{});
    _fail.add(0);
    _out.add(<int>[]);
    return _next.length - 1;
  }

  /// Indices (into the constructor's list) of every keyword found in [text].
  Set<int> matchesIn(String text) {
    final found = <int>{..._always};
    var node = 0;
    for (var i = 0; i < text.length; i++) {
      final unit = text.codeUnitAt(i);
      while (node != 0 && !_next[node].containsKey(unit)) {
        node = _fail[node];
      }
      node = _next[node][unit] ?? 0;
      final out = _out[node];
      if (out.isNotEmpty) found.addAll(out);
    }
    return found;
  }
}
