#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase 2 priority 2 — finance_catalog.json.

A FINANCE PRODUCT is one financial instrument offered under one scheme:
a capital subsidy, an interest subvention, a guarantee cover, a term loan,
margin money, a grant, equity support, a reimbursement, insurance, a tax benefit.

Derivation is deterministic and additive — nothing is invented:

  F1  one FIN record per (scheme, active financial benefit slot).
      A slot qualifies only when benefits[<slot>].applicable is True.
  F2  monetary values are COPIED verbatim from the scheme record. Amounts,
      percentages, currency and the *Text fields are never recomputed,
      re-parsed or rounded.
  F3  provider = the scheme's implementing agencies, resolved to INST ids where
      an institution view exists, otherwise the AUTH id. Never guessed.
  F4  productFamily = the common_catalog benefit_type / loan_type term whose code
      matches the slot. No fuzzy matching.
  F5  anything absent on the scheme stays null here and is logged.

English only. localization.ta is null by roadmap decision; schema unchanged.
"""
import json, os, re, hashlib
from collections import OrderedDict, Counter

CAT = "/sessions/practical-charming-hypatia/mnt/Plan/catalog"
AT = "2026-08-04T00:00:00Z"
SV = "1.0.0"
REL = "1.4.0-alpha"

# slot -> (product type, vocabulary code, human label)
SLOTS = OrderedDict([
    ("capitalSubsidy",     ("capital_subsidy",     "capital_subsidy",     "Capital Subsidy")),
    ("interestSubvention", ("interest_subvention", "interest_subvention", "Interest Subvention")),
    ("marginMoney",        ("margin_money",        "margin_money",        "Margin Money")),
    ("grant",              ("grant",               "grant",               "Grant")),
    ("loan",               ("loan",                "loan",                "Loan")),
    ("guarantee",          ("credit_guarantee",    "guarantee",           "Credit Guarantee")),
    ("equitySupport",      ("equity_support",      "equity_support",      "Equity Support")),
    ("insurance",          ("insurance",           "insurance",           "Insurance")),
    ("taxBenefit",         ("tax_benefit",         "tax_benefit",         "Tax Benefit")),
    ("reimbursement",      ("reimbursement",       "reimbursement",       "Reimbursement")),
])
REPAYABLE = {"loan"}
GUARANTEE = {"guarantee"}

def load(f): return json.load(open(os.path.join(CAT, f), encoding="utf-8"))
def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)

def main():
    schemes = load("scheme_catalog.json")["data"]
    common = load("common_catalog.json")["data"]
    insts = load("institution_catalog.json")["data"]

    # F4 vocabulary index: benefit/loan type code -> CMN id
    vocab = {r["content"]["code"]: r["identity"]["id"] for r in common
             if r["content"]["termType"] in ("benefit_type", "loan_type")}
    # F3 authority -> institution view
    auth2inst = {r["content"]["authorityId"]: r["identity"]["id"] for r in insts}

    recs, n = [], 0
    skipped_no_provider = 0
    for s in schemes:
        b = s["content"]["benefits"]
        g = s["content"]["classification"]["government"]
        sid = s["identity"]["id"]
        agencies = g["implementingAgencyIds"]
        providers = [(auth2inst.get(a, a), "institution" if a in auth2inst else "authority")
                     for a in agencies]
        if not providers: skipped_no_provider += 1

        for slot, (ptype, vcode, label) in SLOTS.items():
            o = b.get(slot)
            if not isinstance(o, dict) or o.get("applicable") is not True:
                continue
            n += 1
            fid = "FIN%06d" % n
            name = f"{label} — {s['identity']['name']}"
            miss = []
            if o.get("maxAmountInr") is None and o.get("amountInr") is None:
                miss.append({"field": "content.amount.maxInr",
                             "reason": "No parseable amount on the source scheme record"})
            if o.get("percentage") is None:
                miss.append({"field": "content.amount.percentage",
                             "reason": "No percentage stated on the source scheme record"})
            if not providers:
                miss.append({"field": "content.providers",
                             "reason": "Scheme has no resolved implementing agency"})
            for f in ("content.tenure", "content.interestRate", "content.eligibilityNotes",
                      "content.applicationRoute"):
                miss.append({"field": f, "reason": "Not available in available sources"})

            refs = [{"entityId": sid, "entityType": "scheme",
                     "relationType": "offered_under", "role": None, "note": None}]
            for pid, ptypename in providers:
                refs.append({"entityId": pid, "entityType": ptypename,
                             "relationType": "provided_by", "role": None, "note": None})
            if vocab.get(vcode):
                refs.append({"entityId": vocab[vcode], "entityType": "common_term",
                             "relationType": "classified_as", "role": None, "note": None})

            content = OrderedDict([
                ("productType", ptype),
                ("productFamilyId", vocab.get(vcode)),
                ("productFamilyText", label),
                ("schemeId", sid),
                ("schemeName", s["identity"]["name"]),
                ("providers", [{"entityId": p, "entityType": t} for p, t in providers]),
                ("isRepayable", slot in REPAYABLE),
                ("isGuarantee", slot in GUARANTEE),
                # F2 — copied verbatim from the scheme, never recomputed
                ("amount", OrderedDict([
                    ("currency", b.get("currency")),
                    ("percentage", o.get("percentage")),
                    ("percentageText", o.get("percentageText")),
                    ("amountInr", o.get("amountInr")),
                    ("amountText", o.get("amountText")),
                    ("minInr", o.get("minAmountInr")),
                    ("minText", o.get("minAmountText")),
                    ("maxInr", o.get("maxAmountInr")),
                    ("maxText", o.get("maxAmountText")),
                    ("basis", o.get("basis")),
                    ("varies", o.get("varies")),
                    ("variesBy", o.get("variesBy"))])),
                ("tenure", OrderedDict([
                    ("durationMonths", o.get("durationMonths")),
                    ("tenureMonths", o.get("tenureMonths")),
                    ("moratoriumMonths", o.get("moratoriumMonths"))])),
                ("interestRate", OrderedDict([
                    ("percent", o.get("interestRatePercent")),
                    ("text", o.get("interestRateText"))])),
                ("collateralRequired", o.get("collateralRequired")),
                ("coveragePercent", o.get("coveragePercent")),
                ("maxCoverInr", o.get("maxCoverInr")),
                ("feePercent", o.get("feePercent")),
                ("disbursement", b.get("disbursement")),
                ("conditions", o.get("conditions") or []),
                ("description", o.get("description")),
                ("eligibilityNotes", None),
                ("applicationRoute", s["content"]["applicationProcess"].get("mode")),
                ("applicationUrl", s["content"]["applicationProcess"].get("onlineUrl")),
            ])

            recs.append(OrderedDict([
                ("identity", OrderedDict([
                    ("id", fid), ("entityType", "finance_product"),
                    ("code", f"{s['identity']['code']}-{ptype.upper()[:6]}"),
                    ("legacyCodes", []), ("name", name),
                    ("shortName", label), ("acronym", None),
                    ("slug", re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")[:120]),
                    ("language", "en"), ("status", s["identity"]["status"])])),
                ("content", content),
                ("relationships", {"references": refs}),
                ("localization", {l: {"name": name if l == "en" else None,
                                      "description": (o.get("description") if l == "en" else None),
                                      "conditions": None} for l in ("en", "ta", "hi")}),
                ("search", {"keywords": {"en": sorted({w for w in re.findall(r"[a-z]{3,}",
                                                       (name + " " + label).lower())}), "ta": []},
                            "aliases": {"en": [label], "ta": []},
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
                    ("notes", "Derived from the parent scheme's benefit record; "
                              "monetary values copied verbatim, never recomputed"),
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
                    ("pipelineVersion", "finance-1.0.0"), ("fieldSources", []),
                    ("translations", OrderedDict([("ta", OrderedDict([
                        ("method", "none"), ("engine", None), ("status", "not_started"),
                        ("dictionaryVersion", None), ("generatedAt", None),
                        ("fieldMethods", {}), ("fieldsTranslated", 0),
                        ("fieldsContextual", 0), ("fieldsPending", 1),
                        ("isApproved", False), ("reviewRequired", True),
                        ("note", "Localization deferred to a later phase; schema unchanged.")]))])),
                    ("transformationNotes", [
                        f"Derived from {sid} benefits.{slot} (rule F1)",
                        "Monetary values copied verbatim from the scheme (rule F2)",
                        "English only; localization.ta intentionally null (roadmap Phase 5)"])])),
            ]))

    cat = OrderedDict([
        ("metadata", OrderedDict([("catalogName", "finance"), ("schemaVersion", SV),
                                  ("catalogVersion", REL), ("generatedAt", AT),
                                  ("language", "en"), ("recordCount", len(recs)),
                                  ("checksum", "sha256:" + hashlib.sha256(canon(recs).encode()).hexdigest())])),
        ("data", recs)])
    json.dump(cat, open(os.path.join(CAT, "finance_catalog.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)

    # ---- integrity: every amount must equal its source scheme value
    byid = {s["identity"]["id"]: s for s in schemes}
    drift = []
    for r in recs:
        src = byid[r["content"]["schemeId"]]["content"]["benefits"]
        slot = next(k for k, v in SLOTS.items() if v[0] == r["content"]["productType"])
        o = src[slot]
        a = r["content"]["amount"]
        if (a["percentage"], a["maxInr"], a["amountInr"]) != \
           (o.get("percentage"), o.get("maxAmountInr"), o.get("amountInr")):
            drift.append(r["identity"]["id"])

    stats = OrderedDict([
        ("generatedAt", AT), ("catalog", "finance_catalog.json"),
        ("schemesScanned", len(schemes)),
        ("schemesWithFinancialBenefit", len({r["content"]["schemeId"] for r in recs})),
        ("financeProducts", len(recs)),
        ("byType", dict(Counter(r["content"]["productType"] for r in recs))),
        ("withAmountOrPercentage", sum(1 for r in recs
                                       if r["content"]["amount"]["maxInr"] is not None
                                       or r["content"]["amount"]["percentage"] is not None)),
        ("withProvider", sum(1 for r in recs if r["content"]["providers"])),
        ("schemesWithoutProvider", skipped_no_provider),
        ("classifiedToVocabulary", sum(1 for r in recs if r["content"]["productFamilyId"])),
        ("repayableProducts", sum(1 for r in recs if r["content"]["isRepayable"])),
        ("guaranteeProducts", sum(1 for r in recs if r["content"]["isGuarantee"])),
        ("amountDrift", len(drift)),
        ("tamilPopulated", 0),
        ("localizationStatus", "deferred to roadmap Phase 5"),
    ])
    json.dump(stats, open(os.path.join(CAT, "finance_statistics.json"), "w",
                          encoding="utf-8"), indent=2, ensure_ascii=False)
    for k, v in stats.items(): print(f"   {k:32} {v}")
    if drift:
        print("   AMOUNT DRIFT DETECTED:", drift[:5]); raise SystemExit(1)

if __name__ == "__main__":
    main()
