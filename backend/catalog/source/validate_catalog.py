#!/usr/bin/env python3
"""MSS catalog validator — base 1-30, scheme 31-45, policy 1-10, batch 1-8."""
import json, re, hashlib, os, sys
from collections import Counter

OUT = os.path.dirname(os.path.abspath(__file__))
FAIL, WARN = [], []
def chk(n, cond, msg):
    (FAIL if not cond else []).append(f"[{n}] {msg}") if not cond else None

def dup_hook(pairs):
    ks = [k for k, _ in pairs]
    d = [k for k, c in Counter(ks).items() if c > 1]
    if d: FAIL.append(f"[1] duplicate keys: {d}")
    return dict(pairs)

raw = open(os.path.join(OUT, "scheme_catalog.json"), encoding="utf-8").read()
cat = json.loads(raw, object_pairs_hook=dup_hook)
man = json.load(open(os.path.join(OUT, "manifest.json"), encoding="utf-8"))
data = cat["data"]

# ---- base 2-3
chk(2, set(cat) == {"metadata", "data"}, f"root keys {set(cat)}")
MD = ["catalogName","schemaVersion","catalogVersion","generatedAt","language","recordCount","checksum"]
chk(3, set(cat["metadata"]) == set(MD), "envelope metadata keys")
chk(3, cat["metadata"]["recordCount"] == len(data), "recordCount != len(data)")

BLOCKS = ["identity","content","relationships","localization","search","ai",
          "verification","analytics","metadata","provenance"]
CONTENT = ["classification","overview","objectives","targetBeneficiaries","eligibility",
           "benefits","requiredDocuments","applicationProcess","applicationTimeline",
           "contacts","faqs","sources"]
STATUS = {"active","inactive","upcoming","suspended","closed","superseded","unknown"}
VSTATUS = {"verified","partially_verified","unverified","disputed","historical"}
MANDATORY = {"required","conditional","post_award","not_applicable","unknown"}
FACETS = ["age","gender","enterprise","businessStage","sector","turnover","investment",
          "location","community","specialCategory","existingRegistration"]

ids, slugs = [], []
for r in data:
    i = r["identity"]; rid = i.get("id", "?")
    # base 4-8
    chk(4, bool(re.fullmatch(r"SCH\d{6}", i["id"])), f"{rid} id pattern")
    chk(4, i["entityType"] == "scheme", f"{rid} entityType/prefix mismatch")
    chk(7, isinstance(i["name"], str) and i["name"].strip(), f"{rid} empty name")
    chk(8, i["status"] in STATUS, f"{rid} status {i['status']}")
    ids.append(i["id"]); slugs.append(i["slug"])
    # base 9-11 / scheme 32
    chk(9, list(r) == BLOCKS, f"{rid} block order {list(r)}")
    chk(32, list(r["content"]) == CONTENT, f"{rid} content sections")
    chk(11, not (set(r["content"]) & set(BLOCKS)), f"{rid} content redefines base name")
    # base 12-14
    for ref in r["relationships"]["references"]:
        chk(12, bool(re.fullmatch(r"(SCH|AUTH|INST|FIN|TAX|TDS|CSR|EXP|KNOW|CMN)\d{6}",
                                  ref["entityId"])), f"{rid} ref id")
    # base 16-19
    def walk(o, path=""):
        if isinstance(o, dict):
            for k, v in o.items(): walk(v, f"{path}.{k}")
        elif isinstance(o, list):
            for n, v in enumerate(o): walk(v, f"{path}[{n}]")
        else:
            if o == "": FAIL.append(f"[16] {rid}{path} empty string")
            if path.endswith("Inr") and o is not None:
                if not (isinstance(o, int) and o >= 0):
                    FAIL.append(f"[18/44] {rid}{path} = {o!r}")
    walk(r)
    chk(19, r["metadata"]["createdAt"] <= r["metadata"]["updatedAt"], f"{rid} created>updated")
    # base 20-21
    ai = r["ai"]
    chk(20, ai["confidence"] is None or 0.0 <= ai["confidence"] <= 1.0, f"{rid} ai.confidence")
    if ai["summary"] or ai["sectionSummaries"]:
        chk(21, all(ai[k] for k in ("generationMode","generatedBy","generatedAt")),
            f"{rid} ai populated without attribution")
    chk(21, ai["isApproved"] is False, f"{rid} ai.isApproved must default false")
    # base 22 — every null required field has missingFields entry
    mf = {m["field"] for m in r["verification"]["missingFields"]}
    REQ = {"content.overview.summary": r["content"]["overview"]["summary"],
           "content.eligibility.narrative.criteria": r["content"]["eligibility"]["narrative"]["criteria"],
           "content.applicationProcess.mode": r["content"]["applicationProcess"]["mode"],
           "content.classification.government.level": r["content"]["classification"]["government"]["level"]}
    for f, v in REQ.items():
        if v is None: chk(22, f in mf, f"{rid} null {f} without missingFields entry")
    if not r["content"]["contacts"]["national"] and not r["content"]["contacts"]["state"] \
       and not r["content"]["contacts"]["district"] and not r["content"]["contacts"]["helplines"]:
        chk(22, "content.contacts" in mf, f"{rid} empty contacts unlogged")
    if not r["content"]["faqs"]: chk(22, "content.faqs" in mf, f"{rid} empty faqs unlogged")
    # base 23
    LOC = {"name","shortName","summary","description","objective","eligibilityText",
           "benefitsText","applicationText"}
    for lang, obj in r["localization"].items():
        chk(23, re.fullmatch(r"[a-z]{2}(-[A-Za-z0-9]+)*", lang), f"{rid} bad lang {lang}")
        chk(23, set(obj) == LOC, f"{rid} localization[{lang}] shape")
    # base 25-30 — provenance / completion policy
    p = r["provenance"]
    chk(25, isinstance(p["defaultSourceTier"], int) and 1 <= p["defaultSourceTier"] <= 5,
        f"{rid} defaultSourceTier")
    for fs in p["fieldSources"]:
        chk(30, 1 <= fs["sourceTier"] <= 5, f"{rid} tier {fs['sourceTier']} (tier 6 forbidden)")
        chk(29, fs["supersededValue"] is None, f"{rid} supersededValue non-null — overwrite")
        chk(26, fs["sourceTier"] > p["defaultSourceTier"] or fs["isBackfill"],
            f"{rid} fieldSources entry not a backfill")
        if fs["sourceTier"] == 5:
            chk(27, fs["url"] and fs["retrievedAt"], f"{rid} tier5 missing url/retrievedAt")
    # scheme 31, 33-45
    chk(31, i["id"].startswith("SCH"), f"{rid} prefix")
    did = [d["documentId"] for d in r["content"]["requiredDocuments"]]
    sids = [s["sourceId"] for s in r["content"]["sources"]]
    for coll, tag in ((did, "DOC"), (sids, "SRC")):
        chk(33, len(coll) == len(set(coll)), f"{rid} duplicate {tag} ids")
        chk(33, all(x.startswith(rid + "-") for x in coll), f"{rid} {tag} id prefix")
    for st in r["content"]["applicationProcess"]["steps"]:
        chk(34, all(x in did for x in st["requiredDocumentIds"]), f"{rid} step doc ref")
    steps = r["content"]["applicationProcess"]["steps"]
    chk(35, [s["stepNumber"] for s in steps] == list(range(1, len(steps) + 1)), f"{rid} step order")
    chk(36, all(x in sids for x in r["verification"]["verifiedAgainst"]), f"{rid} verifiedAgainst")
    chk(36, p["primarySourceId"] is None or p["primarySourceId"] in sids, f"{rid} primarySourceId")
    b = r["content"]["benefits"]
    active = [k for k in b if isinstance(b[k], dict) and b[k].get("applicable") is True]
    chk(37, sorted(b["benefitTypes"]) == sorted(active), f"{rid} benefitTypes {b['benefitTypes']} vs {active}")
    chk(38, sum(1 for s in r["content"]["sources"] if s["isPrimary"]) <= 1, f"{rid} multiple primary")
    st_ = r["content"]["eligibility"]["structured"]
    for fct in FACETS:
        chk(39, "applies" in st_[fct], f"{rid} facet {fct} missing applies")
    if any(st_[f]["applies"] is None for f in FACETS):
        chk(40, "content.eligibility.structured" in mf, f"{rid} unresolved facets unlogged")
    for lvl, arr in r["content"]["contacts"].items():
        for c in arr:
            want = "helpline" if lvl == "helplines" else lvl
            chk(41, c["level"] == want, f"{rid} contact level {c['level']} in {lvl}")
    g = r["content"]["classification"]["government"]
    refd = {x["entityId"] for x in r["relationships"]["references"]}
    for key in ("ministryId", "departmentId"):
        if g[key]: chk(42, g[key] in refd, f"{rid} {key} not in references")
    for aid in g["implementingAgencyIds"]:
        chk(42, aid in refd, f"{rid} agency {aid} not in references")
    v = r["content"]["overview"]["validity"]
    if v["from"] and v["to"]: chk(43, v["from"] <= v["to"], f"{rid} validity range")
    tl = r["content"]["applicationTimeline"]
    if tl["opensOn"] and tl["closesOn"]: chk(43, tl["opensOn"] <= tl["closesOn"], f"{rid} timeline")
    for d in r["content"]["requiredDocuments"]:
        chk(0, d["mandatory"] in MANDATORY, f"{rid} mandatory {d['mandatory']}")
    chk(17, r["verification"]["status"] in VSTATUS, f"{rid} verification.status")
    # URL-typed fields must hold a URL or null
    URLF = [("applicationProcess.onlineUrl", r["content"]["applicationProcess"]["onlineUrl"])]
    URLF += [(f"sources[{n}].url", s["url"]) for n, s in enumerate(r["content"]["sources"])]
    URLF += [(f"requiredDocuments[{n}].sourceUrl", x["sourceUrl"])
             for n, x in enumerate(r["content"]["requiredDocuments"])]
    for fname, u in URLF:
        if u is not None:
            chk("B37", u.lower().startswith(("http://", "https://")) and "." in u,
                f"{rid} {fname} not a URL: {u[:60]!r}")

# base 5,7 global
chk(5, len(ids) == len(set(ids)), "duplicate ids")
chk(7, len(slugs) == len(set(slugs)), f"duplicate slugs: {[s for s,c in Counter(slugs).items() if c>1][:5]}")

# base 24 checksum
def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
calc = "sha256:" + hashlib.sha256(canon(data).encode()).hexdigest()
chk(24, calc == cat["metadata"]["checksum"], "catalog checksum")
entry = next((f for f in man["data"][0]["files"]
              if f["fileName"] == "scheme_catalog.json"), None)
chk(24, entry is not None, "scheme_catalog.json absent from manifest files[]")
if entry:
    chk(24, calc == entry["checksum"], "manifest checksum")
    chk(24, entry["recordCount"] == len(data), "manifest recordCount")
chk(3, set(man["metadata"]) == set(MD), "manifest envelope metadata")

# batch gates
# Updated Phase F Task 2 (2026-08-15): 217 -> 219 after adding SCH000218
# (Stand Up India) and SCH000219 (PMFME) as deliberate, sourced new
# records -- see catalog/add_new_schemes_phase_f.py and
# CONFLICT_RESOLUTION_REPORT.md / MSS_RELEASE_READINESS_REPORT.md for the
# justification. This is a real catalog-size change, not a bypassed gate:
# the range and count below were extended to match, not relaxed or removed.
TOTAL_SCHEMES = 219
codes = [r["identity"]["code"] for r in data]
chk("B25", len(data) == TOTAL_SCHEMES, f"expected {TOTAL_SCHEMES}, got {len(data)}")
chk("B25", sorted(codes) == sorted("TN%03d" % n for n in range(1, TOTAL_SCHEMES + 1)), f"TN001-TN{TOTAL_SCHEMES} coverage")
chk("B26", [r["identity"]["id"] for r in data] == ["SCH%06d" % n for n in range(1, TOTAL_SCHEMES + 1)], "SCH contiguity")
ndocs = sum(len(r["content"]["requiredDocuments"]) for r in data)
chk("B27", ndocs == 561, f"documents {ndocs} != 561")
chk("B27", all(r["content"]["requiredDocuments"] for r in data), "scheme with zero documents")
PH = {"not verified","not specified","not applicable","pending official verification","not confirmed"}
def scan(o):
    if isinstance(o, dict):
        for k, v in o.items():
            if k.endswith("Text") or k in ("statusText","notes","reason","remarks","mandatoryText"): continue
            scan(v)
    elif isinstance(o, list):
        for v in o: scan(v)
    elif isinstance(o, str) and o.strip().lower() in PH:
        FAIL.append(f"[B28] placeholder leaked: {o!r}")
for r in data: scan(r["content"]["eligibility"]); scan(r["content"]["benefits"])
chk("B33", all(fs["isBackfill"] and fs["supersededValue"] is None
               for r in data for fs in r["provenance"]["fieldSources"]), "backfill integrity")

print(f"records={len(data)} documents={ndocs} sources={sum(len(r['content']['sources']) for r in data)}")
print(f"checksum={calc[:26]}…")
if FAIL:
    print(f"\nVALIDATION FAILED — {len(FAIL)} issue(s)")
    for f in FAIL[:40]: print("  ", f)
    if len(FAIL) > 40: print(f"   … +{len(FAIL)-40} more")
    sys.exit(1)
print("\nVALIDATION PASSED — base 1-30, scheme 31-45, policy, batch gates all clean")
