"""Give CEN2026-090 ("Promotion of MSME in NER and Sikkim") its structured coverage.

The record says "North Eastern States and Sikkim" in `statesText` but has
`appliesNationally: false` and an empty `states` list, so state browsing showed
it nowhere (#152: it must appear for the eight north-eastern states and be
excluded elsewhere). The 1.37 preview catalog carries the same fix; this script
applies it to the bundled packs until the new catalog is activated.

Idempotent. Rewrites the packs and the core manifest hashes via catalog_packs.

usage: python tools/fix_ner_scheme_coverage.py
"""
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
repo = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(repo / "tools"))
import catalog_packs  # noqa: E402

PACKS = repo / "frontend" / "assets" / "catalog"
SCHEME_ID = "CEN2026-090"
NER_STATES = ["IN-AR", "IN-AS", "IN-MN", "IN-ML", "IN-MZ", "IN-NL", "IN-SK", "IN-TR"]

bundle = catalog_packs.load_dir(PACKS)
record = next(
    s for s in bundle[catalog_packs.SCHEME_SECTION]["data"] if s["identity"]["id"] == SCHEME_ID
)
gov = record["content"]["classification"]["government"]
if gov.get("states") == NER_STATES and gov.get("appliesNationally") is False:
    print(f"{SCHEME_ID} already covers {len(NER_STATES)} states; nothing to do")
    sys.exit(0)
gov["appliesNationally"] = False
gov["states"] = list(NER_STATES)

languages = {
    p["jurisdiction"]: p.get("languages", [])
    for p in bundle["manifest.json"]["data"][0].get("packs", [])
    if p.get("kind") == "jurisdiction"
}
packs = catalog_packs.split(bundle, PACKS, languages)
core = catalog_packs.write_core(bundle, PACKS, packs)
print(f"{SCHEME_ID}: states={NER_STATES}; wrote {len(packs)} packs; core {core['bytes']} bytes")
