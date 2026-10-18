#!/usr/bin/env python3
"""
Stage B -- Pass 2 (fill-only enrichment), batches 2-9.

Same discipline as stage_b_pass2.py's batch-1 run: every fill below is
hand-curated from evidence already recorded in Pass 1's results_N.json
notes (batches 2-9). Only `content.applicationProcess.mode` is targeted
this round -- the only field where the available Pass-1 evidence met the
same evidentiary bar used for batch 1 (a specific statement that THIS
scheme's own portal is an application/registration mechanism, not just
confirmation that the administering ministry/institution has a website).

Explicitly NOT filled this round, and why:
  - identity.status: every "unknown" status candidate's only evidence was a
    department/ministry HOMEPAGE confirmation, not scheme-specific current
    application data (the AABCS/NEEDS/UYEGP live-FY-stats pattern that
    justified fills in the batch-1 report). Homepage-live != scheme-live.
  - content.overview.lastUpdated: every "last updated" date found was a
    department HOMEPAGE FOOTER date (BIRAC, WCD, DST, TN Govt), not the
    specific scheme/source page's own date -- same rejection rule already
    applied in STAGE_B_PASS2_BATCH1_REPORT.md for DCMSME's homepage footer.
  - contacts: no phone/email was captured in this round's results_N.json
    notes (Pass 1 for batches 2-9 focused on domain/content confirmation,
    not contact extraction) -- nothing to structure without re-fetching,
    which is out of scope for a fill-only pass over already-verified data.

Guard: identical mechanism to stage_b_pass2.py -- snapshots every record
before the run and aborts if anything other than the intended `mode` paths
changed.
"""
import json, os, hashlib

CAT = os.path.dirname(os.path.abspath(__file__))
LIVE = os.path.join(CAT, "scheme_catalog.json")
RETRIEVED = "2026-08-14"

def load(p): return json.load(open(p, encoding="utf-8"))

FILLS = [
    {
        "schemeId": "SCH000092", "url": "https://cluster.dcmsme.gov.in/",
        "organization": "MSME Cluster Development Programme (DCMSME)",
        "note": "Confirmed official Cluster Development Programme portal -- application "
                "procedures for Common Facility Centers and Infrastructure Development "
                "described directly on-site (batch-2 Pass 1 fetch).",
    },
    {
        "schemeId": "SCH000109", "url": "https://pmvikas.minorityaffairs.gov.in/",
        "organization": "PM VIKAS (Ministry of Minority Affairs)",
        "note": "Confirmed official portal with 'login and registration options for various "
                "stakeholder groups' stated directly on-site (batch-5 Pass 1 fetch).",
    },
    {
        "schemeId": "SCH000123", "url": "https://pmsvanidhi.mohua.gov.in/",
        "organization": "PM SVANidhi (Ministry of Housing and Urban Affairs)",
        "note": "Confirmed official portal explicitly providing 'loan applications, "
                "dashboards, and scheme information' (batch-5 Pass 1 fetch).",
    },
    {
        "schemeId": "SCH000124", "url": "https://pmvishwakarma.gov.in/",
        "organization": "PM Vishwakarma (Ministry of MSME)",
        "note": "Confirmed official portal with 'registration processes, along with multiple "
                "login portals for different user categories (applicants, CSCs, ...)' "
                "stated directly on-site (batch-5 Pass 1 fetch).",
    },
    {
        "schemeId": "SCH000127", "url": "https://pmmvy.wcd.gov.in/",
        "organization": "PMMVY (Ministry of Women and Child Development)",
        "note": "Confirmed official portal providing 'application tracking, grievance "
                "filing, and mobile applications' as direct services (batch-6 Pass 1 fetch).",
    },
    {
        "schemeId": "SCH000152", "url": "https://www.sidbi.in/en/business-loan",
        "organization": "Small Industries Development Bank of India (SIDBI)",
        "note": "Confirmed official SIDBI Business Loan product page describing a 'Quick "
                "straight-through process' with online application (batch-7 Pass 1 fetch).",
    },
    {
        "schemeId": "SCH000196", "url": "https://udyamregistration.gov.in/",
        "organization": "Udyam Registration (Ministry of MSME)",
        "note": "Confirmed official self-registration government portal -- explicitly "
                "'the only Government Portal for MSME (Udyam) Registration', unambiguously "
                "online (batch-8 Pass 1 fetch).",
    },
]


def apply():
    cat = load(LIVE)
    idx = {r["identity"]["id"]: r for r in cat["data"]}
    pre_snapshot = {i: json.dumps(idx[i], sort_keys=True) for i in idx}

    applied, skipped = [], []
    for f in FILLS:
        rec = idx[f["schemeId"]]
        ap = rec["content"]["applicationProcess"]
        if ap["mode"] is not None:
            skipped.append((f["schemeId"], "mode no longer null -- not overwritten"))
            continue
        ap["mode"] = "online"
        prov = rec["provenance"]
        prov.setdefault("fieldSources", [])
        prov["fieldSources"].append({
            "field": "content.applicationProcess.mode", "value": "online", "sourceTier": 5,
            "sourceType": "official_website", "organization": f["organization"],
            "url": f["url"], "retrievedAt": RETRIEVED, "confidence": "high",
            "isBackfill": True, "supersededValue": None, "note": f["note"],
        })
        rec["verification"]["missingFields"] = [
            m for m in rec["verification"]["missingFields"]
            if m["field"] != "content.applicationProcess.mode"
        ]
        applied.append(f["schemeId"])

    # ---- GUARD: only content.applicationProcess.mode, provenance.fieldSources,
    # and verification.missingFields may differ on any touched record.
    bad = []
    for i, rec in idx.items():
        before = json.loads(pre_snapshot[i])
        if before == rec:
            continue
        b2, a2 = json.loads(json.dumps(before)), json.loads(json.dumps(rec))
        for blk in (b2, a2):
            blk["content"]["applicationProcess"]["mode"] = None
            blk["provenance"]["fieldSources"] = []
            blk["verification"]["missingFields"] = []
        if b2 != a2:
            bad.append(i)
    if bad:
        print(f"ABORT -- fields outside the intended target set changed on {len(bad)} "
              f"record(s): {bad[:5]}")
        raise SystemExit(1)

    def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    ck = "sha256:" + hashlib.sha256(canon(cat["data"]).encode()).hexdigest()
    prev_version = cat["metadata"]["catalogVersion"]
    new_version = prev_version + "+stageb.pass2.batches2-9"
    cat["metadata"]["checksum"] = ck
    cat["metadata"]["catalogVersion"] = new_version
    json.dump(cat, open(LIVE, "w", encoding="utf-8"), ensure_ascii=False, indent=2)

    man = load(os.path.join(CAT, "manifest.json"))
    d0 = man["data"][0]
    f0 = next(f for f in d0["files"] if f["fileName"] == "scheme_catalog.json")
    f0["checksum"] = ck
    f0["byteSize"] = os.path.getsize(LIVE)
    d0["stageBPasses"] = sorted(set(d0.get("stageBPasses", []) + ["scheme:pass2-batches2-9"]))
    man["metadata"]["checksum"] = "sha256:" + hashlib.sha256(
        canon(man["data"]).encode()).hexdigest()
    json.dump(man, open(os.path.join(CAT, "manifest.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)

    print(f"Pass 2 batches 2-9 applied: {len(applied)} fills, {len(skipped)} skipped, "
          f"guard passed")
    for sid in applied: print(f"   + {sid:10} mode=online")
    for sid, why in skipped: print(f"   - {sid:10} ({why})")
    print(f"release {new_version}  checksum={ck[:26]}...  (supersedes {prev_version})")


if __name__ == "__main__":
    apply()
