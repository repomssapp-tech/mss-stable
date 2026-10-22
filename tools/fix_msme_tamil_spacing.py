"""Write Tamil MSME as spaced letters inside the bundled scheme content.

The app UI writes Tamil MSME as spaced letters ("எம் எஸ் எம் ஈ", the form in
backend/catalog/source/translation_terminology_dictionary.json). The shipped
catalog packs still carry the short form ("எம்எஸ்எம்இ") in scheme text, so a
scheme's own wording and the labels around it read differently. This applies the
UI form to the packs until the catalog is regenerated upstream.

Only Tamil-script text is touched: the short form cannot occur in Latin, Hindi or
Marathi text, and the search index has none of it. Idempotent. Rewrites the packs
and the core manifest hashes via catalog_packs, like fix_ner_scheme_coverage.py.

usage: python tools/fix_msme_tamil_spacing.py
"""
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
repo = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(repo / "tools"))
import catalog_packs  # noqa: E402

PACKS = repo / "frontend" / "assets" / "catalog"
OLD = "எம்எஸ்எம்இ"
NEW = "எம் எஸ் எம் ஈ"


def respace(node):
    """Replace OLD with NEW in every string under [node]; return (node, count)."""
    if isinstance(node, str):
        n = node.count(OLD)
        return (node.replace(OLD, NEW) if n else node), n
    if isinstance(node, list):
        total = 0
        for i, item in enumerate(node):
            node[i], n = respace(item)
            total += n
        return node, total
    if isinstance(node, dict):
        total = 0
        for key, item in node.items():
            node[key], n = respace(item)
            total += n
        return node, total
    return node, 0


bundle = catalog_packs.load_dir(PACKS)
changed = 0
for section, value in bundle.items():
    bundle[section], n = respace(value)
    changed += n
if not changed:
    print("no short-form MSME left in the packs; nothing to do")
    sys.exit(0)

languages = {
    p["jurisdiction"]: p.get("languages", [])
    for p in bundle["manifest.json"]["data"][0].get("packs", [])
    if p.get("kind") == "jurisdiction"
}
packs = catalog_packs.split(bundle, PACKS, languages)
core = catalog_packs.write_core(bundle, PACKS, packs)
print(f"respaced {changed} occurrences; wrote {len(packs)} packs; core {core['bytes']} bytes")
