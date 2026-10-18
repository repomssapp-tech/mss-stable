#!/usr/bin/env python3
"""Phase 1 — common_catalog.json. CMN entities extending MSS_Base_Entity_Model_v1.0."""
import json, re, os, hashlib, csv
from collections import OrderedDict, Counter

CAT = "/sessions/practical-charming-hypatia/mnt/Plan/catalog"
BASE = os.path.join(CAT, "stage_a_frozen", "scheme_catalog.json")
AT = "2026-08-04T00:00:00Z"
SV = CV = "1.0.0"

_n = [0]
def ent(term_type, code, label, description=None, aliases=None, parent=None, extra=None):
    _n[0] += 1
    eid = "CMN%06d" % _n[0]
    return OrderedDict([
        ("identity", OrderedDict([
            ("id", eid), ("entityType", "common_term"), ("code", code),
            ("legacyCodes", []), ("name", label), ("shortName", None), ("acronym", None),
            ("slug", re.sub(r"[^a-z0-9]+", "-", f"{term_type}-{code}".lower()).strip("-")),
            ("language", "en"), ("status", "active")])),
        ("content", OrderedDict([
            ("termType", term_type), ("code", code), ("label", label),
            ("description", description), ("aliases", sorted(set(aliases or []))),
            ("parentCode", parent), ("attributes", extra or {})])),
        ("relationships", {"references": []}),
        ("localization", {l: {"label": label if l == "en" else None,
                              "description": description if l == "en" else None}
                          for l in ("en", "ta", "hi")}),
        ("search", {"keywords": sorted({w for w in re.findall(r"[a-z]{3,}", label.lower())}),
                    "synonyms": sorted(set(aliases or [])), "aliases": [code],
                    "crossReferences": [], "searchRank": None, "boostTerms": []}),
        ("ai", OrderedDict([("summary", None), ("sectionSummaries", {}),
                            ("generationMode", "extractive"), ("confidence", None),
                            ("generatedBy", None), ("generatedAt", None),
                            ("sourceFieldsUsed", []), ("reviewedBy", None),
                            ("reviewedAt", None), ("isApproved", False)])),
        ("verification", OrderedDict([
            ("status", "verified"), ("statusText", "Controlled vocabulary term"),
            ("isVerified", True), ("verifiedAgainst", []), ("verifiedBy", None),
            ("verifiedAt", None), ("confidence", "high"), ("researchStatus", None),
            ("notes", None), ("missingFields", []), ("disputedFields", []),
            ("reviewDueOn", None)])),
        ("analytics", {"popularity": None, "viewCount": None, "saveCount": None,
                       "actionCount": None, "lastAggregatedAt": None}),
        ("metadata", OrderedDict([("createdAt", AT), ("updatedAt", AT),
                                  ("catalogVersion", CV), ("schemaVersion", SV),
                                  ("recordStatus", "published"), ("revision", 1)])),
        ("provenance", OrderedDict([
            ("defaultSourceTier", 2), ("primarySourceId", None),
            ("contributingSourceIds", []), ("extractionMethod", "assisted"),
            ("extractedAt", AT), ("pipelineVersion", "common-1.0.0"),
            ("fieldSources", []),
            ("transformationNotes", ["Vocabulary term; aliases harvested from source free text"])])),
    ])

# ---------------------------------------------------------------- vocabularies
STATES = [("IN-AN","Andaman and Nicobar Islands","ut"),("IN-AP","Andhra Pradesh","state"),
("IN-AR","Arunachal Pradesh","state"),("IN-AS","Assam","state"),("IN-BR","Bihar","state"),
("IN-CH","Chandigarh","ut"),("IN-CT","Chhattisgarh","state"),("IN-DH","Dadra and Nagar Haveli and Daman and Diu","ut"),
("IN-DL","Delhi","ut"),("IN-GA","Goa","state"),("IN-GJ","Gujarat","state"),("IN-HR","Haryana","state"),
("IN-HP","Himachal Pradesh","state"),("IN-JK","Jammu and Kashmir","ut"),("IN-JH","Jharkhand","state"),
("IN-KA","Karnataka","state"),("IN-KL","Kerala","state"),("IN-LA","Ladakh","ut"),
("IN-LD","Lakshadweep","ut"),("IN-MP","Madhya Pradesh","state"),("IN-MH","Maharashtra","state"),
("IN-MN","Manipur","state"),("IN-ML","Meghalaya","state"),("IN-MZ","Mizoram","state"),
("IN-NL","Nagaland","state"),("IN-OR","Odisha","state"),("IN-PY","Puducherry","ut"),
("IN-PB","Punjab","state"),("IN-RJ","Rajasthan","state"),("IN-SK","Sikkim","state"),
("IN-TN","Tamil Nadu","state"),("IN-TG","Telangana","state"),("IN-TR","Tripura","state"),
("IN-UP","Uttar Pradesh","state"),("IN-UT","Uttarakhand","state"),("IN-WB","West Bengal","state")]

TN_DISTRICTS = ["Ariyalur","Chengalpattu","Chennai","Coimbatore","Cuddalore","Dharmapuri","Dindigul",
"Erode","Kallakurichi","Kancheepuram","Kanniyakumari","Karur","Krishnagiri","Madurai","Mayiladuthurai",
"Nagapattinam","Namakkal","Nilgiris","Perambalur","Pudukkottai","Ramanathapuram","Ranipet","Salem",
"Sivaganga","Tenkasi","Thanjavur","Theni","Thoothukudi","Tiruchirappalli","Tirunelveli","Tirupathur",
"Tiruppur","Tiruvallur","Tiruvannamalai","Tiruvarur","Vellore","Viluppuram","Virudhunagar"]

ENTERPRISE = [("micro","Micro Enterprise"),("small","Small Enterprise"),("medium","Medium Enterprise"),
("startup","Startup"),("shg","Self-Help Group"),("cooperative","Cooperative Society"),
("proprietorship","Proprietorship"),("partnership","Partnership Firm"),("llp","Limited Liability Partnership"),
("company","Company"),("trust","Trust"),("society","Society"),("section8","Section 8 Company")]

STAGES = [("idea","Idea Stage"),("new","New / Greenfield"),("existing","Existing / Operating"),
("expansion","Expansion"),("diversification","Diversification"),("modernisation","Modernisation"),
("revival","Revival / Rehabilitation")]

BENEFICIARY = [("women","Women"),("sc","Scheduled Caste"),("st","Scheduled Tribe"),
("obc","Other Backward Classes"),("minority","Minority"),("differently_abled","Differently Abled"),
("transgender","Transgender"),("ex_servicemen","Ex-Servicemen"),("youth","Youth"),
("artisan","Artisan"),("farmer","Farmer"),("student","Student"),("first_generation","First-Generation Entrepreneur"),
("rural","Rural"),("urban","Urban"),("bpl","Below Poverty Line"),("orphan","Orphan"),("widow","Widow")]

BENEFIT = [("capital_subsidy","Capital Subsidy"),("interest_subvention","Interest Subvention"),
("margin_money","Margin Money"),("grant","Grant"),("loan","Loan"),("tax_benefit","Tax Benefit"),
("reimbursement","Reimbursement"),("equity_support","Equity Support"),("guarantee","Credit Guarantee"),
("insurance","Insurance"),("training_support","Training Support"),("market_support","Market Support"),
("technology_support","Technology Support")]

LOAN = [("term_loan","Term Loan"),("working_capital","Working Capital Loan"),
("equipment_loan","Equipment Loan"),("collateral_free","Collateral-Free Loan"),
("bill_discounting","Bill Discounting"),("composite_loan","Composite Loan"),
("soft_loan","Soft Loan"),("refinance","Refinance")]

TAX = [("gst","Goods and Services Tax"),("income_tax","Income Tax"),("corporate_tax","Corporate Tax"),
("composition_scheme","Composition Scheme"),("qrmp","QRMP"),("customs_duty","Customs Duty"),
("stamp_duty","Stamp Duty"),("electricity_tax","Electricity Tax")]

AUTHORITY_TYPE = [("ministry","Ministry"),("department","Department"),("directorate","Directorate"),
("commissionerate","Commissionerate"),("board","Statutory Board"),("corporation","Government Corporation"),
("district_industries_centre","District Industries Centre"),("mission","Mission"),
("council","Council"),("facilitation_council","Facilitation Council"),("regulator","Regulator")]

ORGANIZATION_TYPE = [("central_government","Central Government"),("state_government","State Government"),
("psu","Public Sector Undertaking"),("development_finance_institution","Development Finance Institution"),
("bank","Bank"),("nbfc","NBFC"),("incubator","Incubator"),("training_institute","Training Institute"),
("industry_association","Industry Association"),("statutory_body","Statutory Body")]

REGISTRATION = [("udyam","Udyam Registration"),("em_part2","Entrepreneur Memorandum Part II"),
("dpiit","DPIIT Startup Recognition"),("iec","Importer-Exporter Code"),("gst_reg","GST Registration"),
("sprs","NSIC Single Point Registration"),("pan","PAN"),("tan","TAN"),
("shop_establishment","Shops and Establishments Registration"),("factory_licence","Factory Licence"),
("fssai","FSSAI Licence"),("cin","Corporate Identity Number")]

COMPLIANCE = [("gst_return","GST Return Filing"),("income_tax_return","Income Tax Return"),
("annual_return","Annual Return"),("udyam_update","Udyam Annual Update"),
("pollution_consent","Pollution Control Consent"),("labour_return","Labour Return"),
("delayed_payment","Delayed Payment Reporting (MSME Samadhaan)")]

# scheme_type canonical + substring rules used to harvest aliases from source text
SCHEME_RULES = [
 ("capital_subsidy","Capital Subsidy",["capital subsidy"]),
 ("interest_subvention","Interest Subvention",["interest subsidy","interest subvention"]),
 ("credit_linked_subsidy","Credit-Linked Subsidy",["credit-linked","credit linked"]),
 ("credit_guarantee","Credit Guarantee",["credit guarantee","guarantee"]),
 ("loan","Loan / Term Finance",["loan","term finance","soft loan","emergency finance","refinance",
                               "finance","credit","lending"]),
 ("grant","Grant / Grant-in-Aid",["grant"]),
 ("equity_funding","Equity / Venture Funding",["equity","fund of funds","venture","seed"]),
 ("training","Training / Skill Development",["training","skill","entrepreneurship development","capacity"]),
 ("market_promotion","Market / Export Promotion",["market promotion","trade fair","export","marketing",
                                                  "exhibition","tender"]),
 ("technology_support","Technology / Innovation Support",["technology","innovation","design","r&d",
                                                          "research","incubation","commercialization"]),
 ("infrastructure","Infrastructure Support",["infrastructure","cluster","industrial estate"]),
 ("social_assistance","Social / Welfare Assistance",["marriage assistance","educational assistance",
     "girl child","child protection","welfare","livelihood","social change","behavioural",
     "small-savings","protection","safety","rehabilitation","home","women"]),
 ("reimbursement","Reimbursement",["reimbursement"]),
 ("startup_support","Startup Support",["startup","start-up"]),
 ("event_support","Event / Exhibition Support",["event","fair","buyer-seller","delegation"]),
 ("public_procurement","Public Procurement Access",["procurement","gem","purchase preference"]),
 ("energy_support","Energy / Utility Support",["energy","power tariff","electricity","generator",
                                               "tariff","utility"]),
 ("operating_incentive","Operating / Location Incentive",["relocation","shifting","payroll",
                                                          "stamp duty","incentive"]),
 ("certification_support","Certification / Quality Support",["certification","quality","zed","lean",
                                                             "standard","testing","ipr","patent"]),
 ("facilitation","Facilitation / Handholding",["facilitation","handholding","umbrella","mission",
                                               "programme","policy benefit","authorisation","exemption",
                                               "support","assistance","scheme","service","subsidy",
                                               "benefit","platform","award","fund"]),
]

def harvest_scheme_aliases():
    """Attach real source strings to canonical scheme types (data-derived aliases)."""
    p = os.path.join(CAT, "unmapped_values.csv")
    vals = []
    if os.path.exists(p):
        vals = [r[1] for r in list(csv.reader(open(p, encoding="utf-8")))[1:]
                if r[0] == "classification.schemeType"]
    out = {c: [] for c, _, _ in SCHEME_RULES}
    unmatched = []
    for v in vals:
        low = v.lower()
        hit = next((c for c, _, keys in SCHEME_RULES if any(k in low for k in keys)), None)
        (out[hit].append(v) if hit else unmatched.append(v))
    return out, unmatched

GLOSSARY = [
 ("msme","MSME","Micro, Small and Medium Enterprise, as classified under the MSMED Act."),
 ("udyam","Udyam","The current online registration for MSMEs in India."),
 ("dbt","DBT","Direct Benefit Transfer — payment made directly to a beneficiary's bank account."),
 ("back_ended_subsidy","Back-Ended Subsidy","Subsidy credited after the loan is disbursed, reducing outstanding principal."),
 ("margin_money","Margin Money","Promoter's own contribution to project cost, or a subsidy substituting for it."),
 ("go","Government Order (G.O.)","A formal executive instruction issued by a State government."),
 ("spv","SPV","Special Purpose Vehicle formed to implement a cluster or common-facility project."),
 ("dic","DIC","District Industries Centre — district-level MSME implementing office."),
 ("mlI","Member Lending Institution","A lender enrolled under a guarantee scheme."),
 ("thrust_sector","Thrust Sector","A sector notified for enhanced incentives under State policy."),
]

def build():
    recs = []
    for code, label, kind in STATES:
        recs.append(ent("state", code, label, extra={"subdivision": kind, "country": "IN"}))
    for d in TN_DISTRICTS:
        recs.append(ent("district", "IN-TN-" + re.sub(r"[^A-Za-z]", "", d)[:12].upper(), d,
                        parent="IN-TN", extra={"state": "IN-TN"}))
    for c, l in ENTERPRISE: recs.append(ent("enterprise_type", c, l))
    for c, l in STAGES: recs.append(ent("business_stage", c, l))
    for c, l in BENEFICIARY: recs.append(ent("beneficiary_type", c, l))
    for c, l in BENEFIT: recs.append(ent("benefit_type", c, l))
    for c, l in LOAN: recs.append(ent("loan_type", c, l))
    for c, l in TAX: recs.append(ent("tax_type", c, l))
    for c, l in AUTHORITY_TYPE: recs.append(ent("authority_type", c, l))
    for c, l in ORGANIZATION_TYPE: recs.append(ent("organization_type", c, l))
    for c, l in REGISTRATION: recs.append(ent("registration_type", c, l))
    for c, l in COMPLIANCE: recs.append(ent("compliance_type", c, l))

    alias_map, unmatched = harvest_scheme_aliases()
    for c, l, _ in SCHEME_RULES:
        recs.append(ent("scheme_type", c, l, aliases=alias_map[c]))

    # document_type — harvested from real document names in the frozen catalog
    base = json.load(open(BASE, encoding="utf-8"))["data"]
    dnames = Counter()
    for r in base:
        for d in r["content"]["requiredDocuments"]:
            if d["name"]: dnames[d["name"].strip()] += 1
    DOC_RULES = [
      ("registration_proof","Enterprise Registration Proof",["udyam","entrepreneur memorandum","registration certificate"]),
      ("identity_proof","Identity Proof",["aadhaar","pan card","identity","photograph","voter"]),
      ("address_proof","Address Proof",["address","ration"]),
      ("constitution_document","Constitution Document",["partnership deed","memorandum","articles","incorporation","llp"]),
      ("land_property_document","Land / Property Document",["land","lease","rent","property","building","premises"]),
      ("financial_statement","Financial Statement",["balance sheet","financial","audited","income","profit","itr"]),
      ("bank_document","Bank Document",["bank","loan sanction","cheque","passbook","disbursement"]),
      ("project_report","Project Report",["project report","dpr","feasibility"]),
      ("invoice_proof","Invoice / Purchase Proof",["invoice","bill","purchase","receipt","quotation"]),
      ("certificate","Certificate",["certificate","licence","license","consent","noc","clearance"]),
      ("category_proof","Category / Community Proof",["community","caste","disability","income certificate","nativity"]),
      ("application_form","Application Form",["application"]),
      ("other","Other Supporting Document",[]),
    ]
    dmap = {c: [] for c, _, _ in DOC_RULES}
    for n in dnames:
        low = n.lower()
        hit = next((c for c, _, k in DOC_RULES if any(x in low for x in k)), "other")
        dmap[hit].append(n)
    for c, l, _ in DOC_RULES:
        recs.append(ent("document_type", c, l, aliases=dmap[c][:60],
                        extra={"observedVariants": len(dmap[c])}))

    for c, l, d in GLOSSARY: recs.append(ent("glossary_term", c, l, description=d))

    # search_keyword — global keyword frequency across the frozen catalog
    kw = Counter()
    for r in base: kw.update(r["search"]["keywords"])
    for w, n in kw.most_common(120):
        recs.append(ent("search_keyword", w, w, extra={"documentFrequency": n}))

    def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    cat = OrderedDict([
        ("metadata", OrderedDict([("catalogName", "common"), ("schemaVersion", SV),
                                  ("catalogVersion", CV), ("generatedAt", AT), ("language", "en"),
                                  ("recordCount", len(recs)),
                                  ("checksum", "sha256:" + hashlib.sha256(canon(recs).encode()).hexdigest())])),
        ("data", recs)])
    json.dump(cat, open(os.path.join(CAT, "common_catalog.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)
    byt = Counter(r["content"]["termType"] for r in recs)
    print(f"common_catalog.json  terms={len(recs)}")
    for k, v in byt.most_common(): print(f"   {k:22} {v}")
    print(f"\nschemeType source strings mapped: "
          f"{sum(len(v) for v in alias_map.values())} / "
          f"{sum(len(v) for v in alias_map.values()) + len(unmatched)}")
    if unmatched: print("   unmatched:", unmatched[:8])
    print(f"documentType variants clustered: {sum(len(v) for v in dmap.values())} "
          f"distinct names into {len(DOC_RULES)} types")

if __name__ == "__main__":
    build()
