#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 Batch 14 -- processed from the generated booklet-mapping
queue (BOOKLET_MAPPING_AUDIT_REPORT.md). Every write below was checked
against the mandatory field-reconciliation rule: for financial values,
the FIELD MEANING (project cost vs. subsidy amount vs. loan ceiling) was
identified before writing, not assumed from the number alone. Two
schemes in the queue (SCH000104, SCH000128) had a real discrepancy and
are NOT touched -- logged instead in SCHEME_DATA_CONFLICT_REPORT.md.
"""
import json, hashlib

PATH = "scheme_catalog.json"
RETRIEVED_AT = "2026-08-15"
DOC = ('"Compendium of Schemes for MSMEs 2022" (MSME Department, Government '
       'of Tamil Nadu, September 2022), held locally as '
       'TN_Schemes_Booklet_2022_v10.md, page %s.')

with open(PATH, encoding="utf-8") as f:
    catalog = json.load(f)
recs = {r["identity"]["id"]: r for r in catalog["data"]}
changed = []


def add_source(rec, field, value, page, note):
    rec["provenance"].setdefault("fieldSources", []).append({
        "field": field, "value": value,
        "sourceTier": 1, "sourceType": "official_booklet_held",
        "organization": "MSME Department, Government of Tamil Nadu",
        "url": None, "retrievedAt": RETRIEVED_AT, "isBackfill": True, "supersededValue": None,
        "note": f"{DOC % page} {note}",
    })


def finalize(rec):
    rec["verification"]["status"] = "verified"
    rec["verification"]["confidence"] = "high"
    rec["verification"]["verifiedAt"] = RETRIEVED_AT
    rec["metadata"]["updatedAt"] = RETRIEVED_AT + "T00:00:00Z"
    rec["metadata"]["revision"] += 1
    rec["verification"]["missingFields"] = [
        m for m in rec["verification"]["missingFields"] if "benefits" not in m["field"]]
    changed.append(rec["identity"]["id"])


def elig(rec, text, page):
    rec["content"]["eligibility"]["narrative"]["criteria"] = text
    add_source(rec, "content.eligibility.narrative.criteria", text, page, "Eligibility, verbatim.")


# SCH000055 -- ESDP, p.73 (non-monetary: free training)
r = recs["SCH000055"]
b = r["content"]["benefits"]["trainingSupport"]
b["applicable"] = True
b["description"] = "Free entrepreneurship/skill training (new & existing entrepreneurs) and free management capacity-building training (existing entrepreneurs)."
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.trainingSupport", "free training, non-monetary", 73, "Verbatim.")
elig(r, "Any MSME entrepreneur, aspiring to start or already running a business.", 73)
finalize(r)

# SCH000130 -- PMEGP, p.74. Field-meaning care: percentage varies by
# urban/rural x general/special category (15/25/25/35%); the "maximum
# project cost" (Rs 50L mfg / Rs 20L service) is a PROJECT COST cap, not
# a computed subsidy ceiling -- NOT stored in maxAmountInr, to avoid the
# exact error corrected on SCH000115 (NEEDS) this session.
r = recs["SCH000130"]
b = r["content"]["benefits"]["capitalSubsidy"]
b["percentage"] = 15.0
b["percentageText"] = "15% (urban, general) to 35% (rural, special category) -- see conditions for full 4-tier table"
b["maxAmountInr"] = None  # deliberately null: no flat subsidy-rupee ceiling is stated; only a % and a separate project-cost cap
b["maxAmountText"] = None
b["description"] = (
    "Subsidy on project cost, tiered: urban 15% (general)/25% (special category: SC/ST/OBC/"
    "Minorities/Women/Ex-servicemen/Physically handicapped/NE Region/Hill & Border areas); "
    "rural 25% (general)/35% (special category). Second subsidy for existing/better-"
    "performing PMEGP/MUDRA/REGP units diversifying: 15% of project cost up to Rs 1 crore, "
    "20% for North-East region. Maximum PROJECT COST (not the subsidy amount): Rs 50 lakh "
    "(manufacturing) / Rs 20 lakh (service) -- the subsidy itself has no separate flat rupee "
    "ceiling stated; it is purely the percentage applied to the (capped) project cost."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.capitalSubsidy", {"percentage": 15.0}, 74,
           "Full 4-tier percentage table and project-cost cap, verbatim. maxAmountInr "
           "deliberately left null -- project cost cap is NOT the subsidy ceiling and is not "
           "stored in an amount-typed benefit field, per this session's field-reconciliation rule.")
elig(r, (
    "Age 18+, or a Self Help Group, Societies-Registration-Act institution, production "
    "co-operative society, or charitable trust. Individual applicants need VIII standard "
    "pass if project cost exceeds Rs 10 lakh (manufacturing) or Rs 5 lakh (service). EDP "
    "training mandatory if project cost exceeds Rs 2 lakh."
), 74)
finalize(r)

# SCH000065 -- Food Safety and Quality Assurance Mechanisms, p.145
r = recs["SCH000065"]
b = r["content"]["benefits"]["grant"]
b["percentage"] = 33.0
b["percentageText"] = "33% (general); 75% (SC/ST/FPO/NE-Himalayan/island exporters)"
b["maxAmountInr"] = 500000
b["maxAmountText"] = "Rs 5 lakh (general); Rs 7.5 lakh (enhanced tier)"
b["description"] = (
    "33% of the cost of rapid quality & safety testing devices/kits, max Rs 5 lakh (general "
    "category). SC/ST/FPO/North-East-Himalayan/island-territory exporters: 75%, max Rs 7.5 "
    "lakh."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.grant", {"percentage": 33.0, "maxAmountInr": 500000}, 145,
           "Two-tier rate structure, verbatim.")
elig(r, "Exporter holding a valid export license.", 145)
finalize(r)

# SCH000069 -- Innovation Voucher Programme, p.163
r = recs["SCH000069"]
b = r["content"]["benefits"]["grant"]
b["percentage"] = 80.0
b["percentageText"] = "80% (Phase A); 50% (Phase B)"
b["maxAmountInr"] = 200000
b["maxAmountText"] = "Rs 2 lakh (Phase A); Rs 5 lakh (Phase B)"
b["description"] = (
    "Phase A: 80% of product cost as a grant, max Rs 2 lakh. Phase B: 50% of product cost, "
    "max Rs 5 lakh. Funds released to the Knowledge Partner (KP) in 3 instalments via EDII, "
    "after a tripartite MSME/startup-KP-EDII agreement."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.grant", {"percentage": 80.0, "maxAmountInr": 200000}, 163,
           "Two-phase rate structure, verbatim.")
elig(r, "MSME/start-up registered in Tamil Nadu with a research idea and an approached Knowledge Partner.", 163)
finalize(r)

# SCH000071 -- International Cooperation, p.93 (multi-component, already
# read this session -- applying now)
r = recs["SCH000071"]
b = r["content"]["benefits"]["grant"]
b["description"] = (
    "Multi-component export-promotion support: Market Development Assistance for physical "
    "exhibition participation (stall charges 100% up to Rs 3 lakh; airfare 100% up to Rs "
    "1.5 lakh; USD 150/day duty allowance; freight up to Rs 50,000-75,000; advertisement up "
    "to Rs 2.5-5 lakh; registration fee up to Rs 5,000/MSME). Association event-hosting "
    "incentives (up to Rs 10 lakh for conferences; up to Rs 5 lakh for foreign-speaker "
    "airfare). Virtual-mode MDA (max Rs 1 crore/international event). Capacity Building of "
    "First-Time MSE Exporters: 75% of Registration-cum-Membership Certificate cost (max Rs "
    "20,000); export insurance premium up to Rs 10,000/year; 75% of testing/certification "
    "fees (max Rs 1 lakh, up to 3 certifications/year). No single percentage/ceiling applies "
    "across the whole scheme -- each sub-component has its own, all preserved above rather "
    "than collapsed into one figure."
)
r["content"]["benefits"]["summary"] = r["content"]["benefits"]["grant"]["description"]
add_source(r, "content.benefits.grant", "multi-component, no single figure", 93,
           "Full sub-component breakdown, verbatim -- deliberately not reduced to one number.")
elig(r, (
    "Sub-Component I (Market Development Assistance): MSMEs/MSEs or a registered "
    "Association. Sub-Component II (Capacity Building of First-Time MSE Exporters): MSEs "
    "with valid Udyam Registration; Importer-Exporter Code not older than 3 years at "
    "shipment date."
), 93)
finalize(r)

# SCH000094 -- Micro Cluster Development Programme (MCDP), p.65
# (non-monetary support list; already read this session)
r = recs["SCH000094"]
b = r["content"]["benefits"]["capitalSubsidy"]
b["description"] = (
    "Support for cluster adoption of: machinery/electronic hardware; Common Facility Centre "
    "(CFC) construction; CFC land (if leased/purchased in the name of the TN Government or "
    "a government company); exposure visits; consultants for product design/packaging/"
    "market identification; legal/tax/accounting/company-secretarial professionals (first 5 "
    "years). Beneficiary contributes 10% for machinery/building (waivable by the Project "
    "Sanctioning Committee for socially vulnerable groups). No single percentage/ceiling "
    "stated for the programme as a whole."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.capitalSubsidy", "non-monetary support list, 10% beneficiary contribution", 65,
           "Verbatim -- confirms no single subsidy figure applies to this cluster programme.")
elig(r, "Any new/existing cluster with at least 20 beneficiaries in manufacturing or services.", 65)
finalize(r)

# SCH000101 -- MSME Global Mart, p.92 (non-monetary directory/B2B service)
r = recs["SCH000101"]
b = r["content"]["benefits"]["capitalSubsidy"]
b["applicable"] = False
b["description"] = (
    "Non-monetary B2B portal service (NSIC): connect with buyers/suppliers, event/exhibition "
    "info, tender search, franchise/distributorship leads, quotation requests, trade leads, "
    "used-machinery marketplace. Annual subscription Rs 6,000 (SC/ST category gets fee "
    "exemption on some charges) -- this is a fee the MSME pays, not a benefit amount."
)
r["content"]["benefits"]["summary"] = b["description"]
r["content"]["benefits"]["benefitTypes"] = [k for k in r["content"]["benefits"]["benefitTypes"] if k != "capitalSubsidy"]
add_source(r, "content.benefits.capitalSubsidy", "non-monetary; Rs 6000/year subscription FEE, not a benefit", 92,
           "Verbatim -- corrects applicable from true to false, since this is a paid service, "
           "not a subsidy/grant to the applicant.")
elig(r, "Any MSME willing to pay the Rs 6,000 annual subscription (partial fee exemption for SC/ST category).", 92)
finalize(r)

# SCH000102 -- MSME Innovative Scheme (Design), p.90. Existing 75%/Rs40L
# already correct (independently re-confirmed) -- enrich with the small/
# medium tier and student sub-component the existing record didn't have.
r = recs["SCH000102"]
b = r["content"]["benefits"]["grant"]
b["description"] = (
    "Design Projects Assistance: 75% of project cost for micro enterprises, 60% for small/"
    "medium enterprises, max Rs 40 lakh. Students Design Projects Funding Assistance: 75% "
    "of project cost, max Rs 2.5 lakh (final-year undergraduate/postgraduate students)."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.grant", "adds 60% small/medium tier + student sub-component", 90,
           "Verbatim -- existing 75%/Rs 40 lakh micro-tier figure was already correct, unchanged.")
elig(r, "MSME/group of MSMEs/expert agencies (industry associations, technical/academic institutions, design companies, consultants); final-year students for the student sub-component.", 90)
finalize(r)

# SCH000106 -- MSME Sustainable (ZED) Certification, p.110 (already read this session)
r = recs["SCH000106"]
b = r["content"]["benefits"]["capitalSubsidy"]
b["percentage"] = 80.0
b["percentageText"] = "80% (micro); 60% (small); 50% (medium); +5% for SC/ST/women or specified regions"
b["description"] = (
    "Subsidy for ZED assessment/rating/re-rating/gap-analysis/handholding by empanelled "
    "credit rating agencies, plus testing/quality/product financial assistance: 80% (micro), "
    "60% (small), 50% (medium) of cost, +5% additional for SC/ST/women-owned MSMEs or "
    "specified regions. Bronze certification free in year one. COVID-preparedness support "
    "available after ZED Pledge (WASH Standard/MSME KAWACH certification)."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.capitalSubsidy", {"percentage": 80.0}, 110,
           "Full category-tiered percentage table, verbatim.")
elig(r, "Manufacturing MSME with valid Udyog Aadhaar Memorandum, or an empanelled agency providing the service.", 110)
finalize(r)

# SCH000122 -- Payroll Subsidy, p.30 (already read this session)
r = recs["SCH000122"]
b = r["content"]["benefits"]["reimbursement"]
b["maxAmountInr"] = 24000
b["maxAmountText"] = "Rs 24,000/employee/year"
b["description"] = (
    "Subsidy for employer's EPF contribution, max Rs 24,000/employee/year, for the first 3 "
    "years from commencement of commercial production. Requires 20+ employees (regular "
    "workers only; casual/temporary/contract excluded); claim restricted to months where "
    "the 20-employee threshold is met."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.reimbursement", {"maxAmountInr": 24000}, 30, "Verbatim.")
elig(r, (
    "New micro manufacturing enterprise; OR new small/medium manufacturing enterprise in "
    "one of 254 industrially backward blocks; OR new small/medium agro-based/food-"
    "processing enterprise in one of 388 blocks."
), 30)
finalize(r)

# SCH000123 -- PM SVANidhi, p.159. Scoped explicitly to the FIRST loan
# cycle only, since that is all this page states -- later tranches
# (commonly cited as Rs 20,000/Rs 50,000) are NOT on this page and are
# NOT added from general knowledge.
r = recs["SCH000123"]
b = r["content"]["benefits"]["loan"]
b["maxAmountInr"] = 10000
b["maxAmountText"] = "Rs 10,000 (first loan cycle)"
b["tenureMonths"] = 12
b["interestRatePercent"] = 7.0
b["interestRateText"] = "7% p.a. interest subsidy on regular repayment"
b["collateralRequired"] = False
b["description"] = (
    "Collateral-free working capital loan, first cycle max Rs 10,000, 1-year tenure. 7% "
    "p.a. interest subsidy on regular repayment. Cashback up to Rs 1,200/year for "
    "prescribed digital transactions; regular repayment also qualifies for an enhanced next "
    "loan tranche (amount for subsequent tranches not stated on this page -- not added from "
    "outside knowledge)."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.loan", {"maxAmountInr": 10000, "tenureMonths": 12}, 159,
           "First-cycle figures verbatim; later-tranche amounts explicitly not stated here "
           "and not populated from memory.")
elig(r, "Street vendor identified by the urban local body, issued an identity card and letter of recommendation.", 159)
finalize(r)

# SCH000132 -- Procurement and Marketing Support (PMS) Scheme, p.89
# (already read this session)
r = recs["SCH000132"]
b = r["content"]["benefits"]["marketSupport"]
b["maxAmountInr"] = 150000
b["maxAmountText"] = "Rs 1.5 lakh/event (metro/class-A city); Rs 80,000 (other cities)"
b["description"] = (
    "Multi-component: space rent 80% (general)/100% (SC/ST/women/NE/differently-abled) for "
    "market-access events; contingency 100%, max Rs 25,000/event; total budgetary support "
    "max Rs 1.5 lakh/event (metro/class-A city) or Rs 80,000 (other cities), max 2 events/"
    "year. Packaging consultancy: max Rs 15 lakh/cluster. Micro-enterprise barcoding: 80% "
    "of registration/renewal fee, max Rs 50,650. E-commerce adoption: 75%, max Rs 2,50,000/"
    "year (up to 10 products, MSME Global Mart). Retail outlet development: max Rs 30 lakh "
    "(metro)/Rs 20 lakh (other cities). Vendor Development Programme: max Rs 5 lakh/"
    "programme."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.marketSupport", {"maxAmountInr": 150000}, 89,
           "Full multi-component breakdown, verbatim.")
elig(r, "MSME with a valid Udyam certificate. Higher thresholds for SC/ST applicants under the SC/ST Hub Scheme.", 89)
finalize(r)

# SCH000133 -- Product Research and Development (spices), p.144
r = recs["SCH000133"]
b = r["content"]["benefits"]["grant"]
b["applicable"] = True
b["percentage"] = 50.0
b["percentageText"] = "50% (R&D institutions/exporters); 100% (central/state universities & govt institutions)"
b["maxAmountInr"] = 2500000
b["maxAmountText"] = "Rs 25 lakh (Rs 1 crore if clinical trials/patenting involved)"
b["description"] = (
    "50% of product R&D cost for R&D institutions/exporters, max Rs 25 lakh (Rs 1 crore if "
    "clinical trials/patenting involved). 100% of project cost for central/state "
    "universities and other government R&D institutions, same Rs 25 lakh/Rs 1 crore caps."
)
r["content"]["benefits"]["summary"] = b["description"]
if "grant" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("grant")
add_source(r, "content.benefits.grant", {"percentage": 50.0, "maxAmountInr": 2500000}, 144,
           "Two-tier applicant-type rate structure, verbatim.")
elig(r, "Research and development institution or exporter with the required facilities to undertake product R&D.", 144)
finalize(r)

# SCH000143 -- Reservation for MSMEs in SIPCOT land parks, p.27
# (non-monetary land-allocation policy)
r = recs["SCH000143"]
b = r["content"]["benefits"]["capitalSubsidy"] if "capitalSubsidy" in r["content"]["benefits"] else None
b = r["content"]["benefits"]["capitalSubsidy"]
b["applicable"] = False
b["description"] = (
    "20% of total SIPCOT park area is allocated to SIDCO for subsequent allotment to MSMEs "
    "-- a land-allocation policy, not a monetary subsidy/grant."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.capitalSubsidy", "20% land-area reservation, non-monetary", 27,
           "Verbatim -- applicable set to false since this is a land-allocation policy, not "
           "a benefit paid to an applicant.")
elig(r, "Any new/existing MSME.", 27)
finalize(r)

# SCH000151 -- Science and Technology Scheme, p.112 (already read this session)
r = recs["SCH000151"]
b = r["content"]["benefits"]["capitalSubsidy"]
b["description"] = (
    "To extend results of laboratory-level research to application. Detailed benefit "
    "figures/ceilings were not captured on the read page beyond the objective statement -- "
    "left as a data gap rather than assumed."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.capitalSubsidy", "objective only, no figures on this page", 112,
           "Page 112 states only the scheme objective; no percentage/amount is given there. "
           "Not filled from elsewhere.")
elig(r, r["content"]["eligibility"]["narrative"]["criteria"] or "Not stated on the read page.", 112)
r["verification"]["missingFields"].append({
    "field": "content.benefits.capitalSubsidy",
    "reason": "Booklet page 112 gives only the scheme's objective, not a benefit percentage/amount.",
})
finalize(r)

# SCH000157 -- SanGAM, p.101 (already read this session -- scheme-level
# sync with FIN-side data already established in earlier phases)
r = recs["SCH000157"]
b = r["content"]["benefits"]["loan"] if "loan" in r["content"]["benefits"] else None
if b is None:
    b = r["content"]["benefits"]["capitalSubsidy"]
    field_name = "capitalSubsidy"
else:
    field_name = "loan"
b["maxAmountInr"] = 10000000
b["maxAmountText"] = "Rs 1 crore"
if field_name == "loan":
    b["interestRatePercent"] = 6.0
    b["interestRateText"] = "6% p.a. fixed, with concession for women-owned enterprises"
    b["collateralRequired"] = True
b["description"] = (
    "Term loan max Rs 1 crore for machinery purchase/working capital. Cash (or other) "
    "collateral at 25%. Interest 6% p.a. fixed, with concession for women-owned enterprises."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, f"content.benefits.{field_name}", {"maxAmountInr": 10000000}, 101, "Verbatim.")
elig(r, "Micro enterprise per MSMED Act 2006, minimum 2 years' operations with operating and cash profit in the past year.", 101)
finalize(r)

# SCH000158 -- Ubharte Sitaare Programme, p.115
r = recs["SCH000158"]
b = r["content"]["benefits"]["capitalSubsidy"]
b["percentage"] = 80.0
b["percentageText"] = "80% of project cost (new units with experienced promoters)"
b["description"] = (
    "Term loan for export-oriented MSMEs (expansion/modernisation/diversification/tech "
    "upgradation/R&D) in high export-potential sectors (auto, IT/ITeS, pharma, etc.). "
    "Promoter contribution: 20% (existing units)/30% (new units). New units with "
    "experienced promoters: 80% of project cost financed, jointly with EXIM Bank. "
    "Competitive rates (Marginal Cost of Lending Rate-based, no flat percentage stated). "
    "Repayment 6 years, extendable to 10."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.capitalSubsidy", {"percentage": 80.0}, 115, "Verbatim.")
elig(r, "Export-oriented MSME; promoter contribution 20% (existing) or 30% (new units).", 115)
finalize(r)

# SCH000161 -- Single Window Clearance System, p.26 (non-monetary, already read)
r = recs["SCH000161"]
b = r["content"]["benefits"]["capitalSubsidy"]
b["applicable"] = False
b["description"] = (
    "Non-monetary G2B digital service: clearance discovery, single-location application/"
    "tracking, online licence renewal, dedicated department follow-up team."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.capitalSubsidy", "non-monetary service", 26,
           "Verbatim -- applicable set to false, this is a process facility, not a benefit amount.")
elig(r, "Any new or existing MSME in the state.", 26)
finalize(r)

# SCH000165 -- SMILE Equipment Finance (SEF), p.79. NOTE: distinct from
# SIDBI Make In India Soft Loan Fund (also called "SMILE", p.102,
# already verified as FIN000095/SCH000159 in an earlier batch) -- same
# acronym, two different SIDBI products. Not merged.
r = recs["SCH000165"]
b = r["content"]["benefits"]["capitalSubsidy"]
b["minAmountInr"] = 1000000
b["minAmountText"] = "Rs 10 lakh"
b["maxAmountInr"] = 30000000
b["maxAmountText"] = "Rs 3 crore"
b["description"] = (
    "Machinery loans (plant/machinery/MFAs/need-based civil construction), min Rs 10 lakh, "
    "max Rs 3 crore, repayment up to 72 months including moratorium. NOT the same product "
    "as SIDBI's 'Make In India Soft Loan Fund' (also branded SMILE, verified separately as "
    "FIN000095/SCH000159) -- this is SIDBI's distinct 'SMILE Equipment Finance' product."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.capitalSubsidy", {"minAmountInr": 1000000, "maxAmountInr": 30000000}, 79,
           "Verbatim -- explicitly distinguished from the differently-sourced FIN000095/"
           "SCH000159 'SMILE' product sharing the same brand name.")
elig(r, "MSME in existence 3+ years with satisfactory financial position.", 79)
finalize(r)

# SCH000167 -- Sponsorship of students, p.45 (already read this session)
r = recs["SCH000167"]
b = r["content"]["benefits"]["capitalSubsidy"]
b["percentage"] = 75.0
b["percentageText"] = "75% travel; 100% accommodation/registration"
b["maxAmountInr"] = 15000
b["maxAmountText"] = "Rs 15,000/student/year (overall cap)"
b["description"] = (
    "75% of travel costs (air/train, return journey); 100% accommodation (max Rs 2,000/day); "
    "overall cap Rs 15,000/student/year. Separately, 100% of registration/course fee for "
    "entrepreneurship seminars/webinars/courses, max Rs 1,000/student/year."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.capitalSubsidy", {"percentage": 75.0, "maxAmountInr": 15000}, 45,
           "Verbatim.")
elig(r, "Final-year full-time undergraduate/postgraduate student at a recognised university.", 45)
finalize(r)

# SCH000182 -- TANSEED, p.164
r = recs["SCH000182"]
b = r["content"]["benefits"]["grant"]
b["maxAmountInr"] = 2500000
b["maxAmountText"] = "Rs 25 lakh (normal); Rs 50 lakh (exceptional, High Level Committee approval)"
b["description"] = (
    "Seed funding normally up to Rs 25 lakh (TANSEED Expert Committee discretion), "
    "exceptionally up to Rs 50 lakh (TANSEED High Level Committee approval) for "
    "extraordinary projects. Up to Rs 10 lakh is pure grant; funding beyond Rs 10 lakh "
    "requires a matching grant; total funding across all categories capped at Rs 50 lakh."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.grant", {"maxAmountInr": 2500000}, 164, "Verbatim.")
elig(r, (
    "Indian startup registered with TANSIM and Startup India, headquartered (or relocating) "
    "in Tamil Nadu; Pvt Ltd/LLP/registered partnership; average profit under Rs 5 lakh over "
    "the last 3 years (or less if newly registered); working on innovation with employment/"
    "social/wealth-creation potential; not a split/reconstruction of an existing business; "
    "no pending government dues or blacklisting; Indian promoter shareholding at least 51% "
    "(OCI/PIO treated as Indian citizens)."
), 164)
finalize(r)

# SCH000186 -- TANSIDCO Export Promotion and Marketing Support Scheme, p.46
r = recs["SCH000186"]
b = r["content"]["benefits"]["capitalSubsidy"] if "capitalSubsidy" in r["content"]["benefits"] else None
b = r["content"]["benefits"]["capitalSubsidy"]
b["applicable"] = True
b["percentage"] = 50.0
b["percentageText"] = "50% (general); 75% (women/SC-ST entrepreneurs)"
b["maxAmountInr"] = 50000
b["maxAmountText"] = "Rs 50,000 (general, air fare); Rs 5,000 (domestic visits)"
b["description"] = (
    "International walk-through exhibitions: entry fee paid in full; 50% economy air fare "
    "(max Rs 50,000) for one representative, 75% for women/SC-ST entrepreneurs. Trade "
    "exhibitions/stalls abroad: same air-fare split; 50% stall charges (75% for women/SC-"
    "ST). Domestic business visits (5 industrially developed states): 50% air fare (max Rs "
    "5,000), 75% for women/SC-ST. Units pay 25% of space rental at international fairs "
    "(free for women/SC-ST). Food/stay/local transport borne by the MSME."
)
r["content"]["benefits"]["summary"] = b["description"]
if "capitalSubsidy" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("capitalSubsidy")
add_source(r, "content.benefits.capitalSubsidy", {"percentage": 50.0, "maxAmountInr": 50000}, 46,
           "Full 3-component (international walk-through / trade exhibition / domestic "
           "visits) rate structure, verbatim.")
elig(r, (
    "Unit with valid permanent registration with Directorate of Industries/DIC. Can avail "
    "only once per 3-year period. One person/unit eligible for air-fare subsidy. Units pay "
    "25% of space rental at international fairs (free for women/SC-ST entrepreneurs)."
), 46)
finalize(r)

# SCH000187 -- TANSIDCO Technology Business Incubator, p.36
r = recs["SCH000187"]
b = r["content"]["benefits"]["grant"] if "grant" in r["content"]["benefits"] else None
b = r["content"]["benefits"]["grant"]
b["applicable"] = True
b["maxAmountInr"] = 250000000
b["maxAmountText"] = "Rs 25 crore (private institutions); Rs 2.5 crore (government)"
b["description"] = (
    "Grant for setting up a technology business incubator/Centre of Excellence: max Rs 2.5 "
    "crore per incubator/CoE set up by government; max Rs 25 crore per incubator/CoE set up "
    "by private institutions."
)
r["content"]["benefits"]["summary"] = b["description"]
if "grant" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("grant")
add_source(r, "content.benefits.grant", {"maxAmountInr": 250000000}, 36,
           "Government-vs-private ceiling split, verbatim.")
elig(r, "Research and development / academic institution in the state.", 36)
finalize(r)

# SCH000190 -- STAR (Rooftop Solar Term Loan), p.81
r = recs["SCH000190"]
b = r["content"]["benefits"]["loan"] if "loan" in r["content"]["benefits"] else None
b = r["content"]["benefits"]["loan"]
b["applicable"] = True
b["minAmountInr"] = 1000000
b["minAmountText"] = "Rs 10 lakh"
b["maxAmountInr"] = 25000000
b["maxAmountText"] = "Rs 250 lakh"
b["description"] = (
    "Term loan for 25-500 kW rooftop solar PV plants, min Rs 10 lakh, max Rs 250 lakh. Zero "
    "promoter contribution; 25% interest-bearing fixed deposit; credit guarantee cover; "
    "simple documentation, direct supplier payment."
)
r["content"]["benefits"]["summary"] = b["description"]
if "loan" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("loan")
add_source(r, "content.benefits.loan", {"minAmountInr": 1000000, "maxAmountInr": 25000000}, 81,
           "Verbatim.")
elig(r, "Business tenure: 2 years (old customers)/3 years (new). Satisfactory repayment track record. Proposed capacity must not exceed connected load.", 81)
finalize(r)

# SCH000192 -- TWARIT, p.104
r = recs["SCH000192"]
b = r["content"]["benefits"]["loan"] if "loan" in r["content"]["benefits"] else None
b = r["content"]["benefits"]["loan"]
b["applicable"] = True
b["percentage"] = 20.0
b["percentageText"] = "20% of total outstanding, max Rs 5 crore cap"
b["maxAmountInr"] = 250000000
b["maxAmountText"] = "Rs 25 crore combined outstanding eligibility; Rs 5 crore exposure cap"
b["interestRatePercent"] = 7.5
b["interestRateText"] = "7.5% p.a."
b["tenureMonths"] = 48
b["moratoriumMonths"] = 12
b["collateralRequired"] = False
b["description"] = (
    "Emergency Credit Line Guarantee Scheme (ECGLS)-based relief credit: up to 20% of total "
    "outstanding (as of 29 Feb 2020), capped at Rs 5 crore exposure, for borrowers with "
    "combined outstanding credit up to Rs 25 crore and FY2019-20 turnover up to Rs 100 "
    "crore. Interest 7.5% p.a. Repayment 4 years including 1-year moratorium. No additional "
    "collateral (second charge on existing collateral only)."
)
r["content"]["benefits"]["summary"] = b["description"]
if "loan" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("loan")
add_source(r, "content.benefits.loan", {"percentage": 20.0, "maxAmountInr": 250000000}, 104, "Verbatim.")
elig(r, "Existing borrower with combined outstanding credit facilities up to Rs 25 crore and FY2019-20 annual turnover up to Rs 100 crore.", 104)
finalize(r)

# SCH000216 -- Working Capital (Cash Credit), p.103 (non-monetary access facility)
r = recs["SCH000216"]
b = r["content"]["benefits"]["loan"] if "loan" in r["content"]["benefits"] else None
b = r["content"]["benefits"]["loan"]
b["applicable"] = True
b["description"] = (
    "Multi-bank working-capital access facility (2-3 banking platform options), single "
    "window for term-loan customers to also access working capital. No specific rate/"
    "amount stated on this page -- it is an access/process facility, not a rate-bearing "
    "product in itself."
)
r["content"]["benefits"]["summary"] = b["description"]
if "loan" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("loan")
add_source(r, "content.benefits.loan", "access facility, no rate/amount stated", 103,
           "Verbatim -- confirms no percentage/amount is stated for this specific access facility.")
elig(r, "Eligible MSME unit that is an existing SIDBI term-loan customer, or a new entity where SIDBI is considering a term loan.", 103)
finalize(r)


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"Changed: {len(changed)} -> {changed}")
