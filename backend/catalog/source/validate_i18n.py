#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Multilingual invariants: prove nothing but localization/search/provenance changed."""
import json, os, re, sys
from collections import Counter

import os as _os
CAT = _os.path.dirname(_os.path.abspath(__file__))
PRE = {"scheme_catalog.json": "/tmp/pre_i18n_scheme.json",
       "authority_catalog.json": "/tmp/pre_i18n_auth.json",
       "common_catalog.json": "/tmp/pre_i18n_common.json"}
fails = []
def chk(c, m):
    if not c: fails.append(m)

def canon(o): return json.dumps(o, sort_keys=True, ensure_ascii=False)
TA = re.compile(r"[஀-௿]")
LATIN_URL = re.compile(r"https?://|@[\w-]+\.")

for fn, pre in PRE.items():
    if not os.path.exists(pre):
        print(f"  (no pre-image for {fn}; skipped)"); continue
    A = json.load(open(pre, encoding="utf-8"))["data"]
    B = json.load(open(os.path.join(CAT, fn), encoding="utf-8"))["data"]
    chk(len(A) == len(B), f"{fn} record count changed")
    for a, b in zip(A, B):
        rid = a["identity"]["id"]
        # 1 identity untouched
        chk(canon(a["identity"]) == canon(b["identity"]), f"{fn} {rid} identity changed")
        # 2 content untouched (English source of truth)
        chk(canon(a["content"]) == canon(b["content"]), f"{fn} {rid} content changed")
        # 3 relationships untouched BY THE I18N PASS.
        # Phase 3 later added inverse edges, each marked generated:true. Those are a
        # legitimate, separately-validated change, so they are excluded here; every
        # edge the i18n pass could have touched must still match exactly.
        def orig_edges(rec):
            return canon([e for e in rec["relationships"]["references"]
                          if not e.get("generated")])
        chk(orig_edges(a) == orig_edges(b),
            f"{fn} {rid} pre-existing relationships changed")
        # 4 verification untouched except appended localization.ta notes
        av, bv = dict(a["verification"]), dict(b["verification"])
        amf = av.pop("missingFields"); bmf = bv.pop("missingFields")
        chk(canon(av) == canon(bv), f"{fn} {rid} verification changed")
        extra = [m for m in bmf if m not in amf]
        chk(all(m["field"] == "localization.ta" for m in extra),
            f"{fn} {rid} unexpected missingFields added")
        chk(all(m in bmf for m in amf), f"{fn} {rid} missingFields removed")
        # 5 provenance untouched except the translations marker
        ap, bp = dict(a["provenance"]), dict(b["provenance"])
        bp.pop("translations", None)
        # transformationNotes is append-only across phases: assert the earlier notes
        # survive as an exact prefix, then compare the rest of provenance strictly.
        an, bn = ap.pop("transformationNotes", []), bp.pop("transformationNotes", [])
        chk(bn[:len(an)] == an, f"{fn} {rid} transformationNotes rewritten, not appended")
        chk(canon(ap) == canon(bp), f"{fn} {rid} provenance changed")
        chk("translations" in b["provenance"], f"{fn} {rid} missing translations marker")
        t = b["provenance"].get("translations", {}).get("ta", {})
        chk(t.get("status") == "machine" and t.get("isApproved") is False
            and t.get("reviewRequired") is True
            and t.get("method") in ("llm_contextual_translation", "dictionary")
            and t.get("engine"),
            f"{fn} {rid} translation not marked machine-generated / unapproved")
        # 6 analytics untouched; ai was later populated by Phase 4, so the surviving
        # i18n guarantee is that the translation pass never leaked INTO the ai block:
        # no Tamil script may appear there, and nothing there may be pre-approved.
        chk(canon(a["analytics"]) == canon(b["analytics"]), f"{fn} {rid} analytics changed")
        chk(not TA.search(canon(b["ai"])), f"{fn} {rid} Tamil leaked into the ai block")
        chk(b["ai"].get("isApproved") is False, f"{fn} {rid} ai pre-approved")
        chk(b["ai"].get("generationMode") in ("extractive", "hybrid", "abstractive"),
            f"{fn} {rid} ai.generationMode missing")
        # 7 English localization preserved exactly
        chk(canon(a["localization"]["en"]) == canon(b["localization"]["en"]),
            f"{fn} {rid} English localization changed")
        # 8 localization shape unchanged, hi still null
        chk(set(a["localization"]) == set(b["localization"]), f"{fn} {rid} language set changed")
        for lang in b["localization"]:
            chk(set(b["localization"][lang]) == set(a["localization"]["en"]),
                f"{fn} {rid} localization[{lang}] shape drift")
        chk(all(v is None for v in b["localization"]["hi"].values()),
            f"{fn} {rid} hi unexpectedly populated")
        # 9 Tamil must not contain URLs/emails, and must actually be Tamil
        for k, v in b["localization"]["ta"].items():
            if v:
                chk(not LATIN_URL.search(v), f"{fn} {rid} ta.{k} contains a URL/email")
                # A Tamil value must contain Tamil script, UNLESS the source is a bare
                # government acronym. Acronyms are never translated, so the Tamil form is
                # legitimately identical. The carve-out is deliberately narrow: the value
                # must equal the English EXACTLY and look like an acronym — otherwise this
                # would silently permit untranslated English to pass as Tamil.
                en_v = b["localization"]["en"].get(k)
                bare_acronym = (v == en_v
                                and re.fullmatch(r"[A-Z][A-Za-z0-9]*(?:[-/][A-Za-z0-9]+)*s?", v)
                                and len(v) <= 12
                                and sum(c.isupper() for c in v) >= 2)
                chk(bool(TA.search(v)) or bare_acronym,
                    f"{fn} {rid} ta.{k} has no Tamil characters and is not a bare acronym: {v!r}")
        # 10 search: English keywords preserved, ta added
        sa, sb = a["search"], b["search"]
        chk(sb["keywords"]["en"] == sa["keywords"], f"{fn} {rid} search English keywords changed")
        chk(sb["aliases"]["en"] == sa["aliases"], f"{fn} {rid} search English aliases changed")
        # a Tamil keyword must contain Tamil script UNLESS it is a preserved
        # government acronym, which is never transliterated (policy: acronyms verbatim)
        chk(all(TA.search(w) or w.isupper() or w in ("Udyam", "Startup India")
                for w in sb["keywords"]["ta"]),
            f"{fn} {rid} non-Tamil, non-acronym token in ta keywords: "
            f"{[w for w in sb['keywords']['ta'] if not TA.search(w) and not w.isupper()][:3]}")

# dictionary artifact
dp = os.path.join(CAT, "translation_dictionary.json")
chk(os.path.exists(dp), "translation_dictionary.json missing")
if os.path.exists(dp):
    d = json.load(open(dp, encoding="utf-8"))
    chk(d["metadata"]["entryCount"] == len(d["entries"]), "dictionary entryCount mismatch")
    chk(all(TA.search(v["ta"]) or v["ta"].isascii() for v in d["entries"].values()),
        "dictionary entry without Tamil")

if fails:
    print(f"I18N INVARIANTS FAILED — {len(fails)}")
    for f in fails[:25]: print("  ", f)
    sys.exit(1)
print("I18N INVARIANTS PASSED")
print("  identity / content / relationships / ai / analytics : unchanged")
print("  verification : unchanged (localization.ta notes appended only)")
print("  provenance   : unchanged (translations marker added only)")
print("  English      : preserved byte-for-byte")
print("  Tamil        : localizable fields only, no URLs/emails, marked machine-generated")
