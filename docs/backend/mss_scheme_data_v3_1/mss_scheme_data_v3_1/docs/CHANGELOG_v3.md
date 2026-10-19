# MSME schemes JSON – v3 changelog

Generated 2026-10-04 from v2 (`msme_schemes_2015_hindi_all_v2.json`). Hindi text is unchanged.

## What's new

| # | Change | Coverage |
|---|---|---|
| 1 | `source_2015.application_steps`: ordered steps with mode, where, url and documents | 355 steps across 253 schemes |
| 2 | `benefit_facts`: amounts in INR, percent and base, condition, Hindi quote | 360 facts across 166 schemes; every quote matched to the source |
| 3 | `targeting`: beneficiary types, target groups and sectors from fixed vocabularies, plus age and education | 256 schemes tagged |
| 4 | English `en` arrays beside every Hindi point (1:1) | all schemes |
| 5 | `current`: today's name, benefits, eligibility, how to apply and sources, kept separate from `source_2015` | 111 schemes |
| 6 | `parent_id` / `children_ids`, with 20 synthetic group nodes (`MSME2015-G01…G20`) | 279 nodes |
| 7 | `contacts`: websites, emails, phones and offices | 201 contacts |
| + | `status.verified_on` / `source_url` | 87 statuses confirmed with web sources |

## Status changes applied (high confidence, official source)

- **MSME2015-136 ECGC Policy for SME Exporters**: active → **renamed** (ECGC Micro Exporters Policy (MEP)) – https://main.ecgc.in/english/?p=1802
- **MSME2015-138 Market Access Initiative (MAI)**: active → **merged** (Export Promotion Mission – Niryat Disha (Market Access Support)) – https://static.pib.gov.in/WriteReadData/specificdocs/documents/2026/feb/doc2026224799801.pdf
- **MSME2015-196 National Urban Livelihoods Mission (NULM)**: renamed → **discontinued** (Deendayal Jan Aajeevika – Shehari (DJAY-S) pilot) – https://www.pib.gov.in/PressReleasePage.aspx?PRID=2220349&reg=3&lang=1
- **MSME2015-243 Hotel Project Approval & Classification**: active → **active** (Hotel Star Classification (NIDHI+)) – https://nidhi.tourism.gov.in/home/
- **MSME2015-248 Refresher Course for Regional Level Guides**: active → **renamed** (Incredible India Tourist Guide (IITG) refresher course under IITF programme) – https://tourism.gov.in/sites/default/files/2022-07/usq%20628%20for%2021072022.pdf

## Status proposals still to review (stored in `status.proposal`, not applied)

- MSME2015-039 Development of Production Infrastructure (Coir): active → merged [medium] – Coir Vikas Yojana – Coir Industry Technology Upgradation Scheme (CITUS) – https://dmeo.gov.in/sites/default/files/2022-05/Coir_Vikas_Yojana.pdf
- MSME2015-047 Pradhan Mantri Kaushal Vikas Yojana (PMKVY): active → merged [medium] – Skill India Programme (PMKVY 4.0 component) – https://www.tribuneindia.com/news/business/cabinet-approves-continuation-and-restructuring-of-skill-india-programme/amp
- MSME2015-048 Apprenticeship Training (Apprentices Act): renamed → renamed [medium] – National Apprenticeship Promotion Scheme-2 (NAPS-2 / PM-NAPS), under Skill India Programme – https://msde.gov.in/schemes-initiatives/apprenticeship-training/naps
- MSME2015-061 RDD&D for New & Renewable Energy: active → renamed [high] – Renewable Energy Research and Technology Development (RE-RTD) Programme – https://powerline.net.in/2026/07/22/mnre-approves-rs-4-37-billion-renewable-research-programme-for-2026-31/
- MSME2015-064 NEDFi Corporate Finance: active → renamed [low] – NEDFi Project Finance / Working Capital Loan – https://www.nedfi.com/who-we-are/
- MSME2015-065 NEDFi Equipment Finance: active → discontinued [low] – https://www.nedfi.com/who-we-are/
- MSME2015-066 NEDFi Initiative for Development of Entrepreneurs in Agriculture (IDEA): active → discontinued [low] – https://www.nedfi.com/who-we-are/
- MSME2015-068 NEDFi Equity Fund: active → discontinued [low] – https://www.nedfi.com/who-we-are/
- MSME2015-069 NEDFi Opportunity Scheme for Small Enterprises (NOSSE): active → merged [low] – Loan for Existing & New Business (NEDFi) – https://www.nedfi.com/
- MSME2015-070 North East Entrepreneurs Development (NEED): active → merged [low] – Loan for Existing & New Business (NEDFi) – https://www.nedfi.com/
- MSME2015-071 North East Handloom & Handicrafts (NEHH): active → merged [low] – Loan for Artisans (Atmanirbhar Hastshilpkar Scheme) – https://www.nedfi.com/loan-for-artisans/
- MSME2015-072 Rupee Term Loan (NEDFi): active → renamed [low] – Project Finance (NEDFi) – https://www.nedfi.com/
- MSME2015-073 Working Capital Term Loan (NEDFi): active → renamed [low] – Working Capital Loan (NEDFi) – https://www.nedfi.com/working-capital-loan/
- MSME2015-074 WCTL for Contract Finance (NEDFi): active → discontinued [low] – https://www.nedfi.com/
- MSME2015-075 Women Enterprise Development (WED, NEDFi): active → renamed [medium] – Loan for Women Entrepreneurs (NEDFi) – https://www.nedfi.com/loan-for-women-entrepreneurs/
- MSME2015-089 Extra Mural Research in AYUSH: active → merged [medium] – AYURGYAN Scheme (Research & Innovation in Ayush) – https://eparlib.sansad.in/bitstream/123456789/3000039/1/AU1934_MfHFkp.pdf
- MSME2015-097 Financial Assistance for Road Safety Programmes: active → renamed [medium] – Scheme of Financial Assistance for administering Road Safety Advocacy and Awards for outstanding work in Road Safety – https://rsa.morth.gov.in/WriteReadData/Sceme_of_Fin.pdf
- MSME2015-101 Allotment of Class-V 'B' Surplus Army Vehicles to ESM/Widows: active → discontinued [low] – https://desw.gov.in/Self-Employment-Schemes-DGR
- MSME2015-103 LPG Distributorship under 18% Quota (Defence): active → renamed [medium] – Issue of Eligibility Certificate for Allotment of Regular LPG Distributorship – https://desw.gov.in/Self-Employment-Schemes-DGR
- MSME2015-115 Assistance to NCDC Programmes for Cooperative Development: active → merged [medium] – Central Sector Integrated Scheme on Agricultural Cooperation (CSISAC); NCDC now funded via 'Grant in aid to NCDC' – https://www.ncdc.in/documents/other/2817200419Guidelines_CSISAC.pdf
- MSME2015-221 Biotechnology (DBT schemes): active → merged [medium] – Bio-RIDE (Biotechnology Research Innovation and Entrepreneurship Development) – https://dbtindia.gov.in/sites/default/files/BioRIDE_Press%20Release_Press%20Information%20Bureau.pdf
- MSME2015-223 Animal/Agri/Marine Biotechnology & Bioresources Programmes: active → merged [low] – Bio-RIDE (R&D component) – https://dbtindia.gov.in/sites/default/files/BioRIDE_Press%20Release_Press%20Information%20Bureau.pdf

## Agent flags

270 flags across 163 schemes are stored in `agent_flags`. They mark garbled source text, ambiguous numbers and sections that look misplaced. Check these before showing amounts in the app.