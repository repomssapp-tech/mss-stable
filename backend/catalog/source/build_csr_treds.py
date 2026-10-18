#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase 2 priorities 4 and 6 — csr_catalog.json and treds_catalog.json.

Both are extracted from their dedicated policy notes, which are tier-3 official
reference documents. Unlike the tax catalog, these sources carry real content:
statute references, thresholds, named mechanisms, named platforms and figures.

Rules:
  P1  every record cites the source document and the section it came from
  P2  figures, thresholds and statute references are copied VERBATIM from the
      note; numerics are added alongside the text, never in place of it
  P3  nothing is added that the note does not state. No rate, no eligibility and
      no recommendation is invented or extended
  P4  where the note is silent (contacts, URLs, fees, current status) the field
      is null and logged

English only. localization.ta null by roadmap decision; schema unchanged.
"""
import json, os, re, hashlib
from collections import OrderedDict, Counter

CAT = "/sessions/practical-charming-hypatia/mnt/Plan/catalog"
AT = "2026-08-04T00:00:00Z"
SV = "1.0.0"
REL = "1.6.0-alpha"
CSR_SRC = "CSR_MSME_Policy_Note.md"
TDS_SRC = "TReDS_Policy_Note.md"

def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
def load(f): return json.load(open(os.path.join(CAT, f), encoding="utf-8"))

def envelope(name, recs):
    return OrderedDict([
        ("metadata", OrderedDict([("catalogName", name), ("schemaVersion", SV),
                                  ("catalogVersion", REL), ("generatedAt", AT),
                                  ("language", "en"), ("recordCount", len(recs)),
                                  ("checksum", "sha256:" + hashlib.sha256(canon(recs).encode()).hexdigest())])),
        ("data", recs)])

def shell(eid, etype, name, content, refs, source, section, miss, localizable,
          acronym=None, status="active"):
    return OrderedDict([
        ("identity", OrderedDict([
            ("id", eid), ("entityType", etype), ("code", acronym), ("legacyCodes", []),
            ("name", name), ("shortName", acronym), ("acronym", acronym),
            ("slug", re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")[:120]),
            ("language", "en"), ("status", status)])),
        ("content", content),
        ("relationships", {"references": refs}),
        ("localization", {l: {k: (v if l == "en" else None) for k, v in localizable.items()}
                          for l in ("en", "ta", "hi")}),
        ("search", {"keywords": {"en": sorted({w for w in re.findall(r"[a-z]{4,}", name.lower())}),
                                 "ta": []},
                    "aliases": {"en": [acronym] if acronym else [], "ta": []},
                    "synonyms": [], "crossReferences": [], "searchRank": None,
                    "boostTerms": []}),
        ("ai", OrderedDict([("summary", None), ("sectionSummaries", {}),
                            ("generationMode", "extractive"), ("confidence", None),
                            ("generatedBy", None), ("generatedAt", None),
                            ("sourceFieldsUsed", []), ("reviewedBy", None),
                            ("reviewedAt", None), ("isApproved", False)])),
        ("verification", OrderedDict([
            ("status", "partially_verified"),
            ("statusText", f"Extracted verbatim from {source}"),
            ("isVerified", False), ("verifiedAgainst", []), ("verifiedBy", None),
            ("verifiedAt", None), ("confidence", "medium"), ("researchStatus", None),
            ("notes", f"Content taken from {source}, section: {section}. The note is a "
                      f"policy reference, not the governing instrument; statute text "
                      f"should be confirmed against the primary source."),
            ("missingFields", miss), ("disputedFields", []), ("reviewDueOn", None)])),
        ("analytics", {"popularity": None, "viewCount": None, "saveCount": None,
                       "actionCount": None, "lastAggregatedAt": None}),
        ("metadata", OrderedDict([("createdAt", AT), ("updatedAt", AT),
                                  ("catalogVersion", REL), ("schemaVersion", SV),
                                  ("recordStatus", "published"), ("revision", 1)])),
        ("provenance", OrderedDict([
            ("defaultSourceTier", 3), ("primarySourceId", None),
            ("contributingSourceIds", []), ("extractionMethod", "assisted"),
            ("extractedAt", AT), ("pipelineVersion", "csr-treds-1.0.0"),
            ("fieldSources", []),
            ("translations", OrderedDict([("ta", OrderedDict([
                ("method", "none"), ("engine", None), ("status", "not_started"),
                ("dictionaryVersion", None), ("generatedAt", None), ("fieldMethods", {}),
                ("fieldsTranslated", 0), ("fieldsContextual", 0), ("fieldsPending", 1),
                ("isApproved", False), ("reviewRequired", True),
                ("note", "Localization deferred to a later phase; schema unchanged.")]))])),
            ("transformationNotes", [
                f"Extracted from {source} — {section} (rule P1)",
                "Figures and statute references copied verbatim (rule P2)",
                "English only; localization.ta intentionally null (roadmap Phase 5)"])])),
    ])

NOSRC = lambda *fs: [{"field": f, "reason": "Not stated in the source policy note"} for f in fs]

# ---------------------------------------------------------------- CSR
CSR_PROVISIONS = [
 dict(kind="statute", name="Section 135, Companies Act 2013", acronym=None,
      section="2. Legal Framework",
      body="Companies meeting prescribed thresholds must spend at least 2% of average net profits on CSR; activities are strictly limited to Schedule VII, executed per CSR Rules 2014 (as amended through 2022/2024 MCA notifications).",
      attrs=dict(spendPercentOfAverageNetProfit=2.0,
                 spendText="at least 2% of average net profits",
                 applicabilityThresholds=[
                   {"criterion": "net worth", "text": "net worth ≥ ₹500 cr", "amountInr": 5000000000},
                   {"criterion": "turnover", "text": "turnover ≥ ₹1,000 cr", "amountInr": 10000000000},
                   {"criterion": "net profit", "text": "net profit ≥ ₹5 cr", "amountInr": 50000000}],
                 thresholdLogic="any one of the three thresholds triggers applicability",
                 rules="CSR Rules 2014, as amended through 2022/2024 MCA notifications")),
 dict(kind="schedule_clause", name="Schedule VII clause (i) — eradicating poverty and livelihood enhancement",
      acronym=None, section="2. Legal Framework",
      body="Relevant Schedule VII clause for MSME-aligned interventions: eradicating poverty and livelihood enhancement.",
      attrs=dict(clause="(i)", msmeAligned=True)),
 dict(kind="schedule_clause", name="Schedule VII clause (ii) — promoting education, employability and vocational skills",
      acronym=None, section="2. Legal Framework",
      body="Relevant Schedule VII clause for MSME-aligned interventions: promoting education, employability, and vocational skills.",
      attrs=dict(clause="(ii)", msmeAligned=True)),
 dict(kind="schedule_clause", name="Schedule VII clause (iv) — environmental sustainability and technology upgradation",
      acronym=None, section="2. Legal Framework",
      body="Relevant Schedule VII clause for MSME-aligned interventions: environmental sustainability and technology upgradation.",
      attrs=dict(clause="(iv)", msmeAligned=True)),
 dict(kind="schedule_clause", name="Schedule VII clause (ix) — contributions to technology incubators and R&D",
      acronym=None, section="2. Legal Framework",
      body="Relevant Schedule VII clause for MSME-aligned interventions: contributions to technology incubators, R&D projects, and incubators funded by Central/State Government or PSUs.",
      attrs=dict(clause="(ix)", msmeAligned=True)),
 dict(kind="prohibition", name="Prohibition on commercial support to for-profit MSMEs", acronym=None,
      section="1. Introduction",
      body="Direct commercial lending, equity investment, or profit-linked support to for-profit MSMEs is not a permissible CSR activity under the Companies Act 2013.",
      attrs=dict(prohibited=["direct commercial lending", "equity investment",
                             "profit-linked support to for-profit MSMEs"])),
 dict(kind="mechanism", name="Grants via registered implementing agencies", acronym=None,
      section="3. Compliant Mechanisms & Structures",
      body="Channel funds through Section 8 companies, registered societies, or public trusts holding CSR-1 registration with the MCA and (where required) a 3-year track record. Suitable for skill, livelihood, and technology grants benefiting MSMEs.",
      attrs=dict(vehicles=["Section 8 company", "registered society", "public trust"],
                 requiresCsr1=True, trackRecordYears=3,
                 suitableFor=["skill grants", "livelihood grants", "technology grants"])),
 dict(kind="mechanism", name="Contributions to approved incubators", acronym=None,
      section="3. Compliant Mechanisms & Structures",
      body="Direct contributions to Atal Incubation Centres, DST-recognised incubators, or Government/PSU-funded technology business incubators supporting MSMEs and start-ups (Schedule VII clause ix).",
      attrs=dict(eligibleRecipients=["Atal Incubation Centres", "DST-recognised incubators",
                                     "Government/PSU-funded technology business incubators"],
                 scheduleClause="(ix)")),
 dict(kind="mechanism", name="Livelihood enhancement and cluster development", acronym=None,
      section="3. Compliant Mechanisms & Structures",
      body="Programs combining skill training, market linkage, and non-commercial working-capital grants for artisan, weaver, and micro-enterprise clusters—anchored in Schedule VII clauses (i) and (ii).",
      attrs=dict(components=["skill training", "market linkage",
                             "non-commercial working-capital grants"],
                 targetClusters=["artisan", "weaver", "micro-enterprise"],
                 scheduleClauses=["(i)", "(ii)"])),
 dict(kind="mechanism", name="Blended finance and venture philanthropy via not-for-profits",
      acronym=None, section="3. Compliant Mechanisms & Structures",
      body="Impact-first or recoverable grants routed through eligible Section 8 vehicles, where any recovered amounts are ploughed back into the same CSR project (consistent with MCA's stance that CSR funds may not generate commercial return for the donor company).",
      attrs=dict(vehicles=["Section 8 company"], recoveryMustBeReinvested=True,
                 donorCommercialReturnAllowed=False)),
 dict(kind="mechanism", name="Partnerships with SIDBI, NSIC or state MSME corporations",
      acronym=None, section="3. Compliant Mechanisms & Structures",
      body="Co-funded capacity-building, technology-upgradation, and financial-literacy projects, leveraging the public-institution route under Schedule VII.",
      attrs=dict(partners=["SIDBI", "NSIC", "state MSME corporations"],
                 projectTypes=["capacity building", "technology upgradation",
                               "financial literacy"])),
 dict(kind="mechanism", name="Company-specific CSR Foundation or Trust", acronym=None,
      section="3. Compliant Mechanisms & Structures",
      body="A dedicated Section 8 company or trust (CSR-1 registered) that designs and delivers Schedule VII-compliant programmes for MSMEs—offering governance control while retaining strict non-commercial character.",
      attrs=dict(vehicles=["Section 8 company", "trust"], requiresCsr1=True)),
 dict(kind="compliance", name="CSR-1 registration of implementing agencies", acronym="CSR-1",
      section="4. Implementation Roadmap & Best Practices",
      body="CSR Committee recommendation and Board approval of the Annual Action Plan; verify CSR-1 status of all implementing agencies.",
      attrs=dict(form="CSR-1", registrar="MCA",
                 approvals=["CSR Committee recommendation", "Board approval of Annual Action Plan"])),
 dict(kind="compliance", name="Third-party impact assessment", acronym=None,
      section="4. Implementation Roadmap & Best Practices",
      body="Mandatory third-party impact assessment for projects ≥ ₹1 crore (per CSR Rules); define MSME-level KPIs—jobs, incomes, formalisation.",
      attrs=dict(thresholdText="projects ≥ ₹1 crore", thresholdInr=10000000,
                 mandatory=True, kpis=["jobs", "incomes", "formalisation"])),
 dict(kind="compliance", name="Form CSR-2 reporting and unspent funds transfer", acronym="CSR-2",
      section="4. Implementation Roadmap & Best Practices",
      body="Disclose in Form CSR-2 with the Registrar and the Board's Report; transfer unspent earmarked funds to the prescribed Unspent CSR Account within 30 days.",
      attrs=dict(form="CSR-2", unspentTransferDays=30,
                 unspentAccount="Unspent CSR Account")),
 dict(kind="compliance", name="Monitoring and audit trail", acronym=None,
      section="4. Implementation Roadmap & Best Practices",
      body="Quarterly review by the CSR Committee; independent audit trail for all disbursements.",
      attrs=dict(reviewFrequency="quarterly", auditTrailRequired=True)),
]

CSR_CONTEXT = dict(annualCsrSpendText="₹30,000–35,000 crore (2025–26)",
                   msmeCreditGapText="₹25–30 lakh crore")

def build_csr():
    recs = []
    for i, p in enumerate(CSR_PROVISIONS, start=1):
        cid = "CSR%06d" % i
        content = OrderedDict([
            ("provisionKind", p["kind"]),
            ("statute", "Companies Act 2013"),
            ("summary", p["body"]),
            ("attributes", p["attrs"]),
            ("appliesToMsme", True),
            ("sourceDocument", CSR_SRC),
            ("sourceSection", p["section"]),
            ("context", CSR_CONTEXT if p["kind"] == "statute" else {}),
            ("applicableSchemes", []), ("relatedInstitutionIds", []),
            ("forms", [p["attrs"].get("form")] if p["attrs"].get("form") else []),
            ("guidance", None), ("faqs", []),
        ])
        miss = NOSRC("content.applicableSchemes", "content.relatedInstitutionIds",
                     "content.guidance", "content.faqs")
        recs.append(shell(cid, "csr_provision", p["name"], content, [], CSR_SRC,
                          p["section"], miss,
                          {"name": p["name"], "summary": p["body"], "guidance": None},
                          acronym=p["acronym"]))
    json.dump(envelope("csr", recs), open(os.path.join(CAT, "csr_catalog.json"), "w",
                                          encoding="utf-8"), ensure_ascii=False, indent=2)
    return recs

# ---------------------------------------------------------------- TReDS
TDS_PLATFORMS = [
 dict(name="Receivables Exchange of India Limited", acronym="RXIL"),
 dict(name="M1xchange", acronym="M1xchange"),
 dict(name="Invoicemart", acronym="Invoicemart"),
]
TDS_ENTRIES = [
 dict(kind="framework", name="Trade Receivables Discounting System", acronym="TReDS",
      section="1. Introduction & Current Challenges",
      body="TReDS is an RBI-regulated electronic platform that enables MSMEs to discount invoices raised on large buyers, securing rapid working-capital liquidity through competitive financier bidding. Operating since 2017 across three platforms—RXIL, M1xchange, and Invoicemart.",
      attrs=dict(regulator="RBI", operatingSince=2017, platformCount=3,
                 platforms=["RXIL", "M1xchange", "Invoicemart"],
                 mechanism="competitive financier bidding on buyer-accepted invoices")),
 dict(kind="adoption_metric", name="TReDS adoption and throughput", acronym=None,
      section="1. Introduction & Current Challenges",
      body="Of 7.3+ crore Udyam-registered MSMEs, fewer than 1% are active TReDS sellers as of 2025–26. Cumulative TReDS throughput crossed ₹6.5 lakh crore, yet annual volumes (~₹2.5 lakh crore) remain a fraction of the estimated ₹10–12 lakh crore receivables-financing potential.",
      attrs=dict(udyamRegisteredText="7.3+ crore", activeSellerShareText="fewer than 1%",
                 cumulativeThroughputText="₹6.5 lakh crore",
                 annualVolumeText="~₹2.5 lakh crore",
                 potentialText="₹10–12 lakh crore", asOf="2025–26")),
 dict(kind="barrier", name="Structural barriers to small-MSME participation", acronym=None,
      section="1. Introduction & Current Challenges",
      body="Credit-rating and KYC requirements, financier risk aversion toward unrated micro units, slow buyer-side invoice acceptance, fragmentation across platforms, weak digital literacy, and high relative transaction costs on small-ticket invoices.",
      attrs=dict(barriers=["credit-rating requirements", "KYC requirements",
                           "financier risk aversion toward unrated micro units",
                           "slow buyer-side invoice acceptance",
                           "fragmentation across platforms", "weak digital literacy",
                           "high relative transaction costs on small-ticket invoices"])),
 dict(kind="barrier", name="Buyer reluctance and mandate under-compliance", acronym=None,
      section="1. Introduction & Current Challenges",
      body="Despite the mandate for companies above ₹250 crore turnover and CPSEs, active large-buyer participation lags, delaying invoice acceptance beyond viable discounting windows.",
      attrs=dict(mandateThresholdText="companies above ₹250 crore turnover",
                 mandateThresholdInr=2500000000, alsoCovered=["CPSEs"])),
 dict(kind="framework", name="RBI interoperability framework", acronym=None,
      section="2. Role of Interoperability",
      body="RBI's interoperability framework allows an invoice uploaded on one TReDS platform to be visible to financiers on all platforms, breaking platform-level lock-in. For small MSMEs this means wider financier access, sharper price discovery, lower discount rates through real competition, and reduced dependency on a single platform's financier base.",
      attrs=dict(regulator="RBI",
                 benefits=["wider financier access", "sharper price discovery",
                           "lower discount rates", "reduced platform dependency"])),
 dict(kind="recommendation", name="Simplify onboarding", acronym=None,
      section="3. Actionable Recommendations",
      body="Auto-onboard via Udyam-GST linkage; waive external credit ratings for micro enterprises with invoices below ₹50 lakh.",
      attrs=dict(ratingWaiverBelowText="₹50 lakh", ratingWaiverBelowInr=5000000,
                 linkage=["Udyam", "GST"])),
 dict(kind="recommendation", name="Operationalise interoperability fully", acronym=None,
      section="3. Actionable Recommendations",
      body="Mandate cross-platform bidding within a defined timeline and publish unified MIS dashboards.", attrs={}),
 dict(kind="recommendation", name="Deep system integration", acronym=None,
      section="3. Actionable Recommendations",
      body="Connect TReDS with Udyam, GSTN, GeM, PFMS, and Account Aggregator stacks for one-click invoice flow and verification.",
      attrs=dict(systems=["Udyam", "GSTN", "GeM", "PFMS", "Account Aggregator"])),
 dict(kind="recommendation", name="Incentivise buyers and financiers", acronym=None,
      section="3. Actionable Recommendations",
      body="Expand the MSMED Act/CPSE mandate to all firms above ₹100 crore turnover; offer priority-sector benefits and refinance support to TReDS financiers focused on micro units.",
      attrs=dict(proposedThresholdText="₹100 crore turnover",
                 proposedThresholdInr=1000000000)),
 dict(kind="recommendation", name="Technology upgrades", acronym=None,
      section="3. Actionable Recommendations",
      body="API-first architecture, vernacular mobile apps, and AI/ML-based risk scoring leveraging GST and bank-statement data.", attrs={}),
 dict(kind="recommendation", name="Awareness, hand-holding and fee relief", acronym=None,
      section="3. Actionable Recommendations",
      body="Cluster-level outreach with MSME-DFOs and DICs; cap or waive platform fees on invoices below ₹10 lakh.",
      attrs=dict(feeReliefBelowText="₹10 lakh", feeReliefBelowInr=1000000,
                 outreachPartners=["MSME-DFOs", "DICs"])),
 dict(kind="recommendation", name="Credit guarantees and co-lending", acronym=None,
      section="3. Actionable Recommendations",
      body="Extend CGTMSE-style cover to TReDS factoring units and enable bank–NBFC–fintech co-lending for first-time micro sellers.",
      attrs=dict(guaranteeModel="CGTMSE-style",
                 coLendingParties=["bank", "NBFC", "fintech"])),
 dict(kind="recommendation", name="Strengthen buyer accountability", acronym=None,
      section="3. Actionable Recommendations",
      body="Penalise delayed invoice acceptance beyond 7 days and link CPSE compliance to Budget 2026 procurement-linked incentives.",
      attrs=dict(acceptanceWindowDays=7)),
]

def build_treds():
    recs, n = [], 0
    for p in TDS_PLATFORMS:
        n += 1
        content = OrderedDict([
            ("entryKind", "platform"), ("regulator", "RBI"),
            ("summary", f"{p['name']} is one of the three RBI-regulated TReDS platforms."),
            ("attributes", {"isTredsPlatform": True}),
            ("sourceDocument", TDS_SRC), ("sourceSection", "1. Introduction & Current Challenges"),
            ("website", None), ("onboardingUrl", None), ("fees", []), ("contacts", []),
            ("guidance", None), ("faqs", []),
        ])
        miss = NOSRC("content.website", "content.onboardingUrl", "content.fees",
                     "content.contacts", "content.guidance", "content.faqs")
        recs.append(shell("TDS%06d" % n, "treds_platform", p["name"], content, [], TDS_SRC,
                          "1. Introduction & Current Challenges", miss,
                          {"name": p["name"], "summary": content["summary"], "guidance": None},
                          acronym=p["acronym"]))
    for e in TDS_ENTRIES:
        n += 1
        content = OrderedDict([
            ("entryKind", e["kind"]), ("regulator", e["attrs"].get("regulator")),
            ("summary", e["body"]), ("attributes", e["attrs"]),
            ("sourceDocument", TDS_SRC), ("sourceSection", e["section"]),
            ("website", None), ("onboardingUrl", None), ("fees", []), ("contacts", []),
            ("guidance", None), ("faqs", []),
        ])
        miss = NOSRC("content.website", "content.fees", "content.contacts",
                     "content.guidance", "content.faqs")
        recs.append(shell("TDS%06d" % n, "treds_platform", e["name"], content, [], TDS_SRC,
                          e["section"], miss,
                          {"name": e["name"], "summary": e["body"], "guidance": None},
                          acronym=e["acronym"]))
    json.dump(envelope("treds", recs), open(os.path.join(CAT, "treds_catalog.json"), "w",
                                            encoding="utf-8"), ensure_ascii=False, indent=2)
    return recs

if __name__ == "__main__":
    c, t = build_csr(), build_treds()
    stats = OrderedDict([
        ("generatedAt", AT),
        ("csr", OrderedDict([("catalog", "csr_catalog.json"), ("records", len(c)),
                             ("byKind", dict(Counter(r["content"]["provisionKind"] for r in c))),
                             ("sourceDocument", CSR_SRC),
                             ("statuteThresholds", 3), ("scheduleClauses", 4)])),
        ("treds", OrderedDict([("catalog", "treds_catalog.json"), ("records", len(t)),
                               ("byKind", dict(Counter(r["content"]["entryKind"] for r in t))),
                               ("sourceDocument", TDS_SRC),
                               ("platforms", 3)])),
        ("dataSufficiency", "GOOD — both notes carry statute references, thresholds, named "
                            "mechanisms and figures. Contacts, URLs and fees are absent."),
        ("tamilPopulated", 0), ("localizationStatus", "deferred to roadmap Phase 5"),
    ])
    json.dump(stats, open(os.path.join(CAT, "csr_treds_statistics.json"), "w",
                          encoding="utf-8"), indent=2, ensure_ascii=False)
    print(f"csr_catalog.json    {len(c)} records  {dict(Counter(r['content']['provisionKind'] for r in c))}")
    print(f"treds_catalog.json  {len(t)} records  {dict(Counter(r['content']['entryKind'] for r in t))}")
