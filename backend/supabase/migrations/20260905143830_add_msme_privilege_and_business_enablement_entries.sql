-- 4.2/4.3/4.4 (audit_fix.md): catalog.msme_privilege (1 row) and
-- catalog.business_enablement (4 rows) were too sparse to drive any
-- eligibility/discovery logic meaningfully. Adds 4 real, verified entries
-- (web-searched against official government sources 2026-09-05, not
-- fabricated -- see each row's provenance.fieldSources) matching the
-- exact schema shape of the existing rows. checksum is auto-computed by
-- the existing trg_recompute_checksum trigger.

insert into catalog.msme_privilege (id, version, status, record_json, updated_at)
values (
  'PRIV000002',
  '1.34.0-alpha',
  'PUBLISHED',
  '{
    "ai": {"summary": null, "confidence": null, "isApproved": false, "reviewedAt": null, "reviewedBy": null, "generatedAt": null, "generatedBy": null, "semanticTags": [], "generationMode": null, "reviewRequired": false, "recommendations": [], "relatedEntities": [], "sectionSummaries": {}, "similarityMethod": null, "sourceFieldsUsed": [], "recommendationsNote": null},
    "search": {"aliases": {"en": ["Public Procurement Policy for MSEs", "PPP-MSE"], "ta": []}, "keywords": {"en": ["procurement", "tender", "reservation", "25 percent", "sc st", "women entrepreneur", "public procurement policy"], "ta": []}, "synonyms": ["Public Procurement Policy Order 2012"], "boostTerms": [], "searchRank": null, "crossReferences": []},
    "content": {
      "statute": "MSMED Act 2006; Public Procurement Policy for Micro and Small Enterprises Order, 2012 (S.O. 581(E), effective 1 April 2012; minimum procurement percentage raised from 20% to 25% by order dated 9 November 2018)",
      "summary": "Every Central Ministry, Department and Central Public Sector Enterprise (CPSU) must procure a minimum of 25% of its total annual goods/services value from Micro and Small Enterprises. Within that 25%, at least 4% must be sourced from MSEs owned by SC/ST entrepreneurs and at least 3% from MSEs owned by women entrepreneurs.",
      "compliance": {"text": "Compliance is monitored by the Ministry of MSME via the MSME Sambandh portal, where CPSUs publish monthly and annual procurement factsheets.", "benefits": []},
      "privilegeType": "tender_benefits",
      "tenderBenefits": {"text": "25% minimum annual procurement from MSEs by every Central Ministry/Department/CPSU, with a 4% sub-target for SC/ST-owned MSEs and a 3% sub-target for women-owned MSEs.", "applicable": true, "priceParity": null, "emdExemption": null, "reservedProcurementPercent": 25},
      "billDiscounting": {"text": null, "applicable": null, "platformIds": []},
      "privilegeTypeText": "Public Procurement Policy for Micro and Small Enterprises"
    },
    "identity": {"id": "PRIV000002", "code": "PPP001", "name": "Public Procurement Policy for Micro and Small Enterprises", "slug": "public-procurement-policy-mse", "status": "active", "acronym": "PPP-MSE", "language": "en", "shortName": "MSE Public Procurement Policy", "entityType": "msme_privilege", "legacyCodes": []},
    "metadata": {"revision": 1, "createdAt": "2026-09-05T00:00:00Z", "updatedAt": "2026-09-05T00:00:00Z", "recordStatus": "published", "schemaVersion": "1.0.0", "catalogVersion": "1.34.0-alpha"},
    "analytics": {"saveCount": null, "viewCount": null, "popularity": null, "actionCount": null, "lastAggregatedAt": null},
    "provenance": {"extractedAt": "2026-09-05T00:00:00Z", "fieldSources": [{"url": "https://sambandh.msme.gov.in/PPP_about.aspx", "note": "25% minimum procurement mandate, 4% SC/ST and 3% women sub-targets, and the 2018 increase from 20% to 25%, confirmed against the MSME Sambandh portal and PIB press release.", "field": "content.tenderBenefits", "isBackfill": false, "sourceTier": 5, "sourceType": "official_website", "retrievedAt": "2026-09-05", "organization": "Ministry of MSME", "supersededValue": null}], "translations": {}, "pipelineVersion": "build_msme_privilege.py-1.0.0", "primarySourceId": null, "extractionMethod": "live_official_source", "defaultSourceTier": 5, "transformationNotes": ["Fills the tenderBenefits gap PRIV000001 explicitly flagged as missing (no numeric reservation figure had been sourced at that time)."], "contributingSourceIds": []},
    "localization": {"en": {"name": "Public Procurement Policy for Micro and Small Enterprises", "summary": "Every Central Ministry, Department and CPSU must procure a minimum of 25% of its annual goods/services value from Micro and Small Enterprises, with 4% reserved for SC/ST-owned MSEs and 3% for women-owned MSEs."}, "hi": {"name": null, "summary": null}, "ta": {"name": null, "summary": null}},
    "verification": {"notes": "25/4/3 percent figures and the 2018 increase from 20 percent confirmed against sambandh.msme.gov.in and a PIB press release. No Tamil translation generated -- left null rather than machine-translate without review capacity this session.", "status": "verified", "confidence": "high", "isVerified": true, "statusText": "Confirmed against live official sources", "verifiedAt": "2026-09-05T00:00:00Z", "verifiedBy": null, "reviewDueOn": null, "missingFields": [{"field": "localization.ta", "reason": "Not machine-translated this session -- avoided rather than risk an unreviewed mistranslation of a legal/statutory figure."}], "disputedFields": [], "researchStatus": "Official-source researched", "verifiedAgainst": ["sambandh.msme.gov.in", "pib.gov.in"]},
    "relationships": {"references": []}
  }'::jsonb,
  now()
)
on conflict (id) do nothing;

insert into catalog.business_enablement (id, version, status, record_json, updated_at)
values
(
  'ENAB000005',
  '1.34.0-alpha',
  'PUBLISHED',
  '{
    "ai": {"summary": null, "confidence": null, "isApproved": false, "reviewedAt": null, "reviewedBy": null, "generatedAt": null, "generatedBy": null, "semanticTags": [], "generationMode": null, "reviewRequired": false, "recommendations": [], "relatedEntities": [], "sectionSummaries": {}, "similarityMethod": null, "sourceFieldsUsed": [], "recommendationsNote": null},
    "search": {"aliases": {"en": ["GeM"], "ta": []}, "keywords": {"en": ["gem", "government e-marketplace", "procurement", "tender", "sell to government", "public procurement portal"], "ta": []}, "synonyms": ["Government e-Marketplace"], "boostTerms": [], "searchRank": null, "crossReferences": []},
    "content": {"summary": "National public procurement portal where MSMEs can register as sellers/service providers and sell goods and services directly to Central and State Government departments, ministries and PSUs. Registered MSMEs get tender-fee and EMD exemptions, purchase preference, a reserved MSE procurement quota, and relaxed prior-turnover/prior-experience norms.", "onlineUrl": "https://gem.gov.in/", "eligibility": {"text": "Any MSME/enterprise with valid business registration (PAN/GSTIN as applicable) can register as a seller.", "enterpriseTypeIds": []}, "enablementType": "marketplace_access", "servicesOffered": [], "enablementTypeText": "Government e-Marketplace (GeM)", "providerAuthorityId": null},
    "identity": {"id": "ENAB000005", "code": "GEM001", "name": "Government e-Marketplace (GeM)", "slug": "government-e-marketplace-gem", "status": "active", "acronym": "GeM", "language": "en", "shortName": "GeM", "entityType": "business_enablement", "legacyCodes": []},
    "metadata": {"revision": 1, "createdAt": "2026-09-05T00:00:00Z", "updatedAt": "2026-09-05T00:00:00Z", "recordStatus": "published", "schemaVersion": "1.0.0", "catalogVersion": "1.34.0-alpha"},
    "analytics": {"saveCount": null, "viewCount": null, "popularity": null, "actionCount": null, "lastAggregatedAt": null},
    "provenance": {"extractedAt": "2026-09-05T00:00:00Z", "fieldSources": [{"url": "https://gem.gov.in/aboutus", "note": "MSME seller benefits (tender fee/EMD exemption, purchase preference, reserved MSE quota, relaxed norms) confirmed on the official GeM portal.", "field": "content", "isBackfill": false, "sourceTier": 5, "sourceType": "official_website", "retrievedAt": "2026-09-05", "organization": "Government e-Marketplace / Ministry of Commerce and Industry", "supersededValue": null}], "translations": {}, "pipelineVersion": "build_business_enablement.py-1.0.0", "primarySourceId": null, "extractionMethod": "live_official_source", "defaultSourceTier": 5, "transformationNotes": [], "contributingSourceIds": []},
    "localization": {"en": {"name": "Government e-Marketplace (GeM)", "summary": "National public procurement portal where MSMEs can register as sellers and sell directly to Government departments and PSUs, with tender-fee/EMD exemptions and a reserved procurement quota."}, "hi": {"name": null, "summary": null}, "ta": {"name": null, "summary": null}},
    "verification": {"notes": "Confirmed against the official gem.gov.in portal.", "status": "verified", "confidence": "high", "isVerified": true, "statusText": "Confirmed against live official source", "verifiedAt": "2026-09-05T00:00:00Z", "verifiedBy": null, "reviewDueOn": null, "missingFields": [{"field": "localization.ta", "reason": "Not machine-translated this session -- avoided rather than risk an unreviewed mistranslation."}], "disputedFields": [], "researchStatus": "Official-source researched", "verifiedAgainst": ["gem.gov.in"]},
    "relationships": {"references": []}
  }'::jsonb,
  now()
),
(
  'ENAB000006',
  '1.34.0-alpha',
  'PUBLISHED',
  '{
    "ai": {"summary": null, "confidence": null, "isApproved": false, "reviewedAt": null, "reviewedBy": null, "generatedAt": null, "generatedBy": null, "semanticTags": [], "generationMode": null, "reviewRequired": false, "recommendations": [], "relatedEntities": [], "sectionSummaries": {}, "similarityMethod": null, "sourceFieldsUsed": [], "recommendationsNote": null},
    "search": {"aliases": {"en": ["MSME Sambandh"], "ta": []}, "keywords": {"en": ["sambandh", "public procurement monitoring", "cpse procurement", "msme procurement portal"], "ta": []}, "synonyms": [], "boostTerms": [], "searchRank": null, "crossReferences": []},
    "content": {"summary": "Public Procurement Policy monitoring portal, launched 8 December 2017, where Central Public Sector Enterprises (CPSEs) publish monthly/annual factsheets of their procurement from Micro and Small Enterprises. MSEs can browse what CPSEs are procuring and track ministry/department-wise procurement performance against the 25% MSE procurement mandate.", "onlineUrl": "https://sambandh.msme.gov.in/", "eligibility": {"text": "Open to the public for viewing procurement data; CPSE officers log in to publish factsheets.", "enterpriseTypeIds": []}, "enablementType": "market_intelligence", "servicesOffered": [], "enablementTypeText": "MSME Sambandh Portal", "providerAuthorityId": null},
    "identity": {"id": "ENAB000006", "code": "SAMBANDH001", "name": "MSME Sambandh Portal", "slug": "msme-sambandh-portal", "status": "active", "acronym": "Sambandh", "language": "en", "shortName": "MSME Sambandh", "entityType": "business_enablement", "legacyCodes": []},
    "metadata": {"revision": 1, "createdAt": "2026-09-05T00:00:00Z", "updatedAt": "2026-09-05T00:00:00Z", "recordStatus": "published", "schemaVersion": "1.0.0", "catalogVersion": "1.34.0-alpha"},
    "analytics": {"saveCount": null, "viewCount": null, "popularity": null, "actionCount": null, "lastAggregatedAt": null},
    "provenance": {"extractedAt": "2026-09-05T00:00:00Z", "fieldSources": [{"url": "https://sambandh.msme.gov.in/PPP_index.aspx", "note": "Launch date (8 Dec 2017) and purpose confirmed against the official portal and a PIB press release.", "field": "content", "isBackfill": false, "sourceTier": 5, "sourceType": "official_website", "retrievedAt": "2026-09-05", "organization": "Ministry of MSME", "supersededValue": null}], "translations": {}, "pipelineVersion": "build_business_enablement.py-1.0.0", "primarySourceId": null, "extractionMethod": "live_official_source", "defaultSourceTier": 5, "transformationNotes": [], "contributingSourceIds": []},
    "localization": {"en": {"name": "MSME Sambandh Portal", "summary": "Public procurement monitoring portal where CPSEs publish their MSE procurement factsheets, letting MSEs track what government enterprises are buying."}, "hi": {"name": null, "summary": null}, "ta": {"name": null, "summary": null}},
    "verification": {"notes": "Confirmed against the official sambandh.msme.gov.in portal and a PIB press release.", "status": "verified", "confidence": "high", "isVerified": true, "statusText": "Confirmed against live official source", "verifiedAt": "2026-09-05T00:00:00Z", "verifiedBy": null, "reviewDueOn": null, "missingFields": [{"field": "localization.ta", "reason": "Not machine-translated this session -- avoided rather than risk an unreviewed mistranslation."}], "disputedFields": [], "researchStatus": "Official-source researched", "verifiedAgainst": ["sambandh.msme.gov.in"]},
    "relationships": {"references": []}
  }'::jsonb,
  now()
),
(
  'ENAB000007',
  '1.34.0-alpha',
  'PUBLISHED',
  '{
    "ai": {"summary": null, "confidence": null, "isApproved": false, "reviewedAt": null, "reviewedBy": null, "generatedAt": null, "generatedBy": null, "semanticTags": [], "generationMode": null, "reviewRequired": false, "recommendations": [], "relatedEntities": [], "sectionSummaries": {}, "similarityMethod": null, "sourceFieldsUsed": [], "recommendationsNote": null},
    "search": {"aliases": {"en": ["NSWS"], "ta": []}, "keywords": {"en": ["nsws", "single window", "business approvals", "clearances", "dpiit", "know your approvals"], "ta": []}, "synonyms": ["National Single Window System"], "boostTerms": [], "searchRank": null, "crossReferences": []},
    "content": {"summary": "Digital platform, launched September 2021 by DPIIT (Department for Promotion of Industry and Internal Trade), that lets businesses identify, apply for, and track regulatory approvals through one unified interface instead of visiting multiple ministries/state portals. Its Know Your Approvals (KYA) module covers 32 Central Departments and 34 States/UTs.", "onlineUrl": "https://www.nsws.gov.in/", "eligibility": {"text": "Open to any business needing Central or State regulatory approvals, registrations, or clearances.", "enterpriseTypeIds": []}, "enablementType": "regulatory_clearance", "servicesOffered": [], "enablementTypeText": "National Single Window System (NSWS)", "providerAuthorityId": null},
    "identity": {"id": "ENAB000007", "code": "NSWS001", "name": "National Single Window System (NSWS)", "slug": "national-single-window-system-nsws", "status": "active", "acronym": "NSWS", "language": "en", "shortName": "NSWS", "entityType": "business_enablement", "legacyCodes": []},
    "metadata": {"revision": 1, "createdAt": "2026-09-05T00:00:00Z", "updatedAt": "2026-09-05T00:00:00Z", "recordStatus": "published", "schemaVersion": "1.0.0", "catalogVersion": "1.34.0-alpha"},
    "analytics": {"saveCount": null, "viewCount": null, "popularity": null, "actionCount": null, "lastAggregatedAt": null},
    "provenance": {"extractedAt": "2026-09-05T00:00:00Z", "fieldSources": [{"url": "https://www.nsws.gov.in/", "note": "Launch date, DPIIT ownership, and KYA module coverage (32 Central Departments, 34 States/UTs) confirmed against the official NSWS portal.", "field": "content", "isBackfill": false, "sourceTier": 5, "sourceType": "official_website", "retrievedAt": "2026-09-05", "organization": "DPIIT / Invest India", "supersededValue": null}], "translations": {}, "pipelineVersion": "build_business_enablement.py-1.0.0", "primarySourceId": null, "extractionMethod": "live_official_source", "defaultSourceTier": 5, "transformationNotes": [], "contributingSourceIds": []},
    "localization": {"en": {"name": "National Single Window System (NSWS)", "summary": "DPIIT unified digital platform for identifying, applying for, and tracking business regulatory approvals across Central and State governments."}, "hi": {"name": null, "summary": null}, "ta": {"name": null, "summary": null}},
    "verification": {"notes": "Confirmed against the official nsws.gov.in portal.", "status": "verified", "confidence": "high", "isVerified": true, "statusText": "Confirmed against live official source", "verifiedAt": "2026-09-05T00:00:00Z", "verifiedBy": null, "reviewDueOn": null, "missingFields": [{"field": "localization.ta", "reason": "Not machine-translated this session -- avoided rather than risk an unreviewed mistranslation."}], "disputedFields": [], "researchStatus": "Official-source researched", "verifiedAgainst": ["nsws.gov.in"]},
    "relationships": {"references": []}
  }'::jsonb,
  now()
)
on conflict (id) do nothing;
