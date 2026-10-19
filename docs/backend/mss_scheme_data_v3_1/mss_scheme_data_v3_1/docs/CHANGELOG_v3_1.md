# CHANGELOG v3.1 — 2025-26 booklet + new central schemes

Generated 2026-10-04. Combined file `msme_schemes_v3_1.json` = 279 v3 records (unchanged) + 114 new records. `new_schemes_2025_26.json` holds only the 114 new records.

## What changed in the format (v3 → v3.1)

- New id prefixes: `MSME2526-xxx` (MSME Schemes Booklet 2025-26), `NEW2026-xxx` (other new/missing central schemes).
- New block `source_current` (same inner shape as `source_2015`: description/benefits/eligibility hi+en point lists, `application_steps`, `page_book`, plus `document_title`, `document_url`, `as_of`, `hi_is_machine_translation`). New records have `source_2015: null`; old records have `source_current: null`.
- `benefit_facts.as_of` now any string (`2015`, `2025-26`, `2026`…); added `source_quote_en`.
- `status.value` adds `announced` and `closed`.
- New fields on every record: `related_v3_ids` (new → 2015 predecessor), `related_new_ids` (2015 → new successor, back-links), `catalog_match` (exact/partial/none), `app_relevance` (high/medium/low).
- Schema validates with 0 errors; 2015 text byte-identical to v3.

## Booklet 2025-26: all 18 schemes covered

| id | scheme | page | catalog | catalog ids |
|---|---|---|---|---|
| MSME2526-001 | Prime Minister's Employment Generation Programme (PMEGP) | 3 | exact | SCH000130 |
| MSME2526-002 | ↳ 2nd Loan for Upgradation of existing PMEGP/REGP/MUDRA units | 5 | partial |  |
| MSME2526-003 | Credit Guarantee Scheme for Micro & Small Enterprises (CGTMSE) | 7 | exact | SCH000038 |
| MSME2526-005 | Micro & Small Enterprises Cluster Development Programme (MSE-CDP) | 9 | exact | SCH000092 |
| MSME2526-006 | Scheme of Fund for Regeneration of Traditional Industries (SFURTI) | 11 | exact | SCH000144 |
| MSME2526-007 | Entrepreneurship Skill Development Programme (ESDP) | 13 | exact | SCH000095, SCH000055 |
| MSME2526-008 | ↳ Entrepreneurship Awareness Programme (EAP) | 13 | partial |  |
| MSME2526-009 | ↳ Entrepreneurship cum Skill Development Programme (E-SDP) | 13 | partial |  |
| MSME2526-010 | ↳ Advance Entrepreneurship cum Skill Development Programme (Advance E-SDP) | 13 | partial |  |
| MSME2526-011 | ↳ Management Development Programme (MDP) | 13 | partial |  |
| MSME2526-012 | ↳ Advance Management Development Programme (Advance MDP) | 13 | partial |  |
| MSME2526-020 | Assistance to Training Institutions (ATI) Scheme | 15 | exact | SCH000013 |
| MSME2526-021 | Coir Vikas Yojana | 16 | exact | SCH000033 |
| MSME2526-022 | ↳ Science & Technology |  | partial |  |
| MSME2526-023 | ↳ Skill Upgradation and Mahila Coir Yojana |  | exact | SCH000035 |
| MSME2526-024 | ↳ Export Market Promotion |  | exact | SCH000034 |
| MSME2526-025 | ↳ Domestic Market Promotion |  | partial |  |
| MSME2526-026 | ↳ Trade and Industry Related Functional Support Services |  | partial |  |
| MSME2526-027 | ↳ Welfare Measures (Pradhan Mantri Suraksha Bima Yojana for coir workers) |  | partial |  |
| MSME2526-028 | Procurement and Marketing Support (PMS) Scheme | 19 | exact | SCH000132 |
| MSME2526-029 | International Cooperation Scheme | 21 | exact | SCH000071 |
| MSME2526-030 | ↳ Market Development Assistance of MSMEs (MDA) | 21 | partial | SCH000121, SCH000072, SCH000073 |
| MSME2526-031 | ↳ Capacity Building of First Time MSE Exporters (CBFTE) |  | partial |  |
| MSME2526-032 | ↳ Framework for International Market Intelligence Dissemination (IMID) |  | partial |  |
| MSME2526-050 | National SC-ST Hub Scheme (NSSH) | 24 | exact | SCH000113 |
| MSME2526-051 | ↳ Special Credit Linked Capital Subsidy Scheme (SCLCSS) | 24 | partial |  |
| MSME2526-052 | ↳ Special Marketing Assistance Scheme (SMAS) | 24 | partial |  |
| MSME2526-053 | ↳ Single Point Registration Scheme (SPRS) under NSSH | 24 | partial |  |
| MSME2526-054 | ↳ Reimbursement of Bank Loan Processing Fee (NSSH) | 24 | partial |  |
| MSME2526-055 | ↳ Reimbursement of Performance Bank Guarantee charges (NSSH) | 24 | partial |  |
| MSME2526-056 | ↳ Reimbursement of Testing Fee (NSSH) | 24 | partial |  |
| MSME2526-057 | ↳ Reimbursement of Export Promotion Council Membership Fee (NSSH) | 24 | partial |  |
| MSME2526-058 | ↳ Reimbursement of Government e-Commerce Portals Membership Fee (NSSH) | 24 | partial |  |
| MSME2526-059 | ↳ Reimbursement of Management Training Programme Fee (NSSH) | 24 | partial |  |
| MSME2526-060 | A Scheme for Promotion of Innovation, Rural Industries and Entrepreneurship (ASPIRE) | 26 | exact | SCH000150 |
| MSME2526-061 | Khadi Gramodyog Vikas Yojana (KGVY) | 28 | exact | SCH000075 |
| MSME2526-062 | ↳ Khadi Vikas Yojana (KVY) | 28 | exact | SCH000076 |
| MSME2526-063 | ↳ Modified Market Development Assistance (MMDA) | 29 | partial |  |
| MSME2526-064 | ↳ Interest Subsidy Eligibility Certificate Scheme (ISEC) | 29 | partial |  |
| MSME2526-065 | ↳ Work-shed Scheme for Khadi Artisans | 29 | partial |  |
| MSME2526-066 | ↳ Strengthening Infrastructure of Existing Weak Khadi Institutions | 29 | partial |  |
| MSME2526-067 | ↳ Marketing Infrastructure (Khadi) | 29 | partial |  |
| MSME2526-068 | ↳ Gramodyog Vikas Yojana (GVY) | 29 | partial |  |
| MSME2526-069 | ↳ Agarbatti Programme – Gramodyog Vikas Yojana | 30 | exact | SCH000006 |
| MSME2526-070 | ↳ Leather Footwear Programme – Gramodyog Vikas Yojana | 30 | partial |  |
| MSME2526-071 | ↳ Pottery Programme – Gramodyog Vikas Yojana | 30 | exact | SCH000125 |
| MSME2526-072 | ↳ Honey Mission (Beekeeping) – Gramodyog Vikas Yojana | 30 | exact | SCH000019 |
| MSME2526-073 | ↳ Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana | 30 | partial |  |
| MSME2526-074 | ↳ Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana | 30 | partial |  |
| MSME2526-075 | ↳ Agro-Food Processing Programme – Gramodyog Vikas Yojana | 30 | partial |  |
| MSME2526-076 | ↳ Service Industry Programme (Electrician, Plumber, DigniTEA) – Gramodyog Vikas Yojana | 30 | partial |  |
| MSME2526-077 | Promotion of MSMEs in North Eastern Region and Sikkim | 31 | exact | SCH000136 |
| MSME2526-078 | PM Vishwakarma | 34 | exact | SCH000124 |
| MSME2526-080 | Tool Rooms and Technical Institutions | 36 | exact | SCH000193 |
| MSME2526-081 | MSME Champions Scheme | 38 | exact | SCH000099 |
| MSME2526-082 | ↳ MSME Sustainable (ZED) Certification Scheme | 39 | exact | SCH000106 |
| MSME2526-083 | ↳ MSME Innovative Scheme (Incubation, Design and IPR) | 42 | partial |  |
| MSME2526-084 | ↳ MSME Innovative Scheme (Incubation) | 42 | exact | SCH000103 |
| MSME2526-085 | ↳ MSME Innovative Scheme (Design) | 43 | exact | SCH000102 |
| MSME2526-086 | ↳ MSME Innovative Scheme (Intellectual Property Rights – IPR) | 44 | exact | SCH000104 |
| MSME2526-087 | ↳ MSME Competitive (LEAN) Scheme | 45 | exact | SCH000100 |
| MSME2526-088 | ↳ Digital MSME | 38 | none |  |
| MSME2526-089 | Self Reliant India (SRI) Fund | 48 | exact | SCH000153 |
| MSME2526-090 | Raising and Accelerating MSME Performance (RAMP) | 50 | exact | SCH000138 |

## Brand-new schemes to add to the app (catalog_match = none)

| id | scheme | status | relevance |
|---|---|---|---|
| NEW2026-001 | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) | active | high |
| NEW2026-005 | Collateral Support for Export Credit (EPM – Niryat Protsahan) | active | high |
| NEW2026-006 | Export Factoring Support (EPM – Niryat Protsahan) | active | high |
| NEW2026-007 | E-Commerce Export Credit Facility (EPM – Niryat Protsahan) | active | high |
| NEW2026-009 | Niryat Disha (EPM non-financial & market access enablers) | active | high |
| NEW2026-010 | TRACE – Trade Regulations, Accreditation & Compliance Support (EPM – Niryat Disha) | active | high |
| NEW2026-011 | LIFT – Logistics Interventions for Freight & Transport (EPM – Niryat Disha) | active | high |
| NEW2026-015 | Credit Guarantee Scheme for Exporters (CGSE) | closed | high |
| NEW2026-017 | Credit Cards for Micro Enterprises Scheme | active | high |
| NEW2026-018 | Scheme for First-Time Entrepreneurs (Women, SC and ST) – Budget 2025-26 | announced | high |
| NEW2026-021 | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints | active | high |
| NEW2026-022 | Trade Receivables Discounting System (TReDS) | active | high |
| NEW2026-024 | GENESIS – Gen-Next Support for Innovative Startups | active | high |
| NEW2026-050 | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme | active | high |
| NEW2026-051 | Prime Minister's Internship Scheme (PMIS) | active | high |
| NEW2026-054 | Jan Shikshan Sansthan (JSS) Scheme | active | high |
| NEW2026-056 | Mission for Aatmanirbharta in Pulses | active | high |
| NEW2026-057 | National Mission on Natural Farming (NMNF) | active | high |
| NEW2026-058 | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) | active | high |
| NEW2026-059 | Agriculture Infrastructure Fund (AIF) | active | high |
| NEW2026-060 | Pradhan Mantri Kisan Urja Suraksha evam Utthaan Mahabhiyan (PM-KUSUM) | active | high |
| NEW2026-061 | PM Surya Ghar: Muft Bijli Yojana | active | high |
| NEW2026-064 | Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi (PM-DAKSH) Yojana | active | high |
| NEW2026-067 | National Action for Mechanised Sanitation Ecosystem (NAMASTE) | active | high |
| NEW2026-069 | Samarth – Scheme for Capacity Building in Textiles Sector | unknown | high |
| NEW2026-071 | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) | active | high |
| NEW2026-072 | Animal Husbandry Infrastructure Development Fund (AHIDF) | unknown | high |
| NEW2026-008 | Emerging Export Opportunities – Risk Sharing (EPM – Niryat Protsahan) | active | medium |
| NEW2026-014 | Market Access Support (MAS) (EPM – Niryat Disha) | active | medium |
| NEW2026-020 | Research, Development and Innovation (RDI) Scheme | active | medium |
| NEW2026-025 | SME Growth Fund (Budget 2026-27) | announced | medium |
| NEW2026-055 | Prime Minister Dhan-Dhaanya Krishi Yojana (PMDDKY) | active | medium |
| NEW2026-063 | Dharti Aaba Janjatiya Gram Utkarsh Abhiyan (DAJGUA) | active | medium |
| NEW2026-065 | Scheme for Residential Education for Students in High Schools in Targeted Areas (SHRESHTA) | unknown | medium |
| NEW2026-066 | Support for Marginalized Individuals for Livelihood and Enterprise (SMILE) | active | medium |
| NEW2026-068 | Silk Samagra-2 (Integrated Scheme for Development of Silk Industry) | unknown | medium |
| NEW2026-073 | Formation and Promotion of 10,000 Farmer Producer Organisations (FPOs) | active | medium |
| MSME2526-088 | Digital MSME | announced | low |
| NEW2026-012 | INSIGHT – Trade Intelligence & Facilitation (EPM – Niryat Disha) | active | low |
| NEW2026-013 | FLOW – Overseas Warehousing & Fulfilment (EPM – Niryat Disha) | active | low |
| NEW2026-026 | National Manufacturing Mission | announced | low |
| NEW2026-062 | PM Electric Drive Revolution in Innovative Vehicle Enhancement (PM E-DRIVE) Scheme | active | low |
| NEW2026-070 | PM Mega Integrated Textile Region and Apparel (PM MITRA) Parks | active | low |

## Partial matches (catalog has a parent/predecessor only)

| id | scheme | related catalog ids |
|---|---|---|
| MSME2526-002 | 2nd Loan for Upgradation of existing PMEGP/REGP/MUDRA units |  |
| MSME2526-008 | Entrepreneurship Awareness Programme (EAP) |  |
| MSME2526-009 | Entrepreneurship cum Skill Development Programme (E-SDP) |  |
| MSME2526-010 | Advance Entrepreneurship cum Skill Development Programme (Advance E-SDP) |  |
| MSME2526-011 | Management Development Programme (MDP) |  |
| MSME2526-012 | Advance Management Development Programme (Advance MDP) |  |
| MSME2526-022 | Science & Technology |  |
| MSME2526-025 | Domestic Market Promotion |  |
| MSME2526-026 | Trade and Industry Related Functional Support Services |  |
| MSME2526-027 | Welfare Measures (Pradhan Mantri Suraksha Bima Yojana for coir workers) |  |
| MSME2526-030 | Market Development Assistance of MSMEs (MDA) | SCH000121, SCH000072, SCH000073 |
| MSME2526-031 | Capacity Building of First Time MSE Exporters (CBFTE) |  |
| MSME2526-032 | Framework for International Market Intelligence Dissemination (IMID) |  |
| MSME2526-051 | Special Credit Linked Capital Subsidy Scheme (SCLCSS) |  |
| MSME2526-052 | Special Marketing Assistance Scheme (SMAS) |  |
| MSME2526-053 | Single Point Registration Scheme (SPRS) under NSSH |  |
| MSME2526-054 | Reimbursement of Bank Loan Processing Fee (NSSH) |  |
| MSME2526-055 | Reimbursement of Performance Bank Guarantee charges (NSSH) |  |
| MSME2526-056 | Reimbursement of Testing Fee (NSSH) |  |
| MSME2526-057 | Reimbursement of Export Promotion Council Membership Fee (NSSH) |  |
| MSME2526-058 | Reimbursement of Government e-Commerce Portals Membership Fee (NSSH) |  |
| MSME2526-059 | Reimbursement of Management Training Programme Fee (NSSH) |  |
| MSME2526-063 | Modified Market Development Assistance (MMDA) |  |
| MSME2526-064 | Interest Subsidy Eligibility Certificate Scheme (ISEC) |  |
| MSME2526-065 | Work-shed Scheme for Khadi Artisans |  |
| MSME2526-066 | Strengthening Infrastructure of Existing Weak Khadi Institutions |  |
| MSME2526-067 | Marketing Infrastructure (Khadi) |  |
| MSME2526-068 | Gramodyog Vikas Yojana (GVY) |  |
| MSME2526-070 | Leather Footwear Programme – Gramodyog Vikas Yojana |  |
| MSME2526-073 | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana |  |
| MSME2526-074 | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana |  |
| MSME2526-075 | Agro-Food Processing Programme – Gramodyog Vikas Yojana |  |
| MSME2526-076 | Service Industry Programme (Electrician, Plumber, DigniTEA) – Gramodyog Vikas Yojana |  |
| MSME2526-083 | MSME Innovative Scheme (Incubation, Design and IPR) |  |
| NEW2026-002 | Export Promotion Mission (EPM) |  |
| NEW2026-003 | Niryat Protsahan (EPM financial enablers) |  |
| NEW2026-004 | Interest Subvention on Pre- and Post-Shipment Export Credit (EPM – Niryat Protsahan) |  |
| NEW2026-019 | Startup India Fund of Funds 2.0 (Startup India FoF 2.0) |  |
| NEW2026-052 | Skill India Programme (restructured: PMKVY 4.0, PM-NAPS, JSS) | SCH000126 |
| NEW2026-053 | Pradhan Mantri National Apprenticeship Promotion Scheme (PM-NAPS) |  |
| NEW2026-074 | Deendayal Jan Aajeevika Yojana – Shehari (DJAY-S) |  |

## Catalog corrections suggested (catalog.scheme, not changed — files only)

- SCH000043 DAY-NULM: marked active, ended 30.09.2024 → successor NEW2026-074 (DAY Jan Aajeevika Yojana – Shehari).
- SCH000070 Interest Equalisation Scheme: marked active, closed/merged into Export Promotion Mission → see NEW2026-004.
- SCH000144 SFURTI, SCH000076 Khadi Vikas Yojana, SCH000035 Skill Upgradation & Mahila Coir Yojana: marked inactive but listed as running in the 2025-26 booklet.
- Duplicates: ESDP (SCH000055 / SCH000095); Stand-Up India (SCH000168 inactive / SCH000218 active).
- Not yet catalogued but in booklet: ESDP sub-programmes, SC-ST Hub sub-schemes, Gramodyog Vikas Yojana components, International Cooperation sub-components, Digital MSME (announced).

## Verification

- Spot-check of 9 key amounts against the booklet PDF: 7 confirmed (2nd-loan caps, ZED 80/60/50% + ₹10,000, Lean ₹1.2 lakh, PM Vishwakarma ₹15,000 / ₹500 / ₹1+2 lakh, SCLCSS 25% up to ₹25 lakh, workshed ₹1.2 lakh, MSE-CDP 80% of ₹30 cr). CGTMSE: booklet says ₹5 cr, record keeps both ₹5 cr (booklet) and ₹10 cr (from 01.04.2025). PMEGP general-category split was not cleanly printed in the booklet extract; record keeps the 15–35% range and the special-category 25%/35%.
- Booklet text came through a summarising fetch tool, not raw PDF text; quotes not seen verbatim carry `quote_verified: false` or an `agent_flags` note.
- Hindi in `source_current` is machine translated.
- Dropped duplicates: MSME2526-004 (MCGS-MSME, kept NEW2026-001), NEW2026-023 (PM Internship, kept NEW2026-051).

## Open items to check

- PMEGP approved only to 31.03.2026; continuation not confirmed (status active, low confidence).
- MSME Champions period 2021-22 to 2025-26; portals still live, no extension notice found.
- Schemes whose period ended Mar 2026 without confirmed continuation: Skill India, PM-DAKSH, NAMASTE, Samarth, Silk Samagra-2, AHIDF.
- Credit Cards for Micro Enterprises (NEW2026-017) status relies on a news report of a Lok Sabha answer; First-time Women/SC/ST entrepreneurs (NEW2026-018) still announced only.
- Many official portals timed out during research (kviconline, scsthub, aspire, pmvishwakarma, coirboard, cgtmse); `current.official_url` not live-checked for those.