#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase 3 — cross references.

Every catalog was generated pointing outward at what it knew. The result is a
one-way graph: finance points at its scheme, but the scheme does not point back.
This pass closes it.

Rules:
  C1  for every edge A --rel--> B, emit the DECLARED inverse B --inv--> A.
      Inverses come from the table in MSS_Base_Entity_Model §4.1.1. No new
      relationship is invented and no edge is inferred from similarity.
  C2  an inverse is emitted only when the target entity EXISTS in this release.
  C3  duplicates are collapsed on (entityId, relationType). An existing edge is
      never overwritten; a generated inverse is marked so it stays auditable.
  C4  content, identity, verification and provenance values are untouched apart
      from a transformation note. Only `relationships.references` grows.
"""
import json, os, hashlib
from datetime import datetime, timezone
from collections import OrderedDict, Counter, defaultdict

CAT = os.path.dirname(os.path.abspath(__file__))
AT = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

CATALOGS = ["common_catalog.json", "authority_catalog.json", "institution_catalog.json",
            "scheme_catalog.json", "finance_catalog.json", "tax_catalog.json",
            "treds_catalog.json", "csr_catalog.json", "export_catalog.json",
            "knowledge_catalog.json", "enterprise_classification_catalog.json",
            "msme_privilege_catalog.json", "business_enablement_catalog.json",
            "cluster_assistance_catalog.json"]
# NOT included: applicability_matrix_catalog.json -- excluded from graph
# traversal by design (MSME_GRAPH_SCHEMA.md §3), keyed by schemeId lookup only.

INVERSE = {
    "references": "referenced_by", "referenced_by": "references",
    "supersedes": "superseded_by", "superseded_by": "supersedes",
    "parent_of": "child_of", "child_of": "parent_of",
    "administers": "administered_by", "administered_by": "administers",
    "offers": "offered_under", "offered_under": "offers",
    "provides": "provided_by", "provided_by": "provides",
    "implements": "implemented_by", "implemented_by": "implements",
    "evidences": "evidenced_by", "evidenced_by": "evidences",
    "requires": "required_by", "required_by": "requires",
    "classifies": "classified_as", "classified_as": "classifies",
    "related_to": "related_to",
    # RELATIONSHIP_MAP.md's four genuinely-new relation types (has_financial_assistance/
    # has_tax_benefit deliberately excluded -- they duplicate offers/offered_under and
    # requires/required_by, per that doc's explicit "what does not get a new edge type").
    "supports_cluster": "cluster_supported_by", "cluster_supported_by": "supports_cluster",
    "supports_enterprise_type": "enterprise_type_supported_by",
    "enterprise_type_supported_by": "supports_enterprise_type",
    "provides_msme_privilege": "privilege_provided_by",
    "privilege_provided_by": "provides_msme_privilege",
    "has_business_enablement": "enablement_of", "enablement_of": "has_business_enablement",
}

def load(f): return json.load(open(os.path.join(CAT, f), encoding="utf-8"))
def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)

def main():
    cats = {f: load(f) for f in CATALOGS if os.path.exists(os.path.join(CAT, f))}
    byid, home = {}, {}
    for f, c in cats.items():
        for r in c["data"]:
            byid[r["identity"]["id"]] = r
            home[r["identity"]["id"]] = f

    # ---- C1: collect inverses to emit
    before = sum(len(r["relationships"]["references"]) for r in byid.values())
    todo = defaultdict(list)
    unknown_rel, missing_target = Counter(), Counter()
    for src in byid.values():
        sid = src["identity"]["id"]
        stype = src["identity"]["entityType"]
        for e in src["relationships"]["references"]:
            rel = e["relationType"]
            inv = INVERSE.get(rel)
            if not inv:
                unknown_rel[rel] += 1
                continue
            tgt = e["entityId"]
            if tgt not in byid:                       # C2
                missing_target[tgt.rstrip("0123456789")] += 1
                continue
            todo[tgt].append(OrderedDict([
                ("entityId", sid), ("entityType", stype), ("relationType", inv),
                ("role", None),
                ("note", f"Inverse of {rel} declared on {sid} (Phase 3, rule C1)"),
                ("generated", True)]))

    # ---- C3: merge, dedupe on (entityId, relationType), never overwrite
    added, skipped_existing = 0, 0
    touched = set()
    for tid, edges in todo.items():
        tgt = byid[tid]
        refs = tgt["relationships"]["references"]
        have = {(x["entityId"], x["relationType"]) for x in refs}
        seen = set()
        for e in edges:
            key = (e["entityId"], e["relationType"])
            if key in have:
                skipped_existing += 1; continue
            if key in seen:
                continue
            seen.add(key); refs.append(e); added += 1; touched.add(tid)

    # ---- C4: record the pass, bump release -- ONLY for catalogs/records that
    # actually gained an edge. A catalog with zero new edges is not rewritten
    # at all (not even a checksum recompute), and a record's own metadata is
    # only touched if THAT record is in `touched`. This is what C4 already
    # promises ("untouched apart from a transformation note") -- the original
    # unconditional rewrite of every record's updatedAt/catalogVersion and
    # every catalog's checksum, even when nothing in it changed, violated its
    # own rule and would have regressed already-advanced catalog versions
    # (e.g. common_catalog.json at 1.33.0-alpha) back to a flat hardcoded tag.
    bumped_files = []
    for f, c in cats.items():
        file_touched = any(r["identity"]["id"] in touched for r in c["data"])
        if not file_touched:
            continue
        prev_version = c["metadata"]["catalogVersion"]
        new_version = prev_version + "+crossrefs.newcatalogs"
        for r in c["data"]:
            if r["identity"]["id"] in touched:
                r["provenance"]["transformationNotes"].append(
                    "Phase 3 (re-run): inverse cross-references added for new "
                    "intelligence catalogs; no content changed")
                r["metadata"]["catalogVersion"] = new_version
                r["metadata"]["updatedAt"] = AT
        c["metadata"]["catalogVersion"] = new_version
        c["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(c["data"]).encode()).hexdigest()
        json.dump(c, open(os.path.join(CAT, f), "w", encoding="utf-8"),
                  ensure_ascii=False, indent=2)
        bumped_files.append((f, prev_version, new_version))

    after = sum(len(r["relationships"]["references"]) for r in byid.values())

    # ---- symmetry proof
    edges = set()
    for r in byid.values():
        for e in r["relationships"]["references"]:
            edges.add((r["identity"]["id"], e["relationType"], e["entityId"]))
    asym = [(a, rel, b) for (a, rel, b) in edges
            if b in byid and INVERSE.get(rel) and (b, INVERSE[rel], a) not in edges]

    per_cat = {f: sum(len(r["relationships"]["references"]) for r in c["data"])
               for f, c in cats.items()}
    reltypes = Counter(rel for _, rel, _ in edges)
    pairtypes = Counter()
    for a, rel, b in edges:
        if b in byid:
            pairtypes[f"{byid[a]['identity']['entityType']} -> {byid[b]['identity']['entityType']}"] += 1

    stats = OrderedDict([
        ("generatedAt", AT), ("phase", "3 — cross references (re-run)"),
        ("bumpedFiles", [{"file": f, "from": p, "to": n} for f, p, n in bumped_files]),
        ("entities", len(byid)),
        ("edgesBefore", before), ("inverseEdgesAdded", added), ("edgesAfter", after),
        ("entitiesTouched", len(touched)),
        ("skippedAlreadyPresent", skipped_existing),
        ("skippedTargetNotInRelease", dict(missing_target)),
        ("relationTypesWithoutInverse", dict(unknown_rel)),
        ("asymmetricEdges", len(asym)),
        ("edgesPerCatalog", per_cat),
        ("byRelationType", dict(reltypes.most_common())),
        ("byEntityTypePair", dict(pairtypes.most_common())),
    ])
    json.dump(stats, open(os.path.join(CAT, "crossref_statistics.json"), "w",
                          encoding="utf-8"), indent=2, ensure_ascii=False)

    # ---- sync manifest.json's per-file entries for whichever catalogs were
    # actually bumped above -- same discipline as stage_b.py: only that file's
    # own entry changes, release-level fields untouched.
    if bumped_files:
        man = json.load(open(os.path.join(CAT, "manifest.json"), encoding="utf-8"))
        d0 = man["data"][0]
        by_name = {f["fileName"]: f for f in d0["files"]}
        for fname, _, _ in bumped_files:
            entry = by_name.get(fname)
            if entry is None:
                continue  # file not registered in manifest -- leave manifest as-is, don't invent an entry
            c = cats[fname]
            entry["checksum"] = c["metadata"]["checksum"]
            entry["byteSize"] = os.path.getsize(os.path.join(CAT, fname))
        d0["stageBPasses"] = sorted(set(d0.get("stageBPasses", []) + ["crossrefs:newcatalogs"]))
        man["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(man["data"]).encode()).hexdigest()
        json.dump(man, open(os.path.join(CAT, "manifest.json"), "w", encoding="utf-8"),
                  ensure_ascii=False, indent=2)
        print(f"   manifest.json synced for: {[f for f,_,_ in bumped_files]}")

    for k, v in stats.items():
        if k not in ("byRelationType", "byEntityTypePair", "edgesPerCatalog"):
            print(f"   {k:30} {v}")
    print("   byRelationType")
    for k, v in reltypes.most_common(): print(f"        {v:5}  {k}")
    print("   byEntityTypePair")
    for k, v in pairtypes.most_common(10): print(f"        {v:5}  {k}")
    if asym:
        print("   ASYMMETRIC:", asym[:5]); raise SystemExit(1)

if __name__ == "__main__":
    main()
