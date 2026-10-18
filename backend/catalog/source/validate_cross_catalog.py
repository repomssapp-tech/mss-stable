#!/usr/bin/env python3
"""Cross-catalog referential integrity — base rule 15, now that targets exist."""
import json, os, sys, re
from collections import Counter

CAT = os.path.dirname(os.path.abspath(__file__))
PRESENT = {}
for f in os.listdir(CAT):
    if f.endswith("_catalog.json"):
        c = json.load(open(os.path.join(CAT, f), encoding="utf-8"))
        for r in c["data"]:
            PRESENT[r["identity"]["id"]] = (f, r["identity"]["entityType"])

PREFIX_CATALOG = {"SCH": "scheme_catalog.json", "AUTH": "authority_catalog.json",
                  "CMN": "common_catalog.json", "INST": "institution_catalog.json",
                  "FIN": "finance_catalog.json", "TAX": "tax_catalog.json",
                  "TDS": "treds_catalog.json", "CSR": "csr_catalog.json",
                  "EXP": "export_catalog.json", "KNOW": "knowledge_catalog.json"}
ID = re.compile(r"^(SCH|AUTH|INST|FIN|TAX|TDS|CSR|EXP|KNOW|CMN)\d{6}$")

fails, checked, deferred = [], 0, Counter()

def check(src, path, val):
    global checked
    if not isinstance(val, str) or not ID.match(val):
        return
    checked += 1
    pref = ID.match(val).group(1)
    target = PREFIX_CATALOG[pref]
    if val in PRESENT:
        return
    if not os.path.exists(os.path.join(CAT, target)):
        deferred[target] += 1          # permitted: target catalog absent from release
    else:
        fails.append(f"{src} {path} -> {val} MISSING from {target}")

def walk(src, o, p=""):
    if isinstance(o, dict):
        for k, v in o.items():
            if k.endswith(("Id", "IdS")) or k in ("entityId",) or k.endswith("Ids"):
                if isinstance(v, list):
                    for n, x in enumerate(v): check(src, f"{p}.{k}[{n}]", x)
                else:
                    check(src, f"{p}.{k}", v)
            walk(src, v, f"{p}.{k}")
    elif isinstance(o, list):
        for n, v in enumerate(o): walk(src, v, f"{p}[{n}]")

for f in sorted(os.listdir(CAT)):
    if not f.endswith("_catalog.json"): continue
    c = json.load(open(os.path.join(CAT, f), encoding="utf-8"))
    for r in c["data"]:
        walk(f"{f}:{r['identity']['id']}", r)

# rule 42 — every authority *Id in scheme content also appears in relationships.references
sc = os.path.join(CAT, "scheme_catalog.json")
r42 = 0
if os.path.exists(sc):
    for r in json.load(open(sc, encoding="utf-8"))["data"]:
        g = r["content"]["classification"]["government"]
        refd = {x["entityId"] for x in r["relationships"]["references"]}
        for aid in [g["ministryId"], g["departmentId"]] + g["implementingAgencyIds"]:
            if aid and aid not in refd:
                fails.append(f"[42] {r['identity']['id']} {aid} not in references"); r42 += 1

# Phase 3 — graph symmetry: every edge whose target exists must carry its inverse
INVERSE = {"references": "referenced_by", "referenced_by": "references",
           "supersedes": "superseded_by", "superseded_by": "supersedes",
           "parent_of": "child_of", "child_of": "parent_of",
           "administers": "administered_by", "administered_by": "administers",
           "offers": "offered_under", "offered_under": "offers",
           "provides": "provided_by", "provided_by": "provides",
           "implements": "implemented_by", "implemented_by": "implements",
           "evidences": "evidenced_by", "evidenced_by": "evidences",
           "requires": "required_by", "required_by": "requires",
           "classifies": "classified_as", "classified_as": "classifies",
           "related_to": "related_to"}
edges, undeclared = set(), Counter()
for f in sorted(os.listdir(CAT)):
    if not f.endswith("_catalog.json"): continue
    for r in json.load(open(os.path.join(CAT, f), encoding="utf-8"))["data"]:
        for e in r["relationships"]["references"]:
            edges.add((r["identity"]["id"], e["relationType"], e["entityId"]))
            if e["relationType"] not in INVERSE:
                undeclared[e["relationType"]] += 1
asym = [(a, rel, b) for (a, rel, b) in edges
        if b in PRESENT and rel in INVERSE and (b, INVERSE[rel], a) not in edges]
for a, rel, b in asym[:10]:
    fails.append(f"[P3] {a} --{rel}--> {b} has no inverse {INVERSE[rel]} on {b}")
if undeclared:
    fails.append(f"[14] relation types with no declared inverse: {dict(undeclared)}")

print(f"catalogs present: {sorted(set(v[0] for v in PRESENT.values()))}")
print(f"graph edges: {len(edges)} | asymmetric: {len(asym)}")
print(f"entities indexed: {len(PRESENT)}")
print(f"id references checked: {checked}")
if deferred:
    print(f"deferred (target catalog not in release): {dict(deferred)}")
if fails:
    print(f"\nCROSS-CATALOG FAILED — {len(fails)}")
    for x in fails[:20]: print("  ", x)
    sys.exit(1)
print("\nCROSS-CATALOG PASSED — every reference resolves or is deferred to an absent catalog")
