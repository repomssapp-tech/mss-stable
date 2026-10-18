#!/usr/bin/env python3
"""
Phase 4 — regenerate scheme_catalog.json as 1.1.0-alpha.

INPUT  : catalog/stage_a_frozen/scheme_catalog.json   (1.0.0-alpha, never modified)
         catalog/authority_catalog.json
         catalog/common_catalog.json
OUTPUT : catalog/scheme_catalog.json                  (1.1.0-alpha)

RESOLUTION RULES — deterministic joins only, no inference:

  R1  authority id : the authority text is put through the SAME normalisation
                     pipeline used to build authority_catalog, then joined on an
                     EXACT normalised-token key. No fuzzy matching, no curated map.
  R2  composite    : "A / B" is split into separate authorities before joining,
                     using the same splitter as the authority build.
  R3  scheme type  : classification.schemeTypeText is matched EXACTLY (case-folded)
                     against the aliases harvested into common_catalog scheme_type.
  R4  document type: requiredDocuments[].name is matched EXACTLY (case-folded)
                     against common_catalog document_type aliases.
  R5  no match     -> field stays null and keeps its missingFields entry.

Nothing else about a scheme record changes. Content values are never rewritten.
"""
import json, os, re, hashlib, sys
from collections import OrderedDict, Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
# reuse the EXACT normalisation used to build authority_catalog
from build_authority_catalog import (split_composite, strip_acronym, expand,
                                     strip_trailing_qualifier, split_jurisdiction,
                                     trim_prose, norm_key, is_authority)

CAT = "/sessions/practical-charming-hypatia/mnt/Plan/catalog"
BASE = os.path.join(CAT, "stage_a_frozen", "scheme_catalog.json")
REL = "1.1.0-alpha"
AT = "2026-08-04T00:00:00Z"

def load(n): return json.load(open(os.path.join(CAT, n), encoding="utf-8"))

def authority_key(surface):
    """Same pipeline as the authority build. Returns normalised key or None."""
    if not is_authority(surface): return None
    stripped, _ = strip_acronym(surface)
    core = strip_trailing_qualifier(expand(stripped))
    core, _ = split_jurisdiction(core)
    core = trim_prose(core) or core
    if not core or not is_authority(core): return None
    return norm_key(core)

def main():
    base = load(os.path.join("stage_a_frozen", "scheme_catalog.json")) \
        if False else json.load(open(BASE, encoding="utf-8"))
    auth = load("authority_catalog.json")
    common = load("common_catalog.json")

    # ---- R1 build authority index (normalised key -> AUTH id)
    akey = {}
    for r in auth["data"]:
        aid = r["identity"]["id"]
        akey.setdefault(norm_key(r["identity"]["name"]), aid)
        for al in r["content"]["aliases"]:
            k = authority_key(al)
            if k: akey.setdefault(k, aid)
    # ---- R3/R4 vocabulary indexes (exact, case-folded)
    stype, dtype = {}, {}
    for r in common["data"]:
        c = r["content"]
        if c["termType"] == "scheme_type":
            for al in c["aliases"]: stype.setdefault(al.strip().lower(), c["code"])
        elif c["termType"] == "document_type":
            for al in c["aliases"]: dtype.setdefault(al.strip().lower(), r["identity"]["id"])

    stat = Counter()
    out = []
    for r in base["data"]:
        rec = json.loads(json.dumps(r))          # deep copy of the frozen record
        g = rec["content"]["classification"]["government"]
        notes = rec["provenance"]["transformationNotes"]
        refs = rec["relationships"]["references"]
        seen = {x["entityId"] for x in refs}

        def add_ref(aid, rel):
            if aid and aid not in seen:
                refs.append({"entityId": aid, "entityType": "authority",
                             "relationType": rel, "role": None,
                             "note": "Resolved by exact normalised-name join (rule R1)"})
                seen.add(aid)

        # -- ministry
        if g["ministryText"] and not g["ministryId"]:
            for p in split_composite(g["ministryText"]):
                k = authority_key(p)
                if k and k in akey:
                    g["ministryId"] = akey[k]
                    notes.append(f"classification.government.ministryId resolved to "
                                 f"{akey[k]} from '{p}' by exact normalised-name join "
                                 f"against authority_catalog 1.0.0 (rule R1)")
                    add_ref(akey[k], "administered_by")
                    stat["ministryResolved"] += 1
                    break
        # -- department
        if g["departmentText"] and not g["departmentId"]:
            for p in split_composite(g["departmentText"]):
                k = authority_key(p)
                if k and k in akey:
                    g["departmentId"] = akey[k]
                    notes.append(f"classification.government.departmentId resolved to "
                                 f"{akey[k]} from '{p}' (rule R1)")
                    add_ref(akey[k], "administered_by")
                    stat["departmentResolved"] += 1
                    break
        # -- implementing agencies (R2 composite split, all matches kept)
        if g["implementingAgencyText"] and not g["implementingAgencyIds"]:
            ids = []
            for p in split_composite(g["implementingAgencyText"]):
                k = authority_key(p)
                if k and k in akey and akey[k] not in ids:
                    ids.append(akey[k])
                    notes.append(f"implementingAgencyIds += {akey[k]} from '{p}' (rules R1, R2)")
                    add_ref(akey[k], "implemented_by")
            if ids:
                g["implementingAgencyIds"] = ids
                stat["agencyResolved"] += 1
                stat["agencyIdsTotal"] += len(ids)

        # -- R3 scheme type enum
        cl = rec["content"]["classification"]
        if cl["schemeTypeText"] and not cl["schemeType"]:
            code = stype.get(cl["schemeTypeText"].strip().lower())
            if code:
                cl["schemeType"] = code
                notes.append(f"classification.schemeType resolved to '{code}' by exact "
                             f"alias match against common_catalog (rule R3)")
                stat["schemeTypeResolved"] += 1

        # -- R4 document type ids
        dres = 0
        for d in rec["content"]["requiredDocuments"]:
            if d["name"] and not d["documentTypeId"]:
                cid = dtype.get(d["name"].strip().lower())
                if cid:
                    d["documentTypeId"] = cid
                    dres += 1
        if dres:
            notes.append(f"documentTypeId resolved on {dres} document(s) by exact alias "
                         f"match against common_catalog (rule R4)")
            stat["documentsTyped"] += dres

        # -- refresh missingFields: drop entries now satisfied
        mf = rec["verification"]["missingFields"]
        keep = []
        for m in mf:
            if m["field"] == "content.classification.government.ministryId" and g["ministryId"]:
                stat["missingFieldsCleared"] += 1
                continue
            keep.append(m)
        rec["verification"]["missingFields"] = keep
        # -- record what remains unresolved, explicitly
        for fld, val in (("departmentId", g["departmentId"]),
                         ("implementingAgencyIds", g["implementingAgencyIds"])):
            if not val and (g["departmentText"] if fld == "departmentId"
                            else g["implementingAgencyText"]):
                keep.append({"field": f"content.classification.government.{fld}",
                             "reason": "No exact normalised-name match in authority_catalog; "
                                       "not inferred"})
                stat["unresolvedLogged"] += 1
        if cl["schemeTypeText"] and not cl["schemeType"]:
            keep.append({"field": "content.classification.schemeType",
                         "reason": "Source wording has no exact alias in common_catalog; "
                                   "not inferred"})

        rec["metadata"]["catalogVersion"] = REL
        rec["metadata"]["updatedAt"] = AT
        rec["metadata"]["revision"] = 2
        rec["provenance"]["pipelineVersion"] = "phase4-resolve-1.0.0"
        notes.append("Regenerated from frozen 1.0.0-alpha baseline; content values "
                     "unchanged, identifiers resolved only")
        out.append(rec)

    def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    cat = OrderedDict([
        ("metadata", OrderedDict([("catalogName", "scheme"), ("schemaVersion", "1.0.0"),
                                  ("catalogVersion", REL), ("generatedAt", AT),
                                  ("language", "en"), ("recordCount", len(out)),
                                  ("checksum", "sha256:" + hashlib.sha256(canon(out).encode()).hexdigest())])),
        ("data", out)])
    json.dump(cat, open(os.path.join(CAT, "scheme_catalog.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)

    # ---- integrity: content values must be identical to the baseline
    def content_sig(r):
        c = json.loads(json.dumps(r["content"]))
        g = c["classification"]["government"]
        g["ministryId"] = g["departmentId"] = None
        g["implementingAgencyIds"] = []
        c["classification"]["schemeType"] = None
        for d in c["requiredDocuments"]: d["documentTypeId"] = None
        return canon(c)
    drift = [b["identity"]["id"] for b, n in zip(base["data"], out)
             if content_sig(b) != content_sig(n)]
    print(f"scheme_catalog.json -> {REL}  records={len(out)}")
    for k, v in sorted(stat.items()): print(f"   {k:24} {v}")
    print(f"   {'contentDrift':24} {len(drift)} "
          f"{'(baseline values preserved)' if not drift else drift[:5]}")
    if drift: sys.exit(1)

if __name__ == "__main__":
    main()
