"""Apply the reviewed Hindi corrections to the bundled Maharashtra scheme pack.

The Maharashtra Hindi is machine-translated (every record has
hi_is_machine_translation). Four independent reviewers compared it with the
English, scheme by scheme, and proposed corrections (Marathi words such as
"संचालनालय", glossary mismatches, repeated phrases, a few meaning slips). The
proposals are in tools/data/maharashtra_hindi_review_2026-10-23.json, one row per
field: {sid, field, was, new, conf, why}.

What this does
- Applies rows with confidence "high" and "medium". "low" rows are held back for a
  native Hindi reviewer (pass --include-low to apply them).
- A row is applied only when its "was" still equals the current
  localization.hi[field]; otherwise it is reported and skipped.
- The Hindi of a scheme lives in several mirrored places (localization.hi, the
  source.*.hi lists that the app reads for steps/eligibility, requiredDocuments
  names, notes_hi). Changes are mapped line by line onto every Hindi-path copy so
  they stay in sync. Marathi and English text is never touched.
- Then normalises a few spellings and terms to the project's Hindi glossary
  (frontend/assets/catalog/translation_dictionary_hi.json): nukta spellings,
  "स्टाम्प शुल्क", "बिजली शुल्क", "इन्क्यूबेशन", and the Marathi "भांडवल".

Idempotent. Rewrites the packs and the core manifest hashes via catalog_packs.

usage: python tools/apply_maharashtra_hindi_review.py [--include-low]
"""
import json
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
repo = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(repo / "tools"))
import catalog_packs  # noqa: E402

PACKS = repo / "frontend" / "assets" / "catalog"
REVIEW = repo / "tools" / "data" / "maharashtra_hindi_review_2026-10-23.json"
INCLUDE_LOW = "--include-low" in sys.argv

# Glossary-backed spelling and term normalisation, applied to Hindi text only.
TERM_FIXES = [
    ("स्टाम्प ड्यूटी", "स्टाम्प शुल्क"),
    ("विद्युत शुल्क", "बिजली शुल्क"),
    ("इनक्यूबेशन", "इन्क्यूबेशन"),
    ("इनक्यूबेटर", "इन्क्यूबेटर"),
    ("रोजगार", "रोज़गार"),
    ("बाजार", "बाज़ार"),
    ("पूँजी", "पूंजी"),
    ("भांडवल", "पूंजी"),
]


def normalise(value):
    """[value] with the glossary spelling/term fixes applied to every string in it."""
    if isinstance(value, str):
        for a, b in TERM_FIXES:
            value = value.replace(a, b)
        return value
    if isinstance(value, list):
        return [normalise(v) for v in value]
    if isinstance(value, dict):
        return {k: normalise(v) for k, v in value.items()}
    return value


def units(value):
    """Every line of every string under [value], in order."""
    if isinstance(value, str):
        return value.split("\n")
    if isinstance(value, list):
        return [u for item in value for u in units(item)]
    if isinstance(value, dict):
        return [u for item in value.values() for u in units(item)]
    return []


def has_devanagari(text):
    return any("ऀ" <= ch <= "ॿ" for ch in text)


def is_hindi_path(path):
    """True for a path that holds Hindi: a 'hi' key or a '*_hi' key, never 'mr'."""
    return any(p == "hi" or (isinstance(p, str) and p.endswith("_hi")) for p in path)


def rewrite(node, path, fn):
    """Apply fn to every Hindi-path string leaf of [node] in place; return count."""
    changed = 0
    if isinstance(node, dict):
        for key, child in node.items():
            if isinstance(child, str):
                if is_hindi_path(path + (key,)):
                    new = fn(child)
                    if new != child:
                        node[key] = new
                        changed += 1
            else:
                changed += rewrite(child, path + (key,), fn)
    elif isinstance(node, list):
        for i, child in enumerate(node):
            if isinstance(child, str):
                if is_hindi_path(path):
                    new = fn(child)
                    if new != child:
                        node[i] = new
                        changed += 1
            else:
                changed += rewrite(child, path, fn)
    return changed


bundle = catalog_packs.load_dir(PACKS)
schemes = {s["identity"]["id"]: s for s in bundle[catalog_packs.SCHEME_SECTION]["data"]}
rows = json.loads(REVIEW.read_text(encoding="utf-8"))

applied_rows = skipped_stale = held_low = 0
leaf_changes = 0
per_scheme = {}
for row in rows:
    if row["conf"] == "low" and not INCLUDE_LOW:
        held_low += 1
        continue
    if normalise(row["new"]) == normalise(row["was"]):
        continue  # the glossary pass already makes this row a no-op
    scheme = schemes[row["sid"]]
    current = scheme["localization"]["hi"].get(row["field"])
    if current != row["was"]:
        if normalise(current) == normalise(row["new"]):
            continue  # already applied (and glossary-normalised)
        skipped_stale += 1
        print(f"skip (text changed since review): {row['sid']} {row['field']}")
        continue
    old_units, new_units = units(row["was"]), units(row["new"])
    if len(old_units) != len(new_units):
        skipped_stale += 1
        print(f"skip (line count differs): {row['sid']} {row['field']}")
        continue
    mapping = per_scheme.setdefault(row["sid"], {})
    for o, n in zip(old_units, new_units):
        if o != n and has_devanagari(o):
            if mapping.get(o, n) != n:
                print(f"conflict for one line in {row['sid']}; keeping the first")
                continue
            mapping[o] = n
    applied_rows += 1

for sid, mapping in per_scheme.items():

    def sub(text, mapping=mapping):
        return "\n".join(
            mapping.get(line, mapping.get(line.strip(), line)) for line in text.split("\n")
        )

    leaf_changes += rewrite(schemes[sid], (), sub)

term_changes = 0
for scheme in schemes.values():

    def fix_terms(text):
        for a, b in TERM_FIXES:
            text = text.replace(a, b)
        return text

    term_changes += rewrite(scheme, (), fix_terms)

if not leaf_changes and not term_changes:
    print("nothing to apply")
    sys.exit(0)

languages = {
    p["jurisdiction"]: p.get("languages", [])
    for p in bundle["manifest.json"]["data"][0].get("packs", [])
    if p.get("kind") == "jurisdiction"
}
packs = catalog_packs.split(bundle, PACKS, languages)
core = catalog_packs.write_core(bundle, PACKS, packs)
print(
    f"rows applied {applied_rows}, held back (low) {held_low}, skipped {skipped_stale}; "
    f"{leaf_changes} text copies rewritten, {term_changes} term fixes; "
    f"wrote {len(packs)} packs; core {core['bytes']} bytes"
)
