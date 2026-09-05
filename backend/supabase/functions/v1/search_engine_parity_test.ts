// 1.2 (audit_fix.md): guards the shared ranking parameters and search
// output against silent drift across the three engines (this file,
// TypeScript; hybrid_scheme_search.dart, Dart; scheme_catalog.py, Python).
//
// Two checks:
//  1. This engine's local copy of search_taxonomy.json (in ../_shared/) is
//     byte-identical to the canonical copy at backend/catalog/. Each engine
//     keeps its own local copy (deployment-bundling constraints rule out a
//     single shared file across all three -- see the audit's fix-time
//     notes), so nothing else catches a hand-edit to only one copy.
//  2. Running the fixed query set from
//     backend/catalog/search_parity_golden.json through HybridSearchEngine,
//     built from the SAME real catalog data the golden fixture's Dart run
//     used (frontend/assets/catalog/catalog_bundle.json.gz -- catalog.scheme
//     and catalog.search_index's record_json columns are confirmed
//     byte-identical to this bundle's scheme_catalog.json / search_index.json
//     entries), reproduces the exact recorded scores.

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { HybridSearchEngine, type SchemeEntry } from "./search_engine.ts";

const REPO_ROOT = new URL("../../../../", import.meta.url);

async function readTextFile(relativePath: string): Promise<string> {
  return await Deno.readTextFile(new URL(relativePath, REPO_ROOT));
}

async function loadBundle(): Promise<Record<string, unknown>> {
  const bytes = await Deno.readFile(
    new URL("frontend/assets/catalog/catalog_bundle.json.gz", REPO_ROOT),
  );
  const stream = new Blob([bytes as BlobPart])
    .stream()
    .pipeThrough(new DecompressionStream("gzip"));
  const decompressed = await new Response(stream).text();
  return JSON.parse(decompressed);
}

function buildSchemeEntries(bundle: Record<string, unknown>): SchemeEntry[] {
  const schemeData =
    ((bundle["scheme_catalog.json"] as Record<string, unknown>)["data"] as
      Record<string, unknown>[]);
  const searchIndexData =
    ((bundle["search_index.json"] as Record<string, unknown>)["data"] as
      Record<string, unknown>[]);

  const searchProfileById = new Map<string, Record<string, unknown>>();
  for (const row of searchIndexData) {
    const entityId = row["entityId"] as string | undefined;
    if (entityId) searchProfileById.set(entityId, row);
  }

  return schemeData.map((record) => {
    const identity = record["identity"] as Record<string, unknown>;
    const id = identity["id"] as string;
    return {
      id,
      status: (identity["status"] as string) ?? "unknown",
      nameEn: (identity["name"] as string) ?? "",
      raw: record,
      searchProfile: searchProfileById.get(id) ?? {},
    };
  });
}

Deno.test("local search_taxonomy.json matches the canonical copy", async () => {
  const canonical = await readTextFile("backend/catalog/search_taxonomy.json");
  const local = await Deno.readTextFile(
    new URL("../_shared/search_taxonomy.json", import.meta.url),
  );
  assertEquals(
    local,
    canonical,
    "backend/supabase/functions/_shared/search_taxonomy.json has drifted " +
      "from backend/catalog/search_taxonomy.json (the canonical copy). " +
      "Copy the canonical file over this one -- never hand-edit this copy " +
      "directly.",
  );
});

Deno.test("queryExpansions matches frontend/assets/search/query_expansion.json", async () => {
  const canonical = await readTextFile("backend/catalog/search_taxonomy.json");
  const queryExpansions =
    (JSON.parse(canonical) as { queryExpansions: Record<string, string[]> })
      .queryExpansions;
  const dartExpansions = JSON.parse(
    await readTextFile("frontend/assets/search/query_expansion.json"),
  );
  assertEquals(
    queryExpansions,
    dartExpansions,
    "backend/catalog/search_taxonomy.json's queryExpansions has drifted " +
      "from frontend/assets/search/query_expansion.json (the file " +
      "hybrid_scheme_search.dart loads). This is the exact class of bug " +
      "that made the server silently miss the 'tax'/'exemption' " +
      "expansions Dart already had -- keep both in sync.",
  );
});

Deno.test("HybridSearchEngine reproduces the golden parity fixture", async () => {
  const golden = JSON.parse(
    await readTextFile("backend/catalog/search_parity_golden.json"),
  ) as Array<{ query: string; results: Array<{ schemeId: string; score: number }> }>;

  const bundle = await loadBundle();
  const entries = buildSchemeEntries(bundle);
  const engine = new HybridSearchEngine(entries);

  const mismatches: string[] = [];
  for (const row of golden) {
    const expected = row.results;
    const actual = engine.search(row.query, expected.length);

    const actualIds = actual.map((r) => r.schemeId);
    const expectedIds = expected.map((r) => r.schemeId);
    if (JSON.stringify(actualIds) !== JSON.stringify(expectedIds)) {
      mismatches.push(`"${row.query}": expected ${expectedIds}, got ${actualIds}`);
      continue;
    }

    for (let i = 0; i < expected.length; i++) {
      if (Math.abs(actual[i].score - expected[i].score) > 0.0001) {
        mismatches.push(
          `"${row.query}" #${i} (${actualIds[i]}): expected score ` +
            `${expected[i].score}, got ${actual[i].score}`,
        );
      }
    }
  }

  assertEquals(
    mismatches,
    [],
    "HybridSearchEngine output diverged from the golden parity fixture. " +
      "If this divergence is intentional (a deliberate ranking change), " +
      "regenerate backend/catalog/search_parity_golden.json and re-verify " +
      "the Dart and Python engines still match it too.",
  );
});
