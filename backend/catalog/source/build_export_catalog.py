#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase 2 priority 5 — export_catalog.json.

An EXPORT BENEFIT is an export-facing instrument evidenced by a scheme:
a duty exemption, a capital-goods authorisation, market-promotion assistance,
interest equalisation, a certification subsidy or an exporter recognition.

Rules:
  E1  a scheme qualifies when its identity/overview/benefits/eligibility text
      matches an explicit export term list. No fuzzy matching, no inference.
  E2  one EXP record per qualifying scheme.
  E3  instrument type is assigned from explicit term evidence only; where no
      term is decisive the type is "export_assistance" (the generic parent),
      never a guess at a narrower one.
  E4  monetary values are COPIED from the scheme's benefit record, verbatim.
  E5  duty rates, export-obligation ratios, SION norms and validity periods are
      NOT in any source -> null + logged. Nothing about trade policy is generated.

English only. localization.ta null by roadmap decision; schema unchanged.
"""
import json, os, re, hashlib
from collections import OrderedDict, Counter

CAT = "/sessions/practical-charming-hypatia/mnt/Plan/catalog"
AT = "2026-08-04T00:00:00Z"
SV = "1.0.0"
REL = "1.7.0-alpha"

# E1 — explicit qualifying terms
EXPORT_TERMS = [
    "dgft", "iec", "epcg", "advance authorisation", "duty free import", "dfia",
    "deemed export", "sion", "export obligation", "interest equalisation",
    "shipping bill", "fob", "merchant exporter", "manufacturer exporter",
    "export promotion", "export market", "trade fair", "international exhibition",
    "export credit", "ecgc", "foreign trade policy", "ftp", "exporter",
    "status holder", "business samples abroad", "spice brands abroad",
]
# E3 — instrument typing, most specific first
TYPE_RULES = [
    ("duty_exemption",        ["advance authorisation", "duty free import", "dfia",
                               "duty exemption", "deemed export"]),
    ("capital_goods_scheme",  ["epcg", "export promotion capital goods"]),
    ("interest_equalisation", ["interest equalisation"]),
    ("exporter_recognition",  ["status holder"]),
    ("certification_support", ["certificate of registration", "food safety",
                               "quality assurance", "testing devices"]),
    ("market_promotion",      ["trade fair", "international exhibition", "market promotion",
                               "brands abroad", "business samples", "business exploration",
                               "export market"]),
    ("research_support",      ["product research"]),
]
FIN_SLOTS = ["capitalSubsidy", "grant", "reimbursement", "interestSubvention",
             "loan", "guarantee", "taxBenefit"]

def load(f): return json.load(open(os.path.join(CAT, f), encoding="utf-8"))
def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
def wre(t): return re.compile(r"(?<![A-Za-z])" + re.escape(t) + r"(?![A-Za-z])", re.I)

TERM_RE = [(t, wre(t)) for t in EXPORT_TERMS]

def main():
    schemes = load("scheme_catalog.json")["data"]
    finance = load("finance_catalog.json")["data"]
    fin_by_scheme = {}
    for f in finance:
        fin_by_scheme.setdefault(f["content"]["schemeId"], []).append(f["identity"]["id"])

    recs, n = [], 0
    for s in schemes:
        c = s["content"]
        blob = " ".join(str(x) for x in [
            s["identity"]["name"], c["overview"].get("summary"),
            c["benefits"].get("summary"), c["eligibility"]["narrative"].get("criteria"),
            c["classification"].get("sectorsText")] if x)
        matched = [t for t, p in TERM_RE if p.search(blob)]
        if not matched:
            continue
        n += 1
        eid = "EXP%06d" % n
        low = blob.lower()
        itype = next((k for k, keys in TYPE_RULES if any(x in low for x in keys)),
                     "export_assistance")

        # E4 — copy money verbatim from the scheme's active benefit slot, if any
        money, slot_used = None, None
        for slot in FIN_SLOTS:
            o = c["benefits"].get(slot)
            if isinstance(o, dict) and o.get("applicable") is True:
                slot_used = slot
                money = OrderedDict([
                    ("currency", c["benefits"].get("currency")),
                    ("percentage", o.get("percentage")), ("percentageText", o.get("percentageText")),
                    ("amountInr", o.get("amountInr")), ("amountText", o.get("amountText")),
                    ("maxInr", o.get("maxAmountInr")), ("maxText", o.get("maxAmountText")),
                    ("varies", o.get("varies")), ("variesBy", o.get("variesBy"))])
                break

        g = c["classification"]["government"]
        refs = [{"entityId": s["identity"]["id"], "entityType": "scheme",
                 "relationType": "evidenced_by", "role": None, "note": None}]
        for aid in [g["ministryId"], g["departmentId"]] + g["implementingAgencyIds"]:
            if aid:
                refs.append({"entityId": aid, "entityType": "authority",
                             "relationType": "administered_by", "role": None, "note": None})
        for fid in fin_by_scheme.get(s["identity"]["id"], []):
            refs.append({"entityId": fid, "entityType": "finance_product",
                         "relationType": "related_to", "role": None, "note": None})

        miss = [{"field": f, "reason": "Not available in available sources; trade-policy "
                                       "detail is not generated"}
                for f in ("content.dutyRate", "content.exportObligationRatio",
                          "content.sionNorm", "content.validityPeriod",
                          "content.eligibleProducts", "content.claimProcedure",
                          "content.guidance")]
        if money is None:
            miss.append({"field": "content.assistance",
                         "reason": "Parent scheme records no active financial benefit"})

        content = OrderedDict([
            ("instrumentType", itype),
            ("schemeId", s["identity"]["id"]),
            ("schemeName", s["identity"]["name"]),
            ("matchedTerms", sorted(set(matched))),
            ("governmentLevel", g["level"]),
            ("jurisdiction", {"country": "IN", "states": g["states"], "districts": []}),
            ("administeredByText", g["ministryText"] or g["departmentText"]),
            ("implementingAgencyText", g["implementingAgencyText"]),
            ("beneficiaryText", c["targetBeneficiaries"].get("description")),
            ("assistance", money), ("assistanceSourceSlot", slot_used),
            ("relatedFinanceProductIds", fin_by_scheme.get(s["identity"]["id"], [])),
            ("applicationMode", c["applicationProcess"].get("mode")),
            ("applicationUrl", c["applicationProcess"].get("onlineUrl")),
            ("summary", c["overview"].get("summary")),
            ("eligibilityText", c["eligibility"]["narrative"].get("criteria")),
            # E5 — deliberately empty
            ("dutyRate", None), ("exportObligationRatio", None), ("sionNorm", None),
            ("validityPeriod", None), ("eligibleProducts", []), ("claimProcedure", None),
            ("guidance", None), ("faqs", []),
        ])

        name = s["identity"]["name"]
        recs.append(OrderedDict([
            ("identity", OrderedDict([
                ("id", eid), ("entityType", "export_benefit"),
                ("code", s["identity"]["code"]), ("legacyCodes", []),
                ("name", name), ("shortName", s["identity"]["shortName"]),
                ("acronym", s["identity"]["acronym"]),
                ("slug", re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")[:120]),
                ("language", "en"), ("status", s["identity"]["status"])])),
            ("content", content),
            ("relationships", {"references": refs}),
            ("localization", {l: {"name": name if l == "en" else None,
                                  "summary": (content["summary"] if l == "en" else None),
                                  "eligibilityText": (content["eligibilityText"] if l == "en" else None),
                                  "guidance": None} for l in ("en", "ta", "hi")}),
            ("search", {"keywords": {"en": sorted({w for w in re.findall(r"[a-z]{4,}", name.lower())}),
                                     "ta": []},
                        "aliases": {"en": sorted(set(matched)), "ta": []},
                        "synonyms": [], "crossReferences": [], "searchRank": None,
                        "boostTerms": []}),
            ("ai", OrderedDict([("summary", None), ("sectionSummaries", {}),
                                ("generationMode", "extractive"), ("confidence", None),
                                ("generatedBy", None), ("generatedAt", None),
                                ("sourceFieldsUsed", []), ("reviewedBy", None),
                                ("reviewedAt", None), ("isApproved", False)])),
            ("verification", OrderedDict([
                ("status", s["verification"]["status"]),
                ("statusText", s["verification"]["statusText"]),
                ("isVerified", s["verification"]["isVerified"]),
                ("verifiedAgainst", []), ("verifiedBy", None), ("verifiedAt", None),
                ("confidence", s["verification"]["confidence"]),
                ("researchStatus", s["verification"]["researchStatus"]),
                ("notes", "Export view of an existing scheme. Trade-policy specifics "
                          "(duty rates, export obligation, SION) are absent from all "
                          "sources and were not generated."),
                ("missingFields", miss), ("disputedFields", []), ("reviewDueOn", None)])),
            ("analytics", {"popularity": None, "viewCount": None, "saveCount": None,
                           "actionCount": None, "lastAggregatedAt": None}),
            ("metadata", OrderedDict([("createdAt", AT), ("updatedAt", AT),
                                      ("catalogVersion", REL), ("schemaVersion", SV),
                                      ("recordStatus", "published"), ("revision", 1)])),
            ("provenance", OrderedDict([
                ("defaultSourceTier", s["provenance"]["defaultSourceTier"]),
                ("primarySourceId", s["provenance"]["primarySourceId"]),
                ("contributingSourceIds", s["provenance"]["contributingSourceIds"]),
                ("extractionMethod", "automated"), ("extractedAt", AT),
                ("pipelineVersion", "export-1.0.0"), ("fieldSources", []),
                ("translations", OrderedDict([("ta", OrderedDict([
                    ("method", "none"), ("engine", None), ("status", "not_started"),
                    ("dictionaryVersion", None), ("generatedAt", None), ("fieldMethods", {}),
                    ("fieldsTranslated", 0), ("fieldsContextual", 0), ("fieldsPending", 1),
                    ("isApproved", False), ("reviewRequired", True),
                    ("note", "Localization deferred to a later phase; schema unchanged.")]))])),
                ("transformationNotes", [
                    f"Qualified by explicit export terms {sorted(set(matched))[:5]} (rule E1)",
                    f"Instrument type '{itype}' from explicit term evidence (rule E3)",
                    "Monetary values copied verbatim from the parent scheme (rule E4)",
                    "Trade-policy detail not generated (rule E5)",
                    "English only; localization.ta intentionally null (roadmap Phase 5)"])])),
        ]))

    cat = OrderedDict([
        ("metadata", OrderedDict([("catalogName", "export"), ("schemaVersion", SV),
                                  ("catalogVersion", REL), ("generatedAt", AT),
                                  ("language", "en"), ("recordCount", len(recs)),
                                  ("checksum", "sha256:" + hashlib.sha256(canon(recs).encode()).hexdigest())])),
        ("data", recs)])
    json.dump(cat, open(os.path.join(CAT, "export_catalog.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)

    # integrity: money must equal the source scheme slot
    byid = {s["identity"]["id"]: s for s in schemes}
    drift = []
    for r in recs:
        slot = r["content"]["assistanceSourceSlot"]
        if not slot: continue
        o = byid[r["content"]["schemeId"]]["content"]["benefits"][slot]
        a = r["content"]["assistance"]
        if (a["percentage"], a["maxInr"]) != (o.get("percentage"), o.get("maxAmountInr")):
            drift.append(r["identity"]["id"])

    stats = OrderedDict([
        ("generatedAt", AT), ("catalog", "export_catalog.json"),
        ("dataSufficiency", "MODERATE — named instruments and scheme linkage are present; "
                            "duty rates, export-obligation ratios, SION norms and validity "
                            "periods are absent from all sources and were not generated."),
        ("schemesScanned", len(schemes)), ("exportBenefits", len(recs)),
        ("byInstrumentType", dict(Counter(r["content"]["instrumentType"] for r in recs))),
        ("withAssistanceFigures", sum(1 for r in recs if r["content"]["assistance"])),
        ("withFinanceProductLink", sum(1 for r in recs if r["content"]["relatedFinanceProductIds"])),
        ("withAuthorityLink", sum(1 for r in recs
                                  if any(x["entityType"] == "authority"
                                         for x in r["relationships"]["references"]))),
        ("dutyRatesRecorded", 0), ("exportObligationsRecorded", 0),
        ("assistanceDrift", len(drift)),
        ("missingFieldEntries", sum(len(r["verification"]["missingFields"]) for r in recs)),
        ("tamilPopulated", 0), ("localizationStatus", "deferred to roadmap Phase 5"),
    ])
    json.dump(stats, open(os.path.join(CAT, "export_statistics.json"), "w",
                          encoding="utf-8"), indent=2, ensure_ascii=False)
    for k, v in stats.items(): print(f"   {k:26} {v}")
    if drift:
        print("   DRIFT:", drift[:5]); raise SystemExit(1)

if __name__ == "__main__":
    main()
