#!/usr/bin/env python3
"""
Phase 2 — authority_catalog.json.

A normalised government hierarchy graph, NOT a deduplicated string list.

Merge policy (deliberately conservative):
  * auto-merge ONLY on exact match of the normalised key
  * near-matches are RECORDED as review candidates and left as separate entities
  * every observed surface form is preserved as an alias

Parent policy (no invention):
  * a parent edge is asserted only when the SOURCE STRING names the parent,
    or when it follows definitionally (a central ministry sits under the Union
    Government; a state department under that State Government)
  * otherwise parentAuthorityId is null and logged in verification.missingFields
"""
import json, re, os, hashlib, csv
from collections import OrderedDict, Counter, defaultdict

SRC = "/sessions/practical-charming-hypatia/mnt/Plan"
CAT = os.path.join(SRC, "catalog")
BASE = os.path.join(CAT, "stage_a_frozen", "scheme_catalog.json")
AT = "2026-08-04T00:00:00Z"
SV = CV = "1.0.0"

DOCS = ["CSR_MSME_Policy_Note.md", "TReDS_Policy_Note.md", "MSME_funding_schemes.md",
        "msme.md", "msme-Scheme-booklet-Eng_2025-26.md", "TN_Schemes_Booklet_2022_v10.md",
        "government_schemes.md"]

# ---------------------------------------------------------------- 1. filters
# Roles and generic placeholders that are NOT government authorities.
NOT_AUTHORITY = re.compile(
    r"^(applicant|self|individual|promoter|borrower|beneficiary|entrepreneur|enterprise|"
    r"chartered accountant|company secretary|cost accountant|professional|auditor|"
    r"bank|banks?|lender|lending institution|member lending institution|financial institution|"
    r"bank / financial institution|employer|vendor|supplier|buyer|seller|"
    r"n/?a|none|nil|others?|various|concerned|relevant|competent|applicable)\b", re.I)
PLACEHOLDER = re.compile(
    r"not applicable|not specified|not verified|not confirmed|pending|unverified|"
    r"depends on|as applicable|implementation-specific|component-specific|programme-specific|"
    r"historical|to be |where applicable|if applicable", re.I)

def is_authority(s):
    raw = " ".join((s or "").split())
    if len(raw) < 3 or len(raw) > 160: return False
    if PLACEHOLDER.search(raw): return False
    if NOT_AUTHORITY.match(raw): return False
    # a proper name starts with a capital; all-lowercase is a prose fragment
    if not raw[0].isupper(): return False
    # "Government of India-backed", "State-led", "Ministry-funded" are descriptors, not bodies
    if re.search(r"-(backed|led|funded|supported|owned|run|aided)\b", raw, re.I): return False
    # test the EXPANDED form so acronym-only mentions (SIDBI, NSIC, KVIC…) survive
    t = expand(raw)
    # must look institutional
    return bool(re.search(
        r"\b(ministry|department|dept|directorate|commission|commissionerate|board|corporation|"
        r"authority|agency|centre|center|council|mission|bureau|office|institute|"
        r"government|govt|niti aayog|aayog|hub|cell|society|trust|bank of india|"
        r"development commissioner|regional authority|secretariat)\b", t, re.I))

# ---------------------------------------------------------------- 2. splitting
SPLIT = re.compile(r"\s*(?:/|;|\||\band/or\b)\s*")
def split_composite(s):
    """'Ministry of MSME / District Industries Centres' -> two authorities.
    A trailing ', Government of X' is a jurisdiction qualifier, never a split."""
    parts = [p.strip(" .,-") for p in SPLIT.split(s or "") if p.strip(" .,-")]
    return [p for p in parts if p]

# ---------------------------------------------------------------- 3. normalise
ABBREV = [
    (r"\bMSMEs?\b", "Micro, Small and Medium Enterprises"),
    (r"\bDept\.?\b", "Department"), (r"\bGovt\.?\b", "Government"),
    (r"\bGoI\b", "Government of India"), (r"\bGoTN\b", "Government of Tamil Nadu"),
    (r"\bDIC(s)?\b", r"District Industries Centre\1"),
    (r"\bDGFT\b", "Directorate General of Foreign Trade"),
    (r"\bDPIIT\b", "Department for Promotion of Industry and Internal Trade"),
    (r"\bKVIC\b", "Khadi and Village Industries Commission"),
    (r"\bNSIC\b", "National Small Industries Corporation"),
    (r"\bSIDBI\b", "Small Industries Development Bank of India"),
    (r"\bNABARD\b", "National Bank for Agriculture and Rural Development"),
    (r"\bRBI\b", "Reserve Bank of India"),
    (r"\bEDII[- ]TN\b", "Entrepreneurship Development and Innovation Institute, Tamil Nadu"),
    (r"\bTIIC\b", "Tamil Nadu Industrial Investment Corporation"),
    (r"\bTANGEDCO\b", "Tamil Nadu Generation and Distribution Corporation"),
    (r"\bAIM\b", "Atal Innovation Mission"),
    (r"\bBIRAC\b", "Biotechnology Industry Research Assistance Council"),
    (r"\bDBT\b(?!\s*\()", "Department of Biotechnology"),
    (r"\bCGTMSE\b", "Credit Guarantee Fund Trust for Micro and Small Enterprises"),
    (r"\bWCD\b", "Women and Child Development"),
]
NOISE = re.compile(
    r"\b(designated|eligible|relevant|concerned|respective|applicable|various|other|"
    r"implementing|nodal|competent|participating|selected|approved|partner)\b", re.I)

def expand(s):
    t = " ".join((s or "").split()).replace("&", "and")
    for pat, rep in ABBREV:
        t = re.sub(pat, rep, t, flags=re.I)
    return " ".join(t.split())

ACRO = re.compile(r"\(([A-Z][A-Za-z0-9&.\- ]{1,40})\)")
def strip_acronym(s):
    ac = ACRO.findall(s)
    return ACRO.sub("", s).strip(" ,.-"), [a.strip() for a in ac]

JUR = re.compile(r",?\s*(Government of ([A-Z][A-Za-z ]+?))\s*$")
def split_jurisdiction(s):
    m = JUR.search(s)
    if m and m.group(2).strip().lower() != "india":
        return s[:m.start()].strip(" ,.-"), m.group(1).strip()
    if m:
        return s[:m.start()].strip(" ,.-"), "Government of India"
    return s, None

PARENT_IN_STRING = re.compile(r",\s*(Ministry of [A-Za-z,&\- ]+)$", re.I)

# Trailing qualifier phrases describe HOW a body acts, not WHICH body it is.
# "Ministry of MSME through approved Implementing Agencies" is the same ministry.
TRAIL = re.compile(
    r"\s+(?:with|through|via|and its|along with|together with|under|acting through|"
    r"in collaboration with|supported by|assisted by)\s+.*$", re.I)
TRAIL_WORD = re.compile(r"\s+(ecosystem|network|system|framework|machinery|channels?)\s*$", re.I)

def strip_trailing_qualifier(s):
    t = TRAIL.sub("", s)
    t = TRAIL_WORD.sub("", t)
    return t.strip(" ,.-") or s

# A proper-noun name is Title/UPPER case tokens joined by a small set of connectives.
# The first lowercase token outside that set means the regex has run into prose.
CONNECT = {"of", "and", "for", "the", "in", "on", "to", "at", "&", "or"}
def trim_prose(name):
    toks = name.split()
    out = []
    for tk in toks:
        w = tk.strip(",.;:()")
        if not w:
            continue
        if w.islower() and w.lower() not in CONNECT:
            break                      # ran into a verb / ordinary prose
        out.append(tk)
    while out and out[-1].strip(",.;:").lower() in CONNECT:
        out.pop()                      # never end on a dangling connective
    return " ".join(out).strip(" ,.;:-")

def norm_key(s):
    t = expand(s).lower()
    t = NOISE.sub(" ", t)
    t = re.sub(r"[^a-z0-9 ]", " ", t)
    t = re.sub(r"\b(the|of|and|for|in|at|to)\b", " ", t)
    return " ".join(sorted(set(t.split())))          # order-insensitive token signature

# ---------------------------------------------------------------- 4. typing
def authority_type(s):
    t = s.lower()
    if re.search(r"\bministry\b", t): return "ministry"
    if re.search(r"district industries centre", t): return "district_industries_centre"
    if re.search(r"\bdirectorate\b", t): return "directorate"
    if re.search(r"\bcommissionerate\b", t): return "commissionerate"
    if re.search(r"\bdevelopment commissioner\b", t): return "directorate"
    if re.search(r"\bdepartment\b", t): return "department"
    if re.search(r"\bcommission\b", t): return "board"
    if re.search(r"\bboard\b", t): return "board"
    if re.search(r"\bcorporation\b|\bbank of india\b", t): return "corporation"
    if re.search(r"\bmission\b|aayog", t): return "mission"
    if re.search(r"\bcouncil\b", t): return "council"
    if re.search(r"facilitation council", t): return "facilitation_council"
    if re.search(r"\bgovernment of\b", t): return "government"
    return "agency"

STATE_CODE = {"tamil nadu": "IN-TN", "rajasthan": "IN-RJ", "chhattisgarh": "IN-CT",
              "maharashtra": "IN-MH", "odisha": "IN-OR", "nagaland": "IN-NL",
              "karnataka": "IN-KA", "kerala": "IN-KL", "gujarat": "IN-GJ",
              "andhra pradesh": "IN-AP", "telangana": "IN-TG", "west bengal": "IN-WB"}

# ---------------------------------------------------------------- 5. harvest
MENTION = re.compile(
    r"\b((?:Ministry|Department|Directorate|Office) of [A-Z][A-Za-z,&\-' ]{3,70}"
    r"|[A-Z][A-Za-z&\-' ]{2,50} (?:Board|Commission|Corporation|Council|Authority|Mission))\b")

def harvest():
    """(surfaceForm, sourceRef, level, stateCode) tuples from every available source."""
    out = []
    base = json.load(open(BASE, encoding="utf-8"))["data"]
    for r in base:
        g = r["content"]["classification"]["government"]
        lvl, states = g["level"], g["states"]
        st = states[0] if states else None
        for fld in ("ministryText", "departmentText", "implementingAgencyText"):
            if g[fld]:
                for p in split_composite(g[fld]):
                    out.append((p, f"scheme:{r['identity']['id']}:{fld}", lvl, st))
        for d in r["content"]["requiredDocuments"]:
            if d["issuingAuthorityText"]:
                for p in split_composite(d["issuingAuthorityText"]):
                    out.append((p, f"scheme:{r['identity']['id']}:document", lvl, st))
        # NOTE: sources[].publisherText is deliberately NOT harvested — in this dataset it
        # holds document titles ("TN MSME Compendium 2022"), not authority names.
    for fn in DOCS:
        p = os.path.join(SRC, fn)
        if not os.path.exists(p): continue
        txt = open(p, encoding="utf-8", errors="ignore").read()
        for m in set(MENTION.findall(txt)):
            nm = trim_prose(m.strip(" ,.-"))
            if nm and len(nm.split()) >= 2:
                out.append((nm, f"document:{fn}", None, None))
    return out

# ---------------------------------------------------------------- 6. cluster
def build():
    raw = harvest()
    kept = [(s, ref, lvl, st) for s, ref, lvl, st in raw if is_authority(s)]
    rejected = Counter(s for s, _, _, _ in raw if not is_authority(s))

    clusters = defaultdict(lambda: {"surfaces": Counter(), "refs": set(),
                                    "levels": Counter(), "states": Counter(),
                                    "acronyms": set()})
    for s, ref, lvl, st in kept:
        # acronym is stripped BEFORE expansion, so "(DPIIT)" is not itself expanded
        stripped, acro = strip_acronym(s)
        core = strip_trailing_qualifier(expand(stripped))
        core, jur = split_jurisdiction(core)
        core = trim_prose(core) or core
        if not core or not is_authority(core): continue
        k = norm_key(core)
        c = clusters[k]
        c["surfaces"][s] += 1
        c["refs"].add(ref)
        c["acronyms"].update(acro)
        if lvl: c["levels"][lvl] += 1
        if st: c["states"][st] += 1
        if jur: c["jurisdictions"] = c.get("jurisdictions", Counter()); c["jurisdictions"][jur] += 1
        c.setdefault("cores", Counter())[core] += 1

    # ---- fragment absorption (artifact removal, NOT semantic merging)
    # A cluster seen ONLY in document prose, whose token signature is a strict subset of
    # another cluster's, is a truncation artifact of our own harvest regex. It is removed
    # and its surface forms are preserved as aliases on the fuller entity. Clusters that
    # appear in a structured scheme field are never absorbed.
    absorbed = []
    keys_sorted = sorted(clusters, key=lambda k: -len(k.split()))
    for k in list(clusters):
        c = clusters[k]
        if any(not r.startswith("document:") for r in c["refs"]):
            continue                       # structured provenance — keep
        ks = set(k.split())
        host = next((h for h in keys_sorted
                     if h != k and ks < set(h.split())), None)
        if host:
            clusters[host]["surfaces"].update(c["surfaces"])
            clusters[host]["refs"] |= c["refs"]
            clusters[host]["acronyms"] |= c["acronyms"]
            absorbed.append({"fragment": c["cores"].most_common(1)[0][0],
                             "absorbedInto": clusters[host]["cores"].most_common(1)[0][0]})
            del clusters[k]

    # ---- near-match review candidates (NOT merged)
    keys = list(clusters)
    cand = []
    for i in range(len(keys)):
        a = set(keys[i].split())
        for j in range(i + 1, len(keys)):
            b = set(keys[j].split())
            if not a or not b: continue
            jac = len(a & b) / len(a | b)
            if 0.6 <= jac < 1.0:
                cand.append({"a": clusters[keys[i]]["cores"].most_common(1)[0][0],
                             "b": clusters[keys[j]]["cores"].most_common(1)[0][0],
                             "tokenSimilarity": round(jac, 2),
                             "decision": "NOT merged — requires human confirmation"})

    # ---- roots (definitional, not inferred)
    roots = {}
    recs = []
    _n = [0]

    def mk(name, atype, level, state, aliases, acronym, parent_id, refs, note=None,
           review=None):
        _n[0] += 1
        aid = "AUTH%06d" % _n[0]
        miss = []
        if parent_id is None and atype != "government":
            miss.append({"field": "content.parentAuthorityId",
                         "reason": "Parent not stated in available sources; not inferred"})
        for f in ("content.offices", "content.contacts", "content.website"):
            miss.append({"field": f, "reason": "Not available in available sources"})
        rec = OrderedDict([
            ("identity", OrderedDict([
                ("id", aid), ("entityType", "authority"), ("code", acronym),
                ("legacyCodes", []), ("name", name),
                ("shortName", acronym), ("acronym", acronym),
                ("slug", re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")[:120]),
                ("language", "en"), ("status", "active")])),
            ("content", OrderedDict([
                ("authorityType", atype),
                ("governmentLevel", level),
                ("jurisdiction", {"country": "IN", "state": state, "districts": []}),
                ("parentAuthorityId", parent_id),
                ("hierarchyDepth", None),
                ("aliases", sorted(aliases)),
                ("offices", []), ("contacts", []), ("website", None),
                ("mandate", None),
                ("observedIn", sorted(refs)[:40]),
                ("observedCount", len(refs)),
                ("reviewCandidates", review or []),
            ])),
            ("relationships", {"references": ([{"entityId": parent_id,
                                                "entityType": "authority",
                                                "relationType": "child_of",
                                                "role": None, "note": note}]
                                              if parent_id else [])}),
            ("localization", {l: {"name": name if l == "en" else None,
                                  "mandate": None} for l in ("en", "ta", "hi")}),
            ("search", {"keywords": sorted({w for w in re.findall(r"[a-z]{3,}", name.lower())}),
                        "synonyms": sorted(aliases), "aliases": sorted({acronym} - {None}),
                        "crossReferences": [], "searchRank": None, "boostTerms": []}),
            ("ai", OrderedDict([("summary", None), ("sectionSummaries", {}),
                                ("generationMode", "extractive"), ("confidence", None),
                                ("generatedBy", None), ("generatedAt", None),
                                ("sourceFieldsUsed", []), ("reviewedBy", None),
                                ("reviewedAt", None), ("isApproved", False)])),
            ("verification", OrderedDict([
                ("status", "unverified"), ("statusText", None), ("isVerified", False),
                ("verifiedAgainst", []), ("verifiedBy", None), ("verifiedAt", None),
                ("confidence", "low"), ("researchStatus", None),
                ("notes", "Derived from authority mentions in source documents; "
                          "identity not confirmed against an official register"),
                ("missingFields", miss), ("disputedFields", []), ("reviewDueOn", None)])),
            ("analytics", {"popularity": None, "viewCount": None, "saveCount": None,
                           "actionCount": None, "lastAggregatedAt": None}),
            ("metadata", OrderedDict([("createdAt", AT), ("updatedAt", AT),
                                      ("catalogVersion", CV), ("schemaVersion", SV),
                                      ("recordStatus", "published"), ("revision", 1)])),
            ("provenance", OrderedDict([
                ("defaultSourceTier", 2), ("primarySourceId", None),
                ("contributingSourceIds", []), ("extractionMethod", "automated"),
                ("extractedAt", AT), ("pipelineVersion", "authority-1.0.0"),
                ("fieldSources", []),
                ("transformationNotes", [
                    "Surface forms normalised (abbreviation expansion, acronym and "
                    "jurisdiction extraction); merged only on exact normalised match",
                    "Parent asserted only where stated in source or definitional"])])),
        ])
        recs.append(rec)
        return aid

    # roots first
    roots["IN"] = mk("Government of India", "government", "central", None,
                     {"Union Government", "GoI"}, "GoI", None, {"definitional"})
    used_states = {st for _, _, _, st in kept if st}
    for st in sorted(used_states):
        nm = next((f"Government of {k.title()}" for k, v in STATE_CODE.items() if v == st), None)
        if nm: roots[st] = mk(nm, "government", "state", st, set(), None, None, {"definitional"})

    # entities
    key_to_id = {}
    ministries = {}
    ordered = sorted(clusters.items(), key=lambda kv: -sum(kv[1]["surfaces"].values()))
    # pass 1 — ministries and governments (so children can attach)
    for k, c in ordered:
        core = c["cores"].most_common(1)[0][0]
        at = authority_type(core)
        if at not in ("ministry", "government"): continue
        lvl = c["levels"].most_common(1)[0][0] if c["levels"] else "central"
        st = c["states"].most_common(1)[0][0] if c["states"] else None
        parent = roots.get("IN") if at == "ministry" and lvl != "state" else None
        aid = mk(core, at, lvl, st if at != "ministry" else None,
                 set(c["surfaces"]) | c["acronyms"],
                 (sorted(c["acronyms"])[0] if c["acronyms"] else None),
                 parent, c["refs"],
                 note="Central ministry under the Union Government (definitional)" if parent else None)
        key_to_id[k] = aid
        if at == "ministry": ministries[norm_key(core)] = aid
    # pass 2 — everything else
    for k, c in ordered:
        if k in key_to_id: continue
        core = c["cores"].most_common(1)[0][0]
        at = authority_type(core)
        lvl = c["levels"].most_common(1)[0][0] if c["levels"] else None
        st = c["states"].most_common(1)[0][0] if c["states"] else None
        parent, note = None, None
        m = PARENT_IN_STRING.search(core)
        if m:                                   # parent named IN the string
            pid = ministries.get(norm_key(expand(m.group(1))))
            if pid: parent, note = pid, "Parent named in source string"
        if parent is None:
            jur = c.get("jurisdictions")
            if jur:
                j = jur.most_common(1)[0][0]
                if j == "Government of India": parent, note = roots["IN"], "Jurisdiction stated in source"
                else:
                    sc = STATE_CODE.get(j.replace("Government of ", "").lower())
                    if sc in roots: parent, note = roots[sc], "Jurisdiction stated in source"
        if parent is None and lvl == "state" and st in roots:
            parent, note = roots[st], "State-level body under that State Government (definitional)"
        rev = [x for x in cand if core in (x["a"], x["b"])][:6]
        key_to_id[k] = mk(core, at, lvl, st, set(c["surfaces"]) | c["acronyms"],
                          (sorted(c["acronyms"])[0] if c["acronyms"] else None),
                          parent, c["refs"], note, rev)

    # depth
    byid = {r["identity"]["id"]: r for r in recs}
    def depth(r, seen=None):
        seen = seen or set()
        p = r["content"]["parentAuthorityId"]
        if not p or p in seen: return 0
        seen.add(p)
        return 1 + depth(byid[p], seen)
    for r in recs: r["content"]["hierarchyDepth"] = depth(r)
    # parent_of back-edges
    for r in recs:
        p = r["content"]["parentAuthorityId"]
        if p:
            byid[p]["relationships"]["references"].append(
                {"entityId": r["identity"]["id"], "entityType": "authority",
                 "relationType": "parent_of", "role": None, "note": None})

    def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    cat = OrderedDict([
        ("metadata", OrderedDict([("catalogName", "authority"), ("schemaVersion", SV),
                                  ("catalogVersion", CV), ("generatedAt", AT), ("language", "en"),
                                  ("recordCount", len(recs)),
                                  ("checksum", "sha256:" + hashlib.sha256(canon(recs).encode()).hexdigest())])),
        ("data", recs)])
    json.dump(cat, open(os.path.join(CAT, "authority_catalog.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)

    with open(os.path.join(CAT, "authority_review_candidates.csv"), "w", newline="",
              encoding="utf-8") as f:
        w = csv.writer(f); w.writerow(["nameA", "nameB", "tokenSimilarity", "decision"])
        for x in cand: w.writerow([x["a"], x["b"], x["tokenSimilarity"], x["decision"]])

    stats = OrderedDict([
        ("generatedAt", AT), ("catalog", "authority_catalog.json"),
        ("mentionsHarvested", len(raw)),
        ("mentionsKept", len(kept)),
        ("mentionsRejectedAsNonAuthority", len(raw) - len(kept)),
        ("distinctRejectedStrings", len(rejected)),
        ("topRejected", rejected.most_common(12)),
        ("clusters", len(clusters)), ("authorities", len(recs)),
        ("fragmentsAbsorbed", len(absorbed)),
        ("fragmentSamples", absorbed[:8]),
        ("byType", dict(Counter(r["content"]["authorityType"] for r in recs))),
        ("byLevel", dict(Counter(str(r["content"]["governmentLevel"]) for r in recs))),
        ("byDepth", dict(Counter(r["content"]["hierarchyDepth"] for r in recs))),
        ("withParent", sum(1 for r in recs if r["content"]["parentAuthorityId"])),
        ("orphans", sum(1 for r in recs if not r["content"]["parentAuthorityId"])),
        ("aliasesPreserved", sum(len(r["content"]["aliases"]) for r in recs)),
        ("reviewCandidatePairs", len(cand)),
        ("sourcedFromDocuments", sum(1 for r in recs
                                     if any(o.startswith("document:") for o in r["content"]["observedIn"]))),
    ])
    json.dump(stats, open(os.path.join(CAT, "authority_statistics.json"), "w", encoding="utf-8"),
              indent=2, ensure_ascii=False)
    for k, v in stats.items():
        if k != "topRejected": print(f"  {k:34} {v}")
    print("\n  rejected samples:", [s for s, _ in rejected.most_common(8)])

if __name__ == "__main__":
    build()
