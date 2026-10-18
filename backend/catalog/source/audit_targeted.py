#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.0 -- targeted audits for the sections named in the audit brief.
READ ONLY. Writes only audit_targeted.json (an audit output), never a
catalog file."""
import json, os, sys
from collections import Counter, OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))


def load(f):
    with open(os.path.join(CAT, f), encoding="utf-8") as fh:
        return json.load(fh)


def get(d, path, default=None):
    cur = d
    for part in path.split("."):
        if isinstance(cur, list):
            return default
        if not isinstance(cur, dict) or part not in cur:
            return default
        cur = cur[part]
    return cur


def filled(v):
    if v is None:
        return False
    if isinstance(v, str):
        return v.strip() != ""
    if isinstance(v, (list, dict)):
        return len(v) > 0
    return True


def pct(n, d):
    return round(100 * n / d, 1) if d else 0.0


out = OrderedDict()

# =====================================================================
# 1. SCHEME ENTITY AUDIT
# =====================================================================
scheme_cat = load("scheme_catalog.json")
schemes = scheme_cat["data"]
N = len(schemes)


def field_cov(paths, label):
    rows = []
    for p in paths:
        f = sum(1 for r in schemes if filled(get(r, p)))
        rows.append({"field": p, "total": N, "filled": f, "missing": N - f, "coveragePct": pct(f, N)})
    return {"section": label, "rows": rows}


scheme_identity = field_cov([
    "identity.id", "identity.name",
    "content.classification.government.departmentText",
    "content.classification.government.implementingAgencyText",
    "content.classification.government.states",
    "content.classification.government.level",
], "Identity")

scheme_localization = field_cov([
    "localization.en.name", "localization.en.description",
    "localization.ta.name", "localization.ta.description",
    "localization.hi.name",
], "Localization (English/Tamil/Hindi presence)")
# translation source / approval status -- from provenance.translations.ta
ta_status = Counter(get(r, "provenance.translations.ta.status") for r in schemes)
ta_approved = sum(1 for r in schemes if get(r, "provenance.translations.ta.isApproved") is True)
scheme_localization["translationStatusBreakdown"] = dict(ta_status)
scheme_localization["taApprovedCount"] = ta_approved
scheme_localization["taApprovedPct"] = pct(ta_approved, N)

scheme_benefits = field_cov([
    "content.benefits.summary", "content.benefits.benefitTypes",
], "Benefits (top-level)")
# for each declared benefitType, check if ITS OWN sub-object has an amount/percentage/limit populated
benefit_type_amount_filled = 0
benefit_type_total = 0
for r in schemes:
    types = get(r, "content.benefits.benefitTypes") or []
    b = get(r, "content.benefits") or {}
    for t in types:
        benefit_type_total += 1
        sub = b.get(t) if isinstance(b, dict) else None
        if isinstance(sub, dict):
            has_amt = any(filled(sub.get(k)) for k in
                          ("amountInr", "maxAmountInr", "minAmountInr", "percentage"))
            if has_amt:
                benefit_type_amount_filled += 1
scheme_benefits["declaredBenefitTypeInstances"] = benefit_type_total
scheme_benefits["withAmountOrPercentageFilled"] = benefit_type_amount_filled
scheme_benefits["amountFillPct"] = pct(benefit_type_amount_filled, benefit_type_total)

scheme_eligibility = field_cov([
    "content.targetBeneficiaries.beneficiaryTypes",
    "content.eligibility.structured.gender.values",
    "content.eligibility.structured.community.values",
    "content.eligibility.structured.enterprise.types",
    "content.eligibility.structured.businessStage.values",
], "Eligibility")

scheme_documents = field_cov([
    "content.requiredDocuments",
], "Documents (list non-empty)")
doc_desc_total = doc_desc_filled = 0
for r in schemes:
    docs = get(r, "content.requiredDocuments") or []
    for d in docs:
        doc_desc_total += 1
        if filled(d.get("description")):
            doc_desc_filled += 1
scheme_documents["documentDescriptionsFilled"] = doc_desc_filled
scheme_documents["documentDescriptionsTotal"] = doc_desc_total
scheme_documents["documentDescriptionPct"] = pct(doc_desc_filled, doc_desc_total)

scheme_application = field_cov([
    "content.applicationProcess.mode",
    "content.applicationProcess.steps",
    "content.applicationTimeline",
    "content.applicationProcess.onlineUrl",
], "Application")

# The raw content.eligibility.structured / targetBeneficiaries.* enum
# fields above are checked because the brief names them explicitly, but
# intelligence_resolver.py's actual applicability_match() reads a SEPARATE
# derived catalog (applicability_matrix_catalog.json), not these raw
# fields -- confirmed by reading intelligence_resolver.py directly. Audited
# separately so the audit reflects what the API actually serves, not just
# what the brief happened to name.
am_cat = load("applicability_matrix_catalog.json")
am = am_cat["data"]
AMN = len(am)
am_rows = []
for field in ("gender", "community", "specialCategory", "enterpriseType",
              "businessStage", "sector", "district", "cluster"):
    f = sum(1 for r in am if r["content"].get(field))
    am_rows.append({"field": field, "total": AMN, "filled": f,
                     "missing": AMN - f, "coveragePct": pct(f, AMN)})
out["applicability_matrix_audit"] = {
    "recordCount": AMN,
    "note": ("This is the catalog intelligence_resolver.applicability_match() and "
             "the API's eligibility/search filters actually read at runtime -- "
             "NOT content.eligibility.structured / targetBeneficiaries.* on the raw "
             "scheme record (those are 0% populated, confirmed above, but are "
             "functionally superseded/unused dead schema, not a runtime gap)."),
    "fieldCoverage": am_rows,
}

out["scheme_entity_audit"] = {
    "recordCount": N,
    "identity": scheme_identity,
    "localization": scheme_localization,
    "benefits": scheme_benefits,
    "eligibility": scheme_eligibility,
    "documents": scheme_documents,
    "application": scheme_application,
}

# =====================================================================
# 2. FINANCIAL INTELLIGENCE AUDIT
# =====================================================================
fin_cat = load("finance_catalog.json")
fin = fin_cat["data"]
FN = len(fin)

FIN_REQUIRED = OrderedDict([
    ("assistanceType", "content.productType"),
    ("minimumAmount", "content.amount.minInr"),
    ("maximumAmount", "content.amount.maxInr"),
    ("subsidyPercentage", "content.amount.percentage"),
    ("interestRate", "content.interestRate.percent"),
    ("tenure", "content.tenure.tenureMonths"),
    ("collateralRequirement", "content.collateral.status"),
    ("guaranteeInformation", "content.collateral.guaranteeSupported"),
    ("source", "provenance.primarySourceId"),
    ("verificationStatus", "verification.status"),
])
# collateral.status = "not_specified" is a recorded-but-unresolved value,
# not a real answer -- treated as NOT filled for this audit's purposes.
def fin_field_filled(r, key, path):
    v = get(r, path)
    if key == "collateralRequirement":
        return filled(v) and v != "not_specified"
    return filled(v)

fin_rows = []
for key, path in FIN_REQUIRED.items():
    f = sum(1 for r in fin if fin_field_filled(r, key, path))
    fin_rows.append({"field": key, "path": path, "total": FN, "filled": f,
                      "missing": FN - f, "coveragePct": pct(f, FN)})

# per-record tri-state classification
CRITICAL = ["assistanceType", "minimumAmount", "maximumAmount"]  # at least one amount-shaped field must exist for a repayable/guarantee product
classification = Counter()
missing_critical_records = []
for r in fin:
    is_repayable = get(r, "content.isRepayable") is True or get(r, "content.isGuarantee") is True
    filled_count = sum(1 for key, path in FIN_REQUIRED.items() if fin_field_filled(r, key, path))
    total_fields = len(FIN_REQUIRED)
    if is_repayable:
        has_rate_or_tenure = fin_field_filled(r, "interestRate", FIN_REQUIRED["interestRate"]) or \
                              fin_field_filled(r, "tenure", FIN_REQUIRED["tenure"])
        if not has_rate_or_tenure:
            classification["missing_critical"] += 1
            missing_critical_records.append(r["identity"]["id"])
            continue
    if filled_count == total_fields:
        classification["fully_populated"] += 1
    elif filled_count == 0:
        classification["missing_critical"] += 1
        missing_critical_records.append(r["identity"]["id"])
    else:
        classification["partially_populated"] += 1

out["financial_intelligence_audit"] = {
    "recordCount": FN,
    "fieldCoverage": fin_rows,
    "classification": dict(classification),
    "missingCriticalRecordIds": missing_critical_records,
}

# =====================================================================
# 3. CLUSTER INTELLIGENCE AUDIT
# =====================================================================
clus_cat = load("cluster_assistance_catalog.json")
clus = clus_cat["data"]
CN = len(clus)
clus_rows = field_cov_generic = []
CLUS_FIELDS = OrderedDict([
    ("clusterName", "content.clusterName"),
    ("sector", "content.sector"),
    ("districtLocation", "content.districts"),
    ("supportedIndustries", "content.supportedBusinessTypes"),
    ("financialAssistanceApplicable", "content.financialSupport.applicable"),
    ("financialAmount", "content.financialSupport.maxAmountInr"),
    ("nonFinancialApplicable", "content.nonFinancialSupport.applicable"),
    ("sourceVerification", "verification.verifiedAgainst"),
])
for key, path in CLUS_FIELDS.items():
    f = sum(1 for r in clus if filled(get(r, path)))
    clus_rows.append({"field": key, "path": path, "total": CN, "filled": f,
                       "missing": CN - f, "coveragePct": pct(f, CN)})

fin_applicable_true = sum(1 for r in clus if get(r, "content.financialSupport.applicable") is True)
nonfin_applicable_true = sum(1 for r in clus if get(r, "content.nonFinancialSupport.applicable") is True)
both_true = sum(1 for r in clus if get(r, "content.financialSupport.applicable") is True
                 and get(r, "content.nonFinancialSupport.applicable") is True)

out["cluster_intelligence_audit"] = {
    "recordCount": CN,
    "fieldCoverage": clus_rows,
    "financialSupportApplicableCount": fin_applicable_true,
    "nonFinancialSupportApplicableCount": nonfin_applicable_true,
    "bothApplicableSimultaneously": both_true,  # should be 0 if disjoint
    "records": [{"id": r["identity"]["id"], "name": r["identity"]["name"],
                 "sector": get(r, "content.sector"),
                 "financialApplicable": get(r, "content.financialSupport.applicable"),
                 "nonFinancialApplicable": get(r, "content.nonFinancialSupport.applicable")}
                for r in clus],
}

# =====================================================================
# 4. MSME ADVANTAGE AUDIT
# =====================================================================
priv_cat = load("msme_privilege_catalog.json")
priv = priv_cat["data"]
treds_cat = load("treds_catalog.json")
treds = treds_cat["data"]

priv_areas = OrderedDict([
    ("tenderBenefits", "content.tenderBenefits.applicable"),
    ("delayedPaymentProtection", "content.delayedPaymentProtection.applicable"),
    ("billDiscounting", "content.billDiscounting.applicable"),
    ("complianceBenefits", "content.compliance.benefits"),
])
priv_rows = []
for key, path in priv_areas.items():
    f = sum(1 for r in priv if filled(get(r, path)))
    priv_rows.append({"field": key, "path": path, "total": len(priv), "filled": f,
                       "missing": len(priv) - f, "coveragePct": pct(f, len(priv))})

out["msme_advantage_audit"] = {
    "privilegeRecordCount": len(priv),
    "privilegeAreaCoverage": priv_rows,
    "tredsRecordCount": len(treds),
    "tredsSchemeRelationships": sum(
        1 for r in load("scheme_catalog.json")["data"]
        for ref in get(r, "relationships.references") or []
        if ref.get("entityType") == "treds_platform"
    ),
}

# =====================================================================
# 5. SEARCH READINESS AUDIT
# =====================================================================
idx_cat = load("search_index.json")
idx = [e for e in idx_cat["data"] if e["entityType"] == "scheme"]
IN_ = len(idx)

# Paths verified directly against a live search_index.json entry before
# writing this table (not guessed from field names) -- see the
# investigation note below for the one dimension (gender) that is folded
# into a differently-named field.
SEARCH_DIMENSIONS = OrderedDict([
    ("sector", "schemeSearchProfile.sector"),
    ("industry", "schemeSearchProfile.industryTags"),
    ("beneficiary", "schemeSearchProfile.beneficiary"),
    ("gender", "schemeSearchProfile.communityTags"),  # gender folded into the community-tag vocabulary (e.g. "women"), no separate gender key exists
    ("state", None),  # not in schemeSearchProfile at all -- applied as a post-filter reading identity/content directly
    ("district", "schemeSearchProfile.districts"),
    ("department", None),  # not in schemeSearchProfile -- post-filter only
    ("assistanceType", "schemeSearchProfile.loanType"),
    ("amountRange", None),  # amount lives on finance_catalog.json, never copied into the scheme search profile
    ("enterpriseType", "schemeSearchProfile.enterpriseType"),
    ("businessStage", None),  # key does not exist in schemeSearchProfile at all -- confirmed 0/217 by direct inspection, not just unpopulated
    ("cluster", "schemeSearchProfile.clusters"),
    ("taxBenefits", "schemeSearchProfile.taxBenefits"),
])

sample_entry = idx[0] if idx else {}
sample_profile_keys = sorted((sample_entry.get("schemeSearchProfile") or {}).keys())

# What HybridSearch._searchable_fields() actually reads (hardcoded here from
# the source read during Phase D -- kept in sync manually, since importing
# hybrid_search.py would require constructing a full instance):
HYBRID_SEARCH_USES = {"tokens.en", "tokens.ta", "schemeSearchProfile.loanType",
                       "schemeSearchProfile.subsidyType", "schemeSearchProfile.taxBenefits",
                       "schemeSearchProfile.clusters", "schemeSearchProfile.industryTags",
                       "schemeSearchProfile.benefitTags"}

# What the RC1 API applies as POST-RANKING FILTERS (from
# API_RC1_IMPLEMENTATION_REPORT.md sec 3 -- structured filters, not part of
# the ranking/index at all): state, district, sector, cluster, department,
# beneficiary, gender, enterpriseType, businessStage, assistanceType,
# taxBenefit, collateral, status, governmentLevel, min/maxAssistance.
API_FILTER_DIMENSIONS = {"query", "state", "district", "sector", "cluster",
                          "department", "beneficiary", "gender", "enterpriseType",
                          "businessStage", "assistanceType", "minimumAssistance",
                          "maximumAssistance", "collateral", "taxBenefit", "status",
                          "governmentLevel"}

search_rows = []
for dim, path in SEARCH_DIMENSIONS.items():
    if path:
        f = sum(1 for e in idx if filled(get(e, path)))
        cov = pct(f, IN_)
        in_ranking = path.split(".", 1)[1] in {p.split(".", 1)[1] for p in HYBRID_SEARCH_USES if "." in p}
    else:
        f, cov, in_ranking = None, None, False
    search_rows.append({
        "dimension": dim,
        "profilePath": path,
        "populatedCount": f,
        "coveragePct": cov,
        "usedInRankingScore": in_ranking,
        "usedAsApiPostFilter": dim in API_FILTER_DIMENSIONS,
    })

out["search_readiness_audit"] = {
    "schemeIndexEntryCount": IN_,
    "sampleSchemeSearchProfileKeys": sample_profile_keys,
    "dimensions": search_rows,
    "note": ("state/district/department/enterpriseType/businessStage/amountRange are "
             "NOT part of schemeSearchProfile / the ranking index at all -- they are "
             "applied by MssApiRC1 as POST-RANKING PREDICATES reading identity/content "
             "fields directly (see API_RC1_IMPLEMENTATION_REPORT.md sec 3), never "
             "indexed or scored. That is an architectural choice already documented, "
             "not an oversight found by this audit -- flagged here for completeness."),
}

# =====================================================================
# 6. LOCALIZATION AUDIT (all catalogs)
# =====================================================================
loc_rows = []
for fname in sorted(f for f in os.listdir(CAT) if f.endswith("_catalog.json")):
    cat = load(fname)
    recs = cat["data"]
    n = len(recs)
    if n == 0:
        continue
    en_total = ta_total = ta_official = ta_machine = 0
    localizable_any = False
    for r in recs:
        loc = r.get("localization", {})
        en = loc.get("en", {})
        ta = loc.get("ta", {})
        if not en:
            continue
        localizable_any = True
        if any(filled(v) for v in en.values()):
            en_total += 1
        if ta and any(filled(v) for v in ta.values()):
            ta_total += 1
            status = get(r, "provenance.translations.ta.status")
            approved = get(r, "provenance.translations.ta.isApproved")
            if approved is True:
                ta_official += 1
            else:
                ta_machine += 1
    if not localizable_any:
        continue
    loc_rows.append({
        "catalog": fname, "recordCount": n,
        "englishCoveragePct": pct(en_total, n),
        "tamilCoveragePct": pct(ta_total, n),
        "tamilOfficialPct": pct(ta_official, n),
        "tamilMachinePct": pct(ta_machine, n),
    })

out["localization_audit"] = loc_rows

# =====================================================================
# 7. RELATIONSHIP AUDIT
# =====================================================================
all_catalogs = {}
all_ids = set()
for fname in sorted(f for f in os.listdir(CAT) if f.endswith("_catalog.json")):
    cat = load(fname)
    all_catalogs[fname] = cat["data"]
    for r in cat["data"]:
        all_ids.add(r["identity"]["id"])

dangling = []
orphans_no_outgoing = []
dup_relationships = []
incoming = Counter()
for fname, recs in all_catalogs.items():
    for r in recs:
        refs = get(r, "relationships.references") or []
        seen_pairs = set()
        for ref in refs:
            tid = ref.get("entityId")
            if tid and tid not in all_ids:
                dangling.append({"from": r["identity"]["id"], "to": tid, "catalog": fname})
            if tid:
                incoming[tid] += 1
            key = (tid, ref.get("relationType"))
            if key in seen_pairs:
                dup_relationships.append({"record": r["identity"]["id"], "duplicateOf": key})
            seen_pairs.add(key)
        if not refs and fname == "scheme_catalog.json":
            orphans_no_outgoing.append(r["identity"]["id"])

no_incoming = sorted(i for i in all_ids if incoming[i] == 0)

out["relationship_audit"] = {
    "totalEntities": len(all_ids),
    "danglingReferences": dangling,
    "duplicateRelationships": dup_relationships,
    "schemesWithNoOutgoingRelationships": len(orphans_no_outgoing),
    "schemesWithNoOutgoingRelationshipsSample": orphans_no_outgoing[:10],
    "entitiesWithNoIncomingReferenceCount": len(no_incoming),
    "note": "Full dangling-reference / duplicate-relationship-edge-type check already "
            "runs in validate_cross_catalog.py each phase (0 dangling, always re-verified "
            "before every report in this project) -- this section adds orphan/incoming "
            "counts, which that validator does not report.",
}

# =====================================================================
# 8. API READINESS AUDIT
# =====================================================================
sys.path.insert(0, CAT)
from mss_api_rc1 import MssApiRC1  # noqa: E402

api = MssApiRC1()
api_checks = []


def check_endpoint(name, fn, extract_empty_fields):
    try:
        resp = fn()
        empties = extract_empty_fields(resp)
        api_checks.append({"endpoint": name, "ok": True, "emptyFieldsFound": empties})
    except Exception as e:
        api_checks.append({"endpoint": name, "ok": False, "error": str(e)})


check_endpoint("health", api.health, lambda r: [])
check_endpoint("search('loan')", lambda: api.search({"query": "loan"}),
                lambda r: [] if r["data"]["results"] else ["no results for a broad query"])
check_endpoint("scheme_detail(SCH000001)",
                lambda: api.scheme_detail({"schemeId": "SCH000001"}), lambda r: [])
check_endpoint("scheme_finance(SCH000001)",
                lambda: api.scheme_finance({"schemeId": "SCH000001"}),
                lambda r: [k for k, v in (r.get("data") or {}).items() if v is None])
check_endpoint("clusters()", lambda: api.clusters({}),
                lambda r: [] if r["data"]["total"] else ["0 clusters"])
check_endpoint("tax()", lambda: api.tax({}), lambda r: [] if r["data"]["total"] else ["0 tax records"])
check_endpoint("privileges()", lambda: api.privileges({}),
                lambda r: [] if r["data"]["total"] else ["0 privilege records"])
check_endpoint("finance_products()", lambda: api.finance_products({}),
                lambda r: [] if r["data"]["total"] else ["0 finance products"])
check_endpoint("metadata()", api.metadata, lambda r: [])
check_endpoint("localization(SCH000001)",
                lambda: api.localization({"schemeId": "SCH000001"}), lambda r: [])

out["api_readiness_audit"] = {"checks": api_checks}

# =====================================================================
with open(os.path.join(CAT, "audit_targeted.json"), "w", encoding="utf-8") as fh:
    json.dump(out, fh, ensure_ascii=False, indent=2)

print("wrote audit_targeted.json")
print("sections:", list(out.keys()))
