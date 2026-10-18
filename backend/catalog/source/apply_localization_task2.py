# -*- coding: utf-8 -*-
"""Tamil Localization Completion Phase, Task 2 -- finance_catalog.json
product names.

Root cause (see LOCALIZATION_DATA_COMPLETENESS_REPORT.md): every
localization.en.name value in finance_catalog.json follows the exact
pattern "{productFamilyText} — {schemeName}" (confirmed 115/115).
translate()'s pattern set has no "A — B" rule, so the whole string
fell to `pending` even though both halves are independently
translatable: the family term (Capital Subsidy, Loan, Grant, ...) is
already a dictionary hit, and the scheme half is -- for every single
record -- the exact same string already localized in
scheme_catalog.json[schemeId].localization.ta.name (confirmed 115/115
resolve, 0 missing, in the Part 2A audit).

This is a compositional, dictionary-first fix, not a one-off: reuse
already-verified Tamil (the family term dictionary + the scheme's own
already-generated Tamil name) rather than authoring 115 new translations
by hand. Only content.localization.ta.name is touched -- description was
already 100% covered and is left untouched.

Terms translated: productName (this script), financeType/assistanceType/
loanType/category labels -- already served via each record's
productFamilyId -> common_catalog.json cross-reference (100% Tamil per
Part 2A audit); no new field is added, since finance_catalog.json's
schema has no slot for these outside the family reference (schema not
changed, per instruction).
"""
import json, os, hashlib, sys
from collections import OrderedDict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_i18n as bi

CAT = os.path.dirname(os.path.abspath(__file__))
AT = "2026-08-15T00:00:00Z"


def main():
    fin_path = os.path.join(CAT, "finance_catalog.json")
    sch_path = os.path.join(CAT, "scheme_catalog.json")
    fin = json.load(open(fin_path, encoding="utf-8"))
    sch = json.load(open(sch_path, encoding="utf-8"))["data"]
    sch_ta_name = {r["identity"]["id"]: r["localization"]["ta"].get("name") for r in sch}

    done, skipped, no_scheme_ta = 0, 0, []
    for r in fin["data"]:
        loc = r["localization"]
        if loc["ta"].get("name"):
            skipped += 1  # already has one, leave it -- never overwrite
            continue
        family_en = r["content"].get("productFamilyText")
        scheme_id = r["content"].get("schemeId")
        family_ta, method = bi.translate(family_en) if family_en else (None, "pending")
        scheme_ta = sch_ta_name.get(scheme_id)
        if not (family_ta and scheme_ta):
            no_scheme_ta.append(r["identity"]["id"])
            continue
        loc["ta"]["name"] = f"{family_ta} — {scheme_ta}"

        prov = r["provenance"].setdefault("translations", OrderedDict())
        ta_prov = prov.setdefault("ta", OrderedDict([
            ("method", "dictionary"), ("engine", bi.ENGINE), ("status", "machine"),
            ("dictionaryVersion", "1.0.0"), ("generatedAt", AT),
            ("fieldMethods", {}), ("fieldsTranslated", 0), ("fieldsContextual", 0),
            ("fieldsPending", 0), ("isApproved", False), ("reviewRequired", True),
            ("note", "Machine-generated Tamil. Not an official translation; "
                     "requires review before publication."),
        ]))
        ta_prov["fieldMethods"]["name"] = "compositional (dictionary family term + " \
            "scheme_catalog.json's own already-translated scheme name)"
        ta_prov["fieldsTranslated"] = ta_prov.get("fieldsTranslated", 0) + 1
        ta_prov["generatedAt"] = AT

        r["verification"]["missingFields"] = [
            m for m in r["verification"]["missingFields"] if m["field"] != "localization.ta.name"]
        r["metadata"]["updatedAt"] = AT
        r["metadata"]["revision"] = r["metadata"]["revision"] + 1
        done += 1

    fin["metadata"]["checksum"] = "sha256:" + hashlib.sha256(
        bi.canon(fin["data"]).encode()).hexdigest()
    json.dump(fin, open(fin_path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)

    print(f"finance_catalog.json: {done} product names localized, {skipped} already had one, "
          f"{len(no_scheme_ta)} could not resolve (missing family/scheme Tamil)")
    if no_scheme_ta:
        print("   unresolved:", no_scheme_ta[:10])


if __name__ == "__main__":
    main()
