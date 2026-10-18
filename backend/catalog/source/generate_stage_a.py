#!/usr/bin/env python3
"""
MSS Offline Catalog — Stage A generator (tiers 1-4, deterministic, no network).

Conforms to:
  MSS_Base_Entity_Model_v1.0.md
  MSS_Scheme_Catalog_Schema_v1.0.md
  MSS_Data_Completion_Policy_v1.0.md
  MSS_Data_Migration_Guide.md
"""
import json, re, hashlib, csv, os, sys
from collections import OrderedDict, Counter

SRC = "/sessions/practical-charming-hypatia/mnt/Plan"
OUT = "/sessions/practical-charming-hypatia/mnt/Plan/catalog"
WORK = "/sessions/practical-charming-hypatia/mnt/outputs"
GENERATED_AT = "2026-08-04T00:00:00Z"
SCHEMA_VERSION = "1.0.0"
CATALOG_VERSION = "1.0.0"
PIPELINE_VERSION = "stage-a-1.0.0"
DEFAULT_TIER = 2                      # official structured spreadsheet
GENERATED_BY = "claude-opus-5"

# ---------------------------------------------------------------- parsing
def load_sheets(path):
    lines = open(path, encoding="utf-8").read().split("\n")
    marks = [(i, l[9:].strip()) for i, l in enumerate(lines) if l.startswith("# Sheet:")]
    marks.append((len(lines), None))
    out = {}
    for k in range(len(marks) - 1):
        s, name = marks[k]; e = marks[k + 1][0]
        blk = [l for l in lines[s + 1:e] if l.strip() and l.strip() != "---"]
        hdr = blk[0].split("\t")
        rows = []
        for r in blk[1:]:
            c = r.split("\t")
            c += [""] * (len(hdr) - len(c))
            rows.append([x.strip() for x in c])
        out[name] = (hdr, rows)
    return out

# ---------------------------------------------------------------- policy §3.1
PLACEHOLDERS = {
    "not verified", "not specified", "not specified on source page", "not applicable",
    "not applicable / not verified", "not confirmed", "unverified", "unverified exact scheme",
    "pending official verification", "pending exact official verification",
    "pending exact/current official verification", "pending detailed official verification",
    "pending scheme-identity verification", "", "-", "n/a", "na",
}
# meaningful, NOT missing — policy §3.1 note
VARIES = {"varies", "varies by component", "component-specific", "programme-specific",
          "guideline-specific", "not a subsidy"}

def val(x):
    """Return cleaned value or None if placeholder."""
    if x is None: return None
    t = " ".join(str(x).split())
    return None if t.lower() in PLACEHOLDERS else (t or None)

def is_varies(x):
    return x is not None and " ".join(str(x).split()).lower() in VARIES

# ---------------------------------------------------------------- money §3.5
UNIT = {"lakh": 10**5, "lakhs": 10**5, "lac": 10**5, "lacs": 10**5,
        "crore": 10**7, "crores": 10**7, "cr": 10**7,
        "thousand": 10**3}
def money(x):
    v = val(x)
    if v is None or is_varies(v): return None
    t = v.replace(",", "").replace("₹", " ").replace("Rs.", " ").replace("Rs", " ")
    t = re.sub(r"\bINR\b", " ", t, flags=re.I)
    m = re.search(r"(\d+(?:\.\d+)?)\s*(lakhs?|lacs?|crores?|cr|thousand)\b", t, re.I)
    if m:
        return int(round(float(m.group(1)) * UNIT[m.group(2).lower()]))
    m = re.search(r"(?<![\d.])(\d{3,})(?![\d.]*\s*%)", t)
    if m:
        n = int(m.group(1))
        return n if n >= 100 else None
    return None

def percent(x):
    v = val(x)
    if v is None or is_varies(v): return None
    m = re.search(r"(\d+(?:\.\d+)?)\s*%", v)
    return float(m.group(1)) if m else None

# ---------------------------------------------------------------- enums §3.3
def gov_level(x):
    v = val(x)
    if v is None: return None
    l = v.lower()
    if "central" in l and "state" in l: return "central_state"
    if l.startswith("central") or "central" in l: return "central"
    if l.startswith("state") or "state" in l: return "state"
    if "union territory" in l: return "union_territory"
    return None

def app_mode(x):
    v = val(x)
    if v is None: return None
    l = v.lower()
    on = "online" in l or "portal" in l or "e-sevai" in l
    off = "offline" in l or "physical" in l or "in person" in l
    if on and off: return "both"
    if on: return "online"
    if off: return "offline"
    return None

def scheme_status(x):
    v = val(x)
    if v is None: return "unknown"
    l = v.lower()
    if "historical" in l or "closed" in l or "discontinued" in l: return "closed"
    if l.startswith("current"): return "active"
    if "pending" in l: return "unknown"
    return "unknown"

MAND = [
    ("required", ["yes"]),
    ("post_award", ["post-sanction", "post-event", "post-application", "post-eligibility",
                    "post-selection", "post sanction"]),
    ("conditional", ["conditional"]),
    ("not_applicable", ["not applicable"]),
]
def mandatory(x):
    v = val(x)
    if v is None: return "unknown"
    l = v.lower()
    for enum, keys in MAND:
        for k in keys:
            if l.startswith(k) or k in l:
                if enum == "required" and "conditional" in l: return "conditional"
                return enum
    return "unknown"

def verif_status(verified_yn, vstatus):
    vs = (val(vstatus) or "").lower()
    yes = (val(verified_yn) or "").lower().startswith("y")
    if "historical" in vs: return "historical"
    if yes and vs.startswith("verified"): return "verified"
    if yes: return "partially_verified"
    return "unverified"

def slugify(s):
    t = re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")
    return re.sub(r"-{2,}", "-", t)[:120]

def acronym_of(name):
    m = re.search(r"\(([A-Z][A-Za-z0-9&.\- ]{1,14})\)\s*$", name)
    if not m: return None
    a = m.group(1).strip()
    return a if re.fullmatch(r"[A-Z][A-Za-z0-9&.\-]{1,14}", a) else None

# ---------------------------------------------------------------- eligibility §4.2
def facet(applies=None, **kw):
    d = {"text": None, "applies": applies}; d.update(kw); return d

NEG_AGE  = re.compile(r"no (upper )?age (limit|ceiling)|without age", re.I)
NEG_INC  = re.compile(r"no income (limit|ceiling)", re.I)
NEG_EDU  = re.compile(r"no (minimum )?educational", re.I)
SPECIALS = [("women", r"\bwomen\b|\bwoman\b"), ("sc", r"\bSC\b|scheduled caste"),
            ("st", r"\bST\b|scheduled tribe"), ("differently_abled", r"differently[- ]abled"),
            ("transgender", r"\btransgender\b"), ("minority", r"\bminorit"),
            ("ex_servicemen", r"ex[- ]servicem")]
REGS = [("udyam", r"\budyam\b"), ("dpiit", r"\bDPIIT\b"), ("iec", r"\bIEC\b"),
        ("gst", r"\bGST\b"), ("sprs", r"\bSPRS\b"), ("nsic", r"\bNSIC\b")]
ENT  = [("micro", r"\bmicro\b"), ("small", r"\bsmall\b"), ("medium", r"\bmedium\b")]
STAGE= [("new", r"\bnew\b"), ("existing", r"\bexisting\b"),
        ("expansion", r"\bexpansion\b|\bexpand"), ("diversification", r"diversif")]

def build_eligibility(crit, verified, beneficiary):
    blob = " ".join(x for x in [crit, verified, beneficiary] if x)
    S = {}
    # age
    a = facet(minYears=None, maxYears=None)
    m = re.search(r"aged?\s*(\d{2})\s*[–\-to]+\s*(\d{2})", blob, re.I)
    m2 = re.search(r"(?:up to|upto|below|under|not exceeding)\s*(\d{2})\s*years", blob, re.I)
    m3 = re.search(r"(\d{2})\s*\+|aged?\s*(\d{2})\s*(?:years)?\s*(?:and above|or above|\+)", blob, re.I)
    if m:   a.update(minYears=int(m.group(1)), maxYears=int(m.group(2)), applies=True, text=m.group(0))
    elif m2:a.update(maxYears=int(m2.group(1)), applies=True, text=m2.group(0))
    elif m3:a.update(minYears=int(m3.group(1) or m3.group(2)), applies=True, text=m3.group(0))
    elif NEG_AGE.search(blob): a.update(applies=False, text=NEG_AGE.search(blob).group(0))
    S["age"] = a
    # gender
    g = facet(values=[])
    if re.search(r"\bwomen\b|\bwoman\b|\bgirl", blob, re.I):
        g.update(values=["female"], applies=True)
    S["gender"] = g
    # enterprise
    types = [k for k, p in ENT if re.search(p, blob, re.I)]
    S["enterprise"] = facet(types=types, constitution=[], applies=True if types else None)
    # business stage
    st = [k for k, p in STAGE if re.search(p, blob, re.I)]
    S["businessStage"] = facet(values=st, applies=True if st else None)
    S["sector"] = facet(included=[], excluded=[])
    S["turnover"] = facet(minInr=None, maxInr=None)
    S["investment"] = facet(minInr=None, maxInr=None)
    S["location"] = facet(country=None, states=[], districts=[], areaTypes=[])
    S["community"] = facet(values=[])
    sp = [k for k, p in SPECIALS if re.search(p, blob, re.I)]
    S["specialCategory"] = facet(values=sp, applies=True if sp else None)
    rg = [k for k, p in REGS if re.search(p, blob, re.I)]
    S["existingRegistration"] = facet(required=rg, applies=True if rg else None)
    S["otherConditions"] = []
    return S

# ---------------------------------------------------------------- benefit shapes
def monetary(applicable=None, **kw):
    d = {"applicable": applicable, "percentage": None, "percentageText": None,
         "amountInr": None, "amountText": None, "maxAmountInr": None, "maxAmountText": None,
         "minAmountInr": None, "minAmountText": None, "durationMonths": None, "basis": None,
         "varies": False, "variesBy": None, "conditions": [], "description": None}
    d.update(kw); return d

def loan_shape():
    d = monetary(); d.update(tenureMonths=None, moratoriumMonths=None, interestRatePercent=None,
                             interestRateText=None, collateralRequired=None, repaymentText=None)
    return d

def guarantee_shape():
    d = monetary(); d.update(coveragePercent=None, maxCoverInr=None, guarantorId=None,
                             guarantorText=None, feePercent=None)
    return d

def nonmoney():
    return {"applicable": None, "modalities": [], "durationText": None, "providerIds": [],
            "providerText": None, "conditions": [], "description": None}

MON_KEYS = ["capitalSubsidy", "interestSubvention", "marginMoney", "grant", "taxBenefit",
            "reimbursement", "equitySupport", "insurance"]
NON_KEYS = ["trainingSupport", "marketSupport", "technologySupport"]

def pick_benefit_slot(scheme_type_text, benefits_text):
    """Choose which typed slot receives monetary values. Conservative: only when stated."""
    t = ((scheme_type_text or "") + " " + (benefits_text or "")).lower()
    if "interest subvention" in t or "interest subsidy" in t: return "interestSubvention"
    if "margin money" in t: return "marginMoney"
    if "capital subsidy" in t or "subsidy" in t: return "capitalSubsidy"
    if "grant" in t: return "grant"
    if "reimburse" in t: return "reimbursement"
    if "guarantee" in t: return "guarantee"
    if "loan" in t or "term finance" in t or "credit" in t: return "loan"
    if "tax" in t: return "taxBenefit"
    if "equity" in t: return "equitySupport"
    if "insurance" in t: return "insurance"
    if "training" in t or "skill" in t: return "trainingSupport"
    if "market" in t or "exhibition" in t or "trade fair" in t: return "marketSupport"
    if "technology" in t or "design" in t or "incubat" in t: return "technologySupport"
    return None

# ---------------------------------------------------------------- main build
def main():
    os.makedirs(OUT, exist_ok=True)
    sheets = load_sheets(os.path.join(SRC, "Government_Schemes_TN001-TN217_WITH_SERVICES_FINAL.md"))
    ah, arows = sheets["All Schemes"]
    ih, irows = sheets["Scheme Info"]
    dh, drows = sheets["Documents Required"]

    A = {r[0]: r for r in arows if re.fullmatch(r"TN\d{3}", r[0])}
    I = {r[0]: r for r in irows if re.fullmatch(r"TN\d{3}", r[0])}

    # --- C-7 key repair: 10 Scheme Info rows carry Scheme Code "Not specified".
    # Recovered by EXACT name join against All Schemes (deterministic; no inference).
    repaired = []
    name_to_code = {" ".join(r[1].split()).lower(): r[0] for r in A.values()}
    for r in irows:
        if re.fullmatch(r"TN\d{3}", r[0]):
            continue
        key = " ".join(r[1].split()).lower()
        c = name_to_code.get(key)
        if c and c not in I:
            r2 = list(r); r2[0] = c
            I[c] = r2
            repaired.append((c, r[1]))
    codes = sorted(I.keys(), key=lambda c: int(c[2:]))

    DOCS = {}
    orphan_docs = 0
    for r in drows:
        if re.fullmatch(r"TN\d{3}", r[0]): DOCS.setdefault(r[0], []).append(r)
        else: orphan_docs += 1

    # tier 4 — prior extraction, keyed by name for safe gap-fill
    T4 = {}
    try:
        prior = json.load(open(os.path.join(SRC, "government_schemes.json"), encoding="utf-8"))
        for it in prior.get("All Schemes", []):
            nm = " ".join((it.get("Scheme Name") or "").split()).lower()
            if nm: T4[nm] = it
    except Exception as e:
        print("WARN tier4 load:", e)

    records, unmapped, backfill_log = [], [], []
    for n, code in enumerate(codes, start=1):
        a, i = A.get(code, [""] * len(ah)), I[code]
        sid = "SCH%06d" % n
        name = val(i[1]) or val(a[1]) or code
        miss, fsrc, disputed = [], [], []
        tnotes = ["Currency text parsed to integer rupees",
                  "Placeholder values normalised to null"]
        if code in dict(repaired):
            tnotes.append("Scheme Code recovered by exact name join; source cell read "
                          "'Not specified' (conflict C-7)")

        def M(field, reason="Not available in available sources"):
            miss.append({"field": field, "reason": reason})

        # ---- tier 4 gap fill (never overwrite; policy §3.1)
        p4 = T4.get(name.lower())
        def t4(key):
            if not p4: return None
            return val(p4.get(key))
        def backfill(field, higher, key):
            """Return higher if present; else tier-4 value, logged."""
            if higher is not None: return higher
            v = t4(key)
            if v is not None:
                fsrc.append({"field": field, "value": v, "sourceTier": 4,
                             "sourceType": "prior_extraction",
                             "organization": "MSS previous verified extraction",
                             "url": None, "retrievedAt": None,
                             "isBackfill": True, "supersededValue": None})
                backfill_log.append((sid, code, field, key))
            return v

        # ---------------- content.classification
        lvl_t, lvl = val(i[2]), gov_level(i[2])
        if lvl is None and lvl_t: unmapped.append(("government.level", lvl_t))
        st_t = val(i[6]); states = []
        if st_t and "tamil nadu" in st_t.lower(): states = ["IN-TN"]
        stype_t = val(i[10])
        classification = OrderedDict([
            ("government", OrderedDict([
                ("level", lvl), ("levelText", lvl_t), ("country", "IN"),
                ("states", states), ("statesText", st_t),
                ("districts", []), ("districtsText", val(i[7])),
                ("ministryId", None), ("ministryText", val(i[3])),
                ("departmentId", None), ("departmentText", val(i[4])),
                ("implementingAgencyIds", []), ("implementingAgencyText", val(i[5])),
            ])),
            ("schemeType", None), ("schemeTypeText", stype_t),
            ("sectors", []), ("sectorsText", val(i[8])),
            ("categories", []), ("tags", []),
        ])
        if stype_t: unmapped.append(("classification.schemeType", stype_t))
        if not lvl: M("content.classification.government.level")
        if not classification["government"]["ministryText"]: M("content.classification.government.ministryText")
        M("content.classification.government.ministryId", "authority_catalog.json not present in this release")

        # ---------------- content.overview
        summary = val(i[11]); objective = val(i[12])
        overview = OrderedDict([
            ("summary", summary), ("description", summary), ("objective", objective),
            ("background", None), ("legalBasis", []),
            ("validity", {"from": None, "to": None, "isOpenEnded": None, "text": None}),
            ("version", val(i[23])),
            ("lastUpdated", None), ("lastUpdatedText", val(i[24])),
        ])
        if not summary: M("content.overview.summary")
        M("content.overview.background"); M("content.overview.legalBasis")
        M("content.overview.validity"); M("content.overview.lastUpdated")

        # ---------------- eligibility
        crit = backfill("content.eligibility.narrative.criteria", val(a[2]), "Eligibility Criteria")
        vcrit = backfill("content.eligibility.narrative.verifiedCriteria", val(a[6]), "Verified Eligibility")
        vnotes = backfill("verification.notes", val(a[9]), "Verification Notes")
        vstat = backfill("verification.statusText", val(a[7]), "Verification Status")
        elig_src = backfill("content.sources[eligibility]", val(a[8]), "Official Source")
        beneficiary = val(i[9])
        structured = build_eligibility(crit, vcrit, beneficiary)
        unresolved = [k for k, v in structured.items() if isinstance(v, dict) and v.get("applies") is None]
        eligibility = {"structured": structured,
                       "narrative": {"criteria": crit, "verifiedCriteria": vcrit,
                                     "exclusions": [], "relaxations": []}}
        if not crit: M("content.eligibility.narrative.criteria")
        if not vcrit: M("content.eligibility.narrative.verifiedCriteria")
        if unresolved:
            M("content.eligibility.structured",
              "Facets not determinable from available sources: " + ", ".join(unresolved))
        M("content.eligibility.narrative.exclusions"); M("content.eligibility.narrative.relaxations")

        # ---------------- benefits
        btext = val(i[13])
        benefits = OrderedDict([("summary", btext), ("benefitTypes", [])])
        for k in MON_KEYS: benefits[k] = monetary()
        benefits["loan"] = loan_shape()
        benefits["guarantee"] = guarantee_shape()
        for k in NON_KEYS: benefits[k] = nonmoney()
        benefits["currency"] = "INR"
        benefits["disbursement"] = {"mode": None, "modeText": None, "instalments": None, "text": None}

        pct_t, amt_t = val(i[14]), val(i[15])
        min_t, max_t = val(i[16]), val(i[17])
        pct, amt = percent(i[14]), money(i[15])
        mn, mx = money(i[16]), money(i[17])
        slot = pick_benefit_slot(stype_t, btext)
        if slot and slot in benefits:
            b = benefits[slot]
            b["percentage"], b["percentageText"] = pct, pct_t
            b["maxAmountInr"] = mx if mx is not None else amt
            b["maxAmountText"] = max_t or amt_t
            b["minAmountInr"], b["minAmountText"] = mn, min_t
            b["description"] = btext
            varies = any(is_varies(x) for x in (pct_t, amt_t, min_t, max_t))
            b["varies"] = varies
            if varies:
                b["variesBy"] = next((v for v in (pct_t, amt_t, max_t) if is_varies(v)), None)
            b["applicable"] = True if (pct is not None or b["maxAmountInr"] is not None
                                       or varies or btext) else None
            if b["applicable"]: benefits["benefitTypes"].append(slot)
        else:
            if btext: M("content.benefits.benefitTypes",
                        "Benefit type not stated in available sources; value retained in benefits.summary")
        if not btext: M("content.benefits.summary")
        if pct is None and pct_t is None: M("content.benefits.subsidyPercentage")
        if mx is None and amt is None: M("content.benefits.maxAmount")

        # ---------------- documents
        docs = []
        for k, r in enumerate(DOCS.get(code, []), start=1):
            docs.append(OrderedDict([
                ("documentId", "%s-DOC%03d" % (sid, k)), ("documentTypeId", None),
                ("name", val(r[2])), ("mandatory", mandatory(r[3])), ("mandatoryText", val(r[3])),
                ("issuingAuthorityId", None), ("issuingAuthorityText", val(r[4])),
                ("description", val(r[5])),
                ("estimatedCostInr", money(r[6])), ("estimatedCostText", val(r[6])),
                ("validityMonths", None), ("remarks", val(r[7])),
                ("downloadTemplateUrl", None), ("sampleCopyUrl", None),
                ("verificationPortalUrl", None), ("sourceUrl", val(r[8])),
            ]))
        if not docs: M("content.requiredDocuments")

        # ---------------- application
        mode_t = val(i[18]); mode = app_mode(i[18])
        if mode is None and mode_t: unmapped.append(("applicationProcess.mode", mode_t))
        # URL fields must hold a URL. Prose in a URL column is not a URL.
        online_raw = val(i[20])
        online_url = online_raw if (online_raw or "").lower().startswith(("http://", "https://")) else None
        if online_raw and not online_url:
            tnotes.append("Application URL column held prose, not a URL; field set null")
        application = OrderedDict([
            ("mode", mode), ("modeText", mode_t),
            ("onlineUrl", online_url), ("offlineDetails", None),
            ("applicationFeeInr", None), ("applicationFeeText", None),
            ("steps", []), ("services", []),
        ])
        if not mode: M("content.applicationProcess.mode")
        if not application["onlineUrl"]: M("content.applicationProcess.onlineUrl")
        M("content.applicationProcess.steps")
        M("content.applicationProcess.services",
          "Source service rows are generic placeholders carrying no service detail")

        timeline = {"opensOn": None, "closesOn": None, "isRollingIntake": None,
                    "processingDurationDays": None, "cycles": [], "text": None}
        M("content.applicationTimeline")

        contacts = {"national": [], "state": [], "district": [], "helplines": []}
        M("content.contacts")
        M("content.faqs")

        # ---------------- sources
        sources, sn = [], 0
        def add_src(url, stype, primary=False, title=None):
            nonlocal sn
            u = val(url)
            if not u or not u.lower().startswith("http"): return None
            for s in sources:
                if s["url"] == u:
                    if primary: s["isPrimary"] = True
                    return s["sourceId"]
            sn += 1
            sid_ = "%s-SRC%03d" % (sid, sn)
            sources.append(OrderedDict([
                ("sourceId", sid_), ("sourceType", stype), ("title", title),
                ("reference", None), ("publisherId", None), ("publisherText", val(a[3])),
                ("url", u), ("documentFormat", "pdf" if u.lower().endswith(".pdf") else "html"),
                ("language", "en"), ("publishedOn", None), ("accessedOn", None),
                ("isPrimary", primary), ("isCurrent", True),
            ]))
            return sid_
        primary_id = add_src(i[25], "guideline", True, "Primary source")
        add_src(i[19], "official_website", False, "Official website")
        add_src(i[20], "application_portal", False, "Application portal")
        add_src(i[21], "guideline", False, "Scheme guidelines")
        eid = add_src(elig_src, "guideline", False, "Eligibility source")
        if not sources: M("content.sources")

        # ---------------- ai (extractive)
        ai_parts = [p for p in [summary, btext] if p]
        ai_summary = " ".join(ai_parts) if ai_parts else None
        used = []
        if summary: used.append("content.overview.summary")
        if btext: used.append("content.benefits.summary")
        sect = {}
        if crit: sect["eligibility"] = crit; used.append("content.eligibility.narrative.criteria")
        if btext: sect["benefits"] = btext
        if mode_t: sect["application"] = mode_t; used.append("content.applicationProcess.modeText")
        ai_populated = bool(ai_summary or sect)
        ai = OrderedDict([
            ("summary", ai_summary), ("sectionSummaries", sect),
            ("generationMode", "extractive"), ("confidence", None),
            ("generatedBy", GENERATED_BY if ai_populated else None),
            ("generatedAt", GENERATED_AT if ai_populated else None),
            ("sourceFieldsUsed", used), ("reviewedBy", None), ("reviewedAt", None),
            ("isApproved", False),
        ])
        if not ai_summary: M("ai.summary")

        # ---------------- verification
        vstatus = verif_status(i[26], vstat)
        verification = OrderedDict([
            ("status", vstatus), ("statusText", vstat),
            ("isVerified", (val(i[26]) or "").lower().startswith("y")),
            ("verifiedAgainst", [x for x in [eid or primary_id] if x]),
            ("verifiedBy", None), ("verifiedAt", None),
            ("confidence", {"verified": "high", "partially_verified": "medium"}.get(vstatus, "low")),
            ("researchStatus", val(a[5])), ("notes", vnotes),
            ("missingFields", miss), ("disputedFields", disputed), ("reviewDueOn", None),
        ])

        # ---------------- identity
        legacy = [{"system": "tn_spreadsheet", "code": code}]
        if p4 and val(p4.get("Scheme ID")):
            legacy.append({"system": "legacy_json", "code": val(p4["Scheme ID"])})
        ac = acronym_of(name)
        identity = OrderedDict([
            ("id", sid), ("entityType", "scheme"), ("code", code), ("legacyCodes", legacy),
            ("name", name), ("shortName", ac), ("acronym", ac), ("slug", slugify(name)),
            ("language", "en"), ("status", scheme_status(i[22])),
        ])

        kw = set()
        for txt in [name, classification["sectorsText"], beneficiary]:
            if txt:
                kw |= {w for w in re.findall(r"[A-Za-z]{4,}", txt.lower())
                       if w not in {"scheme", "schemes", "enterprises", "enterprise", "tamil",
                                    "nadu", "state", "central", "government", "under", "with",
                                    "their", "that", "this", "from", "eligible"}}
        aliases = [x for x in [name, ac, code] if x]

        rec = OrderedDict([
            ("identity", identity),
            ("content", OrderedDict([
                ("classification", classification), ("overview", overview),
                ("objectives", [objective] if objective else []),
                ("targetBeneficiaries", {"description": beneficiary, "beneficiaryTypes": [],
                                         "enterpriseTypes": [], "businessStages": [],
                                         "specialCategories": structured["specialCategory"]["values"]}),
                ("eligibility", eligibility), ("benefits", benefits),
                ("requiredDocuments", docs), ("applicationProcess", application),
                ("applicationTimeline", timeline), ("contacts", contacts),
                ("faqs", []), ("sources", sources),
            ])),
            ("relationships", {"references": []}),
            ("localization", {"en": {"name": name, "shortName": ac, "summary": summary,
                                     "description": summary, "objective": objective,
                                     "eligibilityText": crit, "benefitsText": btext,
                                     "applicationText": mode_t},
                              "ta": {k: None for k in ["name", "shortName", "summary", "description",
                                                       "objective", "eligibilityText", "benefitsText",
                                                       "applicationText"]},
                              "hi": {k: None for k in ["name", "shortName", "summary", "description",
                                                       "objective", "eligibilityText", "benefitsText",
                                                       "applicationText"]}}),
            ("search", {"keywords": sorted(kw)[:40], "synonyms": [], "aliases": aliases,
                        "crossReferences": [], "searchRank": None, "boostTerms": []}),
            ("ai", ai), ("verification", verification),
            ("analytics", {"popularity": None, "viewCount": None, "saveCount": None,
                           "actionCount": None, "lastAggregatedAt": None}),
            ("metadata", OrderedDict([("createdAt", GENERATED_AT), ("updatedAt", GENERATED_AT),
                                      ("catalogVersion", CATALOG_VERSION),
                                      ("schemaVersion", SCHEMA_VERSION),
                                      ("recordStatus", "published"), ("revision", 1)])),
            ("provenance", OrderedDict([
                ("defaultSourceTier", DEFAULT_TIER), ("primarySourceId", primary_id),
                ("contributingSourceIds", [s["sourceId"] for s in sources]),
                ("extractionMethod", "automated"), ("extractedAt", GENERATED_AT),
                ("pipelineVersion", PIPELINE_VERSION), ("fieldSources", fsrc),
                ("transformationNotes", tnotes),
            ])),
        ])
        records.append(rec)

    # ---------------------------------------------------------------- write
    def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    def sha(o): return "sha256:" + hashlib.sha256(canon(o).encode("utf-8")).hexdigest()

    catalog = OrderedDict([
        ("metadata", OrderedDict([("catalogName", "scheme"), ("schemaVersion", SCHEMA_VERSION),
                                  ("catalogVersion", CATALOG_VERSION), ("generatedAt", GENERATED_AT),
                                  ("language", "en"), ("recordCount", len(records)),
                                  ("checksum", sha(records))])),
        ("data", records)])
    cpath = os.path.join(OUT, "scheme_catalog.json")
    with open(cpath, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)

    mdata = [OrderedDict([
        ("catalogRelease", CATALOG_VERSION), ("schemaVersion", SCHEMA_VERSION),
        ("releasedAt", GENERATED_AT),
        ("compatibility", {"minAppVersion": None, "supersedes": None}),
        ("files", [OrderedDict([("fileName", "scheme_catalog.json"), ("catalogName", "scheme"),
                                ("schemaVersion", SCHEMA_VERSION), ("recordCount", len(records)),
                                ("byteSize", os.path.getsize(cpath)), ("checksum", sha(records)),
                                ("required", True)])]),
        ("reservedFiles", ["common_catalog.json", "authority_catalog.json", "finance_catalog.json",
                           "tax_catalog.json", "treds_catalog.json", "csr_catalog.json",
                           "export_catalog.json", "institution_catalog.json",
                           "knowledge_catalog.json", "search_index.json",
                           "translations_en.json", "translations_ta.json"])])]
    manifest = OrderedDict([
        ("metadata", OrderedDict([("catalogName", "manifest"), ("schemaVersion", SCHEMA_VERSION),
                                  ("catalogVersion", CATALOG_VERSION), ("generatedAt", GENERATED_AT),
                                  ("language", "en"), ("recordCount", 1), ("checksum", sha(mdata))])),
        ("data", mdata)])
    with open(os.path.join(OUT, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    with open(os.path.join(OUT, "unmapped_values.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f); w.writerow(["field", "sourceValue", "occurrences"])
        for (fl, v), n in sorted(Counter(unmapped).items(), key=lambda x: -x[1]): w.writerow([fl, v, n])

    json.dump({"orphanDocRows": orphan_docs, "backfills": backfill_log,
               "schemes": len(records), "repairedCodes": repaired,
               "t4Matched": sum(1 for r in records
                                if any(l["system"] == "legacy_json" for l in r["identity"]["legacyCodes"]))},
              open(os.path.join(WORK, "stage_a_stats.json"), "w"), indent=2)
    print(f"schemes={len(records)} docs={sum(len(r['content']['requiredDocuments']) for r in records)} "
          f"orphanDocRows={orphan_docs} repairedCodes={len(repaired)} "
          f"backfills={len(backfill_log)} unmapped={len(set(unmapped))}")

if __name__ == "__main__":
    main()
