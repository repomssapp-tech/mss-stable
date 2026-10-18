#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MSS API RC1 -- Phase C.

Implements API_INTEGRATION_CONTRACT.md on top of the EXISTING stack:

    catalog/*.json -> IntelligenceResolver -> HybridSearch -> MssApi -> MssApiRC1

MssApiRC1 SUBCLASSES MssApi rather than replacing it. There is exactly one
search engine: `search()` here calls `super().search()` and then applies
post-ranking filters. It never re-scores, never re-sorts, never introduces a
parallel ranking path -- the contract's "no ranking drift" rule is satisfied
structurally, not by discipline, and api_tests.py asserts it.

Transport-agnostic: returns plain dicts, imports no web framework, binds no
port. HTTP_STATUS (inherited) maps error codes for whichever adapter is
eventually chosen.

Adds over MssApi:
  health()                    version/liveness
  search()                    + structured filters, sorting, cursor pagination
  finance_products()          list/detail
  scheme_finance()            finance assistance for one scheme
  clusters()                  list/detail
  tax()                       list/detail
  privileges()                list/detail
  relationships()             graph traversal
  localization()              per-entity localization + provenance/status
"""
import base64, json, os, sys, time
from collections import OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, CAT)

from mss_api import MssApi, MssApiError, CONTRACT_VERSION, PROFILE_DIMENSIONS
import app_response

RC1_VERSION = "1.0.0-rc1"
MAX_LIMIT = 100
DEFAULT_LIMIT = 20

# Filters from the contract that are NOT profile dimensions. Profile dims
# (state/district/sector/gender/enterpriseType/businessStage) route to
# applicability matching instead; everything here is a post-ranking predicate.
SCALAR_FILTERS = ("status", "governmentLevel", "assistanceType", "department",
                  "beneficiary", "cluster", "taxBenefit", "collateralRequired",
                  "minimumAssistance", "maximumAssistance")

SORT_FIELDS = ("relevance", "name", "confidence")
CONFIDENCE_ORDER = {"high": 3, "medium": 2, "low": 1, None: 0}


class MssApiRC1(MssApi):

    def __init__(self):
        t0 = time.time()
        super().__init__()
        self.load_seconds = round(time.time() - t0, 4)
        self._catalog_version = self.resolver.catalogs["scheme"]["metadata"]["catalogVersion"]

    # ---- helpers ---------------------------------------------------------

    def _envelope(self, contract, data, warnings=None, page=None):
        env = OrderedDict([
            ("contractVersion", CONTRACT_VERSION),
            ("rc", RC1_VERSION),
            ("contract", contract),
            ("catalogVersion", self._catalog_version),
            ("generatedAt", app_response._now()),
            ("deterministic", True),
            ("warnings", warnings or []),
        ])
        if page is not None:
            env["page"] = page
        env["data"] = data
        return env

    def _encode_cursor(self, sort_by, last_id, offset):
        """Cursor carries catalogVersion so a mid-pagination catalog change is
        detectable (CURSOR_STALE) instead of silently serving a reshuffled
        page -- which offset paging cannot detect."""
        raw = json.dumps({"cv": self._catalog_version, "sort": sort_by,
                          "last": last_id, "off": offset}, sort_keys=True)
        return base64.urlsafe_b64encode(raw.encode()).decode()

    def _decode_cursor(self, cursor, sort_by):
        try:
            d = json.loads(base64.urlsafe_b64decode(cursor.encode()).decode())
        except Exception:
            raise MssApiError("INVALID_REQUEST", "Malformed cursor.", field="page.cursor")
        if d.get("cv") != self._catalog_version:
            raise MssApiError(
                "CURSOR_STALE",
                "The catalog changed while paginating; restart from the first page.",
                field="page.cursor",
                detail=f"cursor catalogVersion != current ({self._catalog_version[:40]}…)")
        if d.get("sort") != sort_by:
            raise MssApiError("INVALID_REQUEST",
                              "Sort order changed mid-pagination.", field="sort.by")
        return int(d.get("off", 0))

    def _paginate(self, items, page_req, sort_by):
        page_req = page_req or {}
        limit = page_req.get("limit", DEFAULT_LIMIT)
        if not isinstance(limit, int) or isinstance(limit, bool) or not (1 <= limit <= MAX_LIMIT):
            raise MssApiError("INVALID_REQUEST",
                              f"page.limit must be an integer 1..{MAX_LIMIT}.",
                              field="page.limit", detail=f"got {limit!r}")
        offset = 0
        if page_req.get("cursor"):
            offset = self._decode_cursor(page_req["cursor"], sort_by)
        window = items[offset:offset + limit]
        nxt = None
        if offset + limit < len(items) and window:
            nxt = self._encode_cursor(sort_by, window[-1].get("schemeId") or
                                      window[-1].get("id"), offset + limit)
        return window, OrderedDict([
            ("limit", limit), ("offset", offset), ("returned", len(window)),
            ("total", len(items)), ("nextCursor", nxt),
        ])

    # ---- data-state warnings --------------------------------------------

    def _finance_gap_warnings(self, assistance):
        """Generated from ACTUAL data state, never a fixed list. A null field
        is reported as unverified rather than silently omitted."""
        out, seen = [], set()
        for fb in assistance:
            for field, label in (("interestRate", "Interest rate"),
                                 ("tenure", "Repayment tenure"),
                                 ("conditions", "Conditions")):
                val = fb.get(field)
                empty = val is None or val == [] or val == {} or (
                    isinstance(val, dict) and not any(v is not None for v in val.values()))
                if empty and field not in seen:
                    seen.add(field)
                    out.append(OrderedDict([
                        ("type", "data_gap"), ("field", field),
                        ("message", f"{label} is not verified for this record."),
                    ]))
        return out

    # ---- 1. health -------------------------------------------------------

    def health(self):
        return self._envelope("health", OrderedDict([
            ("status", "ok"),
            ("rcVersion", RC1_VERSION),
            ("contractVersion", CONTRACT_VERSION),
            ("catalogVersion", self._catalog_version),
            ("catalogChecksum", self.resolver.catalogs["scheme"]["metadata"]["checksum"]),
            ("catalogsLoaded", sum(1 for c in self.resolver.catalogs.values() if c)),
            ("schemeCount", len(self.schemes)),
            ("loadSeconds", self.load_seconds),
        ]))

    # ---- 2. search -------------------------------------------------------

    def _passes_filters(self, result, filters):
        """Post-ranking predicates only. Order is never altered here -- items
        are dropped, never re-sorted."""
        if not filters:
            return True
        sid = result["schemeId"]
        rec = self.schemes.get(sid)
        if not rec:
            return False
        content, identity = rec["content"], rec["identity"]

        want = filters.get("status")
        if want and identity.get("status") not in want:
            return False

        lvl = filters.get("governmentLevel")
        if lvl and content["classification"]["government"].get("level") not in lvl:
            return False

        dept = filters.get("department")
        if dept:
            g = content["classification"]["government"]
            if dept not in (g.get("departmentId"), g.get("departmentText")):
                return False

        ben = filters.get("beneficiary")
        if ben:
            desc = (content["targetBeneficiaries"].get("description") or "").lower()
            if ben.lower() not in desc:
                return False

        atype = filters.get("assistanceType")
        if atype:
            types = {a.get("type") for a in result.get("assistance", [])}
            types |= set(content["benefits"].get("benefitTypes") or [])
            if atype not in types:
                return False

        coll = filters.get("collateralRequired")
        if coll is not None:
            statuses = {(a.get("collateralStatus")) for a in result.get("assistance", [])}
            if coll is False and "not_required" not in statuses:
                return False
            if coll is True and "required" not in statuses:
                return False

        tb = filters.get("taxBenefit")
        if tb:
            resolved = self.resolver.resolve(sid)
            if not resolved["tax"]:
                return False

        clus = filters.get("cluster")
        if clus:
            resolved = self.resolver.resolve(sid)
            names = {c["record"]["identity"]["name"].lower() for c in resolved["cluster"]}
            if not any(clus.lower() in n for n in names):
                return False

        lo, hi = filters.get("minimumAssistance"), filters.get("maximumAssistance")
        if lo is not None or hi is not None:
            amounts = [a["amount"].get("maxInr") for a in result.get("assistance", [])
                       if a.get("amount", {}).get("maxInr") is not None]
            if not amounts:
                return False           # unrecorded != matching a numeric range
            best = max(amounts)
            if lo is not None and best < lo:
                return False
            if hi is not None and best > hi:
                return False
        return True

    def _validate_filters(self, filters):
        if filters is None:
            return None, []
        if not isinstance(filters, dict):
            raise MssApiError("INVALID_REQUEST", "filters must be an object.", field="filters")
        unknown = sorted(set(filters) - set(SCALAR_FILTERS))
        if unknown:
            raise MssApiError("INVALID_REQUEST",
                              f"Unknown filter(s): {', '.join(unknown)}.",
                              field=f"filters.{unknown[0]}",
                              detail=f"supported: {', '.join(sorted(SCALAR_FILTERS))}")
        clean, warns = {}, []
        for k, v in filters.items():
            if v is None:
                continue
            if k in ("status", "governmentLevel"):
                if isinstance(v, str):
                    v = [v]
                if not isinstance(v, list):
                    raise MssApiError("INVALID_REQUEST", f"filters.{k} must be a string or list.",
                                      field=f"filters.{k}")
            if k in ("minimumAssistance", "maximumAssistance") and not isinstance(v, (int, float)):
                raise MssApiError("INVALID_REQUEST", f"filters.{k} must be a number.",
                                  field=f"filters.{k}", detail=f"got {v!r}")
            if k == "collateralRequired" and not isinstance(v, bool):
                raise MssApiError("INVALID_REQUEST", "filters.collateralRequired must be boolean.",
                                  field="filters.collateralRequired")
            clean[k] = v
        # Contract: excluding `unknown` hides 112/217 schemes -- warn loudly.
        st = clean.get("status")
        if st and "unknown" not in st:
            warns.append(OrderedDict([
                ("type", "filter_scope"), ("field", "filters.status"),
                ("message", "Excluding status 'unknown' hides schemes whose real-world "
                            "status is unrecorded (112 of 217). They are not confirmed "
                            "closed."),
            ]))
        return (clean or None), warns

    def search(self, request):
        if not isinstance(request, dict):
            return MssApiError("INVALID_REQUEST", "Request must be an object.").to_response()
        try:
            filters, fwarn = self._validate_filters(request.get("filters"))
            sort = request.get("sort") or {}
            sort_by = sort.get("by", "relevance")
            if sort_by not in SORT_FIELDS:
                raise MssApiError("INVALID_REQUEST", "Unsupported sort field.",
                                  field="sort.by",
                                  detail=f"got '{sort_by}'; expected {', '.join(SORT_FIELDS)}")
            page_req = request.get("page") or {}
            if not isinstance(page_req, dict):
                raise MssApiError("INVALID_REQUEST", "page must be an object.", field="page")
        except MssApiError as e:
            return e.to_response()

        # ONE search engine: delegate scoring/ordering entirely to MssApi.
        # Over-fetch so post-ranking filtering has candidates to work with,
        # without ever re-scoring.
        base_req = {k: v for k, v in request.items()
                    if k in ("query", "profile", "language")}
        base_req["topN"] = min(MAX_LIMIT, 50)
        base = super().search(base_req)
        if base.get("contract") == "error":
            return base

        results = base["results"]
        if filters:
            results = [r for r in results if self._passes_filters(r, filters)]

        # Sorting: relevance keeps the engine's exact order. Alternatives
        # always append schemeId as a total-order tiebreak, or determinism dies.
        if sort_by == "name":
            results = sorted(results, key=lambda r: (r["name"].lower(), r["schemeId"]))
        elif sort_by == "confidence":
            results = sorted(results, key=lambda r: (
                -CONFIDENCE_ORDER.get((r.get("confidence") or {}).get("level"), 0),
                -r["score"], r["schemeId"]))

        try:
            window, page = self._paginate(results, page_req, sort_by)
        except MssApiError as e:
            return e.to_response()

        warnings = list(base.get("warnings") or []) + fwarn
        for r in window:
            warnings.extend(w for w in self._finance_gap_warnings(r.get("assistance", []))
                            if w not in warnings)
        if not window and base["results"]:
            warnings.append(OrderedDict([
                ("type", "filters_excluded_all"), ("field", "filters"),
                ("message", "The query matched schemes but every result was removed by "
                            "the supplied filters."),
            ]))
        if not base["results"]:
            warnings.append(OrderedDict([
                ("type", "no_matching_domain"), ("field", "query"),
                ("message", "No scheme in this catalog release matches the query domain. "
                            "This is a data-coverage gap, not a ranking result."),
            ]))

        for i, r in enumerate(window, start=page["offset"] + 1):
            r["rank"] = i
        data = OrderedDict([
            ("query", base["query"]),
            ("profileApplied", base.get("profileApplied")),
            ("filtersApplied", filters),
            ("sort", OrderedDict([("by", sort_by)])),
            ("resultCount", len(window)),
            ("results", window),
        ])
        return self._envelope("search_response", data, warnings, page)

    # ---- 4/8. finance ----------------------------------------------------

    def _finance_record(self, rec):
        c = rec["content"]
        amt = c.get("amount") or {}
        prov = rec.get("provenance") or {}
        return OrderedDict([
            ("financeId", rec["identity"]["id"]),
            ("schemeId", c.get("schemeId")),
            ("schemeName", c.get("schemeName")),
            ("assistanceClass", "financial_assistance"),
            ("type", c.get("productType")), ("typeText", c.get("productFamilyText")),
            ("isRepayable", c.get("isRepayable")), ("isGuarantee", c.get("isGuarantee")),
            # Emits BOTH namings of the same values, deliberately.
            # API_INTEGRATION_CONTRACT.md §4 names them minimumAssistance* /
            # maximumAssistance* / subsidyPercentage, while search results and
            # flutter_models/mss_contract.dart use the catalog's own
            # minInr/maxInr/percentage. Testing found a client would otherwise
            # have to special-case which endpoint it called. Carrying both is
            # additive and breaks nothing; the short keys are canonical.
            ("amount", OrderedDict([
                ("currency", amt.get("currency")),
                ("percentage", amt.get("percentage")),
                ("percentageText", amt.get("percentageText")),
                ("minInr", amt.get("minInr")),
                ("minText", amt.get("minText")),
                ("maxInr", amt.get("maxInr")),
                ("maxText", amt.get("maxText")),
                ("subsidyPercentage", amt.get("percentage")),
                ("subsidyPercentageText", amt.get("percentageText")),
                ("minimumAssistanceInr", amt.get("minInr")),
                ("minimumAssistanceText", amt.get("minText")),
                ("maximumAssistanceInr", amt.get("maxInr")),
                ("maximumAssistanceText", amt.get("maxText")),
            ])),
            ("interestRate", c.get("interestRate")),
            ("repaymentTenure", c.get("tenure")),
            ("collateral", c.get("collateral")),
            ("conditions", list(c.get("conditions") or [])),
            ("mode", c.get("applicationRoute")),
            ("applicationUrl", c.get("applicationUrl")),
            ("providers", [p.get("entityId") for p in (c.get("providers") or [])]),
            ("description", c.get("description")),
            ("verificationStatus", (rec.get("verification") or {}).get("status")),
            ("provenance", OrderedDict([
                ("defaultSourceTier", prov.get("defaultSourceTier")),
                ("fieldSources", prov.get("fieldSources") or []),
            ])),
        ])

    def finance_products(self, request=None):
        request = request or {}
        recs = (self.resolver.catalogs.get("finance_product") or {}).get("data", [])
        fid = request.get("financeId")
        if fid:
            rec = next((r for r in recs if r["identity"]["id"] == fid), None)
            if not rec:
                return MssApiError("UNKNOWN_ENTITY", f"No finance product '{fid}'.",
                                   field="financeId").to_response()
            item = self._finance_record(rec)
            return self._envelope("finance_product", item,
                                  self._finance_gap_warnings([{
                                      "interestRate": item["interestRate"],
                                      "tenure": item["repaymentTenure"],
                                      "conditions": item["conditions"]}]))
        items = [self._finance_record(r) for r in recs]
        items.sort(key=lambda x: x["financeId"])
        try:
            window, page = self._paginate(items, request.get("page"), "id")
        except MssApiError as e:
            return e.to_response()
        return self._envelope("finance_product_list", OrderedDict([
            ("total", len(items)), ("items", window)]),
            self._finance_gap_warnings([{"interestRate": i["interestRate"],
                                          "tenure": i["repaymentTenure"],
                                          "conditions": i["conditions"]} for i in window]),
            page)

    def scheme_finance(self, request):
        sid = (request or {}).get("schemeId")
        if sid not in self.schemes:
            return MssApiError("UNKNOWN_SCHEME", f"No scheme with id '{sid}'.",
                               field="schemeId").to_response()
        recs = [f["record"] for f in self.resolver.resolve(sid)["finance"]]
        items = [self._finance_record(r) for r in recs]
        warns = self._finance_gap_warnings([{"interestRate": i["interestRate"],
                                              "tenure": i["repaymentTenure"],
                                              "conditions": i["conditions"]} for i in items])
        if not items:
            warns.append(OrderedDict([("type", "data_gap"), ("field", "finance"),
                                      ("message", "No finance product is linked to this scheme.")]))
        return self._envelope("scheme_finance", OrderedDict([
            ("schemeId", sid), ("count", len(items)), ("items", items)]), warns)

    # ---- 5/6/7. cluster · tax · privileges -------------------------------

    def _generic_list(self, etype, contract, mapper, request, id_field):
        request = request or {}
        recs = (self.resolver.catalogs.get(etype) or {}).get("data", [])
        wanted = request.get(id_field)
        if wanted:
            rec = next((r for r in recs if r["identity"]["id"] == wanted), None)
            if not rec:
                return MssApiError("UNKNOWN_ENTITY", f"No {etype} '{wanted}'.",
                                   field=id_field).to_response()
            return self._envelope(contract, mapper(rec))
        items = sorted((mapper(r) for r in recs), key=lambda x: x[id_field])
        try:
            window, page = self._paginate(items, request.get("page"), "id")
        except MssApiError as e:
            return e.to_response()
        warns = []
        if len(items) <= 3:
            warns.append(OrderedDict([
                ("type", "sparse_catalog"), ("field", etype),
                ("message", f"This catalog holds only {len(items)} record(s); coverage is "
                            f"known to be incomplete. Absence of a record is a data gap, "
                            f"not a negative finding."),
            ]))
        return self._envelope(contract + "_list", OrderedDict([
            ("total", len(items)), ("items", window)]), warns, page)

    def _cluster_map(self, rec):
        c = rec["content"]; v = rec.get("verification") or {}
        return OrderedDict([
            ("clusterId", rec["identity"]["id"]), ("clusterName", c.get("clusterName")),
            ("sector", c.get("sector")), ("sectorText", c.get("sectorText")),
            ("districts", c.get("districts") or []),
            ("eligibleEnterprise", c.get("supportedBusinessTypes") or []),
            # financial and non-financial are DISJOINT by schema, so a support
            # facility can never collapse into a monetary amount.
            ("financialSupport", c.get("financialSupport")),
            ("nonFinancialSupport", c.get("nonFinancialSupport")),
            ("administeringAuthorityId", c.get("administeringAuthorityId")),
            ("relatedSchemeIds", c.get("relatedSchemeIds") or []),
            ("verificationStatus", v.get("status")),
            ("provenance", (rec.get("provenance") or {}).get("fieldSources") or []),
        ])

    def _tax_map(self, rec):
        c = rec["content"]; v = rec.get("verification") or {}
        return OrderedDict([
            ("taxId", rec["identity"]["id"]), ("name", rec["identity"]["name"]),
            ("provisionKind", c.get("provisionKind")),
            ("governmentLevel", c.get("governmentLevel")),
            ("appliesToMsme", c.get("appliesToMsme")),
            ("jurisdiction", c.get("jurisdiction")),
            ("exemptions", c.get("exemptions")), ("deductions", c.get("deductions")),
            ("dueDates", c.get("dueDates")), ("filingFrequency", c.get("filingFrequency")),
            ("evidencedInSchemes", c.get("evidencedInSchemes") or []),
            ("verificationStatus", v.get("status")),
            ("provenance", (rec.get("provenance") or {}).get("fieldSources") or []),
        ])

    def _privilege_map(self, rec):
        c = rec["content"]; v = rec.get("verification") or {}
        return OrderedDict([
            ("privilegeId", rec["identity"]["id"]), ("name", rec["identity"]["name"]),
            ("privilegeType", c.get("privilegeType")),
            # The statutory/scheme/financial distinction the contract requires.
            ("privilegeClass", "statutory_right" if c.get("statute") else "scheme_benefit"),
            ("statute", c.get("statute")), ("summary", c.get("summary")),
            ("tenderBenefits", c.get("tenderBenefits")),
            ("delayedPaymentProtection", c.get("delayedPaymentProtection")),
            ("billDiscounting", c.get("billDiscounting")),
            ("compliance", c.get("compliance")),
            ("verificationStatus", v.get("status")),
            ("missingFields", (rec.get("verification") or {}).get("missingFields") or []),
            ("provenance", (rec.get("provenance") or {}).get("fieldSources") or []),
        ])

    def clusters(self, request=None):
        return self._generic_list("cluster_assistance", "cluster",
                                  self._cluster_map, request, "clusterId")

    def tax(self, request=None):
        return self._generic_list("tax_provision", "tax", self._tax_map, request, "taxId")

    def privileges(self, request=None):
        return self._generic_list("msme_privilege", "privilege",
                                  self._privilege_map, request, "privilegeId")

    # ---- 10. relationships ----------------------------------------------

    def relationships(self, request):
        eid = (request or {}).get("entityId")
        if not eid or eid not in self.resolver.by_id:
            return MssApiError("UNKNOWN_ENTITY", f"No entity with id '{eid}'.",
                               field="entityId").to_response()
        rec, etype = self.resolver.by_id[eid]
        edges = []
        for e in rec["relationships"]["references"]:
            tgt = self.resolver.by_id.get(e["entityId"])
            edges.append(OrderedDict([
                ("targetId", e["entityId"]),
                ("targetType", tgt[1] if tgt else None),
                ("targetName", tgt[0]["identity"]["name"] if tgt else None),
                ("relationType", e["relationType"]),
                ("direction", "outbound"),
                ("generated", bool(e.get("generated"))),
                ("resolved", tgt is not None),
            ]))
        edges.sort(key=lambda x: (x["relationType"], x["targetId"]))
        dangling = [e["targetId"] for e in edges if not e["resolved"]]
        data = OrderedDict([
            ("entityId", eid), ("entityType", etype),
            ("edgeCount", len(edges)), ("edges", edges),
            ("traversable", ["finance", "tax", "treds", "csr", "authority", "institution",
                             "export", "cluster", "privileges", "enablement", "knowledge"]),
            ("dataIntegrity", OrderedDict([("missingReferences", dangling)])),
        ])
        warns = []
        if dangling:
            warns.append(OrderedDict([("type", "data_integrity"), ("field", "edges"),
                                      ("message", f"{len(dangling)} edge(s) do not resolve.")]))
        return self._envelope("relationships", data, warns)

    # ---- 11. localization -----------------------------------------------

    def localization(self, request):
        req = request or {}
        eid, lang = req.get("entityId"), req.get("lang", "ta")
        if lang not in ("en", "ta"):
            return MssApiError("INVALID_REQUEST", "Unsupported lang.", field="lang",
                               detail=f"got '{lang}'; expected en or ta").to_response()
        if not eid or eid not in self.resolver.by_id:
            return MssApiError("UNKNOWN_ENTITY", f"No entity with id '{eid}'.",
                               field="entityId").to_response()
        rec, etype = self.resolver.by_id[eid]
        loc = (rec.get("localization") or {}).get(lang) or {}
        available = bool(loc.get("name"))
        tr = ((rec.get("provenance") or {}).get("translations") or {}).get(lang) or {}
        warns = []
        if lang == "ta" and not available:
            warns.append(OrderedDict([
                ("type", "data_gap"), ("field", f"localization.{lang}"),
                ("message", f"No Tamil localization exists for this {etype} record."),
            ]))
        if available and tr.get("status") == "machine":
            warns.append(OrderedDict([
                ("type", "unofficial_translation"), ("field", f"localization.{lang}"),
                ("message", "Machine-generated Tamil, not an official government "
                            "translation. Not approved for publication."),
            ]))
        data = OrderedDict([
            ("entityId", eid), ("entityType", etype), ("lang", lang),
            ("available", available),
            ("fields", loc),
            ("fallbackLang", "en" if (lang == "ta" and not available) else None),
            ("provenance", OrderedDict([
                ("method", tr.get("method")), ("engine", tr.get("engine")),
                ("status", tr.get("status")),
                ("isApproved", tr.get("isApproved", False)),
                ("reviewRequired", tr.get("reviewRequired")),
                ("official", tr.get("status") == "official"),
            ])),
        ])
        return self._envelope("localization", data, warns)

    # ---- 12. metadata ----------------------------------------------------

    def metadata(self):
        base = self.meta()
        cov = {}
        for etype, cat in sorted(self.resolver.catalogs.items()):
            if not cat:
                continue
            data = cat["data"]
            ta = sum(1 for r in data if ((r.get("localization") or {}).get("ta") or {}).get("name"))
            cov[etype] = OrderedDict([("records", len(data)),
                                      ("tamil", ta),
                                      ("tamilCoverage", round(ta / len(data), 4) if data else 0.0)])
        base["localizationCoverage"] = cov
        return self._envelope("metadata", base)


if __name__ == "__main__":
    api = MssApiRC1()
    print(json.dumps(api.health()["data"], indent=2, ensure_ascii=False))
    r = api.search({"query": "collateral free loan",
                    "filters": {"status": ["active"]},
                    "page": {"limit": 3}})
    print(f"\nsearch -> {r['data']['resultCount']} results, "
          f"page={dict(r['page'])}, warnings={len(r['warnings'])}")
    for x in r["data"]["results"]:
        print(f"   {x['rank']}. {x['schemeId']} {x['score']} {x['name'][:44]}")
