#!/usr/bin/env python3
"""
Stage B — Pass 2 (fill-only enrichment), batch 1.

Every fill below is hand-curated from evidence already gathered in Pass 1's
WebFetch results for batch 1 (SCH000001-SCH000025) -- see
STAGE_B_PASS1_BATCH1_REPORT.md and results_1.json. This is deliberately not a
generic automated scraper: several candidate fills were investigated and
REJECTED because the evidence didn't specifically support them (see
STAGE_B_PASS2_BATCH1_REPORT.md "Investigated and rejected"). Only fills with
a specific, attributable, on-domain source are included.

Guard: a fill is applied only if the CURRENT live value at that field is
None (or the record's applicable empty sentinel). Before writing, every
other field of the touched record is snapshotted; after writing, only the
exact target paths may differ. Any other drift aborts the whole run.
"""
import json, os, hashlib
from collections import OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))
LIVE = os.path.join(CAT, "scheme_catalog.json")
RETRIEVED = "2026-08-14"

def load(p): return json.load(open(p, encoding="utf-8"))

# ---- declarative fill list -------------------------------------------------
# Each entry: schemeId, path (dotted, list-index via int in tuple form kept
# simple here since every target is a scalar or a one-shot list append),
# value to write, and the provenance.fieldSources[] entry to record.
FILLS = [
    {
        "schemeId": "SCH000006",
        "kind": "identity_status",
        "value": "active",
        "source": {
            "field": "identity.status", "value": "active", "sourceTier": 5,
            "sourceType": "official_website", "organization": "Development Commissioner MSME (DCMSME)",
            "url": "https://dcmsme.gov.in/operational-guidelines-respect-agarbatti-making-project.htm",
            "retrievedAt": RETRIEVED, "confidence": "medium", "isBackfill": True,
            "supersededValue": None,
            "note": "Operational guidelines page for Agarbatti Making under Gramodyog Vikas Yojana "
                    "is live on the official DCMSME domain and presents the scheme as currently operational."
        }
    },
    {
        "schemeId": "SCH000016",
        "kind": "mode",
        "value": ("online", None),
        "source": {
            "field": "content.applicationProcess.mode", "value": "online", "sourceTier": 5,
            "sourceType": "official_website", "organization": "Atal Innovation Mission (AIM)",
            "url": "https://aim.gov.in/", "retrievedAt": RETRIEVED, "confidence": "high",
            "isBackfill": True, "supersededValue": None,
            "note": "Existing stored modeText ('Through AIM ATL application process when calls are "
                    "open') plus confirmed onlineUrl aim.gov.in describe a portal-based application; "
                    "mapped to the catalog's existing 'online' enum value (already used on 44 other "
                    "records) -- no new vocabulary introduced."
        }
    },
    {
        "schemeId": "SCH000017",
        "kind": "mode",
        "value": ("online", None),
        "source": {
            "field": "content.applicationProcess.mode", "value": "online", "sourceTier": 5,
            "sourceType": "official_website", "organization": "Tamil Nadu MSME Online",
            "url": "https://www.msmeonline.tn.gov.in/", "retrievedAt": RETRIEVED, "confidence": "medium",
            "isBackfill": True, "supersededValue": None,
            "note": "Stored modeText ('Through applicable Tamil Nadu MSME/nodal process') plus "
                    "onlineUrl on the TN MSME Online portal; mapped to existing 'online' enum value."
        }
    },
    {
        "schemeId": "SCH000021",
        "kind": "mode",
        "value": ("online", None),
        "source": {
            "field": "content.applicationProcess.mode", "value": "online", "sourceTier": 5,
            "sourceType": "official_website", "organization": "iStart Rajasthan",
            "url": "https://istart.rajasthan.gov.in/", "retrievedAt": RETRIEVED, "confidence": "medium",
            "isBackfill": True, "supersededValue": None,
            "note": "Confirmed official iStart Rajasthan startup portal is the application channel "
                    "referenced in stored modeText; mapped to existing 'online' enum value."
        }
    },
    {
        "schemeId": "SCH000014",
        "kind": "last_updated",
        "value": "2024-01-03",
        "source": {
            "field": "content.overview.lastUpdated", "value": "2024-01-03", "sourceTier": 5,
            "sourceType": "official_website", "organization": "Atal Innovation Mission (AIM)",
            "url": "https://aim.gov.in/atal-incubation-centres.php", "retrievedAt": RETRIEVED,
            "confidence": "high", "isBackfill": True, "supersededValue": None,
            "note": "Page's own displayed 'last updated 03-01-2024' (DD-MM-YYYY), captured verbatim "
                    "and converted to ISO 8601."
        }
    },
    {
        "schemeId": "SCH000018",
        "kind": "last_updated",
        "value": "2025-08-19",
        "source": {
            "field": "content.overview.lastUpdated", "value": "2025-08-19", "sourceTier": 5,
            "sourceType": "official_website", "organization": "National Small Industries Corporation (NSIC)",
            "url": "https://www.nsic.co.in/Schemes/CreditFacilitationThroughBank", "retrievedAt": RETRIEVED,
            "confidence": "high", "isBackfill": True, "supersededValue": None,
            "note": "Page's own displayed 'updated 19-08-2025' (DD-MM-YYYY), captured verbatim and "
                    "converted to ISO 8601."
        }
    },
    {
        "schemeId": "SCH000020",
        "kind": "last_updated",
        "value": "2026-08-03",
        "source": {
            "field": "content.overview.lastUpdated", "value": "2026-08-03", "sourceTier": 5,
            "sourceType": "official_website", "organization": "Savitribai Phule NIWCD, Ministry of Women and Child Development",
            "url": "https://www.spniwcd.wcd.gov.in/beti-bachao-beti-padhao", "retrievedAt": RETRIEVED,
            "confidence": "high", "isBackfill": True, "supersededValue": None,
            "note": "Page's own displayed 'last updated 2026-08-03', captured verbatim (already ISO)."
        }
    },
    {
        "schemeId": "SCH000011",
        "kind": "contact",
        "value": {
            "contactId": "SCH000011-CON001", "authorityId": None, "level": "national",
            "office": "SIDBI Head Office", "designation": None, "state": None, "district": None,
            "address": None, "email": [], "phone": ["0522-2288546", "0522-2288547", "0522-2288548", "0522-2288549"],
            "tollFree": [], "fax": None, "website": "https://www.sidbi.in/", "workingHours": None,
            "workingDays": None, "languages": []
        },
        "source": {
            "field": "content.contacts.national[]", "value": "SIDBI HQ phone numbers", "sourceTier": 5,
            "sourceType": "official_website", "organization": "Small Industries Development Bank of India (SIDBI)",
            "url": "https://www.sidbi.in/", "retrievedAt": RETRIEVED, "confidence": "medium",
            "isBackfill": True, "supersededValue": None,
            "note": "General SIDBI HQ contact number published on the SIDBI homepage. Scheme "
                    "identity.status is already 'closed' (historical facility) -- this is SIDBI's "
                    "institutional contact, not a scheme-specific helpline, and is logged as such."
        }
    },
    {
        "schemeId": "SCH000012",
        "kind": "contact",
        "value": {
            "contactId": "SCH000012-CON001", "authorityId": None, "level": "national",
            "office": "SIDBI Head Office", "designation": None, "state": None, "district": None,
            "address": None, "email": [], "phone": ["0522-2288546", "0522-2288547", "0522-2288548", "0522-2288549"],
            "tollFree": [], "fax": None, "website": "https://www.sidbi.in/", "workingHours": None,
            "workingDays": None, "languages": []
        },
        "source": {
            "field": "content.contacts.national[]", "value": "SIDBI HQ phone numbers", "sourceTier": 5,
            "sourceType": "official_website", "organization": "Small Industries Development Bank of India (SIDBI)",
            "url": "https://www.sidbi.in/", "retrievedAt": RETRIEVED, "confidence": "medium",
            "isBackfill": True, "supersededValue": None,
            "note": "General SIDBI HQ contact number published on the SIDBI homepage. Scheme "
                    "identity.status is already 'closed' (historical facility) -- this is SIDBI's "
                    "institutional contact, not a scheme-specific helpline, and is logged as such."
        }
    },
]

def apply():
    cat = load(LIVE)
    idx = {r["identity"]["id"]: r for r in cat["data"]}
    pre_snapshot = {i: json.dumps(idx[i], sort_keys=True) for i in idx}

    applied, skipped = [], []
    for f in FILLS:
        rec = idx[f["schemeId"]]
        kind = f["kind"]
        ok = False
        if kind == "identity_status":
            if rec["identity"]["status"] == "unknown":
                rec["identity"]["status"] = f["value"]; ok = True
        elif kind == "mode":
            ap = rec["content"]["applicationProcess"]
            if ap["mode"] is None:
                ap["mode"] = f["value"][0]; ok = True
        elif kind == "last_updated":
            ov = rec["content"]["overview"]
            if ov["lastUpdated"] is None:
                ov["lastUpdated"] = f["value"]; ok = True
        elif kind == "contact":
            existing = rec["content"]["contacts"]["national"]
            if not existing:
                existing.append(f["value"]); ok = True
        if not ok:
            skipped.append((f["schemeId"], kind, "target field no longer null -- not overwritten"))
            continue
        prov = rec["provenance"]
        prov.setdefault("fieldSources", [])
        prov["fieldSources"].append(f["source"])
        rec["verification"]["missingFields"] = [
            m for m in rec["verification"]["missingFields"]
            if m["field"] != f["source"]["field"].rstrip("[]")
        ]
        applied.append((f["schemeId"], kind))

    # ---- GUARD: for every touched record, only the intended field(s) may differ.
    bad = []
    for i, rec in idx.items():
        before = json.loads(pre_snapshot[i])
        after = rec
        if before == after:
            continue
        # allow only: identity.status, content.applicationProcess.mode,
        # content.overview.lastUpdated, content.contacts.national, provenance.fieldSources,
        # verification.verifiedFields, verification.missingFields
        b2, a2 = json.loads(json.dumps(before)), json.loads(json.dumps(after))
        for blk in (b2, a2):
            blk["identity"]["status"] = None
            blk["content"]["applicationProcess"]["mode"] = None
            blk["content"]["overview"]["lastUpdated"] = None
            blk["content"]["contacts"]["national"] = []
            blk["provenance"]["fieldSources"] = []
            blk["verification"]["verifiedFields"] = []
            blk["verification"]["missingFields"] = []
        if b2 != a2:
            bad.append(i)
    if bad:
        print(f"ABORT -- Pass 2 touched fields outside the intended target set on {len(bad)} "
              f"record(s): {bad[:5]}")
        raise SystemExit(1)

    def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    ck = "sha256:" + hashlib.sha256(canon(cat["data"]).encode()).hexdigest()
    prev_version = cat["metadata"]["catalogVersion"]
    new_version = prev_version + "+stageb.pass2.batch1"
    cat["metadata"]["checksum"] = ck
    cat["metadata"]["catalogVersion"] = new_version
    json.dump(cat, open(LIVE, "w", encoding="utf-8"), ensure_ascii=False, indent=2)

    man = load(os.path.join(CAT, "manifest.json"))
    d0 = man["data"][0]
    f0 = next(f for f in d0["files"] if f["fileName"] == "scheme_catalog.json")
    f0["checksum"] = ck
    f0["byteSize"] = os.path.getsize(LIVE)
    d0["stageBPasses"] = sorted(set(d0.get("stageBPasses", []) + ["scheme:pass2-batch1"]))
    man["metadata"]["checksum"] = "sha256:" + hashlib.sha256(
        canon(man["data"]).encode()).hexdigest()
    json.dump(man, open(os.path.join(CAT, "manifest.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)

    print(f"Pass 2 batch 1 applied: {len(applied)} fills, {len(skipped)} skipped, "
          f"guard passed (no field outside the intended target set changed)")
    for sid, kind in applied: print(f"   + {sid:10} {kind}")
    for sid, kind, why in skipped: print(f"   - {sid:10} {kind}  ({why})")
    print(f"release {new_version}  checksum={ck[:26]}...  (supersedes {prev_version})")

if __name__ == "__main__":
    apply()
