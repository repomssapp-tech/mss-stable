"""Build the search evaluation query set (reproducible, seeded).

Level 1: the scheme's own name, taken from the catalog (100 schemes per
         language, none of them among the hand-written schemes).
Level 2: hand-written, plainly inferable by meaning (fixture indices 0-99).
Level 3: hand-written, indirect / situational (fixture indices 100-199).

Within each (language, level), exactly half of the 100 queries get typos
injected by a seeded script: swap, drop, double, or a neighbouring-key /
neighbouring-letter substitution, on one word (short queries) or two words.

Output: frontend/test/fixtures/search_eval/queries.json, a list of
  {lang, level, typo, query, expected (scheme id), clean (typo-free text)}
Run:  python tools/search_eval_build.py
"""

import glob
import gzip
import json
import random
import sys
import unicodedata
from collections import Counter
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
ROOT = Path(__file__).resolve().parent.parent
FIXTURES = ROOT / "frontend" / "test" / "fixtures" / "search_eval"
LANGS = ("en", "hi", "ta")
SEEDS = {"en": 11, "hi": 22, "ta": 33}

QWERTY = {
    "q": "wa", "w": "qes", "e": "wrd", "r": "etf", "t": "ryg", "y": "tuh", "u": "yij", "i": "uok",
    "o": "ipl", "p": "ol", "a": "qsz", "s": "awdx", "d": "serf", "f": "drtg", "g": "ftyh",
    "h": "gyuj", "j": "huik", "k": "jiol", "l": "kop", "z": "asx", "x": "zsdc", "c": "xdfv",
    "v": "cfgb", "b": "vghn", "n": "bhjm", "m": "njk",
}
DEVA_CONS = "कखगघचछजझटठडढतथदधनपफबभमयरलवशषसह"
DEVA_VOWEL_SIGNS = "ािीुूेैोौ"
TAMIL_CONS = "கஙசஞடணதநபமயரலவழளறன"
TAMIL_VOWEL_SIGNS = "ாிீுூெேைொோௌ"


def load_catalog():
    out = {}
    for f in sorted(glob.glob(str(ROOT / "frontend/assets/catalog/catalog_*.json.gz"))):
        d = json.load(gzip.open(f)).get("scheme_catalog.json")
        if not d:
            continue
        items = d if isinstance(d, list) else next(v for v in d.values() if isinstance(v, list))
        for s in items:
            loc = s.get("localization", {})
            out[s["identity"]["id"]] = {
                lang: ((loc.get(lang) or {}).get("name") or "").strip() for lang in LANGS
            }
    return out


def stratified(ids, k, rng):
    """k ids spread across catalog packs (CEN/TN/MAH) in proportion to their size."""
    by_pack = {}
    for i in sorted(ids):
        by_pack.setdefault(i.split("-")[0], []).append(i)
    picked = []
    for _, lst in sorted(by_pack.items()):
        rng.shuffle(lst)
        picked.extend(lst[: round(k * len(lst) / len(ids))])
    rng.shuffle(picked)
    while len(picked) < k:
        extra = [i for i in sorted(ids) if i not in picked]
        picked.append(rng.choice(extra))
    return picked[:k]


def typo_word(word, rng):
    chars = list(word)
    n = len(chars)
    if n < 4:
        return word
    kinds = ["swap", "drop", "double", "sub"]
    rng.shuffle(kinds)
    for kind in kinds:
        i = rng.randrange(1, n - 1)  # never the first or last letter
        if kind == "swap" and chars[i] != chars[i + 1]:
            chars[i], chars[i + 1] = chars[i + 1], chars[i]
        elif kind == "drop":
            del chars[i]
        elif kind == "double":
            chars.insert(i, chars[i])
        else:
            c = chars[i]
            if c.lower() in QWERTY:
                chars[i] = rng.choice(QWERTY[c.lower()])
            elif c in DEVA_CONS:
                chars[i] = rng.choice(DEVA_CONS.replace(c, ""))
            elif c in DEVA_VOWEL_SIGNS:
                chars[i] = rng.choice(DEVA_VOWEL_SIGNS.replace(c, ""))
            elif c in TAMIL_CONS:
                chars[i] = rng.choice(TAMIL_CONS.replace(c, ""))
            elif c in TAMIL_VOWEL_SIGNS:
                chars[i] = rng.choice(TAMIL_VOWEL_SIGNS.replace(c, ""))
            else:
                continue
        out = "".join(chars)
        if out != word:
            return out
        chars = list(word)
    return word


def inject_typos(query, rng):
    words = query.split()
    eligible = [i for i, w in enumerate(words) if len(w) >= 4]
    if not eligible:
        return query
    for i in rng.sample(eligible, min(1 if len(words) <= 3 else 2, len(eligible))):
        words[i] = typo_word(words[i], rng)
    return " ".join(words)


def main():
    catalog = load_catalog()
    fx = json.load(open(FIXTURES / "handwritten_queries.json", encoding="utf-8"))
    used = set(fx["schemes"])
    queries = []

    for lang_i, lang in enumerate(LANGS):
        # Level 1: scheme names (schemes not used by the hand-written levels)
        pool = [i for i, n in catalog.items() if n[lang] and i not in used]
        rng = random.Random(SEEDS[lang])
        ids = stratified(pool, 100, rng)
        typo_at = set(rng.sample(range(100), 50))
        for n, sid in enumerate(ids):
            clean = " ".join(unicodedata.normalize("NFC", catalog[sid][lang]).split()[:6])
            queries.append(
                {"lang": lang, "level": 1, "typo": n in typo_at,
                 "query": inject_typos(clean, rng) if n in typo_at else clean,
                 "expected": sid, "clean": clean}
            )
        # Levels 2 and 3: hand-written
        for level, indices in ((2, range(0, 100)), (3, range(100, 200))):
            rng = random.Random(SEEDS[lang] * 10 + level)
            typo_at = set(rng.sample(list(indices), 50))
            for i in indices:
                clean = unicodedata.normalize("NFC", fx["queries"][i][lang_i])
                queries.append(
                    {"lang": lang, "level": level, "typo": i in typo_at,
                     "query": inject_typos(clean, rng) if i in typo_at else clean,
                     "expected": fx["schemes"][i], "clean": clean}
                )

    out = FIXTURES / "queries.json"
    out.write_text(json.dumps(queries, ensure_ascii=False, indent=1), encoding="utf-8")
    print("wrote", out, "-", len(queries), "queries")
    print(Counter((q["lang"], q["level"], q["typo"]) for q in queries))
    for lang in LANGS:
        qs = [q["query"] for q in queries if q["lang"] == lang]
        print(lang, "unique:", len(set(qs)), "of", len(qs))


main()
