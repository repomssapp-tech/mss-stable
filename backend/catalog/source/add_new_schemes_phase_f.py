#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase F Task 2 -- adds 2 new scheme records: Stand Up India (SCH000218)
and PMFME (SCH000219). Both extend the catalog's sequential SCH/TN
numbering (TN218, TN219) -- central schemes already use this prefix
throughout the catalog (e.g. CGTMSE = TN038), it is not TN-state-only.

Sources:
- Stand Up India: https://www.standupmitra.in/ (live fetch, 2026-08-15).
  Domain newly approved this session -- see MSS_Data_Completion_Policy_v1.0.md
  changelog 1.2 and OPERATIONAL_POLICY_REVIEW.md-equivalent justification
  in the same policy file.
- PMFME: https://mofpi.gov.in/ (live fetch, HIGH confidence -- confirms
  the scheme, its 7 named components, and the guidelines PDF's existence/
  URL) + the guidelines PDF itself at
  https://www.mofpi.gov.in/sites/default/files/pmfme_guidelines_english.pdf
  (fetched, but returned non-extractable binary content this session --
  the 35% / Rs 10 lakh / Rs 40,000 SHG-seed-capital figures are recorded
  at MEDIUM confidence, corroborated by highly consistent secondary
  sources, not read verbatim from the primary PDF).
"""
import json, hashlib
from copy import deepcopy

PATH = "scheme_catalog.json"
RETRIEVED_AT = "2026-08-15"

with open(PATH, encoding="utf-8") as f:
    catalog = json.load(f)

TEMPLATE = deepcopy(catalog["data"][0])  # SCH000001, used purely for structural shape


def blank_benefits():
    b = deepcopy(TEMPLATE["content"]["benefits"])
    for key in ("capitalSubsidy", "interestSubvention", "marginMoney", "grant", "taxBenefit",
                "reimbursement", "equitySupport", "insurance", "loan", "guarantee",
                "trainingSupport", "marketSupport", "technologySupport"):
        if isinstance(b.get(key), dict):
            for k in b[key]:
                if k == "applicable":
                    b[key][k] = None
                elif k in ("conditions",):
                    b[key][k] = []
                elif k == "varies":
                    b[key][k] = False
                else:
                    b[key][k] = None
    b["benefitTypes"] = []
    b["summary"] = None
    return b


def blank_eligibility_structured():
    s = deepcopy(TEMPLATE["content"]["eligibility"]["structured"])
    for facet, v in s.items():
        if facet == "otherConditions":
            s[facet] = []
            continue
        for k in v:
            if k == "applies":
                v[k] = None
            elif k in ("values", "types", "included", "excluded", "constitution", "areaTypes", "required"):
                v[k] = []
            else:
                v[k] = None
    return s


def make_source(sid, url, org, tier, fmt="html"):
    return {
        "sourceId": sid, "sourceType": "official_website", "title": "Official website",
        "reference": None, "publisherId": None, "publisherText": org, "url": url,
        "documentFormat": fmt, "language": "en", "publishedOn": None,
        "accessedOn": RETRIEVED_AT, "isPrimary": True, "isCurrent": True,
    }


def new_record(rid, code, name, short_name, acronym, dept_text, ministry_text,
               objective, summary, benefit_desc, elig_text, app_url, app_mode,
               doc_list, keywords, source_url, source_org, confidence, notes,
               scheme_type, scheme_type_text, sectors_text):
    r = deepcopy(TEMPLATE)
    r["identity"] = {
        "id": rid, "entityType": "scheme", "code": code, "legacyCodes": [],
        "name": name, "shortName": short_name, "acronym": acronym,
        "slug": name.lower().replace(" ", "-").replace("(", "").replace(")", "").replace(",", ""),
        "language": "en", "status": "active",
    }
    c = r["content"]
    c["classification"] = {
        "government": {
            "level": "central", "levelText": "Central", "country": "IN",
            "states": [], "statesText": "Pan-India", "districts": [], "districtsText": "Pan-India",
            "ministryId": None, "ministryText": ministry_text,
            "departmentId": None, "departmentText": dept_text,
            "implementingAgencyIds": [], "implementingAgencyText": dept_text,
        },
        "schemeType": scheme_type, "schemeTypeText": scheme_type_text,
        "sectors": [], "sectorsText": sectors_text, "categories": [], "tags": [],
    }
    c["overview"] = {
        "summary": summary, "description": summary, "objective": objective,
        "background": None, "legalBasis": [],
        "validity": {"from": None, "to": None, "isOpenEnded": True, "text": "Ongoing central scheme"},
        "version": "Current official portal information", "lastUpdated": None, "lastUpdatedText": None,
    }
    c["objectives"] = [objective]
    c["targetBeneficiaries"] = {
        "description": elig_text, "beneficiaryTypes": [], "enterpriseTypes": [],
        "businessStages": ["new"], "specialCategories": [],
    }
    c["eligibility"] = {
        "structured": blank_eligibility_structured(),
        "narrative": {"criteria": elig_text, "verifiedCriteria": None, "exclusions": [], "relaxations": []},
    }
    c["benefits"] = blank_benefits()
    c["requiredDocuments"] = doc_list
    c["applicationProcess"] = {
        "mode": app_mode, "modeText": "Online" if app_mode == "online" else None,
        "onlineUrl": app_url, "offlineDetails": None, "applicationFeeInr": None,
        "applicationFeeText": None, "steps": [], "services": [],
    }
    c["applicationTimeline"] = {
        "opensOn": None, "closesOn": None, "isRollingIntake": True,
        "processingDurationDays": None, "cycles": [], "text": "Rolling / ongoing intake",
    }
    c["contacts"] = {"national": [], "state": [], "district": [], "helplines": []}
    c["faqs"] = []
    c["sources"] = [make_source(f"{rid}-SRC001", source_url, source_org, 5)]

    r["relationships"] = {"references": []}
    r["localization"] = {
        "en": {"name": name, "shortName": short_name, "summary": summary, "description": summary,
               "objective": objective, "eligibilityText": elig_text, "benefitsText": benefit_desc,
               "applicationText": "Online" if app_mode == "online" else None},
        "ta": {"name": None, "shortName": None, "summary": None, "description": None, "objective": None,
               "eligibilityText": None, "benefitsText": None, "applicationText": None},
        "hi": {"name": None, "shortName": None, "summary": None, "description": None, "objective": None,
               "eligibilityText": None, "benefitsText": None, "applicationText": None},
    }
    r["search"] = {
        "keywords": {"en": keywords, "ta": []}, "synonyms": [],
        "aliases": {"en": [name, acronym, code] if acronym else [name, code], "ta": []},
        "crossReferences": [], "searchRank": None, "boostTerms": [],
    }
    r["ai"] = {
        "summary": summary, "sectionSummaries": {"eligibility": elig_text, "benefits": benefit_desc},
        "generationMode": "extractive", "confidence": None, "generatedBy": "mss-ai-derive-1.0.0",
        "generatedAt": RETRIEVED_AT + "T00:00:00Z", "sourceFieldsUsed": ["content.overview", "content.benefits"],
        "reviewedBy": None, "reviewedAt": None, "isApproved": False, "semanticTags": [],
        "relatedEntities": [], "recommendations": [],
        "recommendationsNote": "Not generated. A recommendation asserts that a specific user qualifies; "
                                 "the catalog holds no user context.",
        "similarityMethod": None, "reviewRequired": True,
    }
    r["verification"] = {
        "status": "verified" if confidence == "high" else "partially_verified",
        "statusText": "Verified - current official source" if confidence == "high" else "Verified against a live official page for programme structure; specific financial figures corroborated by secondary sources, not read verbatim from the primary PDF",
        "isVerified": True, "verifiedAgainst": [f"{rid}-SRC001"], "verifiedBy": None,
        "verifiedAt": RETRIEVED_AT, "confidence": confidence,
        "researchStatus": "Official-source researched", "notes": notes,
        "missingFields": [
            {"field": "content.classification.government.ministryId", "reason": "No authority_catalog.json entry resolved this round; not inferred"},
            {"field": "content.applicationProcess.steps", "reason": "Not itemised as a numbered sequence on the fetched source"},
            {"field": "content.contacts", "reason": "Not captured this round"},
            {"field": "content.faqs", "reason": "Not captured this round"},
        ],
        "disputedFields": [], "reviewDueOn": None,
    }
    r["analytics"] = {"popularity": None, "viewCount": None, "saveCount": None, "actionCount": None, "lastAggregatedAt": None}
    r["metadata"] = {
        "createdAt": RETRIEVED_AT + "T00:00:00Z", "updatedAt": RETRIEVED_AT + "T00:00:00Z",
        "catalogVersion": "1.33.0-alpha+phaseF.new-schemes", "schemaVersion": "1.0.0",
        "recordStatus": "published", "revision": 1,
    }
    r["provenance"] = {
        "defaultSourceTier": 5, "primarySourceId": f"{rid}-SRC001", "contributingSourceIds": [f"{rid}-SRC001"],
        "extractionMethod": "live_official_source", "extractedAt": RETRIEVED_AT,
        "pipelineVersion": "add_new_schemes_phase_f.py-1.0.0",
        "fieldSources": [{
            "field": "content (full record)", "value": "new record", "sourceTier": 5,
            "sourceType": "official_website", "organization": source_org, "url": source_url,
            "retrievedAt": RETRIEVED_AT, "isBackfill": True, "supersededValue": None, "note": notes,
        }],
        "transformationNotes": [f"New record added Phase F Task 2, {RETRIEVED_AT}."],
        "translations": {"ta": {"method": "none", "engine": None, "status": "not_started",
                                 "dictionaryVersion": None, "generatedAt": None, "fieldMethods": {},
                                 "fieldsTranslated": 0, "fieldsContextual": 0, "fieldsPending": 8,
                                 "isApproved": False, "reviewRequired": True,
                                 "note": "Localization deferred; new record."}},
    }
    return r


# ---------------------------------------------------------------------
# SCH000218 -- Stand Up India
doc_id = "SCH000218-DOC"
stand_up = new_record(
    rid="SCH000218", code="TN218", name="Stand-Up India Scheme", short_name="Stand-Up India",
    acronym="SUI",
    dept_text="Department of Financial Services, Ministry of Finance (multi-lender, coordinated via SIDBI)",
    ministry_text="Ministry of Finance",
    objective="To facilitate bank loans between Rs 10 lakh and Rs 1 crore to at least one Scheduled "
              "Caste (SC) or Scheduled Tribe (ST) borrower and at least one woman borrower per bank "
              "branch, for setting up a greenfield enterprise.",
    summary="Composite bank loan (term loan + working capital) of Rs 10 lakh to Rs 1 crore for SC/ST "
            "and women entrepreneurs setting up a new (greenfield) enterprise in manufacturing, "
            "services, agri-allied activities, or trading.",
    benefit_desc="Composite loan Rs 10 lakh-Rs 1 crore. Margin money: 15% (borrower contribution). "
                 "Collateral: security cover under the Credit Guarantee Fund Scheme for Stand-Up India "
                 "Loans (CGFSIL) -- not a specific percentage/amount stated on the fetched page.",
    elig_text="SC/ST or woman entrepreneur, above 18 years of age, setting up a greenfield "
              "(newly established) enterprise. For non-individual enterprises, at least 51% "
              "shareholding and controlling stake must be held by an SC/ST or woman entrepreneur.",
    app_url="https://www.standupmitra.in/", app_mode="online",
    doc_list=[
        {"documentId": f"{doc_id}001", "documentTypeId": None, "name": "Identity and address proof of borrower",
         "mandatory": "required", "mandatoryText": "Yes", "issuingAuthorityId": None, "issuingAuthorityText": None,
         "description": "Standard KYC documentation for the loan application.", "estimatedCostInr": None,
         "estimatedCostText": None, "validityMonths": None, "remarks": None, "downloadTemplateUrl": None,
         "sampleCopyUrl": None, "verificationPortalUrl": None, "sourceUrl": "https://www.standupmitra.in/"},
        {"documentId": f"{doc_id}002", "documentTypeId": None, "name": "Caste certificate (for SC/ST applicants)",
         "mandatory": "conditional", "mandatoryText": "If applicable", "issuingAuthorityId": None,
         "issuingAuthorityText": "Competent revenue authority", "description": "Required to establish SC/ST category eligibility.",
         "estimatedCostInr": None, "estimatedCostText": None, "validityMonths": None, "remarks": None,
         "downloadTemplateUrl": None, "sampleCopyUrl": None, "verificationPortalUrl": None, "sourceUrl": "https://www.standupmitra.in/"},
        {"documentId": f"{doc_id}003", "documentTypeId": None, "name": "Project report / business plan for the greenfield enterprise",
         "mandatory": "required", "mandatoryText": "Yes", "issuingAuthorityId": None, "issuingAuthorityText": None,
         "description": "Required for loan appraisal.", "estimatedCostInr": None, "estimatedCostText": None,
         "validityMonths": None, "remarks": None, "downloadTemplateUrl": None, "sampleCopyUrl": None,
         "verificationPortalUrl": None, "sourceUrl": "https://www.standupmitra.in/"},
    ],
    keywords=["stand", "stand-up", "india", "sc", "st", "women", "greenfield", "loan", "composite",
              "margin", "cgfsil", "sidbi"],
    source_url="https://www.standupmitra.in/", source_org="Department of Financial Services / SIDBI (Stand-Up India)",
    confidence="high",
    notes='Verbatim from live fetch: "facilitates bank loans between ₹10 lakh and ₹1 Crore to at '
          'least one Scheduled Caste (SC) or Scheduled Tribe (ST) borrower and at least one woman '
          'borrower per bank branch"; "15% Margin money"; "Security cover under Credit Guarantee '
          'Fund Scheme for Stand-Up India Loans (CGFSIL)". 73 banks/157,416 branches onboarded '
          "(a live-page statistic, not stored as a benefit figure). Domain approved this session -- "
          "see MSS_Data_Completion_Policy_v1.0.md changelog 1.2.",
    scheme_type="loan", scheme_type_text="Composite loan (term loan + working capital)",
    sectors_text="Manufacturing, services, agri-allied activities, trading",
)
stand_up["content"]["benefits"]["loan"]["applicable"] = True
stand_up["content"]["benefits"]["loan"]["minAmountInr"] = 1000000
stand_up["content"]["benefits"]["loan"]["minAmountText"] = "Rs 10 lakh"
stand_up["content"]["benefits"]["loan"]["maxAmountInr"] = 10000000
stand_up["content"]["benefits"]["loan"]["maxAmountText"] = "Rs 1 crore"
stand_up["content"]["benefits"]["loan"]["percentage"] = 15.0
stand_up["content"]["benefits"]["loan"]["percentageText"] = "15% margin money (borrower contribution)"
stand_up["content"]["benefits"]["loan"]["collateralRequired"] = False
stand_up["content"]["benefits"]["loan"]["repaymentText"] = "Security cover under CGFSIL in lieu of collateral; specific tenure not stated on the fetched page."
stand_up["content"]["benefits"]["loan"]["description"] = stand_up["content"]["benefits"]["summary"] = (
    "Composite loan (term loan + working capital), Rs 10 lakh to Rs 1 crore. 15% margin money "
    "from the borrower. Collateral-free via CGFSIL guarantee cover, not a specific bank collateral requirement."
)
stand_up["content"]["benefits"]["benefitTypes"] = ["loan"]
stand_up["content"]["targetBeneficiaries"]["specialCategories"] = ["SC", "ST", "women"]
stand_up["content"]["eligibility"]["structured"]["gender"]["applies"] = True
stand_up["content"]["eligibility"]["structured"]["gender"]["values"] = ["female"]
stand_up["content"]["eligibility"]["structured"]["community"]["applies"] = True
stand_up["content"]["eligibility"]["structured"]["community"]["values"] = ["SC", "ST"]
stand_up["content"]["eligibility"]["structured"]["businessStage"]["applies"] = True
stand_up["content"]["eligibility"]["structured"]["businessStage"]["values"] = ["new"]
stand_up["content"]["eligibility"]["structured"]["age"]["applies"] = True
stand_up["content"]["eligibility"]["structured"]["age"]["minYears"] = 18

# ---------------------------------------------------------------------
# SCH000219 -- PMFME
doc_id2 = "SCH000219-DOC"
pmfme = new_record(
    rid="SCH000219", code="TN219", name="PM Formalisation of Micro Food Processing Enterprises (PMFME)",
    short_name="PMFME", acronym="PMFME",
    dept_text="Ministry of Food Processing Industries (MoFPI), Government of India",
    ministry_text="Ministry of Food Processing Industries",
    objective="To formalise existing unorganised micro food processing enterprises, upgrade their "
              "technology, and link them to organised markets via the One District One Product "
              "(ODOP) approach.",
    summary="Centrally-sponsored scheme (launched 29 June 2020, Rs 10,000 crore 5-year outlay) "
            "supporting micro food processing units, FPOs/SHGs/producer cooperatives, common "
            "infrastructure, branding/marketing, and capacity building, structured around 7 named "
            "components: One District One Product, individual unit upgradation, FPO/SHG/cooperative "
            "support, SHG seed capital, common infrastructure, branding & marketing, and capacity building.",
    benefit_desc="Credit-linked subsidy (percentage and per-unit ceiling corroborated by secondary "
                 "sources at MEDIUM confidence, not read verbatim from the primary PDF this session "
                 "-- see verification.notes).",
    elig_text="Individual entrepreneurs, proprietorships, partnerships, and private limited "
              "companies operating existing unorganised micro food processing units; also Farmer "
              "Producer Organisations (FPOs), Self-Help Groups (SHGs), and cooperatives across the "
              "food processing value chain.",
    app_url="https://pmfme.mofpi.gov.in/pmfme/#/Home-Page", app_mode="online",
    doc_list=[
        {"documentId": f"{doc_id2}001", "documentTypeId": None, "name": "Udyam Registration / enterprise registration record",
         "mandatory": "required", "mandatoryText": "Yes", "issuingAuthorityId": None,
         "issuingAuthorityText": "Ministry of MSME / competent registration authority",
         "description": "Enterprise registration required for scheme application.", "estimatedCostInr": None,
         "estimatedCostText": None, "validityMonths": None, "remarks": None, "downloadTemplateUrl": None,
         "sampleCopyUrl": None, "verificationPortalUrl": None, "sourceUrl": "https://pmfme.mofpi.gov.in/"},
        {"documentId": f"{doc_id2}002", "documentTypeId": None, "name": "Detailed Project Report (DPR)",
         "mandatory": "required", "mandatoryText": "Yes", "issuingAuthorityId": None, "issuingAuthorityText": None,
         "description": "Submitted via the PM FME Management Information System for unit upgradation proposals.",
         "estimatedCostInr": None, "estimatedCostText": None, "validityMonths": None, "remarks": None,
         "downloadTemplateUrl": None, "sampleCopyUrl": None, "verificationPortalUrl": None,
         "sourceUrl": "https://pmfme.mofpi.gov.in/"},
    ],
    keywords=["pmfme", "food", "processing", "formalisation", "micro", "odop", "one", "district",
              "product", "fpo", "shg", "seed", "capital", "mofpi"],
    source_url="https://mofpi.gov.in/", source_org="Ministry of Food Processing Industries (MoFPI)",
    confidence="medium",
    notes="Programme structure (7 named components, launch date 29 June 2020, Rs 10,000 crore "
          "outlay, ODOP approach, implementing ministry) confirmed HIGH confidence via a live "
          "mofpi.gov.in fetch, which also confirmed the guidelines PDF's exact URL. That PDF "
          '(https://www.mofpi.gov.in/sites/default/files/pmfme_guidelines_english.pdf) was fetched '
          "but returned non-extractable binary/scanned content this session -- the specific 35% "
          "credit-linked subsidy (max Rs 10 lakh/unit) and Rs 40,000/SHG-member seed capital figures "
          "are recorded at MEDIUM confidence, corroborated by highly consistent secondary sources, "
          "not read verbatim from the primary document. Flagged for a follow-up direct read of the "
          "PDF (e.g. with a PDF-text-extraction tool) or the pmfme.mofpi.gov.in guidelines page "
          "(itself a JS-rendered SPA that returned no content this session).",
    scheme_type="capital_subsidy", scheme_type_text="Credit-linked capital subsidy + seed capital",
    sectors_text="Food processing (micro enterprises, FPOs, SHGs, cooperatives)",
)
pmfme["content"]["benefits"]["capitalSubsidy"]["applicable"] = True
pmfme["content"]["benefits"]["capitalSubsidy"]["percentage"] = 35.0
pmfme["content"]["benefits"]["capitalSubsidy"]["percentageText"] = "35% of eligible project cost (medium confidence -- see verification.notes)"
pmfme["content"]["benefits"]["capitalSubsidy"]["maxAmountInr"] = 1000000
pmfme["content"]["benefits"]["capitalSubsidy"]["maxAmountText"] = "Rs 10 lakh/unit (medium confidence -- see verification.notes)"
pmfme["content"]["benefits"]["capitalSubsidy"]["description"] = (
    "Credit-linked subsidy of 35% of eligible project cost, max Rs 10 lakh per unit, released to "
    "the bank after loan sanction (not paid directly to the applicant). For SHG members: seed "
    "capital of Rs 40,000/member for working capital and small tools. Credit-linked grant of 35% "
    "for capital investment to FPOs/SHGs/Producer Cooperatives also available. Figures at MEDIUM "
    "confidence -- corroborated by consistent secondary sources, not read verbatim from the primary "
    "guidelines PDF this session."
)
pmfme["content"]["benefits"]["grant"]["applicable"] = True
pmfme["content"]["benefits"]["grant"]["amountInr"] = 40000
pmfme["content"]["benefits"]["grant"]["amountText"] = "Rs 40,000/SHG member (seed capital, medium confidence)"
pmfme["content"]["benefits"]["grant"]["description"] = (
    "Seed capital grant of Rs 40,000 per SHG member for working capital and small tools. Medium "
    "confidence -- see capitalSubsidy.description for the same caveat."
)
pmfme["content"]["benefits"]["summary"] = pmfme["content"]["benefits"]["capitalSubsidy"]["description"]
pmfme["content"]["benefits"]["benefitTypes"] = ["capitalSubsidy", "grant"]
pmfme["content"]["targetBeneficiaries"]["enterpriseTypes"] = ["micro"]
pmfme["content"]["eligibility"]["structured"]["enterprise"]["applies"] = True
pmfme["content"]["eligibility"]["structured"]["enterprise"]["types"] = ["micro"]
pmfme["content"]["eligibility"]["structured"]["sector"]["applies"] = True
pmfme["content"]["eligibility"]["structured"]["sector"]["included"] = ["food_processing"]

catalog["data"].append(stand_up)
catalog["data"].append(pmfme)
catalog["metadata"]["recordCount"] = len(catalog["data"])


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Added SCH000218 (Stand Up India), SCH000219 (PMFME). New total:", len(catalog["data"]))
