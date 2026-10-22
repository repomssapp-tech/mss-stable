"""Write the Tamil Nadu Hindi translations (machine, unreviewed) into the catalogue packs.

Mirrors how the packs already carry Tamil for these schemes (and Hindi for
Maharashtra): source.<field>.hi, source.translations.hi, benefit-fact
translations, localization.hi, search.aliases.hi, languages and provenance.

Hindi comes from tools/tn_schemes_hi_2026.json. Idempotent.

usage: python tools/add_tn_hindi.py
"""
import json
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
repo = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(repo / "tools"))
import catalog_packs  # noqa: E402

PACKS = repo / "frontend" / "assets" / "catalog"
RS = re.compile(r"\bRs\.?\s?(?=\d)")
FLAG = {"origin": "machine", "engine": "claude", "verified": False}
HINDI = json.loads((repo / "tools" / "tn_schemes_hi_2026.json").read_text(encoding="utf-8"))["schemes"]


def norm(v):
    """Rupee amounts written "Rs 5" become "₹5", as in the rest of the Hindi."""
    if isinstance(v, str):
        return RS.sub("₹", v).strip()
    if isinstance(v, list):
        return [norm(x) for x in v]
    if isinstance(v, dict):
        return {k: norm(x) for k, x in v.items()}
    return v


def put(d, key, value):
    if isinstance(d.get(key), dict):
        d[key]["hi"] = value


bundle = catalog_packs.load_dir(PACKS)
schemes = bundle[catalog_packs.SCHEME_SECTION]["data"]
done = []
for s in schemes:
    sid = s["identity"]["id"]
    if sid not in HINDI:
        continue
    h = norm(HINDI[sid])
    src = s["source"]
    how = src.setdefault("how_to_apply", {})

    for key in ("name", "short_name", "alt_names", "description", "benefits", "eligibility"):
        put(src, key, h[{"short_name": "short_name"}.get(key, key)])
    put(how, "steps", h["steps"])

    # Document names: the catalogue's own Hindi names, when they line up 1:1.
    docs_en = how.get("documents") if isinstance(how.get("documents"), list) else []
    req = s["content"].get("requiredDocuments") or []
    docs_hi = None
    if docs_en and len(req) == len(docs_en):
        names = [(d.get("name") or {}).get("hi") if isinstance(d.get("name"), dict) else None for d in req]
        if all(names):
            docs_hi = names
            how["documents_hi"] = docs_hi

    tr_hi = {
        "category": h["category"],
        "status": {"note": h["status_note"]},
        "how_to_apply": {"mode": h["mode"], "notes": h["notes"]},
        "authority": h["authority"],
        "alt_names": h["alt_names"],
    }
    src.setdefault("translations", {})["hi"] = tr_hi

    # Benefit facts: same fact order, same keys as the Tamil translations.
    for facts in (
        (src.get("benefit_facts") or {}).get("facts") or [],
        (s["content"].get("benefitFacts") or {}).get("facts") or [],
    ):
        assert len(facts) == len(h["benefit_facts"]), sid
        for fact, hi in zip(facts, h["benefit_facts"]):
            if hi:
                fact.setdefault("translations", {})["hi"] = hi

    loc = {
        "name": h["name"],
        "shortName": h["short_name"],
        "summary": (h["description"] or [None])[0],
        "description": "\n".join(h["description"]),
        "benefitsText": "\n".join(h["benefits"]),
        "eligibilityText": "\n".join(h["eligibility"]),
        "applicationText": "\n".join(h["steps"]),
        "authority": h["authority"],
        "category": h["category"],
        "statusNote": h["status_note"],
        "mode": h["mode"],
        "documents": docs_hi or [],
        "notes": h["notes"],
        "altNames": h["alt_names"],
    }
    s["localization"]["hi"] = {k: v for k, v in loc.items() if v not in (None, "")}

    search = s.setdefault("search", {})
    search.setdefault("aliases", {})["hi"] = h["alt_names"]
    search.setdefault("keywords", {}).setdefault("hi", [])

    langs = s["content"].setdefault("languages", {})
    for k in ("available", "offered"):
        if "hi" not in langs.get(k, []):
            langs[k] = sorted(set(langs.get(k, [])) | {"hi"}, key=["en", "hi", "ta", "mr"].index)

    prov = s.setdefault("provenance", {})
    prov.setdefault("translationFlags", {})["hi_is_machine_translation"] = True
    master = prov.setdefault("master", {}).setdefault("translation_meta", {})
    master["hi"] = dict(FLAG)
    done.append(sid)

# The Tamil Nadu pack now offers Hindi.
languages = {}
for p in bundle["manifest.json"]["data"][0].get("packs", []):
    if p.get("kind") != "jurisdiction":
        continue
    if p["jurisdiction"] == "tamil_nadu" and "hi" not in p["languages"]:
        p["languages"] = ["en", "hi", "ta"]
    languages[p["jurisdiction"]] = p.get("languages", [])

packs = catalog_packs.split(bundle, PACKS, languages)
core = catalog_packs.write_core(bundle, PACKS, packs)
print(f"Hindi added to {len(done)} Tamil Nadu schemes; wrote {len(packs)} packs; core {core['bytes']} bytes")
