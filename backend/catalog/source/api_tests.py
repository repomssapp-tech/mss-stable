#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MSS API RC1 test suite -- Phase C validation.

The centrepiece is test_no_ranking_drift(): API search results must be
IDENTICAL to the underlying HybridSearch for equivalent requests. If the API
ever re-scores or re-sorts, that test fails and RC1 is not shippable. Every
other test is secondary to it.

Run:  python api_tests.py
Exit 0 = all pass.
"""
import json, os, sys, time
from collections import OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, CAT)

from mss_api_rc1 import MssApiRC1, RC1_VERSION
from hybrid_search import HybridSearch

PASS, FAIL = 0, 0
FAILURES = []


def check(cond, label, detail=""):
    global PASS, FAIL
    if cond:
        PASS += 1
        print(f"  PASS  {label}")
    else:
        FAIL += 1
        FAILURES.append(f"{label} :: {detail}")
        print(f"  FAIL  {label}   {detail}")


def section(name):
    print(f"\n=== {name} ===")


# ---------------------------------------------------------------------------

def test_no_ranking_drift(api):
    """THE critical test. For the same query, the ordered (schemeId, score)
    sequence the API returns must equal what HybridSearch produces directly.
    Filters may REMOVE items; they must never REORDER them."""
    section("NO RANKING DRIFT (critical)")
    engine = HybridSearch()
    queries = ["collateral free loan", "women entrepreneur loan", "khadi scheme",
               "beekeeping project funding", "textile manufacturer machinery upgrade",
               "GST benefit", "startup funding"]
    for q in queries:
        raw = engine.search(q, top_n=50)["results"]
        raw_seq = [(r["schemeId"], r["score"]) for r in raw]

        api_r = api.search({"query": q, "page": {"limit": 100}})
        api_seq = [(r["schemeId"], r["score"]) for r in api_r["data"]["results"]]

        check(api_seq == raw_seq[:len(api_seq)],
              f"unfiltered order identical to engine: {q[:34]!r}",
              f"api={api_seq[:3]} engine={raw_seq[:3]}")

    # Filtered results must be an ORDER-PRESERVING SUBSEQUENCE of unfiltered.
    for q in ["collateral free loan", "women entrepreneur loan"]:
        unf = [r["schemeId"] for r in
               api.search({"query": q, "page": {"limit": 100}})["data"]["results"]]
        filt = [r["schemeId"] for r in
                api.search({"query": q, "filters": {"status": ["active", "unknown"]},
                            "page": {"limit": 100}})["data"]["results"]]
        it = iter(unf)
        is_subseq = all(s in it for s in filt)
        check(is_subseq, f"filtered result is an order-preserving subsequence: {q[:30]!r}",
              f"filtered={filt[:4]}")


def test_valid_search(api):
    section("valid search")
    r = api.search({"query": "collateral free loan"})
    check(r["contract"] == "search_response", "contract type")
    check(r["data"]["resultCount"] > 0, "returns results")
    check(r["deterministic"] is True, "deterministic flag")
    check(r["catalogVersion"], "catalogVersion present")
    check(r["rc"] == RC1_VERSION, "rc version stamped")
    top = r["data"]["results"][0]
    for f in ("rank", "schemeId", "name", "score", "rankingSignals",
              "matchReasons", "explanation", "citations", "confidence",
              "assistance", "authority", "nextActions"):
        check(f in top, f"result carries '{f}'")
    check(top["rank"] == 1, "rank is 1-based")


def test_empty_search(api):
    section("empty / no-match search")
    # Pure gibberish. An earlier draft used "...nonexistent domain term",
    # which FAILED because "term" is a real corpus token (idf 5.00, from
    # "term loan") -- the test was wrong, not the API.
    r = api.search({"query": "zzzzqqq xxxyyyzzz qqqwwweee"})
    check(r["contract"] == "search_response", "still a valid response")
    check(r["data"]["resultCount"] == 0, "zero results")
    codes = [w["type"] for w in r["warnings"]]
    check("no_matching_domain" in codes,
          "emits no_matching_domain warning (data gap, not failure)", str(codes))

    e = api.search({})
    check(e.get("contract") == "error", "missing query -> error")
    check(e["error"]["code"] == "INVALID_REQUEST", "code INVALID_REQUEST")


def test_filters(api):
    section("structured filters")
    base = api.search({"query": "loan", "page": {"limit": 100}})
    n_base = base["data"]["resultCount"]

    r = api.search({"query": "loan", "filters": {"status": ["active"]},
                    "page": {"limit": 100}})
    check(r["data"]["resultCount"] <= n_base, "status filter narrows or equals")
    statuses = {api.schemes[x["schemeId"]]["identity"]["status"]
                for x in r["data"]["results"]}
    check(statuses <= {"active"}, "only active returned", str(statuses))
    check(any(w["type"] == "filter_scope" for w in r["warnings"]),
          "warns that excluding 'unknown' hides 112 schemes")

    r2 = api.search({"query": "loan", "filters": {"governmentLevel": ["state"]},
                     "page": {"limit": 100}})
    lv = {api.schemes[x["schemeId"]]["content"]["classification"]["government"].get("level")
          for x in r2["data"]["results"]}
    check(lv <= {"state"}, "governmentLevel filter", str(lv))

    r3 = api.search({"query": "loan", "filters": {"collateralRequired": False},
                     "page": {"limit": 100}})
    ok = all(any(a.get("collateralStatus") == "not_required" for a in x["assistance"])
             for x in r3["data"]["results"])
    check(ok, "collateralRequired=False only returns explicit not_required")

    # NB: search results carry the canonical short key `maxInr`. An earlier
    # draft asserted on `maximumAssistanceInr` (the finance-endpoint name) and
    # failed spuriously -- which surfaced a genuine naming inconsistency
    # between the two endpoints, now fixed by emitting both.
    r4 = api.search({"query": "subsidy", "filters": {"minimumAssistance": 100000},
                     "page": {"limit": 100}})
    ok = all(max([a["amount"].get("maxInr") or 0
                  for a in x["assistance"]] or [0]) >= 100000
             for x in r4["data"]["results"]) if r4["data"]["results"] else True
    check(ok, "minimumAssistance threshold respected")
    check(all(a["amount"].get("maxInr") is not None
              for x in r4["data"]["results"] for a in x["assistance"]),
          "unrecorded amount never satisfies a numeric range")

    bad = api.search({"query": "loan", "filters": {"nonsenseFilter": 1}})
    check(bad.get("contract") == "error", "unknown filter -> error")
    check(bad["error"]["field"] == "filters.nonsenseFilter", "error attributes the field")

    bad2 = api.search({"query": "loan", "filters": {"collateralRequired": "yes"}})
    check(bad2.get("contract") == "error", "wrong filter type -> error")


def test_pagination(api):
    section("pagination")
    p1 = api.search({"query": "loan", "page": {"limit": 3}})
    check(p1["page"]["returned"] == 3, "limit honoured")
    check(p1["page"]["nextCursor"], "nextCursor issued")
    ids1 = [r["schemeId"] for r in p1["data"]["results"]]

    p2 = api.search({"query": "loan", "page": {"limit": 3, "cursor": p1["page"]["nextCursor"]}})
    ids2 = [r["schemeId"] for r in p2["data"]["results"]]
    check(not set(ids1) & set(ids2), "no overlap between pages", f"{ids1} {ids2}")
    check(p2["data"]["results"][0]["rank"] == 4, "rank continues across pages")

    full = api.search({"query": "loan", "page": {"limit": 100}})
    check(ids1 + ids2 == [r["schemeId"] for r in full["data"]["results"]][:6],
          "paged sequence equals unpaged prefix (order preserved)")

    bad = api.search({"query": "loan", "page": {"limit": 0}})
    check(bad.get("contract") == "error", "limit=0 -> error")
    bad2 = api.search({"query": "loan", "page": {"cursor": "!!!notbase64!!!"}})
    check(bad2.get("contract") == "error", "malformed cursor -> error")


def test_stale_cursor(api):
    section("stale catalogVersion cursor")
    import base64
    stale = base64.urlsafe_b64encode(json.dumps(
        {"cv": "0.0.0-different", "sort": "relevance", "last": "SCH000001", "off": 3}
    ).encode()).decode()
    r = api.search({"query": "loan", "page": {"limit": 3, "cursor": stale}})
    check(r.get("contract") == "error", "stale cursor rejected")
    check(r["error"]["code"] == "CURSOR_STALE", "code CURSOR_STALE",
          r.get("error", {}).get("code"))


def test_sorting(api):
    section("sorting + total-order tiebreak")
    r = api.search({"query": "loan", "sort": {"by": "name"}, "page": {"limit": 20}})
    names = [x["name"].lower() for x in r["data"]["results"]]
    check(names == sorted(names), "name sort ordered")
    r2 = api.search({"query": "loan", "sort": {"by": "confidence"}, "page": {"limit": 20}})
    order = {"high": 3, "medium": 2, "low": 1, None: 0}
    lv = [order.get((x.get("confidence") or {}).get("level"), 0) for x in r2["data"]["results"]]
    check(lv == sorted(lv, reverse=True), "confidence sort descending", str(lv[:6]))
    bad = api.search({"query": "loan", "sort": {"by": "bogus"}})
    check(bad.get("contract") == "error", "invalid sort field -> error")


def test_missing_entity(api):
    section("missing entity")
    for label, fn in [
        ("scheme_detail", lambda: api.scheme_detail({"schemeId": "SCH999999"})),
        ("scheme_finance", lambda: api.scheme_finance({"schemeId": "SCH999999"})),
        ("finance_products", lambda: api.finance_products({"financeId": "FIN999999"})),
        ("clusters", lambda: api.clusters({"clusterId": "CLUS999999"})),
        ("tax", lambda: api.tax({"taxId": "TAX999999"})),
        ("privileges", lambda: api.privileges({"privilegeId": "PRIV999999"})),
        ("relationships", lambda: api.relationships({"entityId": "XXX999999"})),
        ("localization", lambda: api.localization({"entityId": "XXX999999"})),
    ]:
        r = fn()
        check(r.get("contract") == "error" and
              r["error"]["code"] in ("UNKNOWN_SCHEME", "UNKNOWN_ENTITY"),
              f"{label}: unknown id -> error", r.get("error", {}).get("code"))


def test_resolver_traversal(api):
    section("relationship traversal")
    r = api.relationships({"entityId": "SCH000001"})
    d = r["data"]
    check(d["edgeCount"] > 0, "edges returned")
    check(all(e["resolved"] for e in d["edges"]), "every edge resolves")
    check(d["dataIntegrity"]["missingReferences"] == [], "no dangling references")
    check(all(e.get("targetType") for e in d["edges"]), "edges carry target type")
    ids = [(e["relationType"], e["targetId"]) for e in d["edges"]]
    check(ids == sorted(ids), "edges deterministically ordered")


def test_financial_assistance(api):
    section("financial assistance")
    r = api.scheme_finance({"schemeId": "SCH000001"})
    check(r["data"]["count"] >= 1, "finance linked to scheme")
    item = r["data"]["items"][0]
    for f in ("financeId", "assistanceClass", "amount", "interestRate",
              "repaymentTenure", "collateral", "conditions", "verificationStatus",
              "provenance"):
        check(f in item, f"finance record carries '{f}'")
    check(item["assistanceClass"] == "financial_assistance",
          "financial assistance explicitly classed")
    a = item["amount"]
    check("minimumAssistanceInr" in a and "maximumAssistanceInr" in a
          and "subsidyPercentage" in a, "min/max/subsidy exposed (contract names)")
    check("maxInr" in a and "minInr" in a and "percentage" in a,
          "canonical short keys also present (search/Dart parity)")
    check(a["maxInr"] == a["maximumAssistanceInr"]
          and a["percentage"] == a["subsidyPercentage"],
          "both namings carry identical values")
    gaps = [w["field"] for w in r["warnings"] if w["type"] == "data_gap"]
    check("interestRate" in gaps or item["interestRate"].get("percent") is not None,
          "unverified interestRate surfaces a data_gap warning", str(gaps))

    lst = api.finance_products({"page": {"limit": 5}})
    check(lst["data"]["total"] == 115, "115 finance products", str(lst["data"]["total"]))


def test_cluster_tax_privilege(api):
    section("cluster · tax · privileges")
    c = api.clusters()
    check(c["data"]["total"] == 10, "10 clusters (Phase D2 added 2 textile; Phase E.1 added 6 sector-specific CFC records)")
    check(not any(w["type"] == "sparse_catalog" for w in c["warnings"]),
          "sparse_catalog warning no longer emitted -- coverage passed the <=3 threshold")
    item = c["data"]["items"][0]
    check("financialSupport" in item and "nonFinancialSupport" in item,
          "financial and non-financial kept disjoint")
    check(item["financialSupport"] is not item["nonFinancialSupport"],
          "they are distinct objects")

    t = api.tax()
    check(t["data"]["total"] == 13, "13 tax provisions")
    check("evidencedInSchemes" in t["data"]["items"][0],
          "tax links to schemes by reference, not duplication")

    p = api.privileges()
    check(p["data"]["total"] == 1, "1 privilege record")
    pi = p["data"]["items"][0]
    check(pi["privilegeClass"] in ("statutory_right", "scheme_benefit"),
          "statutory vs scheme benefit distinguished", pi.get("privilegeClass"))
    check(pi["privilegeClass"] == "statutory_right",
          "MSMED Act delayed payment classed as statutory right")


def test_localization(api):
    section("localization")
    ta = api.localization({"entityId": "SCH000001", "lang": "ta"})
    check(ta["data"]["available"] is True, "scheme has Tamil")
    check(ta["data"]["provenance"]["official"] is False,
          "machine Tamil NOT labelled official")
    check(ta["data"]["provenance"]["isApproved"] is False, "isApproved false")
    check(any(w["type"] == "unofficial_translation" for w in ta["warnings"]),
          "warns the translation is unofficial")

    # FIN000001 (and all of finance_catalog.json) gained a real Tamil
    # localization.ta.name during the Tamil Localization Completion Phase
    # (2026-08-15, Task 2 -- compositional fix, see
    # apply_localization_task2.py) and is no longer a valid "has no Tamil"
    # example. knowledge_catalog.json remains a genuine, untouched gap
    # (out of that phase's scope) -- use it instead.
    gap = api.localization({"entityId": "KNOW000001", "lang": "ta"})
    check(gap["data"]["available"] is False, "knowledge record has no Tamil")
    check(any(w["type"] == "data_gap" for w in gap["warnings"]),
          "missing Tamil surfaces a data_gap")
    check(gap["data"]["fallbackLang"] == "en", "declares English fallback")

    bad = api.localization({"entityId": "SCH000001", "lang": "fr"})
    check(bad.get("contract") == "error", "unsupported lang -> error")


def test_metadata_provenance(api):
    section("metadata + provenance")
    m = api.metadata()["data"]
    check(m["entityCounts"]["scheme"] == 219, "entity counts exposed")
    check("localizationCoverage" in m, "localization coverage exposed")
    # Tamil Localization Completion Phase (2026-08-15) closed both gaps this
    # test used to assert: Task 1 localized SCH000218/SCH000219 (scheme
    # coverage back to 100%), Task 2 gave every finance_catalog.json record
    # a real localization.ta.name via compositional translation (finance
    # coverage now 100% too, up from a real 0% before). See
    # LOCALIZATION_COMPLETION_REPORT.md.
    check(m["localizationCoverage"]["scheme"]["tamilCoverage"] == 1.0,
          "scheme Tamil 100% (SCH000218/219 localized)")
    check(m["localizationCoverage"]["finance_product"]["tamilCoverage"] == 1.0,
          "finance Tamil 100% (product names now composed, not just descriptions)")
    zero = [d for d, i in m["profileDimensions"].items() if i["schemesWithData"] == 0]
    # "community" dropped out of the zero-coverage set after the derived-data
    # repair phase -- SCH000218 (Stand-Up India) carries real community=[SC,ST]
    # structured eligibility, backfilled into applicability_matrix_catalog.json
    # by its own regeneration script, not invented here. "district" remains
    # genuinely zero-coverage.
    check("district" in zero and "community" not in zero,
          "zero-coverage filter dimensions declared", str(zero))
    h = api.health()["data"]
    check(h["status"] == "ok" and h["schemeCount"] == 219, "health ok")


def test_determinism(api):
    section("determinism")
    for q in ["collateral free loan", "khadi scheme", "women entrepreneur loan"]:
        runs = []
        for _ in range(3):
            a = MssApiRC1()
            r = a.search({"query": q, "filters": {"status": ["active", "unknown"]},
                          "page": {"limit": 10}})
            r = json.loads(json.dumps(r))
            r.pop("generatedAt", None)
            runs.append(json.dumps(r, sort_keys=True))
        check(all(x == runs[0] for x in runs), f"identical across fresh instances: {q[:32]!r}")

    a = MssApiRC1()
    runs = []
    for _ in range(3):
        r = json.loads(json.dumps(a.relationships({"entityId": "SCH000001"})))
        r.pop("generatedAt", None)
        runs.append(json.dumps(r, sort_keys=True))
    check(all(x == runs[0] for x in runs), "relationships deterministic")


def test_error_handling(api):
    section("error handling")
    for label, req in [("non-dict request", "notadict"),
                       ("query too long", {"query": "x" * 600}),
                       ("bad profile key", {"query": "loan", "profile": {"gendre": "female"}}),
                       ("bad profile value", {"query": "loan", "profile": {"enterpriseType": "huge"}})]:
        r = api.search(req)
        check(r.get("contract") == "error", f"{label} -> error")
        check("message" in r["error"] and "code" in r["error"], f"{label}: shaped error")
    # "community" was a zero-coverage dimension before the derived-data repair
    # (applicability_matrix_catalog.json rebuild, search-index fix phase) --
    # SCH000218 (Stand-Up India) now carries real community=[SC,ST] structured
    # eligibility data, so "community" is a validated enum today (confirmed:
    # profile.community=SC now returns a real filtered result set, and an
    # invalid value like lowercase "sc" correctly 400s as INVALID_REQUEST
    # rather than warning). "district" remains genuinely zero-coverage, so the
    # probe moves there rather than asserting a state that's no longer true.
    r = api.search({"query": "loan", "profile": {"district": "IN-TN-CHN"}})
    check(any(w.get("code") == "FILTER_NO_COVERAGE" for w in r["warnings"]),
          "zero-coverage profile dim warns rather than silently no-ops")


def measure_performance():
    section("performance (measured, not optimised)")
    t0 = time.time(); api = MssApiRC1(); load = time.time() - t0
    t0 = time.time(); api.search({"query": "collateral free loan"}); cold = time.time() - t0
    t0 = time.time()
    for _ in range(10):
        api.search({"query": "collateral free loan"})
    warm = (time.time() - t0) / 10
    t0 = time.time()
    for _ in range(50):
        api.resolver.resolve("SCH000001")
    resolve = (time.time() - t0) / 50
    t0 = time.time()
    api.search({"query": "loan", "filters": {"status": ["active"], "collateralRequired": False},
                "page": {"limit": 20}})
    filtered = time.time() - t0
    p = api.search({"query": "loan", "page": {"limit": 3}})
    t0 = time.time()
    api.search({"query": "loan", "page": {"limit": 3, "cursor": p["page"]["nextCursor"]}})
    paged = time.time() - t0
    perf = OrderedDict([
        ("catalogLoadSeconds", round(load, 4)),
        ("coldSearchSeconds", round(cold, 4)),
        ("warmSearchSeconds", round(warm, 4)),
        ("resolverLookupSeconds", round(resolve, 6)),
        ("filteredSearchSeconds", round(filtered, 4)),
        ("paginationSeconds", round(paged, 4)),
    ])
    for k, v in perf.items():
        print(f"  {k:26} {v}")
    json.dump(perf, open(os.path.join(CAT, "api_performance.json"), "w"), indent=2)
    return perf


def main():
    print("=" * 72)
    print("MSS API RC1 TEST SUITE")
    print("=" * 72)
    api = MssApiRC1()

    test_no_ranking_drift(api)
    test_valid_search(api)
    test_empty_search(api)
    test_filters(api)
    test_pagination(api)
    test_stale_cursor(api)
    test_sorting(api)
    test_missing_entity(api)
    test_resolver_traversal(api)
    test_financial_assistance(api)
    test_cluster_tax_privilege(api)
    test_localization(api)
    test_metadata_provenance(api)
    test_determinism(api)
    test_error_handling(api)
    perf = measure_performance()

    print("\n" + "=" * 72)
    print(f"{PASS} passed, {FAIL} failed")
    print("=" * 72)
    if FAILURES:
        for f in FAILURES:
            print("  FAILED:", f)
    json.dump({"passed": PASS, "failed": FAIL, "failures": FAILURES,
               "performance": perf},
              open(os.path.join(CAT, "api_test_results.json"), "w"), indent=2)
    if FAIL:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
