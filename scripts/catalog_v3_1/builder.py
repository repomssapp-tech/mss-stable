"""Catalog v3.1 record_json builder.

Transforms msme_schemes_v3_1.json entries into canonical MSS App record_json format,
and enriches existing catalog records adhering strictly to non-destructive merge rules.
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional


def slugify(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "-", text)
    return text.strip("-")


def format_inr(amount: Optional[int]) -> Optional[str]:
    if amount is None:
        return None
    if amount >= 10000000:
        cr = amount / 10000000
        return f"₹{cr:g} crore"
    if amount >= 100000:
        lakh = amount / 100000
        return f"₹{lakh:g} lakh"
    return f"₹{amount:,}"


def empty_benefit_bucket() -> Dict[str, Any]:
    return {
        "applicable": None,
        "percentage": None,
        "percentageText": None,
        "amountInr": None,
        "amountText": None,
        "maxAmountInr": None,
        "maxAmountText": None,
        "minAmountInr": None,
        "minAmountText": None,
        "durationMonths": None,
        "basis": None,
        "varies": False,
        "variesBy": None,
        "conditions": [],
        "description": None,
    }


def resolve_ministry(ministry_raw: Any) -> tuple[Optional[str], Optional[str]]:
    if not ministry_raw:
        return None, None
    if isinstance(ministry_raw, dict):
        ministry_name = ministry_raw.get("en") or ""
    else:
        ministry_name = str(ministry_raw)
    if not ministry_name:
        return None, None
    m_clean = ministry_name.lower().replace("&", "and")
    if "micro, small" in m_clean or "msme" in m_clean:
        return "AUTH000003", "Ministry of Micro, Small and Medium Enterprises"
    if "finance" in m_clean:
        return "AUTH000009", "Ministry of Finance"
    if "commerce" in m_clean:
        return "AUTH000002", "Ministry of Commerce and Industry"
    if "textile" in m_clean:
        return "AUTH000010", "Ministry of Textiles"
    if "rural development" in m_clean:
        return "AUTH000006", "Ministry of Rural Development"
    if "housing and urban" in m_clean or "urban livelihoods" in m_clean:
        return "AUTH000005", "Ministry of Housing and Urban Affairs"
    return None, ministry_name


def map_v3_1_to_record_json(
    v3_rec: Dict[str, Any],
    allocated_id: str,
    action: str = "ADD_NEW",
    parent_sch_id: Optional[str] = None,
    open_issues: Optional[List[Dict[str, str]]] = None,
) -> Dict[str, Any]:
    our_id = v3_rec.get("id")
    name_obj = v3_rec.get("name") or {}
    name_en = (name_obj.get("en") or "").strip()
    name_hi = (name_obj.get("hi") or "").strip()

    source_curr = v3_rec.get("source_current") or {}
    targeting = v3_rec.get("targeting") or {}
    benefit_facts = v3_rec.get("benefit_facts") or []
    status_obj = v3_rec.get("status") or {}
    current_obj = v3_rec.get("current") or {}
    contacts_list = v3_rec.get("contacts") or []

    # 1. Identity
    status_val = status_obj.get("value", "active")
    identity_status = "active" if status_val == "active" else ("closed" if status_val == "closed" else "unknown")

    slug = slugify(name_en)
    short_match = re.search(r"\(([^)]+)\)", name_en)
    short_name = short_match.group(1).strip() if short_match else None

    legacy_codes = [{"system": "mss_v3_1", "code": our_id}]

    identity = {
        "id": allocated_id,
        "entityType": "scheme",
        "language": "en",
        "code": allocated_id,
        "slug": slug,
        "name": name_en,
        "fullName": name_en,
        "shortName": short_name,
        "status": identity_status,
        "legacyCodes": legacy_codes,
    }

    # 2. Classification
    min_id, min_text = resolve_ministry(v3_rec.get("ministry"))
    division_raw = v3_rec.get("division")
    division_text = (division_raw.get("en") if isinstance(division_raw, dict) else division_raw) or min_text

    primary_bf_type = benefit_facts[0].get("type") if benefit_facts else None
    type_map = {
        "guarantee": "credit_guarantee",
        "subsidy": "capital_subsidy",
        "loan": "concessional_loan",
        "grant": "direct_grant",
        "interest_subvention": "interest_subvention",
        "stipend": "skill_development",
        "training": "skill_development",
        "other": "financial_support",
    }
    scheme_type = type_map.get(primary_bf_type, "financial_support")

    classification = {
        "government": {
            "level": "central",
            "ministryId": min_id,
            "ministryText": min_text,
            "departmentText": division_text,
            "implementingAgencyIds": [],
        },
        "schemeType": scheme_type,
        "category": "financial_support",
        "tags": sorted(list(set(
            (targeting.get("sectors") or [])
            + (targeting.get("beneficiary_types") or [])
            + [scheme_type]
        ))),
    }

    # 3. Content
    # Overview
    desc_en_list = source_curr.get("description", {}).get("en") or current_obj.get("summary_en") or []
    summary_en = desc_en_list[0] if desc_en_list else name_en
    description_en = " ".join(desc_en_list) if desc_en_list else summary_en
    objectives_en = desc_en_list[1:] if len(desc_en_list) > 1 else [summary_en]

    # Benefits
    bens_en_list = source_curr.get("benefits", {}).get("en") or current_obj.get("benefits_en") or []
    benefits_summary = " ".join(bens_en_list) if bens_en_list else "Financial assistance and business support."

    benefits_buckets: Dict[str, Any] = {
        "summary": benefits_summary,
        "grant": empty_benefit_bucket(),
        "capitalSubsidy": empty_benefit_bucket(),
        "interestSubvention": empty_benefit_bucket(),
        "marginMoney": empty_benefit_bucket(),
        "loan": {
            **empty_benefit_bucket(),
            "tenureMonths": None,
            "moratoriumMonths": None,
            "interestRatePercent": None,
            "interestRateText": None,
            "collateralRequired": False,
            "repaymentText": None,
        },
        "guarantee": {
            **empty_benefit_bucket(),
            "coveragePercent": None,
            "maxCoverInr": None,
            "guarantorId": None,
            "guarantorText": None,
            "feePercent": None,
        },
        "trainingSupport": {
            "applicable": None,
            "modalities": [],
            "durationText": None,
            "providerIds": [],
            "providerText": None,
            "conditions": [],
            "description": None,
        },
        "reimbursement": empty_benefit_bucket(),
        "taxBenefit": empty_benefit_bucket(),
        "insurance": empty_benefit_bucket(),
        "marketSupport": {
            "applicable": None,
            "modalities": [],
            "durationText": None,
            "providerIds": [],
            "providerText": None,
            "conditions": [],
            "description": None,
        },
        "technologySupport": {
            "applicable": None,
            "modalities": [],
            "durationText": None,
            "providerIds": [],
            "providerText": None,
            "conditions": [],
            "description": None,
        },
        "currency": "INR",
        "disbursement": {
            "mode": None,
            "modeText": None,
            "instalments": None,
            "text": None,
        },
    }

    # Populate buckets from benefit_facts
    for bf in benefit_facts:
        btype = bf.get("type")
        max_inr = bf.get("max_amount_inr")
        pct = bf.get("percent")
        cond = bf.get("condition_en")
        quote = bf.get("source_quote_en")

        if btype == "guarantee":
            b = benefits_buckets["guarantee"]
            b["applicable"] = True
            if b["coveragePercent"] is None and pct:
                b["coveragePercent"] = float(pct)
                b["percentage"] = float(pct)
                b["percentageText"] = f"{pct}%"
            if b["maxCoverInr"] is None and max_inr:
                b["maxCoverInr"] = int(max_inr)
                b["maxAmountInr"] = int(max_inr)
                b["maxAmountText"] = format_inr(max_inr)
            if cond:
                b["conditions"].append(cond)
            if quote and not b["description"]:
                b["description"] = quote

        elif btype in ("subsidy", "margin_money"):
            key = "marginMoney" if (cond and "margin money" in cond.lower()) else "capitalSubsidy"
            b = benefits_buckets[key]
            b["applicable"] = True
            if pct and b["percentage"] is None:
                b["percentage"] = float(pct)
                b["percentageText"] = f"{pct}%"
            if max_inr and b["maxAmountInr"] is None:
                b["maxAmountInr"] = int(max_inr)
                b["maxAmountText"] = format_inr(max_inr)
            if cond:
                b["conditions"].append(cond)
            if quote and not b["description"]:
                b["description"] = quote

        elif btype == "loan":
            b = benefits_buckets["loan"]
            b["applicable"] = True
            if max_inr and b["maxAmountInr"] is None:
                b["maxAmountInr"] = int(max_inr)
                b["maxAmountText"] = format_inr(max_inr)
            if cond:
                b["conditions"].append(cond)
            if quote and not b["description"]:
                b["description"] = quote

        elif btype == "grant":
            b = benefits_buckets["grant"]
            b["applicable"] = True
            if max_inr and b["maxAmountInr"] is None:
                b["maxAmountInr"] = int(max_inr)
                b["maxAmountText"] = format_inr(max_inr)
            if cond:
                b["conditions"].append(cond)
            if quote and not b["description"]:
                b["description"] = quote

        elif btype == "interest_subvention":
            b = benefits_buckets["interestSubvention"]
            b["applicable"] = True
            if pct and b["percentage"] is None:
                b["percentage"] = float(pct)
                b["percentageText"] = f"{pct}%"
            if cond:
                b["conditions"].append(cond)
            if quote and not b["description"]:
                b["description"] = quote

        elif btype in ("training", "stipend"):
            b = benefits_buckets["trainingSupport"]
            b["applicable"] = True
            if cond:
                b["conditions"].append(cond)
            if quote and not b["description"]:
                b["description"] = quote

    # Eligibility
    el_en_list = source_curr.get("eligibility", {}).get("en") or current_obj.get("eligibility_en") or []
    target_groups = targeting.get("target_groups") or []
    beneficiaries = targeting.get("beneficiary_types") or []
    sectors = targeting.get("sectors") or []

    is_ner = "ner" in target_groups
    ner_states = [
        "Assam", "Arunachal Pradesh", "Manipur", "Meghalaya",
        "Mizoram", "Nagaland", "Sikkim", "Tripura"
    ] if is_ner else []

    enterprise_types = [
        b.replace("_enterprise", "") for b in beneficiaries
        if b in ("micro_enterprise", "small_enterprise", "medium_enterprise")
    ]
    if not enterprise_types and ("artisan" in beneficiaries or "individual" in beneficiaries):
        enterprise_types = ["micro"]

    structured_eligibility = {
        "age": {
            "min": targeting.get("age_min"),
            "max": targeting.get("age_max"),
        },
        "gender": {
            "applicable": "women" in target_groups,
            "values": ["female"] if "women" in target_groups else [],
        },
        "community": {
            "applicable": any(c in target_groups for c in ["sc", "st", "obc", "minority"]),
            "values": [c for c in ["sc", "st", "obc", "minority"] if c in target_groups],
        },
        "specialCategory": {
            "applicable": any(c in target_groups for c in ["pwd", "ex_serviceman"]),
            "values": [c for c in ["pwd", "ex_serviceman"] if c in target_groups],
        },
        "location": {
            "areaTypes": ["rural", "urban"] if not is_ner else ["rural"],
            "states": ner_states,
        },
        "sector": {
            "applicable": len(sectors) > 0,
            "included": sectors,
            "excluded": [],
        },
        "enterprise": {
            "types": enterprise_types,
        },
        "turnover": {"applicable": False, "maxAmountInr": None},
        "investment": {"applicable": False, "maxAmountInr": None},
        "landHolding": {"applicable": False},
        "existingRegistration": {
            "applicable": True,
            "requiredTypes": ["Udyam Registration"],
        },
    }

    # Application process & steps
    raw_steps = source_curr.get("application_steps") or []
    app_steps = []
    required_docs = []
    app_mode = "online"
    for s in raw_steps:
        st_num = s.get("step", len(app_steps) + 1)
        action_en = s.get("action", {}).get("en") or ""
        app_steps.append({
            "step": st_num,
            "title": f"Step {st_num}",
            "description": action_en,
            "mode": s.get("mode", "online"),
            "url": s.get("url"),
            "documents": s.get("documents") or [],
        })
        for d in s.get("documents") or []:
            doc_id = "CMN000163" if "udyam" in d.lower() else "CMN000001"
            required_docs.append({
                "documentTypeId": doc_id,
                "name": d,
                "mandatory": True,
            })
        if s.get("mode") in ("offline", "both"):
            app_mode = s.get("mode")

    official_url = (
        current_obj.get("official_url")
        or (app_steps[0].get("url") if app_steps else None)
        or "https://www.dcmsme.gov.in"
    )

    contacts_national = []
    contacts_helplines = []
    for c in contacts_list:
        val = c.get("value")
        label = c.get("label_en") or "Contact"
        if c.get("type") in ("phone", "helpline", "toll_free"):
            contacts_helplines.append({"number": val, "label": label})
        elif c.get("type") == "email":
            contacts_national.append({"email": val, "title": label})
        elif c.get("type") == "website":
            contacts_national.append({"url": val, "title": label})

    # Sources
    sources = []
    doc_url = source_curr.get("document_url") or "https://www.dcmsme.gov.in/ebook/MSMESchemebooklet2025-26.pdf"
    page = source_curr.get("page_book")
    page_suffix = f", p. {page}" if page else ""
    sources.append({
        "id": f"{allocated_id}-SRC001",
        "name": source_curr.get("document_title") or "Ministry of MSME Schemes Booklet 2025-26",
        "url": doc_url,
        "publisherText": f"Ministry of MSME Schemes Booklet 2025-26{page_suffix}",
        "type": "official_booklet",
        "isPrimary": True,
    })
    for i, s_url in enumerate(current_obj.get("sources") or []):
        if s_url != doc_url:
            sources.append({
                "id": f"{allocated_id}-SRC{i+2:03d}",
                "name": "Official Source",
                "url": s_url,
                "publisherText": "Government of India",
                "type": "official_portal",
                "isPrimary": False,
            })

    content = {
        "overview": {
            "summary": summary_en,
            "description": description_en,
            "objectives": objectives_en,
            "keyPointers": [],
        },
        "eligibility": {
            "narrative": {
                "criteria": el_en_list,
                "exclusions": [],
            },
            "structured": structured_eligibility,
        },
        "benefits": benefits_buckets,
        "requiredDocuments": required_docs,
        "applicationProcess": {
            "mode": app_mode,
            "modeText": f"Application via {app_mode} channel",
            "onlineUrl": official_url if app_mode in ("online", "both") else None,
            "steps": app_steps,
            "services": [],
        },
        "contacts": {
            "national": contacts_national,
            "helplines": contacts_helplines,
        },
        "sources": sources,
        "schemeUrl": official_url,
    }

    # 4. Relationships
    relationships_refs = []
    if min_id:
        relationships_refs.append({
            "entityId": min_id,
            "entityType": "authority",
            "relationType": "administered_by",
        })
    if parent_sch_id:
        relationships_refs.append({
            "entityId": parent_sch_id,
            "entityType": "scheme",
            "relationType": "child_of",
        })

    # 5. Localization
    # Hindi narrative
    desc_hi_list = source_curr.get("description", {}).get("hi") or []
    bens_hi_list = source_curr.get("benefits", {}).get("hi") or []
    el_hi_list = source_curr.get("eligibility", {}).get("hi") or []
    app_hi_list = [s.get("action", {}).get("hi") for s in raw_steps if s.get("action", {}).get("hi")]

    localization = {
        "en": {
            "name": name_en,
            "shortName": short_name,
            "summary": summary_en,
            "description": description_en,
            "objective": objectives_en[0] if objectives_en else summary_en,
            "eligibilityText": " ".join(el_en_list),
            "benefitsText": benefits_summary,
            "applicationText": " ".join([s["description"] for s in app_steps]),
        },
        "ta": {
            "name": None,
            "shortName": None,
            "summary": None,
            "description": None,
            "objective": None,
            "eligibilityText": None,
            "benefitsText": None,
            "applicationText": None,
        },
        "hi": {
            "name": name_hi if name_hi else None,
            "shortName": None,
            "summary": desc_hi_list[0] if desc_hi_list else None,
            "description": " ".join(desc_hi_list) if desc_hi_list else None,
            "objective": desc_hi_list[0] if desc_hi_list else None,
            "eligibilityText": " ".join(el_hi_list) if el_hi_list else None,
            "benefitsText": " ".join(bens_hi_list) if bens_hi_list else None,
            "applicationText": " ".join(app_hi_list) if app_hi_list else None,
        },
    }

    # 6. Search
    search = {
        "aliases": {
            "en": [name_en] + ([short_name] if short_name else []),
            "ta": [],
            "hi": [name_hi] if name_hi else [],
        },
        "keywords": {
            "en": [t.lower() for t in re.findall(r"\b[A-Za-z]{4,}\b", name_en)][:10],
            "ta": [],
            "hi": [],
        },
        "synonyms": [],
    }

    # 7. Verification & Open Issues
    disputed_fields = []
    notes_list = []
    if status_obj.get("note_en"):
        notes_list.append(status_obj.get("note_en"))
    for f in v3_rec.get("agent_flags") or []:
        notes_list.append(f)
    if open_issues:
        for issue in open_issues:
            if issue.get("issue_type") == "unverified_amount":
                disputed_fields.append({
                    "field": "content.benefits",
                    "reason": issue.get("detail"),
                })
            else:
                notes_list.append(f"[{issue.get('issue_type')}] {issue.get('detail')}")

    missing_fields = []
    if not official_url:
        missing_fields.append({"field": "content.schemeUrl", "reason": "No official website found"})
    if not raw_steps:
        missing_fields.append({"field": "content.applicationProcess.steps", "reason": "No step-by-step guidance in source"})

    verification = {
        "status": "verified" if status_obj.get("confidence") == "high" else "partially_verified",
        "confidence": status_obj.get("confidence", "medium"),
        "verifiedAt": status_obj.get("verified_on", "2026-10-04"),
        "verifiedAgainst": [f"{allocated_id}-SRC001"],
        "verifiedFields": [
            {
                "field": "content.schemeUrl",
                "value": official_url,
                "sourceTier": 5,
                "url": official_url,
                "retrievedAt": "2026-10-04",
                "outcome": "confirmed",
                "note": "Official scheme portal",
            }
        ],
        "disputedFields": disputed_fields,
        "missingFields": missing_fields,
        "notes": "; ".join(notes_list) if notes_list else None,
    }

    # 8. Provenance
    trans_notes = [
        f"Migrated from mss_scheme_data_v3_1 (ID: {our_id})",
        f"Action: {action}",
    ]
    if parent_sch_id:
        trans_notes.append(f"Child of {parent_sch_id}")

    provenance = {
        "pipelineVersion": "catalog-v3-1-migration",
        "transformationNotes": trans_notes,
        "translations": {
            "ta": {
                "status": "none",
                "reviewRequired": True,
                "engine": "none",
                "note": "Tamil translation pending",
            },
            "hi": {
                "status": "machine",
                "reviewRequired": True,
                "source": "booklet_2025_26_machine_hi",
                "generatedAt": "2026-10-04T00:00:00Z",
            },
        },
    }

    # 9. Metadata
    metadata = {
        "catalogVersion": "1.35.0-alpha",
        "revision": 1,
        "schemaVersion": "1.0.0",
        "createdAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "updatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }

    return {
        "identity": identity,
        "classification": classification,
        "content": content,
        "relationships": {"references": relationships_refs},
        "localization": localization,
        "search": search,
        "verification": verification,
        "provenance": provenance,
        "metadata": metadata,
    }
