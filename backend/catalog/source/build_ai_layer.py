#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase 4 — AI layer.

Everything generated here lives in the `ai` block and NOWHERE else.

The single most important decision in this pass: computed similarity is NOT
written into `relationships.references`. That graph holds government fact —
who administers what, what a scheme offers. A "these two look alike" edge is a
computed opinion. Putting it in the same array would make an opinion
indistinguishable from a fact at read time. Similarity therefore lives in
`ai.relatedEntities`, clearly separated and clearly attributed.

Rules:
  A1  summaries are EXTRACTIVE: sentences already present in `content`, selected
      and concatenated. Nothing is composed, paraphrased or shortened.
  A2  similarity is computed from EXPLICIT shared attributes only — same
      authority, same scheme type, same benefit type, same beneficiary category,
      same state, same sector. Never from a hunch about wording.
  A3  every related entry carries `sharedFeatures`: the exact attributes that
      caused the match. A score with no visible reason is not shipped.
  A4  semantic tags come from EXACT matches against common_catalog vocabulary.
      No new tag vocabulary is invented.
  A5  NO recommendations are generated. A recommendation is a claim that a
      specific user qualifies; the catalog holds no user. The similarity graph
      is the input a client uses to recommend — it is not itself a recommendation.
  A6  every populated ai block carries generationMode, generatedBy, generatedAt,
      sourceFieldsUsed, and isApproved:false.
"""
import json, os, re, hashlib
from collections import OrderedDict, Counter, defaultdict

CAT = "/sessions/practical-charming-hypatia/mnt/Plan/catalog"
AT = "2026-08-04T00:00:00Z"
REL = "1.11.0-alpha"
ENGINE = "mss-ai-derive-1.0.0"
MAX_RELATED = 5
MIN_SCORE = 0.34

CATALOGS = ["common_catalog.json", "authority_catalog.json", "institution_catalog.json",
            "scheme_catalog.json", "finance_catalog.json", "tax_catalog.json",
            "treds_catalog.json", "csr_catalog.json", "export_catalog.json",
            "knowledge_catalog.json"]

def load(f): return json.load(open(os.path.join(CAT, f), encoding="utf-8"))
def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)

def sentences(t):
    if not t: return []
    return [s.strip() for s in re.split(r"(?<=[.;])\s+", str(t).strip()) if len(s.strip()) > 3]

def extract(*texts, limit=3):
    """A1 — verbatim sentences, in source order, deduped."""
    out, seen = [], set()
    for t in texts:
        for s in sentences(t):
            k = s.lower()
            if k in seen: continue
            seen.add(k); out.append(s)
            if len(out) >= limit: return " ".join(out)
    return " ".join(out) if out else None

# ---------------------------------------------------------------- features (A2)
def scheme_features(r):
    c, f = r["content"], set()
    g = c["classification"]["government"]
    for k in ("ministryId", "departmentId"):
        if g[k]: f.add(f"authority:{g[k]}")
    for a in g["implementingAgencyIds"]: f.add(f"agency:{a}")
    if g["level"]: f.add(f"level:{g['level']}")
    for s in g["states"]: f.add(f"state:{s}")
    if c["classification"]["schemeType"]: f.add(f"type:{c['classification']['schemeType']}")
    for b in c["benefits"]["benefitTypes"]: f.add(f"benefit:{b}")
    for s in c["targetBeneficiaries"].get("specialCategories") or []: f.add(f"beneficiary:{s}")
    for k in ("age", "gender", "enterprise", "businessStage", "specialCategory",
              "existingRegistration"):
        fac = c["eligibility"]["structured"].get(k) or {}
        if fac.get("applies") is True:
            for v in (fac.get("values") or fac.get("types") or fac.get("required") or []):
                f.add(f"elig:{k}:{v}")
    for d in c["requiredDocuments"]:
        if d.get("documentTypeId"): f.add(f"doc:{d['documentTypeId']}")
    return f

def generic_features(r):
    c, f = r["content"], set()
    for k in ("institutionType", "productType", "provisionKind", "entryKind",
              "instrumentType", "termType", "authorityType", "itemType", "category"):
        if c.get(k): f.add(f"{k}:{c[k]}")
    if c.get("governmentLevel"): f.add(f"level:{c['governmentLevel']}")
    j = c.get("jurisdiction") or {}
    if j.get("state"): f.add(f"state:{j['state']}")
    for s in (j.get("states") or []): f.add(f"state:{s}")
    if c.get("parentAuthorityId"): f.add(f"parent:{c['parentAuthorityId']}")
    if c.get("authorityId"): f.add(f"authority:{c['authorityId']}")
    if c.get("schemeId"): f.add(f"scheme:{c['schemeId']}")
    if c.get("productFamilyId"): f.add(f"family:{c['productFamilyId']}")
    if c.get("sourceDocument"): f.add(f"src:{c['sourceDocument']}")
    return f

def summarise(fname, r):
    """A1 — per-catalog extractive summary and section summaries."""
    c, used, sect = r["content"], [], {}
    if fname == "scheme_catalog.json":
        s = extract(c["overview"].get("summary"), c["benefits"].get("summary"))
        if c["overview"].get("summary"): used.append("content.overview.summary")
        if c["benefits"].get("summary"): used.append("content.benefits.summary")
        if c["eligibility"]["narrative"].get("criteria"):
            sect["eligibility"] = extract(c["eligibility"]["narrative"]["criteria"], limit=2)
            used.append("content.eligibility.narrative.criteria")
        if c["benefits"].get("summary"):
            sect["benefits"] = extract(c["benefits"]["summary"], limit=2)
        if c["requiredDocuments"]:
            names = [d["name"] for d in c["requiredDocuments"] if d.get("name")][:6]
            if names:
                sect["documents"] = "; ".join(names)
                used.append("content.requiredDocuments[].name")
        return s, sect, used
    for key in ("summary", "description", "body", "mandate", "guidance", "label"):
        if c.get(key):
            used.append(f"content.{key}")
            return extract(c[key]), sect, used
    return None, sect, used

def main():
    cats = {f: load(f) for f in CATALOGS if os.path.exists(os.path.join(CAT, f))}
    feats, meta = {}, {}
    for f, c in cats.items():
        for r in c["data"]:
            rid = r["identity"]["id"]
            feats[rid] = scheme_features(r) if f == "scheme_catalog.json" else generic_features(r)
            meta[rid] = (f, r["identity"]["entityType"], r["identity"]["name"])

    # ---- A2/A3 similarity within entity type, via inverted feature postings
    posting = defaultdict(set)
    for rid, fs in feats.items():
        for x in fs: posting[x].add(rid)
    related = {}
    for rid, fs in feats.items():
        if not fs: continue
        cand = Counter()
        for x in fs:
            if len(posting[x]) > 260:      # a feature shared by almost everything is noise
                continue
            for other in posting[x]:
                if other != rid and meta[other][1] == meta[rid][1]:
                    cand[other] += 1
        scored = []
        for other, _ in cand.most_common(60):
            inter = fs & feats[other]
            union = fs | feats[other]
            score = round(len(inter) / len(union), 3) if union else 0.0
            if score >= MIN_SCORE:
                scored.append(OrderedDict([
                    ("entityId", other), ("entityType", meta[other][1]),
                    ("name", meta[other][2]),
                    ("similarity", score),
                    ("sharedFeatures", sorted(inter)[:12]),
                    ("sharedFeatureCount", len(inter)),
                    ("basis", "explicit shared attributes (Jaccard); no text inference")]))
        scored.sort(key=lambda x: (-x["similarity"], x["entityId"]))
        related[rid] = scored[:MAX_RELATED]

    # ---- A4 semantic tags from vocabulary exact matches
    common = cats.get("common_catalog.json", {"data": []})["data"]
    vocab = {}
    for t in common:
        c = t["content"]
        if c["termType"] in ("scheme_type", "benefit_type", "loan_type", "beneficiary_type",
                             "enterprise_type", "business_stage", "document_type",
                             "registration_type", "tax_type"):
            for al in set(c["aliases"] + [c["label"], c["code"]]):
                if al and len(str(al)) > 3:
                    vocab.setdefault(str(al).strip().lower(),
                                     (t["identity"]["id"], c["code"], c["termType"]))

    stat = Counter()
    for f, c in cats.items():
        for r in c["data"]:
            rid = r["identity"]["id"]
            summary, sect, used = summarise(f, r)
            blob = " ".join(str(x) for x in [r["identity"]["name"], summary] if x).lower()
            tags = []
            for term, (cid, code, ttype) in vocab.items():
                if re.search(r"(?<![a-z])" + re.escape(term) + r"(?![a-z])", blob):
                    tags.append(OrderedDict([("termId", cid), ("code", code),
                                             ("termType", ttype), ("matchedOn", term)]))
            tags = sorted({t["termId"]: t for t in tags}.values(),
                          key=lambda x: x["termId"])[:12]

            populated = bool(summary or sect or tags or related.get(rid))
            ai = r["ai"]
            ai["summary"] = summary
            ai["sectionSummaries"] = sect
            ai["semanticTags"] = tags
            ai["relatedEntities"] = related.get(rid, [])
            ai["recommendations"] = []          # A5
            ai["recommendationsNote"] = ("Not generated. A recommendation asserts that a "
                                         "specific user qualifies; the catalog holds no "
                                         "user context. Clients derive these from "
                                         "relatedEntities plus their own user profile.")
            ai["generationMode"] = "extractive"
            ai["similarityMethod"] = "explicit-shared-attribute Jaccard"
            ai["generatedBy"] = ENGINE if populated else None
            ai["generatedAt"] = AT if populated else None
            ai["sourceFieldsUsed"] = used
            ai["confidence"] = None
            ai["isApproved"] = False
            ai["reviewRequired"] = True
            stat[f"{f}:summary"] += 1 if summary else 0
            stat[f"{f}:tags"] += len(tags)
            stat[f"{f}:related"] += len(related.get(rid, []))
            r["metadata"]["catalogVersion"] = REL
            r["metadata"]["updatedAt"] = AT
        c["metadata"]["catalogVersion"] = REL
        c["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(c["data"]).encode()).hexdigest()
        json.dump(c, open(os.path.join(CAT, f), "w", encoding="utf-8"),
                  ensure_ascii=False, indent=2)

    tot_rel = sum(len(v) for v in related.values())
    ents = sum(len(c["data"]) for c in cats.values())
    stats = OrderedDict([
        ("generatedAt", AT), ("phase", "4 — AI layer"), ("release", REL),
        ("entities", ents),
        ("summariesExtractive", sum(v for k, v in stat.items() if k.endswith(":summary"))),
        ("semanticTagsAssigned", sum(v for k, v in stat.items() if k.endswith(":tags"))),
        ("relatedEdges", tot_rel),
        ("entitiesWithRelated", sum(1 for v in related.values() if v)),
        ("avgRelatedPerEntity", round(tot_rel / ents, 2)),
        ("similarityMethod", "explicit-shared-attribute Jaccard, min score "
                             f"{MIN_SCORE}, max {MAX_RELATED} per entity"),
        ("everyRelatedHasEvidence", all(x["sharedFeatures"]
                                        for v in related.values() for x in v)),
        ("recommendationsGenerated", 0),
        ("recommendationsNote", "Deliberately none — requires user context the catalog "
                                "does not hold."),
        ("similarityInFactGraph", False),
        ("similarityNote", "Computed similarity is confined to ai.relatedEntities and is "
                           "never written into relationships.references."),
        ("aiApproved", 0), ("abstractiveSummaries", 0),
        ("perCatalog", {k: v for k, v in sorted(stat.items())}),
    ])
    json.dump(stats, open(os.path.join(CAT, "ai_statistics.json"), "w", encoding="utf-8"),
              indent=2, ensure_ascii=False)
    for k, v in stats.items():
        if k != "perCatalog": print(f"   {k:28} {v}")

if __name__ == "__main__":
    main()
