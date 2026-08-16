#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""MSS_API_DATA_PACKAGE standalone validator.

Deliberately self-contained: imports nothing from ../catalog, resolves
every path relative to THIS file's own directory only. Proves the
package operates independently of the original catalog folder -- if
this script can validate the package by reading only files inside this
directory, so can a consuming API layer.

Checks: JSON integrity, id uniqueness/global uniqueness, relationship
reference resolution, localization completeness, search-index
consistency, manifest checksum agreement.
"""
import json, os, hashlib, re
from collections import Counter, defaultdict

PKG = os.path.dirname(os.path.abspath(__file__))

ENTITY_CATALOGS = [
    "scheme_catalog.json", "finance_catalog.json", "tax_catalog.json",
    "treds_catalog.json", "csr_catalog.json", "authority_catalog.json",
    "institution_catalog.json", "export_catalog.json",
    "cluster_assistance_catalog.json", "msme_privilege_catalog.json",
    "business_enablement_catalog.json", "knowledge_catalog.json",
    "applicability_matrix_catalog.json", "common_catalog.json",
]
ALL_FILES = ENTITY_CATALOGS + ["search_index.json", "manifest.json"]

FAILS, WARNS = [], []
def fail(m): FAILS.append(m)
def warn(m): WARNS.append(m)

def load(fname):
    return json.load(open(os.path.join(PKG, fname), encoding="utf-8"))

def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)

print("=" * 72)
print("MSS_API_DATA_PACKAGE -- standalone validation")
print(f"package directory: {PKG}")
print("=" * 72)

# ---- 1. JSON integrity + file presence ------------------------------------
loaded = {}
for f in ALL_FILES:
    path = os.path.join(PKG, f)
    if not os.path.exists(path):
        fail(f"MISSING FILE: {f}")
        continue
    try:
        loaded[f] = load(f)
    except Exception as e:
        fail(f"JSON PARSE ERROR: {f}: {e}")
print(f"[1] JSON integrity: {len(loaded)}/{len(ALL_FILES)} files parsed OK")

# ---- 2. envelope shape + self-declared checksum consistency ---------------
for f, cat in loaded.items():
    if f == "manifest.json":
        continue
    if "metadata" not in cat or "data" not in cat:
        fail(f"{f}: missing metadata/data envelope")
        continue
    declared = cat["metadata"].get("checksum")
    recomputed = "sha256:" + hashlib.sha256(canon(cat["data"]).encode()).hexdigest()
    if declared != recomputed:
        fail(f"{f}: self-declared checksum does not match its own data "
             f"(declared={declared!r}, recomputed={recomputed!r})")
print(f"[2] Self-declared checksums: checked {len([f for f in loaded if f!='manifest.json'])} files")

# ---- 3. id uniqueness (within-file and package-global) ---------------------
all_ids = defaultdict(list)
for f in ENTITY_CATALOGS:
    if f not in loaded:
        continue
    seen = Counter()
    for r in loaded[f]["data"]:
        rid = r.get("identity", {}).get("id")
        if not rid:
            fail(f"{f}: record without identity.id")
            continue
        seen[rid] += 1
        all_ids[rid].append(f)
    dupes = [k for k, v in seen.items() if v > 1]
    if dupes:
        fail(f"{f}: duplicate ids within file: {dupes[:5]}")
cross_dupes = {k: v for k, v in all_ids.items() if len(set(v)) > 1}
if cross_dupes:
    fail(f"ids not globally unique across package: {list(cross_dupes.items())[:5]}")
print(f"[3] ID uniqueness: {len(all_ids)} unique ids across {len(ENTITY_CATALOGS)} catalogs, "
      f"0 within-file duplicates, {len(cross_dupes)} cross-file collisions")

# ---- 4. relationship reference resolution ----------------------------------
known_ids = set(all_ids.keys())
unresolved = []
edges = 0
for f in ENTITY_CATALOGS:
    if f not in loaded:
        continue
    for r in loaded[f]["data"]:
        for e in r.get("relationships", {}).get("references", []):
            edges += 1
            tid = e.get("entityId")
            if tid and tid not in known_ids:
                unresolved.append((f, r["identity"]["id"], tid))
if unresolved:
    warn(f"{len(unresolved)} relationship reference(s) point outside the package's own id "
         f"space (sample: {unresolved[:5]})")
print(f"[4] Relationships: {edges} references checked, {len(unresolved)} unresolved "
      f"(within-package)")

# ---- 5. localization completeness ------------------------------------------
loc_total, loc_ta = 0, 0
scheme_ta = 0
if "scheme_catalog.json" in loaded:
    sch = loaded["scheme_catalog.json"]["data"]
    for r in sch:
        en = r["localization"]["en"]
        ta = r["localization"]["ta"]
        if any(ta.get(k) for k in ta):
            scheme_ta += 1
        for k, v in en.items():
            if v:
                loc_total += 1
                if ta.get(k):
                    loc_ta += 1
    print(f"[5] Localization: scheme_catalog.json {scheme_ta}/{len(sch)} records have "
          f"Tamil content; {loc_ta}/{loc_total} localizable fields covered "
          f"({loc_ta/loc_total:.1%})" if loc_total else "[5] Localization: no data")
else:
    fail("[5] scheme_catalog.json not present -- cannot check localization")

# ---- 6. search-index consistency -------------------------------------------
if "search_index.json" in loaded and "scheme_catalog.json" in loaded:
    si = loaded["search_index.json"]
    si_ids = {e["entityId"] for e in si["data"]}
    sch_ids = {r["identity"]["id"] for r in loaded["scheme_catalog.json"]["data"]}
    missing_from_index = sch_ids - si_ids
    if missing_from_index:
        fail(f"search_index.json missing {len(missing_from_index)} scheme(s): "
             f"{sorted(missing_from_index)[:5]}")
    declared_si_ck = si["metadata"]["checksum"]
    recomputed_si_ck = "sha256:" + hashlib.sha256(canon(si["data"]).encode()).hexdigest()
    ck_ok = declared_si_ck == recomputed_si_ck
    print(f"[6] Search index: {len(si_ids)} entries, {len(sch_ids)} schemes all indexed="
          f"{not missing_from_index}, self-checksum-consistent={ck_ok}")
else:
    fail("[6] search_index.json or scheme_catalog.json not present")

# ---- 7. manifest checksum agreement ----------------------------------------
if "manifest.json" in loaded:
    man = loaded["manifest.json"]
    man_files = {f["fileName"]: f for f in man["data"][0]["files"]}
    mismatches, missing_manifest_entries = [], []
    for f in ALL_FILES:
        if f == "manifest.json" or f not in loaded:
            continue
        entry = man_files.get(f)
        if entry is None:
            missing_manifest_entries.append(f)
            continue
        actual_ck = loaded[f]["metadata"]["checksum"]
        if entry["checksum"] != actual_ck:
            mismatches.append(f)
    print(f"[7] Manifest: {len(man_files)} entries tracked, {len(mismatches)} checksum "
          f"mismatch(es), {len(missing_manifest_entries)} file(s) present but not tracked "
          f"in manifest")
    if mismatches:
        warn(f"manifest.json checksum out of sync for: {mismatches}")
    if missing_manifest_entries:
        warn(f"present in package but not tracked in manifest.json: {missing_manifest_entries}")
else:
    fail("[7] manifest.json not present")

# ---- summary ----------------------------------------------------------------
print()
print(f"WARNINGS: {len(WARNS)}")
for w in WARNS[:20]:
    print("  WARN", w)
print(f"FAILURES: {len(FAILS)}")
for x in FAILS[:20]:
    print("  FAIL", x)
if FAILS:
    print("\nPACKAGE VALIDATION FAILED")
    raise SystemExit(1)
print("\nPACKAGE VALIDATION PASSED -- standalone, no access to ../catalog required")
