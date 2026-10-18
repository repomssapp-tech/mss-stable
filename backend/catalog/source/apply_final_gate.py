# -*- coding: utf-8 -*-
"""Final Localization Release Gate -- scoped apply for the remaining real
gaps (common_catalog.json x4, enterprise_classification_catalog.json x5,
knowledge_catalog.json x18 titles only, treds_catalog.json x3 brand-name
fix). Reuses build_i18n.translate()/translate_keyword(), scoped to only
the target record+field so everything else already at 100% is left
byte-identical.
"""
import json, os, hashlib, sys
from collections import OrderedDict, Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_i18n as bi

CAT = os.path.dirname(os.path.abspath(__file__))
bi.CAT = CAT
AT = "2026-08-15T00:00:00Z"


def touch_provenance(r, methods, done, pending):
    llm = sum(1 for v in methods.values() if v == "llm_contextual_translation")
    prov = r["provenance"].setdefault("translations", OrderedDict())
    ta_prov = prov.setdefault("ta", OrderedDict([
        ("method", "dictionary"), ("engine", bi.ENGINE), ("status", "machine"),
        ("dictionaryVersion", "1.0.0"), ("generatedAt", AT),
        ("fieldMethods", {}), ("fieldsTranslated", 0), ("fieldsContextual", 0),
        ("fieldsPending", 0), ("isApproved", False), ("reviewRequired", True),
        ("note", "Machine-generated Tamil. Not an official translation; "
                 "requires review before publication."),
    ]))
    ta_prov["fieldMethods"].update(methods)
    ta_prov["fieldsTranslated"] = ta_prov.get("fieldsTranslated", 0) + done
    ta_prov["fieldsContextual"] = ta_prov.get("fieldsContextual", 0) + llm
    ta_prov["fieldsPending"] = pending
    ta_prov["generatedAt"] = AT
    ta_prov["method"] = "llm_contextual_translation" if (llm or ta_prov["method"] == "llm_contextual_translation") else ta_prov["method"]
    r["metadata"]["updatedAt"] = AT
    r["metadata"]["revision"] = r["metadata"].get("revision", 1) + 1


def apply_fields(fname, target_ids, fields=None, fix_leakage=False):
    """Translate only `fields` (or all null-en/null-ta fields if None) on
    records whose id is in target_ids. Writes the file, returns count.
    fix_leakage=True allows overwriting a ta value that is currently
    identical to en (English leakage being corrected -- not "replacing
    approved Tamil content", since a leaked English copy was never real
    Tamil content in the first place)."""
    path = os.path.join(CAT, fname)
    cat = json.load(open(path, encoding="utf-8"))
    touched = 0
    for r in cat["data"]:
        if r["identity"]["id"] not in target_ids:
            continue
        loc = r["localization"]
        methods, done, pending = {}, 0, 0
        keys = fields or list(loc["en"].keys())
        for field in keys:
            en = loc["en"].get(field)
            if not en:
                continue
            existing_ta = loc["ta"].get(field)
            if existing_ta and not (fix_leakage and existing_ta == en):
                continue  # already has real Tamil, never overwrite
            ta, meth = bi.translate(en)
            if ta and meth != "verbatim":
                loc["ta"][field] = ta
                methods[field] = meth
                done += 1
            else:
                pending += 1
        if done or pending:
            touch_provenance(r, methods, done, pending)
            touched += 1
        print(f"   {fname}:{r['identity']['id']} done={done} pending={pending}")
    cat["metadata"]["checksum"] = "sha256:" + hashlib.sha256(bi.canon(cat["data"]).encode()).hexdigest()
    json.dump(cat, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    return touched


def main():
    print("common_catalog.json (CMN000226, CMN000261, CMN000293, CMN000339 -- 'label'):")
    apply_fields("common_catalog.json",
                 {"CMN000226", "CMN000261", "CMN000293", "CMN000339"}, ["label"])

    print("enterprise_classification_catalog.json (ENTC000007-011 -- 'name'):")
    apply_fields("enterprise_classification_catalog.json",
                 {"ENTC000007", "ENTC000008", "ENTC000009", "ENTC000010", "ENTC000011"}, ["name"])

    print("knowledge_catalog.json (KNOW000001-018 -- 'title' only, NOT 'body'):")
    apply_fields("knowledge_catalog.json",
                 {f"KNOW{n:06d}" for n in range(1, 19)}, ["title"])

    print("treds_catalog.json (TDS000001-003 -- 'name' brand-name leakage fix):")
    apply_fields("treds_catalog.json", {"TDS000001", "TDS000002", "TDS000003"}, ["name"],
                 fix_leakage=True)


if __name__ == "__main__":
    main()
