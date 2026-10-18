#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase 2 priority 1 — institution_catalog.json.

An INSTITUTION is a delivery / finance / support organisation: it implements
schemes, lends, trains, incubates or certifies. An AUTHORITY is a body that
administers. The two overlap in the real world, so:

  * institutions are NEW entities (INST######); no AUTH id is changed or removed
  * where the same body already exists as an AUTH, the INST record REFERENCES it
    rather than restating it (relationType: related_to)
  * membership is DATA-DERIVED, not curated: an authority qualifies as an
    institution when it acts as a scheme implementing agency, or when its
    authority type is a delivery form (corporation / board / council / agency /
    district_industries_centre) rather than an administrative one
    (ministry / department / government)

English only. localization.ta stays null per the approved roadmap (localization
resumes as its own phase; the schema does not change).
"""
import json, os, re, hashlib
from collections import OrderedDict, Counter

CAT = "/sessions/practical-charming-hypatia/mnt/Plan/catalog"
AT = "2026-08-04T00:00:00Z"
SV = "1.0.0"
REL = "1.3.0-alpha"

DELIVERY_TYPES = {"corporation", "board", "council", "agency",
                  "district_industries_centre", "mission"}
ADMIN_TYPES = {"ministry", "department", "government", "directorate", "commissionerate"}

def load(f): return json.load(open(os.path.join(CAT, f), encoding="utf-8"))
def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)

# ---- institution typing, from the name/type already present (no inference)
def institution_type(name, atype):
    t = name.lower()
    if re.search(r"\bbank\b", t) and "development" in t: return "development_finance_institution"
    if re.search(r"\bbank\b", t): return "bank"
    if re.search(r"guarantee (fund )?trust|guarantee corporation", t): return "guarantee_institution"
    if re.search(r"venture capital|fund of funds", t): return "venture_fund"
    if re.search(r"incubat", t): return "incubator"
    if re.search(r"institute|training|skill", t): return "training_institute"
    if re.search(r"\bboard\b|commission\b", t): return "statutory_board"
    if re.search(r"\bcouncil\b", t): return "council"
    if re.search(r"district industries centre", t): return "district_centre"
    if re.search(r"corporation|\bltd\b|corporation ltd", t): return "public_sector_undertaking"
    if re.search(r"mission", t): return "mission_agency"
    if re.search(r"marketplace|mart|exchange|platform", t): return "platform"
    return {"corporation": "public_sector_undertaking", "board": "statutory_board",
            "council": "council", "agency": "support_agency",
            "district_industries_centre": "district_centre",
            "mission": "mission_agency"}.get(atype, "support_agency")

def main():
    auth = load("authority_catalog.json")["data"]
    schemes = load("scheme_catalog.json")["data"]
    byid = {r["identity"]["id"]: r for r in auth}

    # who implements schemes, and which schemes
    implements = {}
    for s in schemes:
        g = s["content"]["classification"]["government"]
        for aid in g["implementingAgencyIds"]:
            implements.setdefault(aid, []).append(s["identity"]["id"])

    # ---- selection (data-derived)
    selected = []
    for r in auth:
        aid = r["identity"]["id"]
        atype = r["content"]["authorityType"]
        acts = aid in implements
        delivery = atype in DELIVERY_TYPES
        if atype in ADMIN_TYPES and not acts:
            continue                     # purely administrative -> stays an authority only
        if not (acts or delivery):
            continue
        if atype in ADMIN_TYPES and acts and atype in ("ministry", "government"):
            continue                     # a ministry implementing directly is still an authority
        selected.append((r, acts, delivery))

    recs, n = [], 0
    for r, acts, delivery in selected:
        n += 1
        iid = "INST%06d" % n
        aid = r["identity"]["id"]
        c = r["content"]
        name = r["identity"]["name"]
        itype = institution_type(name, c["authorityType"])
        sch = implements.get(aid, [])

        miss = [{"field": f, "reason": "Not available in available sources"}
                for f in ("content.offices", "content.contacts", "content.website",
                          "content.establishedOn", "content.mandate")]
        if not c["parentAuthorityId"]:
            miss.append({"field": "content.parentAuthorityId",
                         "reason": "Parent not stated in available sources; not inferred"})

        refs = [{"entityId": aid, "entityType": "authority", "relationType": "related_to",
                 "role": "same body recorded in authority_catalog",
                 "note": "Institution view of an existing authority; AUTH id unchanged"}]
        if c["parentAuthorityId"]:
            refs.append({"entityId": c["parentAuthorityId"], "entityType": "authority",
                         "relationType": "administered_by", "role": None, "note": None})
        for sid in sch:
            refs.append({"entityId": sid, "entityType": "scheme",
                         "relationType": "implements", "role": None, "note": None})

        recs.append(OrderedDict([
            ("identity", OrderedDict([
                ("id", iid), ("entityType", "institution"),
                ("code", r["identity"]["acronym"]), ("legacyCodes", []),
                ("name", name), ("shortName", r["identity"]["shortName"]),
                ("acronym", r["identity"]["acronym"]),
                ("slug", re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")[:120]),
                ("language", "en"), ("status", r["identity"]["status"])])),
            ("content", OrderedDict([
                ("institutionType", itype),
                ("governmentLevel", c["governmentLevel"]),
                ("jurisdiction", c["jurisdiction"]),
                ("parentAuthorityId", c["parentAuthorityId"]),
                ("authorityId", aid),
                ("mandate", None),
                ("establishedOn", None),
                ("services", []),
                ("schemesImplemented", sch),
                ("schemesImplementedCount", len(sch)),
                ("offices", []), ("contacts", []), ("website", None),
                ("aliases", c["aliases"]),
                ("observedIn", c["observedIn"]),
                ("observedCount", c["observedCount"])])),
            ("relationships", {"references": refs}),
            ("localization", {l: {"name": name if l == "en" else None,
                                  "mandate": None} for l in ("en", "ta", "hi")}),
            ("search", {"keywords": {"en": sorted({w for w in re.findall(r"[a-z]{3,}", name.lower())}),
                                     "ta": []},
                        "aliases": {"en": sorted({x for x in [r["identity"]["acronym"]] if x}),
                                    "ta": []},
                        "synonyms": [], "crossReferences": [], "searchRank": None,
                        "boostTerms": []}),
            ("ai", OrderedDict([("summary", None), ("sectionSummaries", {}),
                                ("generationMode", "extractive"), ("confidence", None),
                                ("generatedBy", None), ("generatedAt", None),
                                ("sourceFieldsUsed", []), ("reviewedBy", None),
                                ("reviewedAt", None), ("isApproved", False)])),
            ("verification", OrderedDict([
                ("status", "unverified"), ("statusText", None), ("isVerified", False),
                ("verifiedAgainst", []), ("verifiedBy", None), ("verifiedAt", None),
                ("confidence", "low"), ("researchStatus", None),
                ("notes", "Derived from authority_catalog and scheme implementing-agency "
                          "references; institutional identity not confirmed against an "
                          "official register"),
                ("missingFields", miss), ("disputedFields", []), ("reviewDueOn", None)])),
            ("analytics", {"popularity": None, "viewCount": None, "saveCount": None,
                           "actionCount": None, "lastAggregatedAt": None}),
            ("metadata", OrderedDict([("createdAt", AT), ("updatedAt", AT),
                                      ("catalogVersion", REL), ("schemaVersion", SV),
                                      ("recordStatus", "published"), ("revision", 1)])),
            ("provenance", OrderedDict([
                ("defaultSourceTier", 2), ("primarySourceId", None),
                ("contributingSourceIds", []), ("extractionMethod", "automated"),
                ("extractedAt", AT), ("pipelineVersion", "institution-1.0.0"),
                ("fieldSources", []),
                ("translations", OrderedDict([("ta", OrderedDict([
                    ("method", "none"), ("engine", None), ("status", "not_started"),
                    ("dictionaryVersion", None), ("generatedAt", None),
                    ("fieldMethods", {}), ("fieldsTranslated", 0), ("fieldsContextual", 0),
                    ("fieldsPending", 1), ("isApproved", False), ("reviewRequired", True),
                    ("note", "Localization deferred to a later phase; schema unchanged.")]))])),
                ("transformationNotes", [
                    f"Institution view derived from {aid}; authority record unchanged",
                    "Selected because it implements schemes or is a delivery-type body",
                    "English only; localization.ta intentionally null (roadmap Phase 5)"])])),
        ]))

    cat = OrderedDict([
        ("metadata", OrderedDict([("catalogName", "institution"), ("schemaVersion", SV),
                                  ("catalogVersion", REL), ("generatedAt", AT),
                                  ("language", "en"), ("recordCount", len(recs)),
                                  ("checksum", "sha256:" + hashlib.sha256(canon(recs).encode()).hexdigest())])),
        ("data", recs)])
    json.dump(cat, open(os.path.join(CAT, "institution_catalog.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)

    stats = OrderedDict([
        ("generatedAt", AT), ("catalog", "institution_catalog.json"),
        ("authoritiesConsidered", len(auth)),
        ("institutions", len(recs)),
        ("excludedAsAdministrativeOnly", len(auth) - len(recs)),
        ("byType", dict(Counter(r["content"]["institutionType"] for r in recs))),
        ("byLevel", dict(Counter(str(r["content"]["governmentLevel"]) for r in recs))),
        ("implementingSchemes", sum(1 for r in recs if r["content"]["schemesImplementedCount"])),
        ("schemeLinksTotal", sum(r["content"]["schemesImplementedCount"] for r in recs)),
        ("withParentAuthority", sum(1 for r in recs if r["content"]["parentAuthorityId"])),
        ("tamilPopulated", 0),
        ("localizationStatus", "deferred to roadmap Phase 5"),
    ])
    json.dump(stats, open(os.path.join(CAT, "institution_statistics.json"), "w",
                          encoding="utf-8"), indent=2, ensure_ascii=False)
    for k, v in stats.items(): print(f"   {k:32} {v}")

if __name__ == "__main__":
    main()
