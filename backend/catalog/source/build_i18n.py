#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Multilingual upgrade -> 1.2.0-alpha.

Populates the EXISTING localization block (BaseEntity §5). No new mechanism,
no field changes type, no schema change.

Translation is dictionary + compositional only:
  T1 exact      dictionary hit on the whole string
  T2 pattern    "Ministry of X" -> "X அமைச்சகம்", "A for B" -> "B-க்கான A", "X Scheme" -> "X திட்டம்"
  T3 keyword    single-token search keywords
  T4 pending    no confident rendering -> stays null, logged

Protected tokens (IDs, URLs, email, phone, numbers, currency, %, dates, acronyms)
are never translated; they are masked before translation and restored after.
Every generated string is marked machine-generated in provenance.translations.
"""
import json, os, re, hashlib, sys
from collections import OrderedDict, Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ta_dictionary import TERMS, STATES_TA, DISTRICTS_TA, KEYWORDS_TA, ACRONYMS, all_pairs

CAT = "/sessions/practical-charming-hypatia/mnt/Plan/catalog"
REL = "1.33.0-alpha"
AT = "2026-08-04T00:00:00Z"
ENGINE = "mss-i18n-dictionary-1.0.0"

# ------------------------------------------------------------------ protection
PROTECT = [
    re.compile(r"https?://\S+"),                       # urls
    re.compile(r"\b[\w.+-]+@[\w-]+\.[\w.]+\b"),        # email
    re.compile(r"\b(?:SCH|AUTH|CMN|INST|FIN|TAX|TDS|CSR|EXP|KNOW)\d{6}\b"),
    re.compile(r"\bTN\d{3}\b|\bIN\d{3}\b"),            # scheme codes
    re.compile(r"₹\s?[\d,.]+(?:\s?(?:lakh|crore|lakhs|crores))?", re.I),
    re.compile(r"\b\d+(?:\.\d+)?\s?%"),                 # percentages
    re.compile(r"\b\d{4}-\d{2}-\d{2}\b|\b\d{1,2}/\d{1,2}/\d{2,4}\b"),
    re.compile(r"\b\d+(?:[.,]\d+)*\b"),                 # any number
    re.compile(r"\b(?:" + "|".join(sorted(map(re.escape, ACRONYMS), key=len, reverse=True)) + r")\b"),
]

def mask(s):
    toks, out, i = [], s, 0
    for pat in PROTECT:
        def rep(m):
            nonlocal i
            toks.append(m.group(0)); i += 1
            return f"\u00abT{len(toks)-1}\u00bb"
        out = pat.sub(rep, out)
    return out, toks

def unmask(s, toks):
    for n, t in enumerate(toks):
        s = s.replace(f"\u00abT{n}\u00bb", t)
    return s

# ------------------------------------------------------------------ translation
DICT = {}
for d in (TERMS, STATES_TA, DISTRICTS_TA):
    for k, v in d.items(): DICT.setdefault(k.strip().lower(), v)
KW = {k.lower(): v for k, v in KEYWORDS_TA.items()}

MINISTRY_OF = re.compile(r"^Ministry of (.+)$", re.I)
DEPARTMENT_OF = re.compile(r"^Department of (.+)$", re.I)
DIRECTORATE_OF = re.compile(r"^Directorate(?: General)? of (.+)$", re.I)
X_DEPARTMENT = re.compile(r"^(.+?) Department$", re.I)
X_BOARD = re.compile(r"^(.+?) (Board|Commission|Corporation|Council|Authority|Mission)$", re.I)
A_FOR_B = re.compile(r"^(.+?) for (.+)$", re.I)
X_SCHEME = re.compile(r"^(.+?) (Scheme|Programme|Yojana|Mission|Fund)$", re.I)

SUFFIX = {"Board": "வாரியம்", "Commission": "ஆணையம்", "Corporation": "கழகம்",
          "Council": "மன்றம்", "Authority": "அதிகாரசபை", "Mission": "இயக்கம்",
          "Scheme": "திட்டம்", "Programme": "திட்டம்", "Yojana": "திட்டம்",
          "Fund": "நிதி"}

# ---- LLM contextual translations (highest priority; authored per semantic unit)
OVR = {}
_ovr_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ta_overrides.json")
if os.path.exists(_ovr_path):
    _o = json.load(open(_ovr_path, encoding="utf-8"))
    # Tamil Localization Completion Phase (2026-08-15) Task 3 added 5 new
    # domain sections (cluster_assistance/csr/treds/msme_privilege/
    # business_enablement) -- included here so their contextual overrides
    # actually get picked up by translate(), same as the original 3.
    for sect in ("common", "authority", "scheme", "cluster_assistance", "csr",
                 "treds", "msme_privilege", "business_enablement", "knowledge"):
        for k, v in _o.get(sect, {}).items():
            if v is None:
                continue
            OVR[" ".join(k.split()).lower()] = v
    OVR_KW = {k.lower(): v for k, v in _o.get("keywords", {}).items()}
else:
    OVR_KW = {}

def _lookup(s):
    return DICT.get(s.strip().lower())

def translate(s, allow_pattern=True, depth=0):
    """Return (tamil, method) or (None, 'pending')."""
    if not s or not isinstance(s, str) or depth > 3:
        return None, "pending"
    t = " ".join(s.split())
    ov = OVR.get(t.lower())
    if ov: return ov, "llm_contextual_translation"
    hit = _lookup(t)
    if hit: return hit, "dictionary"

    masked, toks = mask(t)
    core = " ".join(masked.split())
    hit = _lookup(core)
    if hit: return unmask(hit, toks), "dictionary"
    # a string that is purely protected tokens needs no translation
    if re.fullmatch(r"[\d\s.,;:()/&+-]*", core):
        return t, "verbatim"
    if not allow_pattern:
        return None, "pending"

    for pat, tmpl in ((MINISTRY_OF, "{} அமைச்சகம்"), (DEPARTMENT_OF, "{} துறை"),
                      (DIRECTORATE_OF, "{} இயக்குநரகம்")):
        m = pat.match(core)
        if m:
            inner, meth = translate(unmask(m.group(1), toks), True, depth + 1)
            if inner: return tmpl.format(inner), "pattern"
    m = X_DEPARTMENT.match(core)
    if m:
        inner, _ = translate(unmask(m.group(1), toks), True, depth + 1)
        if inner: return f"{inner} துறை", "pattern"
    m = X_BOARD.match(core)
    if m:
        inner, _ = translate(unmask(m.group(1), toks), True, depth + 1)
        if inner: return f"{inner} {SUFFIX[m.group(2).title()]}", "pattern"
    m = X_SCHEME.match(core)
    if m:
        inner, _ = translate(unmask(m.group(1), toks), True, depth + 1)
        if inner: return f"{inner} {SUFFIX[m.group(2).title()]}", "pattern"
    m = A_FOR_B.match(core)
    if m:
        a, _ = translate(unmask(m.group(1), toks), True, depth + 1)
        b, _ = translate(unmask(m.group(2), toks), True, depth + 1)
        if a and b: return f"{b}-க்கான {a}", "pattern"
    return None, "pending"

def translate_keyword(w):
    return OVR_KW.get(w.strip().lower()) or KW.get(w.strip().lower())

# ------------------------------------------------------------------ apply
def load(f): return json.load(open(os.path.join(CAT, f), encoding="utf-8"))
def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)

def upgrade(fname, stat):
    cat = load(fname)
    for r in cat["data"]:
        loc = r["localization"]
        methods, done, pending = {}, 0, 0
        for field, en in loc["en"].items():
            if not en:
                loc["ta"][field] = None
                continue
            ta, meth = translate(en)
            if ta and meth != "verbatim":
                loc["ta"][field] = ta
                methods[field] = meth
                done += 1; stat[f"{fname}:{meth}"] += 1
            else:
                loc["ta"][field] = None
                pending += 1; stat[f"{fname}:pending"] += 1
        # bilingual search terms — existing keys, values become {en, ta}
        s = r["search"]
        if isinstance(s["keywords"], list):
            en_kw = s["keywords"]
            ta_kw = [t for t in (translate_keyword(w) for w in en_kw) if t]
            s["keywords"] = {"en": en_kw, "ta": sorted(set(ta_kw))}
            en_al = s["aliases"]
            s["aliases"] = {"en": en_al, "ta": []}
            stat[f"{fname}:kwTa"] += len(ta_kw)
        # machine-generated marker (provenance, not content)
        llm = sum(1 for v in methods.values() if v == "llm_contextual_translation")
        r["provenance"]["translations"] = OrderedDict([
            ("ta", OrderedDict([
                ("method", "llm_contextual_translation" if llm else "dictionary"),
                ("engine", "Claude" if llm else ENGINE),
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
        # idempotent: this pass may run many times as batches land. Drop any
        # localization.ta entry it wrote before, then re-state the current position.
        r["verification"]["missingFields"] = [
            m for m in r["verification"]["missingFields"] if m["field"] != "localization.ta"]
        if pending:
            r["verification"]["missingFields"].append({
                "field": "localization.ta",
                "reason": f"{pending} localizable field(s) have no confident Tamil "
                          f"rendering from the dictionary; not machine-guessed"})
        r["metadata"]["catalogVersion"] = REL
        r["metadata"]["updatedAt"] = AT
        r["metadata"]["revision"] = r["metadata"]["revision"] + 1
    cat["metadata"]["catalogVersion"] = REL
    cat["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(cat["data"]).encode()).hexdigest()
    json.dump(cat, open(os.path.join(CAT, fname), "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)
    return cat

def main():
    stat = Counter()
    for f in ("common_catalog.json", "authority_catalog.json", "scheme_catalog.json"):
        upgrade(f, stat)

    # ---- translation_dictionary.json
    pairs = all_pairs()
    doc = OrderedDict([
        ("metadata", OrderedDict([
            ("name", "MSS Translation Dictionary"), ("version", "1.0.0"),
            ("catalogRelease", REL), ("generatedAt", AT),
            ("sourceLanguage", "en"), ("targetLanguages", ["ta"]),
            ("entryCount", len(pairs)),
            ("preservedAcronyms", sorted(set(ACRONYMS))),
            ("usage", "Reused by every future catalog generation. Extend rather than "
                      "re-derive; entries here are authoritative for MSS Tamil terminology."),
            ("status", "machine-authored, awaiting linguistic review")])),
        ("entries", OrderedDict(sorted(pairs.items(), key=lambda kv: kv[0].lower())))])
    json.dump(doc, open(os.path.join(CAT, "translation_dictionary.json"), "w",
                        encoding="utf-8"), ensure_ascii=False, indent=2)

    for k in sorted(stat): print(f"   {k:44} {stat[k]}")
    print(f"\n   translation_dictionary.json entries = {len(pairs)}")

if __name__ == "__main__":
    main()
