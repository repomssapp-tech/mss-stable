// Ports of Plan/catalog/mss_api_rc1.py's response mapper functions
// (_finance_record, _cluster_map, _tax_map, _privilege_map). Field names and
// shapes mirror the Python originals exactly -- see that file for the
// authoritative field-by-field rationale (e.g. why finance emits both
// minInr/maxInr AND minimumAssistanceInr/maximumAssistanceInr).

type Rec = Record<string, unknown>;

function get(obj: unknown, ...path: string[]): unknown {
  let cur: unknown = obj;
  for (const p of path) {
    if (cur == null || typeof cur !== "object") return undefined;
    cur = (cur as Rec)[p];
  }
  return cur;
}

export function financeRecord(rec: Rec): Rec {
  const identity = (rec["identity"] as Rec) ?? {};
  const content = (rec["content"] as Rec) ?? {};
  const amt = (content["amount"] as Rec) ?? {};
  const provenance = (rec["provenance"] as Rec) ?? {};
  const providers = (content["providers"] as Array<Rec>) ?? [];

  return {
    financeId: identity["id"],
    schemeId: content["schemeId"],
    schemeName: content["schemeName"],
    assistanceClass: "financial_assistance",
    type: content["productType"],
    typeText: content["productFamilyText"],
    isRepayable: content["isRepayable"],
    isGuarantee: content["isGuarantee"],
    amount: {
      currency: amt["currency"],
      percentage: amt["percentage"],
      percentageText: amt["percentageText"],
      minInr: amt["minInr"],
      minText: amt["minText"],
      maxInr: amt["maxInr"],
      maxText: amt["maxText"],
      subsidyPercentage: amt["percentage"],
      subsidyPercentageText: amt["percentageText"],
      minimumAssistanceInr: amt["minInr"],
      minimumAssistanceText: amt["minText"],
      maximumAssistanceInr: amt["maxInr"],
      maximumAssistanceText: amt["maxText"],
    },
    interestRate: content["interestRate"],
    repaymentTenure: content["tenure"],
    collateral: content["collateral"],
    conditions: content["conditions"] ?? [],
    mode: content["applicationRoute"],
    applicationUrl: content["applicationUrl"],
    providers: providers.map((p) => p["entityId"]),
    description: content["description"],
    verificationStatus: get(rec, "verification", "status"),
    provenance: {
      defaultSourceTier: provenance["defaultSourceTier"],
      fieldSources: provenance["fieldSources"] ?? [],
    },
  };
}

// Generated from ACTUAL data state, never a fixed list -- a null field is
// reported as unverified rather than silently omitted.
export function financeGapWarnings(
  items: Array<{ interestRate: unknown; repaymentTenure: unknown; conditions: unknown }>
): Rec[] {
  const out: Rec[] = [];
  const seen = new Set<string>();
  const labels: Record<string, string> = {
    interestRate: "Interest rate",
    repaymentTenure: "Repayment tenure",
    conditions: "Conditions",
  };
  for (const item of items) {
    for (const field of ["interestRate", "repaymentTenure", "conditions"] as const) {
      const val = item[field];
      const empty =
        val == null ||
        (Array.isArray(val) && val.length === 0) ||
        (typeof val === "object" && val !== null && !Array.isArray(val) && Object.values(val).every((v) => v == null));
      if (empty && !seen.has(field)) {
        seen.add(field);
        out.push({ type: "data_gap", field, message: `${labels[field]} is not verified for this record.` });
      }
    }
  }
  return out;
}

export function clusterMap(rec: Rec): Rec {
  const identity = (rec["identity"] as Rec) ?? {};
  const content = (rec["content"] as Rec) ?? {};
  const verification = (rec["verification"] as Rec) ?? {};
  return {
    clusterId: identity["id"],
    clusterName: content["clusterName"],
    sector: content["sector"],
    sectorText: content["sectorText"],
    districts: content["districts"] ?? [],
    eligibleEnterprise: content["supportedBusinessTypes"] ?? [],
    financialSupport: content["financialSupport"],
    nonFinancialSupport: content["nonFinancialSupport"],
    administeringAuthorityId: content["administeringAuthorityId"],
    relatedSchemeIds: content["relatedSchemeIds"] ?? [],
    verificationStatus: verification["status"],
    provenance: get(rec, "provenance", "fieldSources") ?? [],
  };
}

export function taxMap(rec: Rec): Rec {
  const identity = (rec["identity"] as Rec) ?? {};
  const content = (rec["content"] as Rec) ?? {};
  const verification = (rec["verification"] as Rec) ?? {};
  return {
    taxId: identity["id"],
    name: identity["name"],
    provisionKind: content["provisionKind"],
    governmentLevel: content["governmentLevel"],
    appliesToMsme: content["appliesToMsme"],
    jurisdiction: content["jurisdiction"],
    exemptions: content["exemptions"],
    deductions: content["deductions"],
    dueDates: content["dueDates"],
    filingFrequency: content["filingFrequency"],
    evidencedInSchemes: content["evidencedInSchemes"] ?? [],
    verificationStatus: verification["status"],
    provenance: get(rec, "provenance", "fieldSources") ?? [],
  };
}

export function privilegeMap(rec: Rec): Rec {
  const identity = (rec["identity"] as Rec) ?? {};
  const content = (rec["content"] as Rec) ?? {};
  const verification = (rec["verification"] as Rec) ?? {};
  return {
    privilegeId: identity["id"],
    name: identity["name"],
    privilegeType: content["privilegeType"],
    privilegeClass: content["statute"] ? "statutory_right" : "scheme_benefit",
    statute: content["statute"],
    summary: content["summary"],
    tenderBenefits: content["tenderBenefits"],
    delayedPaymentProtection: content["delayedPaymentProtection"],
    billDiscounting: content["billDiscounting"],
    compliance: content["compliance"],
    verificationStatus: verification["status"],
    missingFields: get(rec, "verification", "missingFields") ?? [],
    provenance: get(rec, "provenance", "fieldSources") ?? [],
  };
}

// Port of IntelligenceResolver.match_applicability() (Plan/catalog/
// intelligence_resolver.py). Tri-state rule: scheme facet list EMPTY ->
// unrecorded, neutral, never excludes; profile value IN facet list ->
// positive match; profile value NOT in facet list (list non-empty) -> hard
// exclusion. Deterministic: eligible first, then by matched-facet count
// descending, then schemeId ascending as the total-order tiebreak -- same
// discipline as the search engine's (-score, schemeId) sort.
export const PROFILE_DIMENSIONS = [
  "gender",
  "community",
  "specialCategory",
  "enterpriseType",
  "businessStage",
  "sector",
  "state",
  "district",
] as const;
export type ProfileDimension = (typeof PROFILE_DIMENSIONS)[number];

function facetValues(content: Rec, dim: ProfileDimension): string[] {
  if (dim === "state") {
    const location = (content["location"] as Rec) ?? {};
    return (location["states"] as string[]) ?? [];
  }
  const v = content[dim];
  return Array.isArray(v) ? (v as string[]) : [];
}

export interface ApplicabilityMatch {
  schemeId: string;
  eligible: boolean;
  matchedFacets: string[];
  neutralFacets: string[];
  excludedBy: string | null;
  excludedByAll: string[];
}

export function matchApplicability(
  profile: Partial<Record<ProfileDimension, string>>,
  applicabilityRows: Array<{ record_json: Rec }>
): ApplicabilityMatch[] {
  const results: ApplicabilityMatch[] = [];
  for (const row of applicabilityRows) {
    const content = (row.record_json["content"] as Rec) ?? {};
    const schemeId = content["schemeId"] as string;
    const matched: string[] = [];
    const neutral: string[] = [];
    const excludedAll: string[] = [];

    for (const dim of PROFILE_DIMENSIONS) {
      const profileValue = profile[dim];
      if (profileValue == null) continue;
      const schemeValues = facetValues(content, dim);
      if (schemeValues.length === 0) {
        neutral.push(dim);
      } else if (schemeValues.includes(profileValue)) {
        matched.push(dim);
      } else {
        excludedAll.push(dim);
      }
    }

    results.push({
      schemeId,
      eligible: excludedAll.length === 0,
      matchedFacets: matched,
      neutralFacets: neutral,
      excludedBy: excludedAll[0] ?? null,
      excludedByAll: excludedAll,
    });
  }

  results.sort((a, b) => {
    if (a.eligible !== b.eligible) return a.eligible ? -1 : 1;
    if (a.matchedFacets.length !== b.matchedFacets.length) return b.matchedFacets.length - a.matchedFacets.length;
    return a.schemeId.localeCompare(b.schemeId);
  });
  return results;
}

export function localizationResponse(entityId: string, entityType: string, rec: Rec, lang: "en" | "ta"): Rec {
  const localization = (rec["localization"] as Rec) ?? {};
  const loc = (localization[lang] as Rec) ?? {};
  const available = Boolean(loc["name"]);
  const translations = get(rec, "provenance", "translations") as Rec | undefined;
  const tr = (translations?.[lang] as Rec) ?? {};

  const warnings: Rec[] = [];
  if (lang === "ta" && !available) {
    warnings.push({
      type: "data_gap",
      field: `localization.${lang}`,
      message: `No Tamil localization exists for this ${entityType} record.`,
    });
  }
  if (available && tr["status"] === "machine") {
    warnings.push({
      type: "unofficial_translation",
      field: `localization.${lang}`,
      message: "Machine-generated Tamil, not an official government translation. Not approved for publication.",
    });
  }

  return {
    data: {
      entityId,
      entityType,
      lang,
      available,
      fields: loc,
      fallbackLang: lang === "ta" && !available ? "en" : null,
      provenance: {
        method: tr["method"] ?? null,
        engine: tr["engine"] ?? null,
        status: tr["status"] ?? null,
        isApproved: tr["isApproved"] ?? false,
        reviewRequired: tr["reviewRequired"] ?? null,
        official: tr["status"] === "official",
      },
    },
    warnings,
  };
}
