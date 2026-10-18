#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Final Localization Release Gate -- Part 1/2 audit. READ-ONLY.
Full coverage audit + "English leaked into Tamil" (ta == en) detection
across all 13 named catalogs.
"""
import json, os, re
from collections import Counter, OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))
TA_RE = re.compile(r"[஀-௿]")

import sys
sys.path.insert(0, CAT)
from ta_dictionary import ACRONYMS
ACRONYM_SET = {a.upper() for a in ACRONYMS}

CATALOGS = [
    "scheme_catalog.json", "finance_catalog.json", "tax_catalog.json",
    "cluster_assistance_catalog.json", "csr_catalog.json", "treds_catalog.json",
    "msme_privilege_catalog.json", "business_enablement_catalog.json",
    "authority_catalog.json", "institution_catalog.json", "common_catalog.json",
    "enterprise_classification_catalog.json", "knowledge_catalog.json",
]

def load(f):
    return json.load(open(os.path.join(CAT, f), encoding="utf-8"))

def is_bare_acronym(v):
    """Same rule validate_i18n.py rule 9 already uses and the whole catalog
    already passes: a bare all-letter-ish short code (<=12 chars, >=2
    uppercase) is a legitimate acronym/scheme-shortcode round-trip, not
    English prose leaking into a Tamil field. Reused verbatim (not
    reinvented) so this audit can't disagree with the validator that
    actually gates the catalog."""
    return bool(re.fullmatch(r"[A-Z][A-Za-z0-9]*(?:[-/][A-Za-z0-9]+)*s?", v)) \
        and len(v) <= 12 and sum(c.isupper() for c in v) >= 2

report = OrderedDict()
leakage = []
missing_examples = {}

for fname in CATALOGS:
    path = os.path.join(CAT, fname)
    if not os.path.exists(path):
        report[fname] = "NOT FOUND"
        continue
    cat = load(fname)
    data = cat["data"]
    field_stat = Counter()
    for r in data:
        loc = r.get("localization", {})
        en = loc.get("en", {}) or {}
        ta = loc.get("ta", {}) or {}
        for k, ev in en.items():
            if not ev:
                field_stat[f"{k}:NOT_APPLICABLE"] += 1
                continue
            tv = ta.get(k)
            if not tv:
                field_stat[f"{k}:MISSING_TAMIL"] += 1
                missing_examples.setdefault((fname, k), []).append(r["identity"]["id"])
                continue
            # A Tamil value equal to English (or with no Tamil script at all)
            # is legitimate ONLY when the English source is itself a bare
            # acronym/short-code that is genuinely acronym-identical in
            # Tamil (e.g. shortName="CGTMSE"). Anything else with no Tamil
            # script present is English leakage into a Tamil field.
            if is_bare_acronym(ev) and tv.upper() == ev.upper():
                field_stat[f"{k}:AVAILABLE_TAMIL(acronym)"] += 1
                continue
            if not TA_RE.search(tv):
                field_stat[f"{k}:LEAKAGE"] += 1
                leakage.append((fname, r["identity"]["id"], k, tv))
                continue
            field_stat[f"{k}:AVAILABLE_TAMIL"] += 1
    report[fname] = {"records": len(data), "fieldStat": dict(field_stat)}

print("=== LEAKAGE (ta populated but == en, or ta has no Tamil script, excluding bare acronyms) ===")
print(f"total leakage cases: {len(leakage)}")
for x in leakage[:40]:
    print("  ", x)

print("\n=== MISSING_TAMIL FIELD COUNTS BY CATALOG ===")
for fname, r in report.items():
    if isinstance(r, str):
        continue
    missing = {k: v for k, v in r["fieldStat"].items() if k.endswith(":MISSING_TAMIL")}
    if missing:
        print(fname, missing)

json.dump({"report": report, "leakageCount": len(leakage), "leakage": leakage[:200],
           "missingExamples": {f"{k[0]}::{k[1]}": v[:5] for k, v in missing_examples.items()}},
          open(os.path.join(CAT, "audit_final_gate.json"), "w", encoding="utf-8"),
          indent=2, ensure_ascii=False)
print("\nwritten: audit_final_gate.json")
