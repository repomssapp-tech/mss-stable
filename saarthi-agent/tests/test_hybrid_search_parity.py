"""1.2/1.3 (audit_fix.md): guards the shared ranking parameters and search
output against silent drift across the three engines (this file, Python;
search_engine.ts, TypeScript; hybrid_scheme_search.dart, Dart).

Two checks, mirroring search_engine_parity_test.ts and
search_taxonomy_parity_test.dart exactly:
 1. This engine's local copy of search_taxonomy.json is byte-identical to
    the canonical copy at backend/catalog/. Each engine keeps its own
    local copy (deployment-bundling constraints rule out a single shared
    file across all three), so nothing else catches a hand-edit to only
    one copy.
 2. Running the fixed query set from
    backend/catalog/search_parity_golden.json through HybridSearchEngine,
    built from this agent's own local scheme_catalog.json/search_index.json
    (kept in sync with the same catalog release the golden fixture's Dart
    run used), reproduces the exact recorded scheme-ID ordering and scores.
"""

from __future__ import annotations

import json
from pathlib import Path

from hybrid_search import HybridSearchEngine, SchemeEntry
from scheme_catalog import DEFAULT_CATALOG_PATH, DEFAULT_SEARCH_INDEX_PATH
from search_taxonomy import DEFAULT_TAXONOMY_PATH, SchemeSearchTaxonomy

REPO_ROOT = Path(__file__).resolve().parents[2]
CANONICAL_TAXONOMY_PATH = REPO_ROOT / "backend" / "catalog" / "search_taxonomy.json"
GOLDEN_FIXTURE_PATH = REPO_ROOT / "backend" / "catalog" / "search_parity_golden.json"


def test_local_search_taxonomy_matches_canonical_copy() -> None:
    canonical = CANONICAL_TAXONOMY_PATH.read_text(encoding="utf-8")
    local = DEFAULT_TAXONOMY_PATH.read_text(encoding="utf-8")
    assert local == canonical, (
        "saarthi-agent/data/search_taxonomy.json has drifted from "
        "backend/catalog/search_taxonomy.json (the canonical copy). Copy "
        "the canonical file over this one -- never hand-edit this copy "
        "directly."
    )


def test_query_expansions_match_frontend_query_expansion_json() -> None:
    canonical = json.loads(CANONICAL_TAXONOMY_PATH.read_text(encoding="utf-8"))
    dart_expansions_path = (
        REPO_ROOT / "frontend" / "assets" / "search" / "query_expansion.json"
    )
    dart_expansions = json.loads(dart_expansions_path.read_text(encoding="utf-8"))
    assert canonical["queryExpansions"] == dart_expansions, (
        "backend/catalog/search_taxonomy.json's queryExpansions has "
        "drifted from frontend/assets/search/query_expansion.json (the "
        "file hybrid_scheme_search.dart loads). This is the exact class "
        "of bug that made the TypeScript server silently miss the "
        "'tax'/'exemption' expansions Dart already had -- keep both in "
        "sync."
    )


def _build_entries() -> list[SchemeEntry]:
    payload = json.loads(DEFAULT_CATALOG_PATH.read_text(encoding="utf-8"))
    search_index_payload = json.loads(
        DEFAULT_SEARCH_INDEX_PATH.read_text(encoding="utf-8")
    )
    search_profile_by_id = {
        row["entityId"]: row
        for row in search_index_payload.get("data", [])
        if row.get("entityId")
    }
    entries = []
    for record in payload["data"]:
        identity = record.get("identity", {})
        record_id = str(identity.get("id", ""))
        entries.append(
            SchemeEntry(
                id=record_id,
                status=identity.get("status", "unknown"),
                name_en=identity.get("name", ""),
                raw=record,
                search_profile=search_profile_by_id.get(record_id, {}),
            )
        )
    return entries


def test_hybrid_search_engine_reproduces_golden_parity_fixture() -> None:
    golden = json.loads(GOLDEN_FIXTURE_PATH.read_text(encoding="utf-8"))
    entries = _build_entries()
    engine = HybridSearchEngine(entries, SchemeSearchTaxonomy())

    mismatches: list[str] = []
    for row in golden:
        query = row["query"]
        expected = row["results"]
        actual = engine.search(query, top_n=len(expected))

        actual_ids = [r.scheme_id for r in actual]
        expected_ids = [r["schemeId"] for r in expected]
        if actual_ids != expected_ids:
            mismatches.append(f'"{query}": expected {expected_ids}, got {actual_ids}')
            continue

        for i, (result, expected_row) in enumerate(zip(actual, expected)):
            if abs(result.score - expected_row["score"]) > 0.0001:
                mismatches.append(
                    f'"{query}" #{i} ({actual_ids[i]}): expected score '
                    f"{expected_row['score']}, got {result.score}"
                )

    assert not mismatches, (
        "HybridSearchEngine output diverged from the golden parity "
        "fixture:\n" + "\n".join(mismatches) + "\n\nIf this divergence is "
        "intentional (a deliberate ranking change), regenerate "
        "backend/catalog/search_parity_golden.json and re-verify the "
        "TypeScript and Dart engines still match it too."
    )
