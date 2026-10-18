#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase 2 priority 3 — tax_catalog.json.

DATA WARNING, recorded in the catalog itself:
the uploaded sources contain almost no tax guidance. There is no rate table,
no threshold, no filing calendar, no deduction text. What genuinely exists is:

  * a controlled vocabulary of tax types, registrations and compliances
  * evidence of which tax registrations schemes actually REQUIRE (PAN, GST, ITR)

So this catalog records TAX PROVISIONS as anchors — tax type, registration or
compliance obligation — each linked to the schemes that evidence it. It contains
no rates, thresholds or advice, because no source supplies them. Every such field
is null with a missingFields entry.

Derivation rules:
  X1  one TAX record per common_catalog tax_type / registration_type(tax) /
      compliance_type(tax) term. Vocabulary is the anchor, never invented.
  X2  a scheme is linked when its required documents or eligibility text
      mention that provision, matched on an explicit term list (no fuzzy match).
  X3  rates, thresholds, due dates, deductions, forms -> null + logged.
      Nothing about tax law is generated.

English only. localization.ta null by roadmap decision; schema unchanged.
"""
import json, os, re, hashlib
from collections import OrderedDict, Counter

CAT = "/sessions/practical-charming-hypatia/mnt/Plan/catalog"
AT = "2026-08-04T00:00:00Z"
SV = "1.0.0"
REL = "1.5.0-alpha"

# X1 — which vocabulary terms are tax provisions, and X2 — their explicit match terms
TAX_TERMS = {
    # tax_type
    "gst":                 ["gst", "gstin", "cgst", "sgst", "igst", "goods and services tax"],
    "income_tax":          ["income tax", "itr", "income-tax"],
    "corporate_tax":       ["corporate tax"],
    "composition_scheme":  ["composition scheme"],
    "qrmp":                ["qrmp"],
    "customs_duty":        ["customs duty", "customs"],
    "stamp_duty":          ["stamp duty"],
    "electricity_tax":     ["electricity tax"],
    # registration_type that are tax registrations
    "gst_reg":             ["gst registration", "gst number", "gstin"],
    "pan":                 ["pan"],
    "tan":                 ["tan"],
    # compliance_type that are tax compliances
    "gst_return":          ["gst return", "gstr"],
    "income_tax_return":   ["income tax return", "itr"],
}
PROVISION_KIND = {
    "gst": "tax_type", "income_tax": "tax_type", "corporate_tax": "tax_type",
    "composition_scheme": "tax_type", "qrmp": "tax_type", "customs_duty": "tax_type",
    "stamp_duty": "tax_type", "electricity_tax": "tax_type",
    "gst_reg": "registration", "pan": "registration", "tan": "registration",
    "gst_return": "compliance", "income_tax_return": "compliance",
}
LEVEL = {"gst": "central_state", "income_tax": "central", "corporate_tax": "central",
         "composition_scheme": "central_state", "qrmp": "central_state",
         "customs_duty": "central", "stamp_duty": "state", "electricity_tax": "state",
         "gst_reg": "central_state", "pan": "central", "tan": "central",
         "gst_return": "central_state", "income_tax_return": "central"}

def load(f): return json.load(open(os.path.join(CAT, f), encoding="utf-8"))
def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)

def word_re(term):
    return re.compile(r"(?<![A-Za-z])" + re.escape(term) + r"(?![A-Za-z])", re.I)

def main():
    common = load("common_catalog.json")["data"]
    schemes = load("scheme_catalog.json")["data"]

    vocab = {r["content"]["code"]: r for r in common
             if r["content"]["termType"] in ("tax_type", "registration_type", "compliance_type")}

    # X2 — evidence scan, explicit terms only
    evidence = {code: {"schemes": set(), "documents": []} for code in TAX_TERMS}
    for s in schemes:
        sid = s["identity"]["id"]
        docs = s["content"]["requiredDocuments"]
        elig = s["content"]["eligibility"]["narrative"].get("criteria") or ""
        for code, terms in TAX_TERMS.items():
            pats = [word_re(t) for t in terms]
            for d in docs:
                blob = " ".join(str(v) for v in [d["name"], d["description"], d["remarks"],
                                                 d["issuingAuthorityText"]] if v)
                if any(p.search(blob) for p in pats):
                    evidence[code]["schemes"].add(sid)
                    evidence[code]["documents"].append(
                        {"schemeId": sid, "documentId": d["documentId"],
                         "documentName": d["name"], "mandatory": d["mandatory"]})
            if any(p.search(elig) for p in pats):
                evidence[code]["schemes"].add(sid)

    recs, n = [], 0
    for code, terms in TAX_TERMS.items():
        v = vocab.get(code)
        if not v:
            continue
        n += 1
        tid = "TAX%06d" % n
        label = v["content"]["label"]
        kind = PROVISION_KIND[code]
        ev = evidence[code]
        sch = sorted(ev["schemes"])

        miss = [{"field": f, "reason": "No source in the uploaded documents supplies this; "
                                       "not generated"}
                for f in ("content.rates", "content.thresholds", "content.dueDates",
                          "content.deductions", "content.forms", "content.filingFrequency",
                          "content.penalties", "content.exemptions", "content.guidance")]
        if not sch:
            miss.append({"field": "content.evidencedInSchemes",
                         "reason": "No scheme in this release evidences this provision"})

        refs = [{"entityId": v["identity"]["id"], "entityType": "common_term",
                 "relationType": "classified_as", "role": None, "note": None}]
        for sid in sch:
            refs.append({"entityId": sid, "entityType": "scheme",
                         "relationType": "required_by", "role": None, "note": None})

        recs.append(OrderedDict([
            ("identity", OrderedDict([
                ("id", tid), ("entityType", "tax_provision"), ("code", code.upper()),
                ("legacyCodes", []), ("name", label), ("shortName", None),
                ("acronym", v["identity"].get("acronym")),
                ("slug", re.sub(r"[^a-z0-9]+", "-", label.lower()).strip("-")[:120]),
                ("language", "en"), ("status", "active")])),
            ("content", OrderedDict([
                ("provisionKind", kind),
                ("taxTypeId", v["identity"]["id"]),
                ("governmentLevel", LEVEL[code]),
                ("jurisdiction", {"country": "IN", "state": None, "districts": []}),
                ("administeredByIds", []),
                ("appliesToMsme", True),
                ("evidencedInSchemes", sch),
                ("evidencedInSchemesCount", len(sch)),
                ("evidencedDocuments", ev["documents"][:40]),
                ("evidencedDocumentCount", len(ev["documents"])),
                ("matchTerms", terms),
                # deliberately empty — no source supplies tax law
                ("rates", []), ("thresholds", []), ("dueDates", []), ("deductions", []),
                ("forms", []), ("filingFrequency", None), ("penalties", []),
                ("exemptions", []), ("guidance", None), ("faqs", []),
                ("description", None)])),
            ("relationships", {"references": refs}),
            ("localization", {l: {"name": label if l == "en" else None,
                                  "description": None, "guidance": None}
                              for l in ("en", "ta", "hi")}),
            ("search", {"keywords": {"en": sorted({w for w in re.findall(r"[a-z]{3,}", label.lower())}),
                                     "ta": []},
                        "aliases": {"en": sorted({t for t in terms}), "ta": []},
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
                ("notes", "Anchor record only. The uploaded sources contain no tax rates, "
                          "thresholds, due dates or guidance; none were generated."),
                ("missingFields", miss), ("disputedFields", []), ("reviewDueOn", None)])),
            ("analytics", {"popularity": None, "viewCount": None, "saveCount": None,
                           "actionCount": None, "lastAggregatedAt": None}),
            ("metadata", OrderedDict([("createdAt", AT), ("updatedAt", AT),
                                      ("catalogVersion", REL), ("schemaVersion", SV),
                                      ("recordStatus", "published"), ("revision", 1)])),
            ("provenance", OrderedDict([
                ("defaultSourceTier", 2), ("primarySourceId", None),
                ("contributingSourceIds", []), ("extractionMethod", "automated"),
                ("extractedAt", AT), ("pipelineVersion", "tax-1.0.0"),
                ("fieldSources", []),
                ("translations", OrderedDict([("ta", OrderedDict([
                    ("method", "none"), ("engine", None), ("status", "not_started"),
                    ("dictionaryVersion", None), ("generatedAt", None),
                    ("fieldMethods", {}), ("fieldsTranslated", 0), ("fieldsContextual", 0),
                    ("fieldsPending", 1), ("isApproved", False), ("reviewRequired", True),
                    ("note", "Localization deferred to a later phase; schema unchanged.")]))])),
                ("transformationNotes", [
                    f"Anchored on common_catalog term {v['identity']['id']} (rule X1)",
                    "Scheme links derived from explicit term matches in required "
                    "documents and eligibility text (rule X2)",
                    "No tax rate, threshold, due date or guidance generated (rule X3)",
                    "English only; localization.ta intentionally null (roadmap Phase 5)"])])),
        ]))

    cat = OrderedDict([
        ("metadata", OrderedDict([("catalogName", "tax"), ("schemaVersion", SV),
                                  ("catalogVersion", REL), ("generatedAt", AT),
                                  ("language", "en"), ("recordCount", len(recs)),
                                  ("checksum", "sha256:" + hashlib.sha256(canon(recs).encode()).hexdigest())])),
        ("data", recs)])
    json.dump(cat, open(os.path.join(CAT, "tax_catalog.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)

    stats = OrderedDict([
        ("generatedAt", AT), ("catalog", "tax_catalog.json"),
        ("dataSufficiency", "LOW — sources contain no tax rates, thresholds, due dates "
                            "or guidance. This catalog holds anchors and scheme linkage only."),
        ("provisions", len(recs)),
        ("byKind", dict(Counter(r["content"]["provisionKind"] for r in recs))),
        ("byLevel", dict(Counter(r["content"]["governmentLevel"] for r in recs))),
        ("provisionsWithSchemeEvidence", sum(1 for r in recs if r["content"]["evidencedInSchemesCount"])),
        ("provisionsWithNoEvidence", sum(1 for r in recs if not r["content"]["evidencedInSchemesCount"])),
        ("schemeLinksTotal", sum(r["content"]["evidencedInSchemesCount"] for r in recs)),
        ("documentEvidenceRows", sum(r["content"]["evidencedDocumentCount"] for r in recs)),
        ("ratesRecorded", 0), ("thresholdsRecorded", 0), ("dueDatesRecorded", 0),
        ("missingFieldEntries", sum(len(r["verification"]["missingFields"]) for r in recs)),
        ("tamilPopulated", 0),
        ("localizationStatus", "deferred to roadmap Phase 5"),
    ])
    json.dump(stats, open(os.path.join(CAT, "tax_statistics.json"), "w",
                          encoding="utf-8"), indent=2, ensure_ascii=False)
    for k, v in stats.items(): print(f"   {k:30} {v}")
    print()
    for r in sorted(recs, key=lambda x: -x["content"]["evidencedInSchemesCount"]):
        print(f"   {r['identity']['id']}  {r['identity']['name'][:34]:36} "
              f"{r['content']['provisionKind']:13} schemes={r['content']['evidencedInSchemesCount']}")

if __name__ == "__main__":
    main()
