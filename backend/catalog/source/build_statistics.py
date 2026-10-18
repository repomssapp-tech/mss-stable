#!/usr/bin/env python3
"""catalog_statistics.json — maintainer artifact. Not consumed by the app."""
import json, os, subprocess, sys
from collections import Counter, OrderedDict

CAT = "/sessions/practical-charming-hypatia/mnt/Plan/catalog"
AT = "2026-08-04T00:00:00Z"
REL = "1.33.0-alpha"

PHASES = [(1,"common_catalog.json"),(2,"authority_catalog.json"),(3,"institution_catalog.json"),
          (4,"scheme_catalog.json"),(5,"finance_catalog.json"),(6,"tax_catalog.json"),
          (7,"treds_catalog.json"),(8,"csr_catalog.json"),(9,"export_catalog.json"),
          (10,"knowledge_catalog.json"),(11,"search_index.json"),(12,"manifest.json")]

def load(n):
    p = os.path.join(CAT, n)
    return json.load(open(p, encoding="utf-8")) if os.path.exists(p) else None

def main():
    stats = OrderedDict([("generatedAt", AT), ("catalogRelease", REL),
                         ("stage", "A — document-derived, tiers 1-4, no network")])

    # ---- phase progress
    prog = []
    for n, f in PHASES:
        c = load(f)
        prog.append(OrderedDict([("phase", n), ("file", f),
                                 ("status", "generated" if c else "pending"),
                                 ("recordCount", c["metadata"]["recordCount"] if c else 0)]))
    stats["phases"] = prog
    stats["phasesComplete"] = sum(1 for p in prog if p["status"] == "generated")
    stats["phasesTotal"] = len(PHASES)

    # ---- entity counts
    counts = OrderedDict()
    # manifest.json and search_index.json are not entity catalogs: the first holds
    # release metadata, the second holds index pointers. Neither carries `identity`.
    NON_ENTITY = {"manifest.json", "search_index.json"}
    for _, f in PHASES:
        c = load(f)
        if c and f not in NON_ENTITY:
            for et, n in Counter(r["identity"]["entityType"] for r in c["data"]).items():
                counts[et + "s" if not et.endswith("s") else et] = n
    stats["entities"] = counts
    stats["entitiesTotal"] = sum(counts.values())

    si = load("search_index.json")
    if si:
        stats["searchIndex"] = OrderedDict([
            ("indexedEntities", si["metadata"]["recordCount"]),
            ("coversAllEntities", si["metadata"]["recordCount"] == sum(counts.values())),
            ("searchRankPopulated", 0)])

    # ---- scheme detail
    sc = load("scheme_catalog.json")
    if sc:
        d = sc["data"]; N = len(d)
        g = lambda fn: sum(1 for r in d if fn(r))
        v = Counter(r["verification"]["status"] for r in d)
        stats["schemes"] = OrderedDict([
            ("total", N),
            ("documents", sum(len(r["content"]["requiredDocuments"]) for r in d)),
            ("sources", sum(len(r["content"]["sources"]) for r in d)),
            ("verified", v.get("verified", 0)),
            ("partiallyVerified", v.get("partially_verified", 0)),
            ("unverified", v.get("unverified", 0)),
            ("historical", v.get("historical", 0)),
            ("missingVerification", N - v.get("verified", 0)),
            ("missingContacts", g(lambda r: not any(r["content"]["contacts"].values()))),
            ("missingApplicationLinks", g(lambda r: not r["content"]["applicationProcess"]["onlineUrl"])),
            ("missingApplicationMode", g(lambda r: not r["content"]["applicationProcess"]["mode"])),
            ("missingBenefitAmount", g(lambda r: not any(
                isinstance(x, dict) and x.get("maxAmountInr") for x in r["content"]["benefits"].values()))),
            ("missingFaqs", g(lambda r: not r["content"]["faqs"])),
            ("missingTimeline", g(lambda r: not r["content"]["applicationTimeline"]["text"])),
            ("missingLegalBasis", g(lambda r: not r["content"]["overview"]["legalBasis"])),
            ("unresolvedAuthorityRefs", g(lambda r: not r["content"]["classification"]["government"]["ministryId"])),
            ("missingFieldEntries", sum(len(r["verification"]["missingFields"]) for r in d)),
            ("aiSummariesExtractive", g(lambda r: r["ai"]["summary"])),
            ("aiApproved", g(lambda r: r["ai"]["isApproved"])),
        ])
        stats["schemes"]["completenessPct"] = round(100 * (
            1 - stats["schemes"]["missingFieldEntries"] / (N * 30)), 1)

    # ---- vocabulary coverage
    cc = load("common_catalog.json")
    if cc and sc:
        terms = Counter(r["content"]["termType"] for r in cc["data"])
        alias = sum(len(r["content"]["aliases"]) for r in cc["data"])
        stats["vocabulary"] = OrderedDict([
            ("terms", cc["metadata"]["recordCount"]),
            ("termTypes", len(terms)),
            ("byType", OrderedDict(sorted(terms.items()))),
            ("harvestedAliases", alias),
            ("schemeTypeAliases", sum(len(r["content"]["aliases"]) for r in cc["data"]
                                      if r["content"]["termType"] == "scheme_type")),
            ("documentTypeAliases", sum(len(r["content"]["aliases"]) for r in cc["data"]
                                        if r["content"]["termType"] == "document_type")),
        ])
        # how many scheme enum gaps common_catalog can now close
        m = {}
        for r in cc["data"]:
            if r["content"]["termType"] == "scheme_type":
                for a in r["content"]["aliases"]: m[a.lower()] = r["content"]["code"]
        closable = sum(1 for r in sc["data"]
                       if r["content"]["classification"]["schemeType"] is None
                       and (r["content"]["classification"]["schemeTypeText"] or "").lower() in m)
        stats["vocabulary"]["schemeTypeEnumsClosable"] = closable
        stats["vocabulary"]["schemeTypeStillNull"] = sum(
            1 for r in sc["data"] if r["content"]["classification"]["schemeType"] is None) - closable

    # ---- baseline delta (1.0.0-alpha -> current)
    bl_path = os.path.join(CAT, "stage_a_frozen", "scheme_catalog.json")
    if sc and os.path.exists(bl_path):
        bl = json.load(open(bl_path, encoding="utf-8"))["data"]
        def m(rs, fn): return sum(1 for r in rs if fn(r))
        M = [("ministryIdResolved", lambda r: bool(r["content"]["classification"]["government"]["ministryId"])),
             ("departmentIdResolved", lambda r: bool(r["content"]["classification"]["government"]["departmentId"])),
             ("implementingAgencyIdsResolved", lambda r: bool(r["content"]["classification"]["government"]["implementingAgencyIds"])),
             ("schemeTypeEnumSet", lambda r: bool(r["content"]["classification"]["schemeType"])),
             ("documentsTyped", lambda r: any(d["documentTypeId"] for d in r["content"]["requiredDocuments"])),
             ("authorityReferences", lambda r: bool(r["relationships"]["references"]))]
        stats["baselineDelta"] = OrderedDict([("from", "1.0.0-alpha"),
                                              ("to", sc["metadata"]["catalogVersion"])])
        for name, fn in M:
            b, n = m(bl, fn), m(sc["data"], fn)
            stats["baselineDelta"][name] = {"before": b, "after": n, "delta": n - b}
        bmf = sum(len(r["verification"]["missingFields"]) for r in bl)
        nmf = sum(len(r["verification"]["missingFields"]) for r in sc["data"])
        stats["baselineDelta"]["missingFieldEntries"] = {"before": bmf, "after": nmf,
                                                         "delta": nmf - bmf}
        idrefs = sum(len(r["relationships"]["references"]) for r in sc["data"])
        stats["baselineDelta"]["totalIdReferences"] = {"before": 0, "after": idrefs,
                                                       "delta": idrefs}

    # ---- multilingual coverage
    i18n = OrderedDict()
    for f in ("common_catalog.json", "authority_catalog.json", "scheme_catalog.json"):
        c = load(f)
        if not c: continue
        tot = ta = 0
        meth = Counter()
        kw_en = kw_ta = 0
        for r in c["data"]:
            for k, v in r["localization"]["en"].items():
                if v:
                    tot += 1
                    if r["localization"]["ta"].get(k): ta += 1
            meth.update(r["provenance"].get("translations", {})
                          .get("ta", {}).get("fieldMethods", {}).values())
            s = r["search"]["keywords"]
            if isinstance(s, dict):
                kw_en += len(s["en"]); kw_ta += len(s["ta"])
        i18n[f] = OrderedDict([("localizableValues", tot), ("tamilPopulated", ta),
                               ("tamilPending", tot - ta),
                               ("coveragePct", round(100 * ta / tot, 1) if tot else 0.0),
                               ("methods", dict(meth)),
                               ("searchKeywordsEn", kw_en), ("searchKeywordsTa", kw_ta)])
    td = load("translation_dictionary.json")
    i18n["dictionaryEntries"] = td["metadata"]["entryCount"] if td else 0
    i18n["languages"] = ["en", "ta"]
    i18n["hindiPopulated"] = 0
    i18n["translationMethod"] = "machine (dictionary + compositional patterns)"
    i18n["translationsApproved"] = 0
    i18n["reviewRequired"] = True
    stats["multilingual"] = i18n

    # ---- validation
    here = os.path.dirname(os.path.abspath(__file__))
    runs = {n: subprocess.run([sys.executable, n], capture_output=True, text=True, cwd=here).returncode
            for n in ("validate_base.py", "validate_catalog.py", "validate_cross_catalog.py",
                      "validate_i18n.py")}
    ok = all(v == 0 for v in runs.values())
    files = sum(1 for _, f in PHASES if load(f))
    stats["validation"] = OrderedDict([
        ("suites", OrderedDict([("base", "1-30"), ("scheme", "31-45"),
                                ("crossCatalog", "referential integrity"),
                                ("policy", "1-14"), ("batch", "25-37")])),
        ("suiteResults", {k: ("PASS" if v == 0 else "FAIL") for k, v in runs.items()}),
        ("filesValidated", files), ("filesPassed", files if ok else 0),
        ("failures", 0 if ok else -1),
        ("validationPassRate", "100%" if ok else "FAILED"),
    ])

    # ---- file sizes
    stats["files"] = [OrderedDict([("fileName", f),
                                   ("byteSize", os.path.getsize(os.path.join(CAT, f)))])
                      for _, f in PHASES if os.path.exists(os.path.join(CAT, f))]
    stats["totalBytes"] = sum(f["byteSize"] for f in stats["files"])

    json.dump(stats, open(os.path.join(CAT, "catalog_statistics.json"), "w", encoding="utf-8"),
              indent=2, ensure_ascii=False)
    print(json.dumps(stats, indent=2)[:2400])

if __name__ == "__main__":
    main()
