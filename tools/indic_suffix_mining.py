"""Mine Hindi and Tamil inflectional suffixes from the catalog's own text.

The scheme catalog is finite and fixed, so its suffixes can be read off the
data instead of being guessed from grammar books. A *stem* that occurs with
several different endings reveals those endings (the Linguistica / Goldsmith
idea): "திட்டம்", "திட்டத்தை", "திட்டத்தில்" ... all share "திட்ட".

For every token and every split point we record stem -> {suffixes}. A stem is
trusted when it carries at least MIN_ENDINGS distinct endings (the bare form
counts as one). A suffix's *support* is the number of trusted stems that take
it. Output is advisory: review it, then keep the list you trust.

Usage: python tools/indic_suffix_mining.py [--out suffixes.json]
"""

import glob
import gzip
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "frontend" / "assets" / "catalog"

SCRIPTS = {
    "ta": re.compile(r"[஀-௿]+"),
    "hi": re.compile(r"[ऀ-ॿ]+"),
}
TEXT_FIELDS = (
    "name",
    "summary",
    "description",
    "benefitsText",
    "eligibilityText",
    "applicationText",
    "category",
)
MIN_STEM = 3  # code points; shorter stems match too many unrelated words
MAX_SUFFIX = 9
MIN_ENDINGS = 3
MIN_SUPPORT = 4


def load_tokens():
    tokens = {"ta": Counter(), "hi": Counter()}
    for f in sorted(glob.glob(str(CATALOG / "catalog_*.json.gz"))):
        data = json.load(gzip.open(f)).get("scheme_catalog.json")
        if not data:
            continue
        items = data if isinstance(data, list) else next(v for v in data.values() if isinstance(v, list))
        for scheme in items:
            loc = scheme.get("localization", {})
            for lang, pat in SCRIPTS.items():
                block = loc.get(lang) or {}
                for key in TEXT_FIELDS:
                    text = block.get(key)
                    if isinstance(text, str):
                        tokens[lang].update(pat.findall(text))
    return tokens


def mine(counter):
    stems = defaultdict(set)
    for tok in counter:
        for i in range(MIN_STEM, len(tok) + 1):
            suffix = tok[i:]
            if len(suffix) > MAX_SUFFIX:
                continue
            stems[tok[:i]].add(suffix)
    support = Counter()
    examples = defaultdict(list)
    for stem, ends in stems.items():
        if len(ends) < MIN_ENDINGS:
            continue
        for suffix in ends:
            if suffix:
                support[suffix] += 1
                if len(examples[suffix]) < 3:
                    examples[suffix].append(stem + "+" + suffix)
    return [
        {"suffix": s, "support": n, "examples": examples[s]}
        for s, n in support.most_common()
        if n >= MIN_SUPPORT
    ]


def main():
    tokens = load_tokens()
    out = {}
    for lang in ("ta", "hi"):
        out[lang] = mine(tokens[lang])
        print(f"{lang}: {sum(tokens[lang].values())} tokens, {len(tokens[lang])} types, "
              f"{len(out[lang])} candidate suffixes (support >= {MIN_SUPPORT})")
        for row in out[lang][:45]:
            print(f"   {row['suffix']:<10} {row['support']:>4}  {', '.join(row['examples'])}")
    if "--out" in sys.argv:
        path = Path(sys.argv[sys.argv.index("--out") + 1])
        path.write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")
        print("wrote", path)


main()
