#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 -- build a complete TN booklet title index and cross-match
against all 217 scheme_catalog.json records. READ ONLY -- writes only
booklet_mapping.json (an audit artifact), never touches a catalog file.
"""
import json, re, os

CAT = os.path.dirname(os.path.abspath(__file__))
BOOKLET = os.path.join(os.path.dirname(CAT), "TN_Schemes_Booklet_2022_v10.md")

FILLER = {
    "illustrative business value chain", "skill and capacity building",
    "quality, research &", "common facility", "export support",
    "branding and market access", "encouraging entrepreneurship",
    "working capital management", "setting up/ expansion of enterprises",
    "table of contents", "annexure", "schemes of government of tamil nadu",
    "schemes of government of india", "compendium of schemes for msmes 2022",
    "important information",
}


def norm(s):
    s = s.lower()
    s = re.sub(r"[^a-z0-9 ]", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def tokens(s):
    stop = {"the", "of", "for", "a", "an", "and", "to", "in", "on", "scheme",
            "schemes", "msme", "msmes", "assistance", "support"}
    return set(t for t in norm(s).split() if t not in stop and len(t) > 2)


# ---- 1. extract booklet titles ----
text = open(BOOKLET, encoding="utf-8").read()
parts = re.split(r"^## Page (\d+)\n", text, flags=re.MULTILINE)
booklet_entries = []
for i in range(1, len(parts), 2):
    pnum = int(parts[i])
    content = parts[i + 1] if i + 1 < len(parts) else ""
    lines = [l.strip() for l in content.split("\n") if l.strip()]
    title_lines = []
    for l in lines[:5]:
        low = l.lower()
        if low.startswith("objective") or low.startswith("#") or low.startswith("key benefit"):
            break
        title_lines.append(l)
    title = " ".join(title_lines).strip()
    if not title or norm(title) in FILLER or any(f in norm(title) for f in FILLER):
        continue
    if len(title) < 4:
        continue
    booklet_entries.append({"page": pnum, "title": title})

# ---- 2. load scheme_catalog ----
sch = json.load(open(os.path.join(CAT, "scheme_catalog.json"), encoding="utf-8"))["data"]

# ---- 3. match ----
results = []
for r in sch:
    sid = r["identity"]["id"]
    name = r["identity"]["name"]
    ntok = tokens(name)
    best = None
    best_score = 0.0
    candidates = []
    for be in booklet_entries:
        btok = tokens(be["title"])
        if not ntok or not btok:
            continue
        overlap = len(ntok & btok)
        union = len(ntok | btok)
        score = overlap / union if union else 0
        # exact normalized match bonus
        if norm(name) == norm(be["title"]):
            score = 1.0
        if score > 0.3:
            candidates.append((score, be["page"], be["title"]))
    candidates.sort(key=lambda x: -x[0])
    if candidates:
        best_score, best_page, best_title = candidates[0]
    match_type = "none"
    if candidates:
        if best_score >= 0.95:
            match_type = "exact"
        elif best_score >= 0.5:
            match_type = "strong"
        else:
            match_type = "weak"
        if len(candidates) > 1 and candidates[1][0] >= best_score - 0.15:
            match_type = "ambiguous"
    results.append({
        "schemeId": sid, "name": name,
        "verificationStatus": r["verification"]["status"],
        "matchType": match_type,
        "candidates": [{"page": p, "title": t, "score": round(s, 3)} for s, p, t in candidates[:3]],
    })

with open(os.path.join(CAT, "booklet_mapping.json"), "w", encoding="utf-8") as f:
    json.dump({"booklet_entries": booklet_entries, "matches": results}, f, ensure_ascii=False, indent=2)

from collections import Counter
c = Counter(r["matchType"] for r in results)
print("Booklet entries found:", len(booklet_entries))
print("Match type counts:", dict(c))
print()
print("=== exact/strong matches still unverified/partially_verified ===")
for r in results:
    if r["matchType"] in ("exact", "strong") and r["verificationStatus"] in ("unverified", "partially_verified"):
        print(f"  {r['schemeId']:10} {r['name'][:55]:55} -> p.{r['candidates'][0]['page']:3} {r['candidates'][0]['title'][:45]} (score {r['candidates'][0]['score']})")
