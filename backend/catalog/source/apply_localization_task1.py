# -*- coding: utf-8 -*-
"""Tamil Localization Completion Phase, Task 1 -- localize SCH000218 and
SCH000219 only. Reuses build_i18n.translate()/translate_keyword() (the
existing pipeline) but scopes the write to these 2 records so the other
217 already-localized schemes are not touched (no revision bump, no
checksum churn) -- mirrors localize_ta_d3.py's own precedent of scoping
build_i18n's engine to a specific record set rather than rewriting
everything build_i18n.upgrade() would otherwise touch.
"""
import json, os, hashlib, sys
from collections import OrderedDict, Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_i18n as bi

CAT = os.path.dirname(os.path.abspath(__file__))
bi.CAT = CAT
AT = "2026-08-15T00:00:00Z"
TARGET_IDS = {"SCH000218", "SCH000219"}


def localize_record(r, stat):
    loc = r["localization"]
    methods, done, pending = {}, 0, 0
    for field, en in loc["en"].items():
        if not en:
            loc["ta"][field] = None
            continue
        ta, meth = bi.translate(en)
        if ta and meth != "verbatim":
            loc["ta"][field] = ta
            methods[field] = meth
            done += 1
            stat[f"scheme:{meth}"] += 1
        else:
            loc["ta"][field] = None
            pending += 1
            stat["scheme:pending"] += 1

    s = r["search"]
    if isinstance(s["keywords"], list):
        en_kw = s["keywords"]
        ta_kw = [t for t in (bi.translate_keyword(w) for w in en_kw) if t]
        s["keywords"] = {"en": en_kw, "ta": sorted(set(ta_kw))}
        en_al = s["aliases"]
        s["aliases"] = {"en": en_al, "ta": []}
        stat["scheme:kwTa"] += len(ta_kw)
    elif isinstance(s.get("keywords"), dict):
        en_kw = s["keywords"].get("en", [])
        ta_kw = [t for t in (bi.translate_keyword(w) for w in en_kw) if t]
        s["keywords"]["ta"] = sorted(set(ta_kw))
        stat["scheme:kwTa"] += len(ta_kw)

    llm = sum(1 for v in methods.values() if v == "llm_contextual_translation")
    r["provenance"]["translations"] = OrderedDict([
        ("ta", OrderedDict([
            ("method", "llm_contextual_translation" if llm else "dictionary"),
            ("engine", "Claude" if llm else bi.ENGINE),
            ("status", "machine"),
            ("dictionaryVersion", "1.0.0"), ("generatedAt", AT),
            ("fieldMethods", methods),
            ("fieldsTranslated", done),
            ("fieldsContextual", llm),
            ("fieldsPending", pending),
            ("isApproved", False),
            ("reviewRequired", True),
            ("note", "Machine-generated Tamil. Not an official translation; "
                     "requires review before publication.")]))])
    r["verification"]["missingFields"] = [
        m for m in r["verification"]["missingFields"] if m["field"] != "localization.ta"]
    if pending:
        r["verification"]["missingFields"].append({
            "field": "localization.ta",
            "reason": f"{pending} localizable field(s) have no confident Tamil "
                      f"rendering from the dictionary; not machine-guessed"})
    r["metadata"]["updatedAt"] = AT
    r["metadata"]["revision"] = r["metadata"]["revision"] + 1
    return done, pending


def main():
    stat = Counter()
    path = os.path.join(CAT, "scheme_catalog.json")
    cat = json.load(open(path, encoding="utf-8"))
    touched = 0
    for r in cat["data"]:
        if r["identity"]["id"] in TARGET_IDS:
            done, pending = localize_record(r, stat)
            touched += 1
            print(f"{r['identity']['id']}: translated={done} pending={pending}")
    assert touched == len(TARGET_IDS), f"expected {len(TARGET_IDS)} records, touched {touched}"

    cat["metadata"]["checksum"] = "sha256:" + hashlib.sha256(
        bi.canon(cat["data"]).encode()).hexdigest()
    json.dump(cat, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)

    for k in sorted(stat):
        print(f"   {k:28} {stat[k]}")
    print("scheme_catalog.json rewritten (only SCH000218/SCH000219 content changed;"
          " other 217 records byte-identical -- verified by caller)")


if __name__ == "__main__":
    main()
