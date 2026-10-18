#!/usr/bin/env python3
"""Base Entity Model validator — rules 1-30, any catalog, any entityType."""
import json, re, hashlib, os, sys
from collections import Counter

CAT = os.path.dirname(os.path.abspath(__file__))
BLOCKS = ["identity","content","relationships","localization","search","ai",
          "verification","analytics","metadata","provenance"]
STATUS = {"active","inactive","upcoming","suspended","closed","superseded","unknown"}
VSTATUS = {"verified","partially_verified","unverified","disputed","historical","derived"}
PREFIX = {"scheme":"SCH","authority":"AUTH","institution":"INST","finance_product":"FIN",
          "tax_provision":"TAX","treds_platform":"TDS","csr_provision":"CSR",
          "export_benefit":"EXP","knowledge_item":"KNOW","common_term":"CMN",
          "applicability_matrix":"APLM","enterprise_classification":"ENTC",
          "business_enablement":"ENAB","msme_privilege":"PRIV","cluster_assistance":"CLUS"}
MD = ["catalogName","schemaVersion","catalogVersion","generatedAt","language","recordCount","checksum"]

def validate(path):
    fails = []
    def chk(n, cond, msg):
        if not cond: fails.append(f"[{n}] {msg}")
    def hook(pairs):
        ks=[k for k,_ in pairs]
        d=[k for k,c in Counter(ks).items() if c>1]
        if d: fails.append(f"[1] duplicate keys {d}")
        return dict(pairs)
    cat = json.loads(open(path, encoding="utf-8").read(), object_pairs_hook=hook)
    data = cat["data"]
    chk(2, set(cat)=={"metadata","data"}, "root keys")
    chk(3, set(cat["metadata"])==set(MD), "envelope metadata keys")
    chk(3, cat["metadata"]["recordCount"]==len(data), "recordCount mismatch")
    ids, slugs = [], Counter()
    for r in data:
        i = r["identity"]; rid = i.get("id","?"); et = i.get("entityType")
        chk(4, et in PREFIX, f"{rid} unknown entityType {et}")
        if et in PREFIX:
            chk(4, bool(re.fullmatch(PREFIX[et]+r"\d{6}", i["id"])), f"{rid} id/prefix vs {et}")
        chk(7, isinstance(i["name"],str) and i["name"].strip(), f"{rid} empty name")
        chk(8, i["status"] in STATUS, f"{rid} status {i['status']}")
        ids.append(i["id"]); slugs[(et, i["slug"])] += 1
        chk(9, list(r)==BLOCKS, f"{rid} block order")
        chk(11, isinstance(r["content"], dict), f"{rid} content not object")
        chk(11, not (set(r["content"]) & set(BLOCKS)), f"{rid} content redefines base name")
        for ref in r["relationships"]["references"]:
            chk(12, bool(re.fullmatch(r"(SCH|AUTH|INST|FIN|TAX|TDS|CSR|EXP|KNOW|CMN)\d{6}",
                                      ref["entityId"])), f"{rid} ref id")
            chk(13, ref["entityId"].startswith(PREFIX.get(ref["entityType"],"@")),
                f"{rid} ref prefix vs entityType")
        def walk(o, p=""):
            if isinstance(o, dict):
                for k,v in o.items(): walk(v, f"{p}.{k}")
            elif isinstance(o, list):
                for n,v in enumerate(o): walk(v, f"{p}[{n}]")
            else:
                if o == "": fails.append(f"[16] {rid}{p} empty string")
                if p.endswith("Inr") and o is not None and not (isinstance(o,int) and o>=0):
                    fails.append(f"[18] {rid}{p}={o!r}")
        walk(r)
        chk(19, r["metadata"]["createdAt"] <= r["metadata"]["updatedAt"], f"{rid} dates")
        ai = r["ai"]
        chk(20, ai["confidence"] is None or 0.0<=ai["confidence"]<=1.0, f"{rid} ai.confidence")
        if ai["summary"] or ai["sectionSummaries"]:
            chk(21, all(ai[k] for k in ("generationMode","generatedBy","generatedAt")),
                f"{rid} ai unattributed")
        v = r["verification"]
        chk(17, v["status"] in VSTATUS, f"{rid} verification.status")
        for lang, obj in r["localization"].items():
            chk(23, bool(re.fullmatch(r"[a-z]{2}(-[A-Za-z0-9]+)*", lang)), f"{rid} lang {lang}")
        shapes = {frozenset(o) for o in r["localization"].values()}
        chk(23, len(shapes)==1, f"{rid} localization shapes differ")
        p = r["provenance"]
        chk(25, isinstance(p["defaultSourceTier"],int) and 1<=p["defaultSourceTier"]<=5,
            f"{rid} defaultSourceTier")
        for fs in p["fieldSources"]:
            chk(30, 1<=fs["sourceTier"]<=5, f"{rid} tier6 forbidden")
            chk(29, fs["supersededValue"] is None, f"{rid} overwrite detected")
            if fs["sourceTier"]==5:
                chk(27, fs["url"] and fs["retrievedAt"], f"{rid} tier5 uncited")
    chk(5, len(ids)==len(set(ids)), "duplicate ids")
    chk(7, all(c==1 for c in slugs.values()),
        f"duplicate slugs {[k for k,c in slugs.items() if c>1][:4]}")
    def canon(o): return json.dumps(o, sort_keys=True, separators=(",",":"), ensure_ascii=False)
    chk(24, "sha256:"+hashlib.sha256(canon(data).encode()).hexdigest()==cat["metadata"]["checksum"],
        "checksum")
    return cat, fails

if __name__ == "__main__":
    targets = sys.argv[1:] or [f for f in sorted(os.listdir(CAT)) if f.endswith("_catalog.json")]
    total = 0
    for t in targets:
        p = t if os.path.sep in t else os.path.join(CAT, t)
        cat, fails = validate(p)
        et = Counter(r["identity"]["entityType"] for r in cat["data"])
        print(f"{os.path.basename(p):26} records={cat['metadata']['recordCount']:>5}  "
              f"types={dict(et)}  {'FAIL '+str(len(fails)) if fails else 'PASS'}")
        for f in fails[:15]: print("    ", f)
        total += len(fails)
    print(("\nBASE VALIDATION PASSED — rules 1-30" if not total
           else f"\nBASE VALIDATION FAILED — {total} issue(s)"))
    sys.exit(1 if total else 0)
