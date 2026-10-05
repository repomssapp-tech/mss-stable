#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
scripts/catalog_v3_1/add_approved_authorities.py

Adds the 7 approved Central Ministries (AUTH000125 - AUTH000131) to authority_catalog.json:
- AUTH000125: Ministry of Electronics and Information Technology (MeitY)
- AUTH000126: Ministry of Labour and Employment (MoLE)
- AUTH000127: Ministry of Corporate Affairs (MCA)
- AUTH000128: Ministry of Fisheries, Animal Husbandry and Dairying (MoFAHD)
- AUTH000129: Ministry of New and Renewable Energy (MNRE)
- AUTH000130: Ministry of Heavy Industries (MHI)
- AUTH000131: Ministry of Tribal Affairs (MoTA)
"""
from __future__ import annotations

import copy
import json
import os
import sys
from datetime import datetime, timezone

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

CAT_DIR = r"C:\Users\roger\OneDrive\Documents\Plan\catalog"
AUTH_PATH = os.path.join(CAT_DIR, "authority_catalog.json")

NEW_AUTHORITIES = [
    {
        "id": "AUTH000125",
        "name": "Ministry of Electronics and Information Technology",
        "shortName": "MeitY",
        "acronym": "MeitY",
        "slug": "ministry-of-electronics-and-information-technology",
        "aliases": [
            "Ministry of Electronics and Information Technology",
            "Ministry of Electronics & Information Technology",
            "MeitY"
        ],
        "schemes": ["SCH000275"]
    },
    {
        "id": "AUTH000126",
        "name": "Ministry of Labour and Employment",
        "shortName": "MoLE",
        "acronym": "MoLE",
        "slug": "ministry-of-labour-and-employment",
        "aliases": [
            "Ministry of Labour and Employment",
            "Ministry of Labour & Employment",
            "MoLE"
        ],
        "schemes": ["SCH000278"]
    },
    {
        "id": "AUTH000127",
        "name": "Ministry of Corporate Affairs",
        "shortName": "MCA",
        "acronym": "MCA",
        "slug": "ministry-of-corporate-affairs",
        "aliases": [
            "Ministry of Corporate Affairs",
            "MCA"
        ],
        "schemes": ["SCH000279"]
    },
    {
        "id": "AUTH000128",
        "name": "Ministry of Fisheries, Animal Husbandry and Dairying",
        "shortName": "MoFAHD",
        "acronym": "MoFAHD",
        "slug": "ministry-of-fisheries-animal-husbandry-and-dairying",
        "aliases": [
            "Ministry of Fisheries, Animal Husbandry and Dairying",
            "Ministry of Fisheries, Animal Husbandry & Dairying",
            "MoFAHD"
        ],
        "schemes": ["SCH000286", "SCH000299", "SCH000300"]
    },
    {
        "id": "AUTH000129",
        "name": "Ministry of New and Renewable Energy",
        "shortName": "MNRE",
        "acronym": "MNRE",
        "slug": "ministry-of-new-and-renewable-energy",
        "aliases": [
            "Ministry of New and Renewable Energy",
            "MNRE"
        ],
        "schemes": ["SCH000288", "SCH000289"]
    },
    {
        "id": "AUTH000130",
        "name": "Ministry of Heavy Industries",
        "shortName": "MHI",
        "acronym": "MHI",
        "slug": "ministry-of-heavy-industries",
        "aliases": [
            "Ministry of Heavy Industries",
            "MHI"
        ],
        "schemes": ["SCH000290"]
    },
    {
        "id": "AUTH000131",
        "name": "Ministry of Tribal Affairs",
        "shortName": "MoTA",
        "acronym": "MoTA",
        "slug": "ministry-of-tribal-affairs",
        "aliases": [
            "Ministry of Tribal Affairs",
            "MoTA"
        ],
        "schemes": ["SCH000291"]
    },
]


def make_authority_record(item: dict, template: dict) -> dict:
    rec = copy.deepcopy(template)
    aid = item["id"]
    name = item["name"]
    short = item["shortName"]
    slug = item["slug"]
    aliases = item["aliases"]
    schemes = item["schemes"]

    # identity
    rec["identity"] = {
        "id": aid,
        "entityType": "authority",
        "code": short,
        "legacyCodes": [],
        "name": name,
        "shortName": short,
        "acronym": short,
        "slug": slug,
        "language": "en",
        "status": "active"
    }

    # content
    tokens = [w.lower() for w in name.replace("&", "and").replace(",", "").split() if len(w) > 2]
    rec["content"]["authorityType"] = "ministry"
    rec["content"]["governmentLevel"] = "central"
    rec["content"]["jurisdiction"] = {"country": "IN", "state": None, "districts": []}
    rec["content"]["parentAuthorityId"] = "AUTH000001"
    rec["content"]["hierarchyDepth"] = 1
    rec["content"]["aliases"] = aliases
    rec["content"]["offices"] = []
    rec["content"]["contacts"] = []
    rec["content"]["website"] = None
    rec["content"]["mandate"] = None
    rec["content"]["observedIn"] = [f"scheme:{sid}:ministryText" for sid in schemes]
    rec["content"]["observedCount"] = len(schemes)
    rec["content"]["reviewCandidates"] = []

    # relationships
    rec["relationships"] = {
        "references": [
            {
                "entityId": sid,
                "entityType": "scheme",
                "relationType": "administers",
                "role": None,
                "note": "Administers scheme (catalog v3.1 migration)",
                "generated": True
            }
            for sid in schemes
        ]
    }

    # localization
    rec["localization"] = {
        "en": {"name": name, "mandate": None},
        "ta": {"name": None, "mandate": None},
        "hi": {"name": None, "mandate": None}
    }

    # search
    rec["search"] = {
        "keywords": {"en": sorted(list(set(tokens))), "ta": []},
        "synonyms": aliases,
        "aliases": {"en": [short], "ta": []},
        "crossReferences": [],
        "searchRank": None,
        "boostTerms": []
    }

    # metadata
    rec["metadata"] = {
        "createdAt": "2026-10-04T00:00:00Z",
        "updatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "catalogVersion": "1.35.1-alpha",
        "schemaVersion": "1.0.0",
        "recordStatus": "published",
        "revision": 1
    }

    # verification
    rec["verification"] = {
        "confidence": "high",
        "disputedFields": [],
        "isVerified": True,
        "missingFields": [
            {"field": "content.offices", "reason": "Not available in available sources"},
            {"field": "content.contacts", "reason": "Not available in available sources"},
            {"field": "content.website", "reason": "Not available in available sources"}
        ],
        "notes": "Added in Catalog v3.1 remediation with user approval (Option A) for central ministries of new schemes.",
        "researchStatus": "Researched",
        "reviewDueOn": None,
        "status": "verified",
        "statusText": None,
        "verifiedAgainst": ["GoI official ministries master list"],
        "verifiedAt": "2026-10-05",
        "verifiedBy": "Antigravity",
        "verifiedFields": ["identity.name", "content.parentAuthorityId", "content.governmentLevel"]
    }

    return rec


def main():
    print(f"Loading {AUTH_PATH}...")
    with open(AUTH_PATH, "r", encoding="utf-8") as f:
        auth_cat = json.load(f)

    data = auth_cat["data"]
    existing_ids = {r["identity"]["id"] for r in data}
    template = data[2]  # AUTH000003

    added = 0
    for item in NEW_AUTHORITIES:
        aid = item["id"]
        if aid not in existing_ids:
            new_rec = make_authority_record(item, template)
            data.append(new_rec)
            existing_ids.add(aid)
            added += 1
            print(f"  Added: {aid} - {item['name']} ({item['shortName']})")

    if added > 0:
        auth_cat["metadata"]["updatedAt"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        with open(AUTH_PATH, "w", encoding="utf-8") as f:
            json.dump(auth_cat, f, indent=2, ensure_ascii=False)
        print(f"Saved {added} new authorities to {AUTH_PATH}. Total authorities: {len(data)}")
    else:
        print(f"All 7 authorities already present in {AUTH_PATH}. Total authorities: {len(data)}")


if __name__ == "__main__":
    main()
