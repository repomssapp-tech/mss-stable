#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MSS Intelligence Benchmark V1 -- dataset builder.

Goal: test whether MSS surfaces the MOST RELEVANT scheme, not the scheme with
the widest coverage.

GROUNDING RULE (the thing that makes this benchmark trustworthy):
expected-answer sets are DERIVED FROM THE CATALOG by matching rules, never
hand-typed from memory. If a query's domain has no matching scheme, the
builder marks it a DATA-GAP query instead of inventing an expectation. That
distinction is the whole point -- otherwise a data gap looks like a ranking
failure and the benchmark misleads whoever reads it.

REJECTED APPROACH, recorded so nobody re-introduces it:
an earlier draft scored "specificity" by counting structured eligibility
facets with applies==True. Measured on real data that ranks PMEGP at 4 --
ABOVE genuinely narrow schemes like the Agarbatti project at 0 -- because
facet count measures how well-DOCUMENTED a scheme is, not how NARROW it is.
Using it would have rewarded the exact broad schemes this benchmark exists to
catch. Topical matching is used instead.
"""
import json, os, re
from collections import OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))

# The four schemes the brief names as "must not dominate": widest coverage,
# highest name recognition, applicable to almost any MSME query.
BROAD_SCHEMES = {
    "SCH000130": "PMEGP",
    "SCH000128": "Pradhan Mantri Mudra Yojana (PMMY)",
    "SCH000038": "CGTMSE",
    "SCH000169": "Startup India Initiative",
}


def load_schemes():
    d = json.load(open(os.path.join(CAT, "scheme_catalog.json"), encoding="utf-8"))["data"]
    out = {}
    for r in d:
        c = r["content"]
        blob = " ".join(filter(None, [
            r["identity"]["name"],
            c["classification"].get("sectorsText"),
            c["overview"].get("summary"),
            c["targetBeneficiaries"].get("description"),
            c["benefits"].get("summary"),
        ])).lower()
        out[r["identity"]["id"]] = {
            "id": r["identity"]["id"],
            "name": r["identity"]["name"],
            "status": r["identity"]["status"],
            "blob": blob,
            "benefitTypes": c["benefits"].get("benefitTypes", []),
            "states": c["classification"]["government"].get("states", []),
            "level": c["classification"]["government"].get("level"),
        }
    return out


def match(schemes, *terms, require_benefit=None, state=None):
    """Schemes whose text contains ANY term. This is the grounding rule --
    expectations come from here, never from recollection."""
    hits = []
    for sid, s in schemes.items():
        if not any(t.lower() in s["blob"] for t in terms):
            continue
        if require_benefit and not any(b in s["benefitTypes"] for b in require_benefit):
            continue
        if state and state not in s["states"]:
            continue
        hits.append(sid)
    return sorted(hits)


# ---------------------------------------------------------------------------
# Query specifications. `terms` drives the catalog-grounded expected set;
# `accept` widens it to a defensible parent category.
# ---------------------------------------------------------------------------

def build_specs():
    S = []

    def add(level, q, terms, accept=None, note="", trap=False):
        S.append(dict(level=level, query=q, terms=terms, accept=accept or [],
                      note=note, trap=trap))

    # ---- LEVEL 1 — 40 direct queries ------------------------------------
    L1 = [
        ("I need a loan", ["loan"], []),
        ("capital subsidy", ["capital subsidy"], ["subsidy"]),
        ("credit guarantee", ["guarantee"], []),
        ("interest subsidy", ["interest subvention", "interest subsidy"], ["subsidy"]),
        ("margin money assistance", ["margin money"], ["subsidy"]),
        ("training programme", ["training", "skill"], []),
        ("marketing assistance", ["marketing"], []),
        ("export incentive", ["export"], []),
        ("technology upgradation", ["technology"], []),
        ("machinery subsidy", ["machinery", "plant and machinery"], ["capital subsidy"]),
        ("working capital", ["working capital"], ["loan"]),
        ("term loan", ["term loan"], ["loan"]),
        ("collateral free loan", ["collateral"], ["guarantee", "loan"]),
        ("seed funding", ["seed"], ["grant"]),
        ("grant for innovation", ["innovation"], ["grant"]),
        ("incubation support", ["incubat"], []),
        ("patent filing support", ["patent", "intellectual property"], []),
        ("quality certification", ["certification", "quality"], []),
        ("barcode support", ["bar code", "barcode"], []),
        ("testing laboratory", ["testing"], []),
        ("cluster development", ["cluster"], []),
        ("infrastructure support", ["infrastructure"], []),
        ("raw material assistance", ["raw material"], []),
        ("power tariff subsidy", ["power tariff", "electricity"], ["subsidy"]),
        ("generator subsidy", ["generator"], ["subsidy"]),
        ("stamp duty exemption", ["stamp duty"], []),
        ("udyam registration", ["udyam", "registration"], []),
        ("delayed payment help", ["delayed payment", "samadhaan"], []),
        ("bill discounting", ["discount", "receivable"], []),
        ("women entrepreneur scheme", ["women", "mahila"], []),
        ("scheme for artisans", ["artisan"], []),
        ("khadi scheme", ["khadi"], []),
        ("coir industry support", ["coir"], []),
        ("food processing scheme", ["food"], []),
        ("solar energy subsidy", ["solar", "energy"], ["subsidy"]),
        ("effluent treatment support", ["effluent", "environment"], []),
        ("tool room facility", ["tool room"], []),
        ("design support", ["design"], []),
        ("packaging support", ["packag"], []),
        ("startup recognition", ["startup"], []),
    ]
    for q, t, a in L1:
        add(1, q, t, a, "direct single-intent query")

    # ---- LEVEL 2 — 40 profile-based queries -----------------------------
    L2 = [
        ("scheme for women entrepreneurs", ["women", "mahila"], []),
        ("loan for women in business", ["women", "mahila"], ["loan"]),
        ("women micro enterprise support", ["women", "mahila"], []),
        ("subsidy for SC entrepreneurs", ["sc/st", "scheduled caste", "ambedkar"], []),
        ("ST entrepreneur assistance", ["sc/st", "scheduled tribe"], []),
        ("scheme for differently abled entrepreneur", ["differently abled", "disab"], []),
        ("transgender entrepreneur support", ["transgender"], []),
        ("minority community business loan", ["minority"], ["loan"]),
        ("ex-servicemen business scheme", ["ex-servicemen", "ex servicemen"], []),
        ("unemployed youth self employment", ["unemployed", "youth"], []),
        ("young entrepreneur under 30", ["youth", "young"], []),
        ("first generation entrepreneur", ["first generation", "new entrepreneur"], []),
        ("scheme for micro enterprise", ["micro"], []),
        ("small enterprise assistance", ["small"], []),
        ("medium enterprise support", ["medium"], []),
        ("new business setup help", ["new enterprise", "new micro", "setting up"], []),
        ("existing business expansion", ["expansion", "scaling up"], []),
        ("Tamil Nadu entrepreneur scheme", ["tamil nadu"], []),
        ("scheme in Tamil Nadu for women", ["tamil nadu"], ["women"]),
        ("Chennai based enterprise support", ["tamil nadu"], []),
        ("rural entrepreneur scheme", ["rural", "village"], []),
        ("urban street vendor loan", ["street vendor", "svanidhi"], ["loan"]),
        ("self help group support", ["self help", "shg"], []),
        ("widow entrepreneur assistance", ["widow"], []),
        ("single woman business support", ["women", "widow"], []),
        ("BPL family enterprise scheme", ["bpl", "below poverty"], []),
        ("weaker section assistance", ["weaker section", "economically weaker"], []),
        ("scheme for traditional craftspeople", ["artisan", "craft", "vishwakarma"], []),
        ("scheme for farmers allied business", ["agri", "farmer"], []),
        ("women SHG loan Tamil Nadu", ["women", "self help"], ["loan"]),
        ("SC ST women entrepreneur", ["sc/st", "ambedkar"], ["women"]),
        ("micro enterprise in backward district", ["backward"], []),
        ("scheme for graduates starting business", ["graduate", "educated"], []),
        ("technical qualification entrepreneur", ["technical", "qualification"], []),
        ("women led startup fund", ["women"], ["startup"]),
        ("mahila udyami loan", ["mahila", "women"], ["loan"]),
        ("scheme for orphan girls marriage assistance", ["orphan", "marriage"], []),
        ("assistance for girl child", ["girl child", "girl"], []),
        ("maternity benefit scheme", ["matru", "maternity"], []),
        ("creche facility support", ["creche", "palna"], []),
    ]
    for q, t, a in L2:
        add(2, q, t, a, "profile-conditioned query")

    # ---- LEVEL 3 — 40 sector-specific queries ---------------------------
    # NOTE: textile/leather/auto deliberately included -- they are the
    # documented data gaps and MUST be measured, not quietly excluded.
    L3 = [
        ("textile manufacturing support", ["textile"], ["manufactur"]),
        ("garment unit subsidy", ["garment", "textile"], ["manufactur"]),
        ("handloom weaver assistance", ["handloom", "weav"], []),
        ("powerloom modernisation", ["powerloom", "loom"], []),
        ("spinning mill support", ["spinning", "textile"], []),
        ("leather industry scheme", ["leather"], ["manufactur"]),
        ("footwear manufacturing support", ["footwear", "leather"], ["manufactur"]),
        ("tannery upgradation", ["tannery", "leather"], []),
        ("auto component manufacturer", ["auto"], ["manufactur"]),
        ("automobile industry support", ["automobile", "auto"], ["manufactur"]),
        ("printing press subsidy", ["printing"], []),
        ("packaging industry support", ["packag"], []),
        ("food processing unit subsidy", ["food"], []),
        ("cold storage support", ["cold storage", "storage"], []),
        ("bakery unit loan", ["food", "bakery"], ["loan"]),
        ("dairy processing support", ["dairy", "milk"], []),
        ("spices export assistance", ["spice"], ["export"]),
        ("agro processing scheme", ["agro", "agri", "food"], []),
        ("export promotion scheme", ["export"], []),
        ("export market development", ["export", "market"], []),
        ("international trade fair participation", ["international", "fair", "exhibition"], []),
        ("IEC and DGFT support", ["export", "dgft"], []),
        ("duty exemption for exporters", ["duty", "export"], []),
        ("service sector enterprise scheme", ["service"], []),
        ("IT services startup", ["software", "it ", "technology"], ["startup"]),
        ("hospitality business support", ["hospitality", "tourism"], []),
        ("healthcare enterprise scheme", ["health", "medical"], []),
        ("biotechnology startup funding", ["biotech", "bio"], ["startup"]),
        ("pharma manufacturing support", ["pharma", "drug"], []),
        ("electronics manufacturing scheme", ["electronic"], ["manufactur"]),
        ("engineering unit support", ["engineering"], []),
        ("chemical industry scheme", ["chemical"], []),
        ("coir cluster support", ["coir"], ["cluster"]),
        ("khadi village industry", ["khadi", "village industr"], []),
        ("pottery cluster assistance", ["pottery"], ["cluster"]),
        ("beekeeping project support", ["beekeep", "honey"], []),
        ("agarbatti making project", ["agarbatti"], []),
        ("handicraft artisan support", ["handicraft", "artisan", "craft"], []),
        ("common facility centre for cluster", ["cluster", "common facility"], []),
        ("industrial estate infrastructure", ["industrial estate", "infrastructure"], []),
    ]
    for q, t, a in L3:
        add(3, q, t, a, "sector-specific query")

    # ---- LEVEL 4 — 40 multi-condition queries ---------------------------
    L4 = [
        ("women textile entrepreneur in Tamil Nadu needing machinery loan", ["textile"], ["women", "machinery"]),
        ("SC entrepreneur setting up food processing unit in Tamil Nadu", ["food"], ["sc/st", "ambedkar"]),
        ("new micro manufacturing unit in Tamil Nadu needing capital subsidy", ["capital subsidy"], ["micro", "manufactur"]),
        ("existing small enterprise expanding with technology upgrade", ["technology"], ["expansion", "scaling"]),
        ("women led startup needing seed funding", ["women"], ["startup", "seed"]),
        ("rural artisan needing toolkit and training", ["artisan", "vishwakarma"], ["training"]),
        ("exporter needing working capital in Tamil Nadu", ["export"], ["working capital", "loan"]),
        ("micro enterprise in backward block seeking capital subsidy", ["capital subsidy"], ["backward"]),
        ("first generation entrepreneur needing project finance above 10 lakh", ["new entrepreneur", "first generation"], ["loan"]),
        ("unemployed graduate starting service business in Tamil Nadu", ["unemployed", "youth"], ["service"]),
        ("women SHG in rural Tamil Nadu needing revolving fund", ["self help", "women"], []),
        ("coir unit needing modernisation support", ["coir"], []),
        ("khadi institution seeking margin money", ["khadi"], ["margin money"]),
        ("startup seeking patent cost reimbursement", ["patent", "intellectual property"], ["startup"]),
        ("MSME needing ZED certification support", ["zed", "certification", "quality"], []),
        ("cluster of micro units needing common facility centre", ["cluster", "common facility"], []),
        ("food processing exporter needing testing equipment", ["food", "testing"], ["export"]),
        ("manufacturer needing effluent treatment plant support", ["effluent", "environment"], []),
        ("enterprise needing solar power subsidy in Tamil Nadu", ["solar", "energy"], ["subsidy"]),
        ("SC ST entrepreneur needing collateral free credit", ["sc/st", "ambedkar"], ["guarantee", "collateral"]),
        ("women entrepreneur needing interest subvention on term loan", ["women"], ["interest subvention", "loan"]),
        ("micro unit in Tamil Nadu needing generator subsidy", ["generator"], ["subsidy"]),
        ("new enterprise needing stamp duty concession", ["stamp duty"], []),
        ("small manufacturer seeking marketing and trade fair support", ["marketing", "fair"], []),
        ("biotech startup needing proof of concept grant", ["biotech", "bio"], ["grant", "startup"]),
        ("street vendor needing micro credit", ["street vendor", "svanidhi"], ["loan"]),
        ("differently abled person starting micro enterprise", ["differently abled", "disab"], ["micro"]),
        ("transgender entrepreneur needing business loan", ["transgender"], ["loan"]),
        ("minority woman starting tailoring unit", ["minority"], ["women"]),
        ("ex-servicemen starting transport business", ["ex-servicemen", "ex servicemen"], []),
        ("young entrepreneur needing incubation and mentorship", ["incubat", "mentor"], []),
        ("existing MSME facing delayed payment from buyer", ["delayed payment", "samadhaan"], []),
        ("MSME needing invoice discounting facility", ["discount", "receivable"], []),
        ("enterprise seeking barcode and quality certification", ["bar code", "barcode", "certification"], []),
        ("manufacturer needing raw material on credit", ["raw material"], []),
        ("women artisan needing marketing platform", ["artisan"], ["women", "marketing"]),
        ("agro exporter needing cold chain support", ["cold", "agro", "food"], ["export"]),
        ("service enterprise in Tamil Nadu needing capital subsidy", ["capital subsidy"], ["service"]),
        ("scaling up micro unit to small enterprise", ["scaling up", "expansion"], []),
        ("technology upgradation for existing manufacturing unit", ["technology"], ["manufactur"]),
    ]
    for q, t, a in L4:
        add(4, q, t, a, "multi-condition query")

    # ---- LEVEL 5 — 40 unclear natural queries ---------------------------
    L5 = [
        ("i need money for my business", ["loan"], ["subsidy"]),
        ("how do i get government help", [], []),
        ("want to start something small", ["new enterprise", "micro"], []),
        ("need funds urgently", ["loan"], []),
        ("my shop needs upgrade", ["machinery", "technology"], []),
        ("looking for subsidy", ["subsidy"], []),
        ("can i get a loan without security", ["collateral", "guarantee"], []),
        ("what schemes am i eligible for", [], []),
        ("help for small business owner", ["micro", "small"], []),
        ("government scheme for my factory", ["manufactur"], []),
        ("i make handmade products", ["artisan", "handicraft", "khadi"], []),
        ("want to sell my products abroad", ["export"], []),
        ("need machine for my unit", ["machinery"], []),
        ("business not doing well need support", [], []),
        ("i am a woman and want to start a business", ["women", "mahila"], []),
        ("my caste certificate is SC can i get benefit", ["sc/st", "ambedkar"], []),
        ("just finished college want to be entrepreneur", ["youth", "unemployed"], []),
        ("need training to start business", ["training", "skill"], []),
        ("how to register my business", ["udyam", "registration"], []),
        ("customer not paying me", ["delayed payment", "samadhaan"], []),
        ("want to make food items and sell", ["food"], []),
        ("i weave cloth at home", ["handloom", "weav", "textile"], []),
        ("i want to buy a generator", ["generator"], []),
        ("electricity bill too high any help", ["power tariff", "electricity"], []),
        ("need money to buy raw material", ["raw material"], ["loan"]),
        ("want to expand my existing business", ["expansion", "scaling up"], []),
        ("looking for partner or investor", ["equity", "venture", "fund"], []),
        ("my product needs certification", ["certification", "quality"], []),
        ("interested in solar for my unit", ["solar", "energy"], []),
        ("need help with exports paperwork", ["export"], []),
        ("i am differently abled entrepreneur", ["differently abled", "disab"], []),
        ("scheme for people like me from village", ["rural", "village"], []),
        ("something for young people starting out", ["youth", "young"], []),
        ("i have an innovative idea need funding", ["innovation"], ["grant", "startup"]),
        ("want to modernise old machinery", ["technology", "machinery"], []),
        ("is there any scheme for tailoring unit", ["textile", "garment"], ["micro"]),
        ("need working capital for festival season", ["working capital"], ["loan"]),
        ("help me grow my small manufacturing", ["manufactur"], []),
        ("what can government do for msme", [], []),
        ("need financial assistance", ["loan", "subsidy"], []),
    ]
    for q, t, a in L5:
        add(5, q, t, a, "vague natural-language query")

    # ---- TRAP QUERIES — the core bias test -------------------------------
    TRAPS = [
        ("I am a textile manufacturer looking for machinery upgrade",
         ["textile"], ["machinery", "technology", "cluster"],
         "Brief's own example. Broad credit schemes must NOT dominate a "
         "sector+asset-specific need."),
        ("leather footwear unit needs modernisation funding",
         ["leather"], ["machinery", "technology"],
         "Sector-specific; generic credit must not dominate."),
        ("auto component maker wants technology upgrade",
         ["auto"], ["technology", "machinery"],
         "Sector-specific; generic credit must not dominate."),
        ("coir processing unit needs equipment support",
         ["coir"], ["machinery"],
         "Coir schemes exist -- a narrow scheme MUST outrank PMEGP/Mudra."),
        ("khadi institution needs margin money assistance",
         ["khadi"], ["margin money"],
         "Khadi schemes exist -- narrow must beat broad."),
        ("agarbatti making unit needs support",
         ["agarbatti"], ["village industr"],
         "A single highly specific scheme exists; it must rank first."),
        ("beekeeping project funding",
         ["beekeep", "honey"], ["village industr"],
         "Narrow scheme exists; must beat generic credit."),
        ("pottery cluster needs common facility",
         ["pottery"], ["cluster"],
         "Narrow + cluster; must beat generic credit."),
        ("tool room services for precision engineering",
         ["tool room"], ["technology"],
         "Narrow infrastructure scheme must beat generic credit."),
        ("street vendor needs small working capital loan",
         ["street vendor", "svanidhi"], ["loan"],
         "PM SVANidhi is purpose-built; Mudra/PMEGP must not dominate."),
    ]
    for q, t, a, note in TRAPS:
        add("TRAP", q, t, a, note, trap=True)

    return S


def main():
    schemes = load_schemes()
    specs = build_specs()

    rows, gaps = [], 0
    for i, sp in enumerate(specs, start=1):
        lvl = sp["level"]
        qid = f"{'T' if sp['trap'] else 'L'}{lvl if not sp['trap'] else ''}-{i:03d}"
        expected = match(schemes, *sp["terms"]) if sp["terms"] else []
        acceptable = match(schemes, *sp["accept"]) if sp["accept"] else []
        acceptable = sorted(set(acceptable) - set(expected))

        # A query whose specific domain has NO scheme is a DATA GAP, not a
        # ranking failure. Recording this distinction is the single most
        # important thing this builder does.
        data_gap = bool(sp["terms"]) and not expected

        if data_gap:
            gaps += 1
        rows.append(OrderedDict([
            ("queryId", qid),
            ("level", lvl),
            ("query", sp["query"]),
            ("expectedBest", expected),
            ("acceptable", acceptable),
            ("shouldNotDominate", sorted(BROAD_SCHEMES)),
            ("isTrap", sp["trap"]),
            ("isDataGap", data_gap),
            ("domainTerms", sp["terms"]),
            ("reason", sp["note"]),
        ]))

    out = OrderedDict([
        ("benchmark", "MSS Intelligence Benchmark V1"),
        ("generatedFrom", "scheme_catalog.json"),
        ("groundingRule", "expected sets derived by catalog text matching; "
                          "never hand-authored from memory"),
        ("broadSchemes", BROAD_SCHEMES),
        ("queryCount", len(rows)),
        ("dataGapCount", gaps),
        ("queries", rows),
    ])
    path = os.path.join(CAT, "benchmark_v1.json")
    json.dump(out, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)

    from collections import Counter
    lv = Counter(r["level"] for r in rows)
    print(f"benchmark_v1.json written: {len(rows)} queries")
    print("by level:", dict(sorted(lv.items(), key=lambda x: str(x[0]))))
    print(f"data-gap queries (no scheme exists for the domain): {gaps}")
    print(f"queries with a grounded expected set: {sum(1 for r in rows if r['expectedBest'])}")


if __name__ == "__main__":
    main()
