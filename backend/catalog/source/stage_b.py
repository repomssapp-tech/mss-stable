#!/usr/bin/env python3
"""
Stage B harness — batching, allowlist, checkpointing, provenance.

Pass 1 (verify)  : read-only on content. Writes only to verification.
Pass 2 (enrich)  : fill-only. Writes to content ONLY where baseline is null.

Usage:
  stage_b.py queue   <batch>     emit Pass-1 work queue for a batch
  stage_b.py apply   <batch>     apply fetched results from results_<batch>.json
  stage_b.py report              coverage + allowlist report
"""
import json, os, sys, re
from urllib.parse import urlparse
from collections import Counter, OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.join(CAT, "stage_a_frozen", "scheme_catalog.json")
LIVE = os.path.join(CAT, "scheme_catalog.json")
WORK = CAT
BATCH = 25

# ---- Data Completion Policy §4.3 -------------------------------------------
SUFFIX = {".gov.in", ".nic.in"}
EXACT = {"sidbi.in", "nsic.co.in", "kvic.gov.in", "dcmsme.gov.in", "dgft.gov.in",
         "gst.gov.in", "rbi.org.in", "nabard.org", "msme.gov.in", "india.gov.in",
         "udyamregistration.gov.in",
         # Added per OPERATIONAL_POLICY_REVIEW.md §1, 2026-08-14: confirmed live
         # ("jointly set up by Ministry of MSME, Government of India and SIDBI").
         # ncgtc.in was checked the same way and NOT added -- ownership statement
         # was not retrievable from the live page, see that doc for detail.
         "cgtmse.in",
         # Added Phase F Task 2, 2026-08-15: confirmed live -- portal states it
         # was launched by the PM as the Stand-Up India initiative and names
         # SIDBI (an already-approved host) directly. See
         # MSS_Data_Completion_Policy_v1.0.md changelog 1.2.
         "standupmitra.in"}

def allowed(host):
    h = (host or "").lower().strip().lstrip(".")
    if h.startswith("www."):
        h = h[4:]
    if any(h.endswith(s) for s in SUFFIX):
        return True
    return any(h == e or h.endswith("." + e) for e in EXACT)

def host_of(u):
    try: return urlparse(u).netloc.lower()
    except Exception: return ""

# ---- policy §4.1 verifiable fields (Pass 1 scope) ---------------------------
def verifiable(rec):
    """Populated fields Pass 1 may confirm. (path, value, url_to_check)."""
    out, c = [], rec["content"]
    ap = c["applicationProcess"]
    if ap["onlineUrl"]:
        out.append(("content.applicationProcess.onlineUrl", ap["onlineUrl"], ap["onlineUrl"]))
    for n, s in enumerate(c["sources"]):
        if s["url"]:
            out.append((f"content.sources[{n}].url", s["url"], s["url"]))
    return out

def load(p): return json.load(open(p, encoding="utf-8"))

def cmd_queue(bn):
    base = load(BASE)["data"]
    lo, hi = (bn - 1) * BATCH, min(bn * BATCH, len(base))
    recs = base[lo:hi]
    seen, q, skipped = {}, [], []
    for r in recs:
        for path, value, url in verifiable(r):
            h = host_of(url)
            item = {"schemeId": r["identity"]["id"], "code": r["identity"]["code"],
                    "field": path, "value": value, "url": url, "host": h}
            if not allowed(h):
                item["reason"] = "host not on approved list (policy §4.3)"
                skipped.append(item); continue
            seen.setdefault(url, []).append(item)
    for url, items in seen.items():
        q.append({"url": url, "host": host_of(url), "refs": items})
    out = {"batch": bn, "schemeRange": [recs[0]["identity"]["id"], recs[-1]["identity"]["id"]],
           "schemes": len(recs), "distinctUrls": len(q),
           "totalRefs": sum(len(x["refs"]) for x in q),
           "skippedNonApproved": skipped, "queue": q}
    json.dump(out, open(os.path.join(WORK, f"queue_{bn}.json"), "w"), indent=2)
    print(f"batch {bn}: schemes={len(recs)} ({out['schemeRange'][0]}-{out['schemeRange'][1]}) "
          f"distinctUrls={len(q)} refs={out['totalRefs']} skipped={len(skipped)}")
    for x in sorted(q, key=lambda z: -len(z["refs"])):
        print(f"   {len(x['refs']):3} refs  {x['url'][:100]}")
    if skipped:
        print(f"\n  SKIPPED — non-approved hosts ({len(skipped)}):")
        for h, n in Counter(s["host"] for s in skipped).most_common():
            print(f"     {n:3}  {h}")

def cmd_apply(bn):
    """Apply Pass-1 results: verification only, content untouched."""
    q = load(os.path.join(WORK, f"queue_{bn}.json"))
    res = load(os.path.join(WORK, f"results_{bn}.json"))   # {url: {"ok":bool,"note":str,"retrievedAt":str}}
    cat = load(LIVE)
    idx = {r["identity"]["id"]: r for r in cat["data"]}
    # Snapshot live content BEFORE this apply mutates verification, so the guard
    # below checks "did this run touch content", not "does content still match
    # the 1.0.0-alpha Stage-A baseline" (content has legitimately moved on since
    # then via later, non-Stage-B phases: crossrefs, i18n, phase4 resolution).
    pre_content = {i: json.dumps(idx[i]["content"], sort_keys=True) for i in idx}
    conf = dis = 0
    for entry in q["queue"]:
        r0 = res.get(entry["url"])
        if not r0: continue
        for ref in entry["refs"]:
            rec = idx[ref["schemeId"]]
            v = rec["verification"]
            v.setdefault("verifiedFields", [])
            item = {"field": ref["field"], "value": ref["value"], "sourceTier": 5,
                    "url": entry["url"], "retrievedAt": r0["retrievedAt"],
                    "outcome": "confirmed" if r0["ok"] else "unreachable",
                    "note": r0.get("note")}
            v["verifiedFields"].append(item)
            if r0["ok"]:
                conf += 1
            else:
                dis += 1
                v["disputedFields"].append({
                    "field": ref["field"], "values": [ref["value"]],
                    "resolution": "baseline value retained; live source unreachable at "
                                  f"{r0['retrievedAt']} — review required",
                    "resolvedBy": None})
    # HARD GUARD — Pass 1 must not mutate content (policy validation rule 11)
    bad = [i for i in idx if json.dumps(idx[i]["content"], sort_keys=True)
           != pre_content[i]]
    if bad:
        print(f"ABORT — Pass 1 mutated content on {len(bad)} record(s): {bad[:5]}")
        sys.exit(1)
    # Stage B is a new release layer over whatever release is currently live —
    # NOT the frozen 1.0.0-alpha baseline, which predates later phases (crossrefs,
    # i18n, phase4 resolution). Version is derived from the live version so those
    # phases' lineage isn't clobbered.
    import hashlib
    def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    ck = "sha256:" + hashlib.sha256(canon(cat["data"]).encode()).hexdigest()
    prev_version = cat["metadata"]["catalogVersion"]
    new_version = f"{prev_version}+stageb.pass1.batch{bn}"
    cat["metadata"]["checksum"] = ck
    cat["metadata"]["catalogVersion"] = new_version
    json.dump(cat, open(LIVE, "w", encoding="utf-8"), ensure_ascii=False, indent=2)

    # manifest.json is a whole-release manifest spanning 11 catalog files, not a
    # scheme-only file — update only scheme_catalog.json's own entry within it,
    # never the shared release-level catalogRelease/compatibility fields, which
    # describe all 11 files and are untouched by a scheme-only Stage B pass.
    man = load(os.path.join(CAT, "manifest.json"))
    d0 = man["data"][0]
    f0 = next(f for f in d0["files"] if f["fileName"] == "scheme_catalog.json")
    f0["checksum"] = ck
    f0["byteSize"] = os.path.getsize(LIVE)
    d0["stageBPasses"] = sorted(set(d0.get("stageBPasses", []) + [f"scheme:pass1-batch{bn}"]))
    man["metadata"]["checksum"] = "sha256:" + hashlib.sha256(
        canon(man["data"]).encode()).hexdigest()
    json.dump(man, open(os.path.join(CAT, "manifest.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)
    print(f"Pass 1 batch {bn} applied: confirmed={conf} unreachable={dis} "
          f"content mutations=0 (guard passed)")
    print(f"release {new_version}  checksum={ck[:26]}…  (supersedes {prev_version})")

def cmd_report():
    base = load(BASE)["data"]
    urls = Counter(); hosts = Counter()
    for r in base:
        for _, _, u in verifiable(r):
            urls[u] += 1
        for x in r["content"]["requiredDocuments"]:
            if x["sourceUrl"]: urls[x["sourceUrl"]] += 1
    for u, n in urls.items(): hosts[host_of(u)] += n
    ok = {h: c for h, c in hosts.items() if allowed(h)}
    no = {h: c for h, c in hosts.items() if not allowed(h)}
    print(f"distinct URLs={len(urls)} occurrences={sum(urls.values())}")
    print(f"approved hosts={len(ok)} ({sum(ok.values())} occ) | "
          f"NON-approved hosts={len(no)} ({sum(no.values())} occ)")
    print(f"batches of {BATCH}: {-(-len(base)//BATCH)}")
    print("\nNON-APPROVED (blocked pending allowlist amendment):")
    for h, c in sorted(no.items(), key=lambda x: -x[1]):
        print(f"  {c:4}  {h or '(malformed)'}")

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "report"
    if cmd == "queue": cmd_queue(int(sys.argv[2]))
    elif cmd == "apply": cmd_apply(int(sys.argv[2]))
    else: cmd_report()
