#!/usr/bin/env python3
"""
Intelligence Resolver — Phase 1, Step 2.

Combines existing catalogs into one read-only, per-scheme view. Creates
NO new source data: every field returned is a lookup through an edge that
already exists in `relationships.references[]`, or (for `applicability`) a
1:1 keyed lookup into `applicability_matrix_catalog.json`.

Architecture (per PHASE1_INTELLIGENCE_ARCHITECTURE.md Part 2):

    Scheme -> Intelligence Resolver -> {
        finance, tax, treds, csr, authority, institution, export,
        applicability, cluster, privileges, enablement, knowledge
    }

All 11 catalogs referenced above now exist on disk. What's still empty is
the EDGE data, not the files: cluster_assistance, msme_privilege,
business_enablement and knowledge_item all have zero
`relationships.references[]` pointing at them from any scheme today (see
REMAINING_DATA_COVERAGE_GAPS.md item 5b) — same as treds/csr, which were
never linked either. The resolver resolves them correctly to `[]`, never
guessed at and never inferred from name similarity, per the same C1 rule
`build_crossrefs.py` already enforces catalog-wide. If a future catalog
regeneration adds edges to any of these, resolve() picks them up with no
code change needed here.
"""
import json, os
from collections import defaultdict

CAT = os.path.dirname(os.path.abspath(__file__))

# catalogName -> filename. Files that don't exist yet are listed so the
# resolver can report them as "not present" rather than KeyError.
CATALOG_FILES = {
    "scheme": "scheme_catalog.json",
    "finance_product": "finance_catalog.json",
    "tax_provision": "tax_catalog.json",
    "treds_platform": "treds_catalog.json",
    "csr_provision": "csr_catalog.json",
    "authority": "authority_catalog.json",
    "institution": "institution_catalog.json",
    "export_benefit": "export_catalog.json",
    "cluster_assistance": "cluster_assistance_catalog.json",
    "msme_privilege": "msme_privilege_catalog.json",
    "business_enablement": "business_enablement_catalog.json",
    "knowledge_item": "knowledge_catalog.json",
    "applicability_matrix": "applicability_matrix_catalog.json",
}


def load(fname):
    path = os.path.join(CAT, fname)
    if not os.path.exists(path):
        return None
    return json.load(open(path, encoding="utf-8"))


class IntelligenceResolver:
    """Read-only. Holds no state that isn't derivable from the catalog files
    on disk at construction time — call `IntelligenceResolver()` again after
    any catalog regeneration rather than mutating an existing instance."""

    def __init__(self):
        self.catalogs = {}      # entityType -> parsed catalog dict, or None if absent
        self.by_id = {}         # entityId -> (record, entityType)
        self.missing_files = []

        for etype, fname in CATALOG_FILES.items():
            data = load(fname)
            self.catalogs[etype] = data
            if data is None:
                self.missing_files.append(fname)
                continue
            for rec in data["data"]:
                self.by_id[rec["identity"]["id"]] = (rec, etype)

        # applicability_matrix is keyed 1:1 by schemeId, not a graph edge —
        # index it separately.
        self.applicability_by_scheme = {}
        am = self.catalogs.get("applicability_matrix")
        if am:
            for rec in am["data"]:
                sid = rec["content"]["schemeId"]
                self.applicability_by_scheme[sid] = rec

    def scheme(self, scheme_id):
        rec, etype = self.by_id.get(scheme_id, (None, None))
        if etype != "scheme":
            raise KeyError(f"{scheme_id!r} is not a known scheme id")
        return rec

    def resolve(self, scheme_id):
        """Return the merged intelligence view for one scheme. Every list
        field is a lookup through an existing edge; nothing is computed from
        text similarity."""
        rec = self.scheme(scheme_id)
        refs = rec["relationships"]["references"]

        grouped = defaultdict(list)
        missing_refs = []
        for e in refs:
            target = self.by_id.get(e["entityId"])
            if target is None:
                missing_refs.append(e["entityId"])
                continue
            target_rec, target_type = target
            grouped[target_type].append({
                "id": e["entityId"], "relationType": e["relationType"],
                "record": target_rec,
            })

        return {
            "schemeId": scheme_id,
            "finance": grouped.get("finance_product", []),
            "tax": grouped.get("tax_provision", []),
            "treds": grouped.get("treds_platform", []),   # currently always [] — see audit
            "csr": grouped.get("csr_provision", []),        # currently always [] — by design
            "authority": grouped.get("authority", []),
            "institution": grouped.get("institution", []),
            "export": grouped.get("export_benefit", []),
            "cluster": grouped.get("cluster_assistance", []),   # [] -- no scheme declares this edge yet
            "privileges": grouped.get("msme_privilege", []),    # [] -- no scheme declares this edge yet
            "enablement": grouped.get("business_enablement", []),  # [] -- no scheme declares this edge yet
            "knowledge": grouped.get("knowledge_item", []),        # [] -- no scheme declares this edge yet
            "applicability": self.applicability_by_scheme.get(scheme_id),
            "missingReferences": missing_refs,  # edges pointing at an id that resolves to nothing
        }

    # ---- applicability matching -----------------------------------------

    # Profile keys this matches against, and the applicability_matrix.content
    # field (or nested path) each one checks. district/state are list-valued
    # in the matrix; sector/gender/community/specialCategory/enterpriseType/
    # businessStage are all list-valued too -- same shape throughout.
    _APPLICABILITY_FIELDS = [
        ("gender", lambda c: c.get("gender", [])),
        ("community", lambda c: c.get("community", [])),
        ("specialCategory", lambda c: c.get("specialCategory", [])),
        ("enterpriseType", lambda c: c.get("enterpriseType", [])),
        ("businessStage", lambda c: c.get("businessStage", [])),
        ("sector", lambda c: c.get("sector", [])),
        ("state", lambda c: c.get("location", {}).get("states", [])),
        ("district", lambda c: c.get("district", [])),
    ]

    def match_applicability(self, profile):
        """Structured profile matching over applicability_matrix_catalog.json.

        `profile` is a flat dict using the same keys as `_APPLICABILITY_FIELDS`
        (e.g. {"gender": "female", "community": "sc", "enterpriseType": "micro",
        "state": "IN-TN"}). Any key omitted or None is simply not checked.

        Tri-state rule, same as hybrid_search.py's eligibility scoring and
        build_applicability_matrix.py's own derivation rule:
          - scheme facet list EMPTY       -> unrecorded, neutral, never excludes
          - profile value IN facet list   -> positive match
          - profile value NOT in facet list (list non-empty) -> hard exclusion
            (the scheme asserts a specific, different set of eligible values)

        No LLM, no similarity scoring, no randomness -- pure lookup and set
        membership, so identical (profile, catalog state) always produces an
        identical, identically-ordered result.

        Returns a list of dicts, one per scheme with an applicability_matrix
        record, sorted deterministically: eligible first, then by number of
        positively-matched facets (descending), then by schemeId (ascending)
        as the total-order tiebreak -- same sort discipline as
        hybrid_search.py's `(-score, schemeId)`.
        """
        am = self.catalogs.get("applicability_matrix")
        if not am:
            return []

        results = []
        for rec in am["data"]:
            c = rec["content"]
            sid = c["schemeId"]
            matched, neutral, excluded_all = [], [], []

            for dim, getter in self._APPLICABILITY_FIELDS:
                profile_value = profile.get(dim)
                if profile_value is None:
                    continue
                scheme_values = getter(c)
                if not scheme_values:
                    neutral.append(dim)
                elif profile_value in scheme_values:
                    matched.append(dim)
                else:
                    excluded_all.append(dim)

            results.append({
                "schemeId": sid,
                "eligible": not excluded_all,
                "matchedFacets": matched,
                "neutralFacets": neutral,
                # `excludedBy` keeps its original meaning (first excluding facet,
                # in _APPLICABILITY_FIELDS order) so existing consumers are
                # unaffected. `excludedByAll` is the additive full list -- the
                # single-value field could never express "excluded on two
                # counts", which the app needs to explain a rejection properly.
                "excludedBy": excluded_all[0] if excluded_all else None,
                "excludedByAll": excluded_all,
            })

        results.sort(key=lambda r: (not r["eligible"], -len(r["matchedFacets"]), r["schemeId"]))
        return results

    def resolve_all(self):
        scheme_cat = self.catalogs.get("scheme")
        if not scheme_cat:
            return {}
        return {r["identity"]["id"]: self.resolve(r["identity"]["id"])
                for r in scheme_cat["data"]}

    # ---- validation --------------------------------------------------------

    def validate(self):
        """Cross-check the resolver's own output against a manual edge walk,
        per MIGRATION_PLAN.md Step 5's gate: 'resolver output must be
        provably derivable from the graph, not a separate calculation.'
        Returns a report dict; does not raise."""
        scheme_cat = self.catalogs.get("scheme")
        if not scheme_cat:
            return {"error": "scheme_catalog.json not found"}

        checked = 0
        mismatches = []
        missing_ref_total = 0
        edge_type_counts = defaultdict(int)

        for rec in scheme_cat["data"]:
            sid = rec["identity"]["id"]
            resolved = self.resolve(sid)
            checked += 1
            missing_ref_total += len(resolved["missingReferences"])

            # manual re-walk, independent of resolve()'s own grouping code path
            manual = defaultdict(int)
            for e in rec["relationships"]["references"]:
                manual[e["entityType"]] += 1
            for etype, count in manual.items():
                edge_type_counts[etype] += count

            resolved_counts = {
                "finance_product": len(resolved["finance"]),
                "tax_provision": len(resolved["tax"]),
                "treds_platform": len(resolved["treds"]),
                "csr_provision": len(resolved["csr"]),
                "authority": len(resolved["authority"]),
                "institution": len(resolved["institution"]),
                "export_benefit": len(resolved["export"]),
                "cluster_assistance": len(resolved["cluster"]),
                "msme_privilege": len(resolved["privileges"]),
                "business_enablement": len(resolved["enablement"]),
                "knowledge_item": len(resolved["knowledge"]),
            }
            for etype in set(manual) | set(resolved_counts):
                expected = manual.get(etype, 0)
                got = resolved_counts.get(etype, 0)
                if expected != got:
                    mismatches.append({"schemeId": sid, "entityType": etype,
                                        "expected": expected, "got": got})

        return {
            "schemesChecked": checked,
            "mismatches": mismatches,
            "missingReferencesTotal": missing_ref_total,
            "edgeTypeCounts": dict(edge_type_counts),
            "missingCatalogFiles": self.missing_files,
            "applicabilityMatrixLoaded": self.catalogs.get("applicability_matrix") is not None,
            "applicabilityCoverage": (
                f"{len(self.applicability_by_scheme)}/{len(scheme_cat['data'])}"
                if self.catalogs.get("applicability_matrix") else "0/0 (catalog not built yet)"
            ),
        }


if __name__ == "__main__":
    r = IntelligenceResolver()
    report = r.validate()
    print(f"schemesChecked            {report['schemesChecked']}")
    print(f"mismatches                {len(report['mismatches'])}")
    print(f"missingReferencesTotal    {report['missingReferencesTotal']}")
    print(f"missingCatalogFiles       {report['missingCatalogFiles']}")
    print(f"applicabilityMatrixLoaded {report['applicabilityMatrixLoaded']}")
    print(f"applicabilityCoverage     {report['applicabilityCoverage']}")
    print("edgeTypeCounts")
    for k, v in sorted(report["edgeTypeCounts"].items(), key=lambda x: -x[1]):
        print(f"   {k:20} {v}")
    if report["mismatches"]:
        print("MISMATCHES FOUND:", report["mismatches"][:5])
        raise SystemExit(1)
    print("RESOLVER VALIDATION PASSED — output matches manual edge walk on all schemes")

    # ---- applicability matching smoke test + determinism check --------------
    print("\napplicability_match() smoke test")
    profile = {"gender": "female", "enterpriseType": "micro", "state": "IN-TN"}
    run1 = r.match_applicability(profile)
    run2 = IntelligenceResolver().match_applicability(profile)  # fresh instance
    same = run1 == run2
    print(f"   profile: {profile}")
    print(f"   results: {len(run1)}  deterministic (fresh instance, same order+content): {same}")
    top = [x for x in run1 if x["eligible"] and x["matchedFacets"]][:5]
    for x in top:
        print(f"   {x['schemeId']}  matched={x['matchedFacets']}  neutral={len(x['neutralFacets'])}")
    excluded = [x for x in run1 if not x["eligible"]][:3]
    print(f"   excluded count: {sum(1 for x in run1 if not x['eligible'])}  sample: {excluded}")
    if not same:
        print("APPLICABILITY MATCH DETERMINISM FAILED")
        raise SystemExit(1)
