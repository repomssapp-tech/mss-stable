"""Summarise search evaluation results.

Usage: python tools/search_eval_report.py results.json [--lang en] [--fails N]

Input is the JSON written by frontend/test/tool/search_eval_runner_test.dart
(or the emulator run): one row per query with the rank of the expected scheme.

Per (language, level, typo): hit@1, hit@5, hit@10, MRR and the share of
queries that returned nothing. For misspelt queries also: how often a
"Did you mean" appears, how often it restores the original text exactly, and
hit@5 if the user taps it ("best" = the better of typed vs. tapped).
Overall: mean hit@5 over all cells, and a difficulty-weighted mean (levels 1:2:3).
"""

import json
import sys
from collections import defaultdict

sys.stdout.reconfigure(encoding="utf-8")
path = sys.argv[1]
only = sys.argv[sys.argv.index("--lang") + 1] if "--lang" in sys.argv else None
fails = int(sys.argv[sys.argv.index("--fails") + 1]) if "--fails" in sys.argv else 0
rows = [r for r in json.load(open(path, encoding="utf-8")) if only in (None, r["lang"])]
langs = [only] if only else ["en", "hi", "ta"]

cells = defaultdict(list)
for r in rows:
    cells[(r["lang"], r["level"], r["typo"])].append(r)


def hit(rank, k):
    return rank is not None and rank <= k


def best_rank(r):
    """Rank the user can reach: the typed query, or after tapping a suggestion."""
    cands = [x for x in (r["rank"], r.get("rankAfterSuggestion")) if x is not None]
    return min(cands) if cands else None


def pct(v):
    return "" if v != v else f"{v:.0%}"


print(f"{'lang':4} {'lvl':3} {'typo':5} {'n':>3} {'h@1':>5} {'h@5':>5} {'h@10':>5} {'MRR':>5} {'empty':>5}"
      f" | {'sugg':>5} {'recov':>5} {'best@5':>6}")
for key in sorted(cells):
    rs = cells[key]
    n = len(rs)
    h1 = sum(hit(r["rank"], 1) for r in rs) / n
    h5 = sum(hit(r["rank"], 5) for r in rs) / n
    h10 = sum(hit(r["rank"], 10) for r in rs) / n
    mrr = sum((1 / r["rank"]) if r["rank"] else 0 for r in rs) / n
    empty = sum(r["returned"] == 0 for r in rs) / n
    sugg = recov = best5 = float("nan")
    if key[2]:
        sugg = sum(r["suggestion"] is not None for r in rs) / n
        recov = sum(r["suggestionRecoversClean"] for r in rs) / n
        best5 = sum(hit(best_rank(r), 5) for r in rs) / n
    print(f"{key[0]:4} {key[1]:3} {str(key[2]):5} {n:3d} {h1:5.0%} {h5:5.0%} {h10:5.0%} {mrr:5.2f} {empty:5.0%}"
          f" | {pct(sugg):>5} {pct(recov):>5} {pct(best5):>6}")

print()
for lang in langs:
    for level in (1, 2, 3):
        a = [r for r in rows if r["lang"] == lang and r["level"] == level]
        if not a:
            continue
        h5 = sum(hit(r["rank"], 5) for r in a) / len(a)
        b5 = sum(hit(best_rank(r), 5) for r in a) / len(a)
        print(f"{lang} level {level}: hit@5 {h5:.0%}   with did-you-mean {b5:.0%}")
print()
for lang in langs + ([] if only else ["ALL"]):
    sel = [r for r in rows if lang == "ALL" or r["lang"] == lang]
    flat = sum(hit(r["rank"], 5) for r in sel) / len(sel)
    flat_b = sum(hit(best_rank(r), 5) for r in sel) / len(sel)
    w = {1: 1.0, 2: 2.0, 3: 3.0}
    num = sum(w[r["level"]] * hit(r["rank"], 5) for r in sel)
    num_b = sum(w[r["level"]] * hit(best_rank(r), 5) for r in sel)
    den = sum(w[r["level"]] for r in sel)
    print(f"{lang:3}: hit@5 equal-weight {flat:.1%} (with DYM {flat_b:.1%});"
          f" difficulty-weighted {num / den:.1%} (with DYM {num_b / den:.1%})")

if fails:
    print("\nSample misses (typed query, expected scheme not returned):")
    shown = defaultdict(int)
    for r in rows:
        if r["rank"] is None and shown[(r["lang"], r["level"])] < fails:
            shown[(r["lang"], r["level"])] += 1
            print(f"  [{r['lang']} L{r['level']} typo={r['typo']}] {r['query']!r} -> {r['expected']}"
                  f" | suggestion={r['suggestion']!r}")
