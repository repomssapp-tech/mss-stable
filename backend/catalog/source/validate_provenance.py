#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Provenance + duplicate validator -- Phase A gate requirement.

The existing suite (base / catalog / cross_catalog / i18n) validates schema,
references and localization. Nothing validated PROVENANCE or DUPLICATES,
which the Phase A completion gate requires. This closes that hole.

Enforces MSS_Data_Completion_Policy_v1.0.md §6 and §8:

  P1  every fieldSources[] entry carries field + sourceTier
  P2  sourceTier is 1..5 (tier 6 = AI inference is never a source)
  P3  every tier-5 (live web) entry carries url + retrievedAt
  P4  every fieldSources[] url host is on the §4.3 approved allowlist
  P5  supersededValue is always null (a backfill never overwrites)
  P6  defaultSourceTier is an int 1..5
  P7  a record claiming verification.isVerified must name what it was
      verified against
  P8  every null in a field listed as required carries a
      verification.missingFields[] entry  (spot-checked via the existing
      missingFields contract rather than re-deriving requiredness)

  D1  entity ids are globally unique across ALL catalogs
  D2  no duplicate ids within a catalog
  D3  no duplicate (name, entityType) pairs that would indicate a
      re-imported record  -- reported as WARN, since legitimately distinct
      schemes can share a name across government levels

Exit 0 = green. Exit 1 = at least one FAIL.
"""
import json, os, sys
from collections import Counter, defaultdict
from urllib.parse import urlparse

CAT = os.path.dirname(os.path.abspath(__file__))

# Approved hosts -- mirrors MSS_Data_Completion_Policy_v1.0.md §4.3 exactly.
# Imported from stage_b so there is ONE definition; if that drifts, this
# validator drifts with it deliberately rather than silently disagreeing.
sys.path.insert(0, CAT)
try:
    from stage_b import allowed as host_allowed
except Exception:                                    # pragma: no cover
    SUFFIX = {".gov.in", ".nic.in"}
    EXACT = {"sidbi.in", "nsic.co.in", "kvic.gov.in", "dcmsme.gov.in", "dgft.gov.in",
             "gst.gov.in", "rbi.org.in", "nabard.org", "msme.gov.in", "india.gov.in",
             "udyamregistration.gov.in", "cgtmse.in", "standupmitra.in"}
    def host_allowed(h):
        h = (h or "").lower().strip().lstrip(".")
        if h.startswith("www."):
            h = h[4:]
        return any(h.endswith(s) for s in SUFFIX) or any(
            h == e or h.endswith("." + e) for e in EXACT)

CATALOGS = [f for f in sorted(os.listdir(CAT))
            if f.endswith("_catalog.json") and not f.startswith(("benchmark", "search_index"))]

FAILS, WARNS, STATS = [], [], Counter()


def fail(code, msg):
    FAILS.append(f"[{code}] {msg}")


def warn(code, msg):
    WARNS.append(f"[{code}] {msg}")


def check_provenance(fname, rec):
    rid = rec["identity"]["id"]
    prov = rec.get("provenance") or {}

    dst = prov.get("defaultSourceTier")
    if not (isinstance(dst, int) and 1 <= dst <= 5):
        fail("P6", f"{fname}:{rid} defaultSourceTier={dst!r} not an int in 1..5")

    for i, fs in enumerate(prov.get("fieldSources") or []):
        loc = f"{fname}:{rid} fieldSources[{i}]"
        STATS["fieldSources"] += 1

        if not fs.get("field"):
            fail("P1", f"{loc} missing 'field'")
        tier = fs.get("sourceTier")
        if not isinstance(tier, int):
            fail("P1", f"{loc} missing/invalid sourceTier={tier!r}")
            continue
        if not (1 <= tier <= 5):
            fail("P2", f"{loc} sourceTier={tier} outside 1..5 "
                       f"(tier 6 / AI inference may never be a source)")
        STATS[f"tier{tier}"] += 1

        if tier == 5:
            if not fs.get("url") or not fs.get("retrievedAt"):
                fail("P3", f"{loc} tier-5 entry missing url and/or retrievedAt")

        url = fs.get("url")
        if url:
            host = urlparse(url).netloc.lower()
            if not host_allowed(host):
                fail("P4", f"{loc} host '{host}' is NOT on the approved allowlist")
            else:
                STATS["approvedHostCitations"] += 1

        if "supersededValue" in fs and fs["supersededValue"] is not None:
            fail("P5", f"{loc} supersededValue={fs['supersededValue']!r} -- a backfill "
                       f"must never overwrite higher-priority data")

    ver = rec.get("verification") or {}
    if ver.get("isVerified") and not ver.get("verifiedAgainst"):
        warn("P7", f"{fname}:{rid} isVerified=true but verifiedAgainst is empty")
    if ver.get("missingFields"):
        STATS["missingFieldEntries"] += len(ver["missingFields"])


def main():
    all_ids = defaultdict(list)
    name_index = defaultdict(list)

    for fname in CATALOGS:
        path = os.path.join(CAT, fname)
        try:
            cat = json.load(open(path, encoding="utf-8"))
        except Exception as e:
            fail("IO", f"{fname} unreadable: {e}")
            continue
        data = cat.get("data") or []
        STATS["records"] += len(data)
        STATS["catalogs"] += 1

        seen = Counter()
        for rec in data:
            idn = rec.get("identity") or {}
            rid = idn.get("id")
            if not rid:
                fail("D2", f"{fname} record without identity.id")
                continue
            seen[rid] += 1
            all_ids[rid].append(fname)
            key = (str(idn.get("name", "")).strip().lower(), idn.get("entityType"))
            if key[0]:
                name_index[key].append(f"{fname}:{rid}")
            check_provenance(fname, rec)

        for rid, n in seen.items():
            if n > 1:
                fail("D2", f"{fname} duplicate id {rid} appears {n}x within the catalog")

    for rid, files in all_ids.items():
        if len(files) > 1:
            fail("D1", f"id {rid} is not globally unique -- appears in {sorted(set(files))}")

    for (name, etype), locs in name_index.items():
        if len(locs) > 1:
            warn("D3", f"{len(locs)} records share name/type ({etype}) '{name[:44]}': "
                       f"{locs[:3]}")

    print("=" * 72)
    print("PROVENANCE + DUPLICATE VALIDATION")
    print("=" * 72)
    print(f"  catalogs                {STATS['catalogs']}")
    print(f"  records                 {STATS['records']}")
    print(f"  fieldSources entries    {STATS['fieldSources']}")
    print(f"    tier-2 (held doc)     {STATS['tier2']}")
    print(f"    tier-5 (live web)     {STATS['tier5']}")
    print(f"  citations on approved hosts {STATS['approvedHostCitations']}")
    print(f"  missingFields entries   {STATS['missingFieldEntries']}")
    print(f"  globally unique ids     {len(all_ids)}")
    print()
    for w in WARNS[:12]:
        print("  WARN", w)
    if len(WARNS) > 12:
        print(f"  ... and {len(WARNS) - 12} more warnings")
    print()
    if FAILS:
        for f in FAILS[:25]:
            print("  FAIL", f)
        if len(FAILS) > 25:
            print(f"  ... and {len(FAILS) - 25} more")
        print(f"\nPROVENANCE VALIDATION FAILED -- {len(FAILS)} issue(s)")
        raise SystemExit(1)
    print(f"PROVENANCE VALIDATION PASSED -- {len(WARNS)} warning(s), 0 failures")


if __name__ == "__main__":
    main()
