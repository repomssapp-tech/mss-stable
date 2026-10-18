#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MSS Intelligence Benchmark V1 -- evaluation harness.

Runs benchmark_v1.json against the CURRENT engine and scores six dimensions.
Ranking weights are NOT touched -- this is the baseline measurement, and
tuning before measuring would destroy the baseline's meaning.

The scoring rule that matters most:

    DATA-GAP queries are scored SEPARATELY and never counted as ranking
    failures. If no textile scheme exists in the catalog, a textile query
    cannot be "ranked wrong" -- reporting it as a ranking failure would
    blame the engine for a data problem and send whoever reads this report
    to fix the wrong thing.
"""
import json, os, sys
from collections import OrderedDict, Counter

CAT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, CAT)
from mss_api import MssApi

TOP_N = 5


def evaluate():
    bench = json.load(open(os.path.join(CAT, "benchmark_v1.json"), encoding="utf-8"))
    api = MssApi()
    broad = set(bench["broadSchemes"])
    closed = {sid for sid, r in api.schemes.items()
              if r["identity"]["status"] == "closed"}

    rows = []
    for q in bench["queries"]:
        resp = api.search({"query": q["query"], "topN": TOP_N})
        results = resp.get("results", [])
        ids = [r["schemeId"] for r in results]
        expected, acceptable = set(q["expectedBest"]), set(q["acceptable"])
        good = expected | acceptable

        top1 = ids[0] if ids else None
        top1_hit = top1 in expected if expected else None
        top1_ok = top1 in good if good else None
        top5_hit = bool(expected & set(ids)) if expected else None

        # Generic domination: a broad scheme outranks every expected scheme.
        best_expected_rank = next((i for i, s in enumerate(ids) if s in expected), None)
        best_broad_rank = next((i for i, s in enumerate(ids) if s in broad), None)
        dominated = (expected and best_broad_rank is not None and
                     (best_expected_rank is None or best_broad_rank < best_expected_rank))

        # Closed-scheme leakage, measured on TWO axes.
        #
        # The first draft of this metric counted only "closed scheme WITH an
        # available apply action" and reported a reassuring 0. That was a
        # measurement bug: the apply-action guard works, so that number is
        # ALWAYS 0 by construction and measures nothing. Meanwhile 17 queries
        # were returning a defunct scheme at rank 1 and scoring PASS, because
        # a closed scheme still matches topically. Both axes are now reported.
        leaked_action = [r["schemeId"] for r in results
                         if r["schemeId"] in closed
                         and any(a["action"] == "apply_online" and a.get("available")
                                 for a in r.get("nextActions", []))]
        closed_in_top5 = [s for s in ids if s in closed]
        closed_at_top1 = top1 in closed if top1 else False

        # Explanation accuracy: every returned result must carry a non-empty
        # explanation AND at least one match reason. An unexplained result is
        # a failure regardless of whether it was relevant.
        unexplained = [r["schemeId"] for r in results
                       if not r.get("explanation") or not r.get("matchReasons")]

        if q["isDataGap"]:
            verdict, reason = "DATA_GAP", "No scheme for this domain exists in the catalog"
        elif not expected:
            verdict, reason = "UNSCORED", "Open-ended query with no grounded expectation"
        elif top1_ok:
            verdict, reason = "PASS", ""
        elif top5_hit:
            verdict = "PARTIAL"
            reason = f"Expected scheme present but not top-1 (rank {best_expected_rank + 1})"
        else:
            verdict = "FAIL"
            reason = ("Broad scheme dominated a specific need"
                      if dominated else "No expected scheme in top 5")

        rows.append(OrderedDict([
            ("queryId", q["queryId"]), ("level", q["level"]), ("query", q["query"]),
            ("isTrap", q["isTrap"]), ("isDataGap", q["isDataGap"]),
            ("top1", top1), ("top2", ids[1] if len(ids) > 1 else None),
            ("top5", ids),
            ("expectedCount", len(expected)),
            ("top1Hit", top1_hit), ("top1Acceptable", top1_ok), ("top5Recall", top5_hit),
            ("genericDominated", bool(dominated)),
            ("closedApplyLeakage", leaked_action),
            ("closedAtTop1", closed_at_top1),
            ("closedInTop5", closed_in_top5),
            ("unexplained", unexplained),
            ("verdict", verdict), ("failureReason", reason),
        ]))
    return bench, rows, api


def summarise(rows):
    scored = [r for r in rows if r["verdict"] in ("PASS", "PARTIAL", "FAIL")]
    gaps = [r for r in rows if r["verdict"] == "DATA_GAP"]
    unscored = [r for r in rows if r["verdict"] == "UNSCORED"]

    def pct(n, d):
        return f"{(100.0 * n / d):.1f}%" if d else "n/a"

    m = OrderedDict()
    m["totalQueries"] = len(rows)
    m["scored"] = len(scored)
    m["dataGap"] = len(gaps)
    m["unscored"] = len(unscored)
    m["top1Relevance"] = pct(sum(1 for r in scored if r["top1Acceptable"]), len(scored))
    m["top1Exact"] = pct(sum(1 for r in scored if r["top1Hit"]), len(scored))
    m["top5Recall"] = pct(sum(1 for r in scored if r["top5Recall"]), len(scored))
    m["genericDomination"] = pct(sum(1 for r in scored if r["genericDominated"]), len(scored))
    # Guard effectiveness (expected 0 -- the apply-action gate works).
    m["closedApplyLeakage"] = sum(len(r["closedApplyLeakage"]) for r in rows)
    # Ranking quality: a defunct scheme shown first is a bad answer even
    # without an apply button. This is the number that actually matters.
    m["closedAtTop1"] = f"{sum(1 for r in rows if r['closedAtTop1'])}/{len(rows)}"
    m["closedInTop5"] = f"{sum(1 for r in rows if r['closedInTop5'])}/{len(rows)}"
    m["unexplainedResults"] = sum(len(r["unexplained"]) for r in rows)
    traps = [r for r in rows if r["isTrap"]]
    trap_scored = [r for r in traps if r["verdict"] in ("PASS", "PARTIAL", "FAIL")]
    m["trapTotal"] = len(traps)
    m["trapDataGap"] = sum(1 for r in traps if r["isDataGap"])
    m["trapPass"] = pct(sum(1 for r in trap_scored if r["verdict"] == "PASS"), len(trap_scored))
    return m, scored, gaps, unscored


def main():
    bench, rows, api = evaluate()
    m, scored, gaps, unscored = summarise(rows)

    json.dump(OrderedDict([("benchmark", bench["benchmark"]),
                            ("metrics", m), ("results", rows)]),
              open(os.path.join(CAT, "benchmark_v1_results.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)

    print("=" * 72)
    print("MSS INTELLIGENCE BENCHMARK V1 -- BASELINE (no weight tuning)")
    print("=" * 72)
    for k, v in m.items():
        print(f"  {k:22} {v}")

    print("\n--- by level (scored only) ---")
    for lvl in [1, 2, 3, 4, 5, "TRAP"]:
        sub = [r for r in scored if r["level"] == lvl]
        if not sub:
            continue
        p = sum(1 for r in sub if r["verdict"] == "PASS")
        pa = sum(1 for r in sub if r["verdict"] == "PARTIAL")
        f = sum(1 for r in sub if r["verdict"] == "FAIL")
        dom = sum(1 for r in sub if r["genericDominated"])
        print(f"  L{lvl:<5} n={len(sub):3}  pass={p:3} partial={pa:3} fail={f:3}  "
              f"genericDominated={dom:3}")

    print("\n--- TRAP QUERIES (the ranking-bias test) ---")
    for r in [x for x in rows if x["isTrap"]]:
        tag = "DATA GAP" if r["isDataGap"] else r["verdict"]
        print(f"  [{tag:8}] {r['query'][:52]:54} top1={r['top1']}")
        if r["failureReason"]:
            print(f"             {r['failureReason']}")

    print("\n--- WORST FAILURES (generic domination) ---")
    dom = [r for r in scored if r["genericDominated"]][:10]
    for r in dom:
        print(f"  {r['queryId']} {r['query'][:46]:48} top1={r['top1']}")

    print("\nwritten: benchmark_v1_results.json")


if __name__ == "__main__":
    main()
