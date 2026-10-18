#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase 2 priority 7 — knowledge_catalog.json.

A KNOWLEDGE ITEM is a piece of explanatory reference text that already exists,
carried over verbatim with its source. Nothing is written, summarised or
paraphrased here.

Sources and rules:
  K1  semantic document sections — a heading plus its body — from source
      documents that HAVE real section titles.
      Headings like "Page 1" are pagination, not article titles, and are
      skipped: they cannot be titled without inventing a title.
  K2  numbered policy-note sections ("1. Introduction", "2. Legal Framework")
      parsed from the CSR and TReDS notes, which use numbering rather than
      markdown headings.
  K3  glossary explainers built from common_catalog glossary terms, whose
      definitions are already authored reference text.
  K4  body text is copied VERBATIM. No summarisation, no rewriting.
  K5  every item cites its source document and section, and links to the
      catalog entities it explains where those links are explicit.

English only. localization.ta null by roadmap decision; schema unchanged.
"""
import json, os, re, hashlib
from collections import OrderedDict, Counter

SRC = "/sessions/practical-charming-hypatia/mnt/Plan"
CAT = os.path.join(SRC, "catalog")
AT = "2026-08-04T00:00:00Z"
SV = "1.0.0"
REL = "1.8.0-alpha"

PAGINATION = re.compile(r"^\s*(page|p\.?)\s*\d+\s*$", re.I)
MD_DOCS = ["MSME_funding_schemes.md", "msme-Scheme-booklet-Eng_2025-26.md",
           "TN_Schemes_Booklet_2022_v10.md"]
NOTE_DOCS = ["CSR_MSME_Policy_Note.md", "TReDS_Policy_Note.md"]
NOTE_SECTION = re.compile(r"^\s*(\d+)\.\s+([A-Z][^\n]{4,90})\s*$", re.M)

def load(f): return json.load(open(os.path.join(CAT, f), encoding="utf-8"))
def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
def clean(s): return re.sub(r"[ -⁯︀-️\U0001F000-\U0001FAFF]", "", s).strip()

def md_sections(path):
    """K1 — heading + body, skipping pagination headings."""
    txt = open(path, encoding="utf-8", errors="ignore").read()
    hits = list(re.finditer(r"^(#{1,4})\s+(.+)$", txt, re.M))
    out = []
    for i, m in enumerate(hits):
        title = clean(m.group(2))
        if not title or PAGINATION.match(title):
            continue
        end = hits[i + 1].start() if i + 1 < len(hits) else len(txt)
        body = txt[m.end():end].strip()
        body = re.sub(r"\n{3,}", "\n\n", body)
        if len(body) < 180:
            continue
        out.append((title, body, f"heading level {len(m.group(1))}"))
    return out

def note_sections(path):
    """K2 — numbered sections in the policy notes."""
    txt = open(path, encoding="utf-8", errors="ignore").read()
    hits = list(NOTE_SECTION.finditer(txt))
    out = []
    for i, m in enumerate(hits):
        end = hits[i + 1].start() if i + 1 < len(hits) else len(txt)
        body = txt[m.end():end].strip()
        if len(body) < 180:
            continue
        out.append((f"{m.group(1)}. {clean(m.group(2))}", body, "numbered section"))
    return out

def shell(kid, name, content, refs, miss, localizable, status="active"):
    return OrderedDict([
        ("identity", OrderedDict([
            ("id", kid), ("entityType", "knowledge_item"), ("code", None),
            ("legacyCodes", []), ("name", name), ("shortName", None), ("acronym", None),
            ("slug", re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")[:120] or kid.lower()),
            ("language", "en"), ("status", status)])),
        ("content", content),
        ("relationships", {"references": refs}),
        ("localization", {l: {k: (v if l == "en" else None) for k, v in localizable.items()}
                          for l in ("en", "ta", "hi")}),
        ("search", {"keywords": {"en": sorted({w for w in re.findall(r"[a-z]{4,}", name.lower())}),
                                 "ta": []},
                    "aliases": {"en": [], "ta": []}, "synonyms": [], "crossReferences": [],
                    "searchRank": None, "boostTerms": []}),
        ("ai", OrderedDict([("summary", None), ("sectionSummaries", {}),
                            ("generationMode", "extractive"), ("confidence", None),
                            ("generatedBy", None), ("generatedAt", None),
                            ("sourceFieldsUsed", []), ("reviewedBy", None),
                            ("reviewedAt", None), ("isApproved", False)])),
        ("verification", OrderedDict([
            ("status", "partially_verified"),
            ("statusText", f"Verbatim extract from {content['sourceDocument']}"),
            ("isVerified", False), ("verifiedAgainst", []), ("verifiedBy", None),
            ("verifiedAt", None), ("confidence", "medium"), ("researchStatus", None),
            ("notes", "Body text copied verbatim from the source document. Not "
                      "summarised, rewritten or condensed."),
            ("missingFields", miss), ("disputedFields", []), ("reviewDueOn", None)])),
        ("analytics", {"popularity": None, "viewCount": None, "saveCount": None,
                       "actionCount": None, "lastAggregatedAt": None}),
        ("metadata", OrderedDict([("createdAt", AT), ("updatedAt", AT),
                                  ("catalogVersion", REL), ("schemaVersion", SV),
                                  ("recordStatus", "published"), ("revision", 1)])),
        ("provenance", OrderedDict([
            ("defaultSourceTier", 3), ("primarySourceId", None),
            ("contributingSourceIds", []), ("extractionMethod", "automated"),
            ("extractedAt", AT), ("pipelineVersion", "knowledge-1.0.0"),
            ("fieldSources", []),
            ("translations", OrderedDict([("ta", OrderedDict([
                ("method", "none"), ("engine", None), ("status", "not_started"),
                ("dictionaryVersion", None), ("generatedAt", None), ("fieldMethods", {}),
                ("fieldsTranslated", 0), ("fieldsContextual", 0), ("fieldsPending", 1),
                ("isApproved", False), ("reviewRequired", True),
                ("note", "Localization deferred to a later phase; schema unchanged.")]))])),
            ("transformationNotes", [
                f"Extracted from {content['sourceDocument']} — {content['sourceSection']}",
                "Body copied verbatim; no summarisation (rule K4)",
                "English only; localization.ta intentionally null (roadmap Phase 5)"])])),
    ])

def main():
    recs, n = [], 0
    skipped_pagination = 0

    # ---- K1 / K2 document sections
    for fname in MD_DOCS + NOTE_DOCS:
        path = os.path.join(SRC, fname)
        if not os.path.exists(path):
            continue
        secs = md_sections(path) if fname in MD_DOCS else note_sections(path)
        if fname in MD_DOCS:
            txt = open(path, encoding="utf-8", errors="ignore").read()
            skipped_pagination += sum(1 for m in re.finditer(r"^#{1,4}\s+(.+)$", txt, re.M)
                                      if PAGINATION.match(clean(m.group(1))))
        for title, body, kind in secs:
            n += 1
            content = OrderedDict([
                ("itemType", "article"), ("category", "reference"),
                ("title", title), ("body", body), ("bodyFormat", "markdown"),
                ("wordCount", len(body.split())),
                ("sourceDocument", fname), ("sourceSection", f"{title} ({kind})"),
                ("explains", []), ("relatedEntityIds", []),
                ("author", None), ("publishedOn", None), ("url", None), ("faqs", []),
            ])
            miss = [{"field": f, "reason": "Not stated in the source document"}
                    for f in ("content.author", "content.publishedOn", "content.url",
                              "content.faqs")]
            recs.append(shell("KNOW%06d" % n, title, content, [], miss,
                              {"title": title, "body": body}))

    # ---- K3 glossary explainers
    common = load("common_catalog.json")["data"]
    for g in [r for r in common if r["content"]["termType"] == "glossary_term"]:
        desc = g["content"].get("description")
        if not desc:
            continue
        n += 1
        title = g["content"]["label"]
        content = OrderedDict([
            ("itemType", "definition"), ("category", "glossary"),
            ("title", title), ("body", desc), ("bodyFormat", "text"),
            ("wordCount", len(desc.split())),
            ("sourceDocument", "common_catalog.json"),
            ("sourceSection", f"glossary term {g['identity']['id']}"),
            ("explains", [g["identity"]["id"]]),
            ("relatedEntityIds", [g["identity"]["id"]]),
            ("author", None), ("publishedOn", None), ("url", None), ("faqs", []),
        ])
        refs = [{"entityId": g["identity"]["id"], "entityType": "common_term",
                 "relationType": "references", "role": None, "note": None}]
        miss = [{"field": f, "reason": "Not applicable to a glossary definition"}
                for f in ("content.author", "content.publishedOn", "content.url")]
        recs.append(shell("KNOW%06d" % n, title, content, refs, miss,
                          {"title": title, "body": desc}))

    cat = OrderedDict([
        ("metadata", OrderedDict([("catalogName", "knowledge"), ("schemaVersion", SV),
                                  ("catalogVersion", REL), ("generatedAt", AT),
                                  ("language", "en"), ("recordCount", len(recs)),
                                  ("checksum", "sha256:" + hashlib.sha256(canon(recs).encode()).hexdigest())])),
        ("data", recs)])
    json.dump(cat, open(os.path.join(CAT, "knowledge_catalog.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)

    stats = OrderedDict([
        ("generatedAt", AT), ("catalog", "knowledge_catalog.json"),
        ("dataSufficiency", "MODERATE — the two policy notes and the funding guide carry "
                            "real sectioned prose. The two scheme booklets are paginated "
                            "scans whose headings are page numbers, not article titles; "
                            "their body text is not titled and was not invented a title."),
        ("knowledgeItems", len(recs)),
        ("byType", dict(Counter(r["content"]["itemType"] for r in recs))),
        ("bySource", dict(Counter(r["content"]["sourceDocument"] for r in recs))),
        ("paginationHeadingsSkipped", skipped_pagination),
        ("totalWords", sum(r["content"]["wordCount"] for r in recs)),
        ("verbatimBodies", len(recs)), ("summarisedBodies", 0),
        ("tamilPopulated", 0), ("localizationStatus", "deferred to roadmap Phase 5"),
    ])
    json.dump(stats, open(os.path.join(CAT, "knowledge_statistics.json"), "w",
                          encoding="utf-8"), indent=2, ensure_ascii=False)
    for k, v in stats.items(): print(f"   {k:28} {v}")

if __name__ == "__main__":
    main()
