import json, sys
sys.stdout.reconfigure(encoding="utf-8")

before = json.load(open("benchmark_v1_results_PRE_D5.json", encoding="utf-8"))
after = json.load(open("benchmark_v1_results.json", encoding="utf-8"))

b = {r["queryId"]: r for r in before["results"]}
a = {r["queryId"]: r for r in after["results"]}

improved, regressed, unchanged_verdict, top1_changed = [], [], 0, []

for qid in b:
    rb, ra = b[qid], a[qid]
    vb = rb.get("top1Hit"), rb.get("top5Recall")
    va = ra.get("top1Hit"), ra.get("top5Recall")
    if vb != va:
        if (va[0] and not vb[0]) or (va[1] and not vb[1]):
            improved.append((qid, rb["query"], vb, va))
        elif (vb[0] and not va[0]) or (vb[1] and not va[1]):
            regressed.append((qid, rb["query"], vb, va))
    else:
        unchanged_verdict += 1
    if rb.get("top1") != ra.get("top1"):
        top1_changed.append((qid, rb["query"], rb.get("top1"), ra.get("top1")))

print(f"Unchanged verdict: {unchanged_verdict}/{len(b)}")
print(f"Improved: {len(improved)}")
for x in improved:
    print("  IMPROVED", x)
print(f"Regressed: {len(regressed)}")
for x in regressed:
    print("  REGRESSED", x)
print(f"\ntop1 changed (any reason): {len(top1_changed)}")
for x in top1_changed[:40]:
    print("  ", x)
