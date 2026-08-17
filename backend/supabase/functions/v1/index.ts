// MSS API gateway -- implements the /v1/* contract the Flutter client
// (MssApiClient) calls: GET /v1/meta, GET /v1/health, POST /v1/search,
// GET /v1/schemes/{id}, GET /v1/schemes/{id}/finance,
// GET /v1/finance-products[/{id}], GET /v1/clusters[/{id}],
// GET /v1/tax[/{id}], GET /v1/privileges[/{id}],
// GET /v1/relationships/{id}, GET /v1/localization/{id}.
//
// Deployed as a function literally named "v1" so that the client's hardcoded
// "/v1/meta" path, appended to a base URL of
// "https://<project>.supabase.co/functions/v1", resolves to
// ".../functions/v1/v1/meta" -- Supabase invokes the "v1" function with the
// request path "/v1/meta", which this router then matches on.
//
// All routes are ports of the tested Python reference implementation
// (Plan/catalog/hybrid_search.py, mss_api_rc1.py, intelligence_resolver.py).
// Search mirrors the already-validated Dart port at
// frontend/lib/services/hybrid_scheme_search.dart field-for-field (see
// search_engine.ts); the rest mirror mss_api_rc1.py's mapper functions (see
// api_mappers.ts). catalog.*/admin.* aren't exposed to PostgREST directly,
// so every route reads via public-schema security-definer RPC functions
// (see the 20260817*_*.sql migrations) rather than supabase-js's .schema()
// switching.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"
import { HybridSearchEngine, SchemeEntry } from "./search_engine.ts"
import {
  financeRecord,
  financeGapWarnings,
  clusterMap,
  taxMap,
  privilegeMap,
  localizationResponse,
  matchApplicability,
  PROFILE_DIMENSIONS,
  ProfileDimension,
} from "./api_mappers.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function getServiceClient(): SupabaseClient | null {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!supabaseUrl || !serviceRoleKey) return null
  return createClient(supabaseUrl, serviceRoleKey)
}

// Fetches every scheme + its search_index entry via the mss_search_data()
// RPC (public schema, security definer -- catalog.* itself isn't exposed to
// PostgREST) and builds the SchemeEntry[] the search engine needs.
async function loadSchemeEntries(supabase: SupabaseClient): Promise<SchemeEntry[]> {
  const { data, error } = await supabase.rpc('mss_search_data')
  if (error) throw new Error(`Failed to load search data: ${error.message}`)

  const entries: SchemeEntry[] = []
  for (const row of (data ?? []) as Array<{
    scheme_id: string
    name_en: string | null
    scheme_record: Record<string, unknown>
    search_record: Record<string, unknown> | null
  }>) {
    const raw = row.scheme_record
    const identity = (raw['identity'] as Record<string, unknown>) ?? {}
    entries.push({
      id: row.scheme_id,
      status: String(identity['status'] ?? 'unknown'),
      nameEn: row.name_en ?? String(identity['name'] ?? ''),
      raw,
      searchProfile: row.search_record ?? {},
    })
  }
  return entries
}

// Warm-isolate cache: rebuilding the search engine means re-fetching all
// ~219 scheme + search_index records from Postgres AND rebuilding the
// vocabulary/IDF index from scratch (O(entries * fields)) -- wasted work
// when repeated on every keystroke-submit within the same warm Deno
// isolate. Supabase Edge Functions keep an isolate alive across bursts of
// requests, so caching here turns "network fetch + rebuild index" into an
// in-memory hashmap lookup for every request after the first, cutting
// search latency without touching the ranking algorithm or its output.
// TTL-bounded (not indefinite) so an admin catalog edit is picked up
// within a few minutes without needing a manual cache-bust; a cold start
// (new isolate) always rebuilds fresh regardless of TTL.
let cachedEntries: SchemeEntry[] | null = null
let cachedEngine: HybridSearchEngine | null = null
let cacheLoadedAt = 0
const CACHE_TTL_MS = 5 * 60 * 1000

async function getSearchEngine(
  supabase: SupabaseClient
): Promise<{ engine: HybridSearchEngine; entries: SchemeEntry[] }> {
  const now = Date.now()
  if (cachedEngine && cachedEntries && now - cacheLoadedAt < CACHE_TTL_MS) {
    return { engine: cachedEngine, entries: cachedEntries }
  }
  const entries = await loadSchemeEntries(supabase)
  const engine = new HybridSearchEngine(entries)
  cachedEntries = entries
  cachedEngine = engine
  cacheLoadedAt = now
  return { engine, entries }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const url = new URL(req.url)
  // pathParts[0] is the function name ("v1"); the app's own "/v1/..." route
  // lives at pathParts[1] onward.
  const pathParts = url.pathname.split('/').filter(Boolean)
  const route = pathParts[1]
  const subRoute = pathParts[2]
  const subSubRoute = pathParts[3]

  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status,
    })

  if (route === 'health') {
    return json({ status: 'ok' })
  }

  if (route === 'meta') {
    try {
      const supabase = getServiceClient()
      if (!supabase) return json({ error: 'Supabase environment variables are missing' }, 500)

      const [metaRes, releaseRes] = await Promise.all([
        supabase.rpc('mss_catalog_meta'),
        supabase.rpc('mss_current_release'),
      ])
      if (metaRes.error) return json({ error: metaRes.error.message }, 500)

      const row = Array.isArray(metaRes.data) ? metaRes.data[0] : metaRes.data
      if (!row) return json({ error: 'No catalog data available' }, 503)

      const releaseRow = (releaseRes.data ?? [])[0] as
        | { release_version: string | null; package_sha256: string | null; schema_version: number | null; published_at: string | null }
        | undefined

      return json({
        // Live, always-current catalog.* row-checksum aggregate -- changes
        // the instant a row is edited in Studio. Answers "has the queryable
        // Supabase data changed since I last checked."
        catalogVersion: row.catalog_version,
        catalogChecksum: row.catalog_checksum,
        entityCounts: row.entity_counts ?? {},
        supportedLanguages: ['en', 'ta'],
        // Published release-artifact identity -- what the offline sync flow
        // (OFFLINE_CLOUD_SYNC_ARCHITECTURE.md) compares against. Deliberately
        // a different value computed a different way -- see
        // HASH_VERIFICATION_SPECIFICATION.md §2. Only present once a release
        // has actually been published to Storage.
        releaseVersion: releaseRow?.release_version ?? null,
        packageSha256: releaseRow?.package_sha256 ?? null,
        releaseSchemaVersion: releaseRow?.schema_version ?? null,
        releasePublishedAt: releaseRow?.published_at ?? null,
      })
    } catch (error) {
      return json({ error: (error as Error).message }, 500)
    }
  }

  if (route === 'search' && req.method === 'POST') {
    try {
      const supabase = getServiceClient()
      if (!supabase) return json({ error: 'Supabase environment variables are missing' }, 500)

      const body = await req.json().catch(() => ({}))
      const query = typeof body.query === 'string' ? body.query : ''
      if (!query.trim()) {
        return json({ error: 'INVALID_REQUEST', message: 'query is required' }, 400)
      }
      const page = body.page ?? {}
      const limit = typeof page.limit === 'number' ? Math.min(Math.max(page.limit, 1), 100) : 20

      const { engine, entries } = await getSearchEngine(supabase)
      const results = engine.search(query, limit)

      return json({
        query,
        results: results.map((r, i) => ({
          rank: i + 1,
          schemeId: r.schemeId,
          name: r.name,
          matchScore: r.score,
          score: r.score,
          matchReasons: r.reasons,
          explanation: {
            summary: r.reasons.length > 0 ? r.reasons.join('; ') : `${r.name} matched with no specific explainable signal.`,
          },
        })),
        metadata: { entityCounts: { scheme: entries.length } },
      })
    } catch (error) {
      return json({ error: 'INTERNAL_ERROR', message: (error as Error).message }, 500)
    }
  }

  // GET /v1/schemes/{id}/finance -- finance products linked to one scheme
  if (route === 'schemes' && subRoute && subSubRoute === 'finance' && req.method === 'GET') {
    try {
      const supabase = getServiceClient()
      if (!supabase) return json({ error: 'Supabase environment variables are missing' }, 500)

      const { data, error } = await supabase.rpc('mss_finance_by_scheme', { p_scheme_id: subRoute })
      if (error) return json({ error: 'INTERNAL_ERROR', message: error.message }, 500)

      const rows = (data ?? []) as Array<{ id: string; record_json: Record<string, unknown> }>
      const items = rows.map((r) => financeRecord(r.record_json))
      const warnings = financeGapWarnings(
        items.map((i) => ({ interestRate: i.interestRate, repaymentTenure: i.repaymentTenure, conditions: i.conditions }))
      )
      if (items.length === 0) {
        warnings.push({ type: 'data_gap', field: 'finance', message: 'No finance product is linked to this scheme.' })
      }
      return json({ schemeId: subRoute, count: items.length, items, warnings })
    } catch (error) {
      return json({ error: 'INTERNAL_ERROR', message: (error as Error).message }, 500)
    }
  }

  // GET /v1/schemes/{id} -- full scheme detail
  if (route === 'schemes' && subRoute && !subSubRoute && req.method === 'GET') {
    try {
      const supabase = getServiceClient()
      if (!supabase) return json({ error: 'Supabase environment variables are missing' }, 500)

      const { data, error } = await supabase.rpc('mss_scheme_detail', { p_scheme_id: subRoute })
      if (error) return json({ error: 'INTERNAL_ERROR', message: error.message }, 500)
      if (!data) return json({ error: 'UNKNOWN_SCHEME', message: `No scheme with id ${subRoute}` }, 404)

      return json({ ...(data as Record<string, unknown>), dataIntegrity: { missingReferences: [] } })
    } catch (error) {
      return json({ error: 'INTERNAL_ERROR', message: (error as Error).message }, 500)
    }
  }

  // GET /v1/finance-products[/{id}]
  if (route === 'finance-products' && req.method === 'GET') {
    try {
      const supabase = getServiceClient()
      if (!supabase) return json({ error: 'Supabase environment variables are missing' }, 500)

      const { data, error } = await supabase.rpc('mss_lookup_catalog', { p_catalog: 'finance' })
      if (error) return json({ error: 'INTERNAL_ERROR', message: error.message }, 500)
      const rows = (data ?? []) as Array<{ id: string; record_json: Record<string, unknown> }>

      if (subRoute) {
        const row = rows.find((r) => r.id === subRoute)
        if (!row) return json({ error: 'UNKNOWN_ENTITY', message: `No finance product '${subRoute}'` }, 404)
        const item = financeRecord(row.record_json)
        const warnings = financeGapWarnings([
          { interestRate: item.interestRate, repaymentTenure: item.repaymentTenure, conditions: item.conditions },
        ])
        return json({ ...item, warnings })
      }

      const items = rows.map((r) => financeRecord(r.record_json)).sort((a, b) => String(a.financeId).localeCompare(String(b.financeId)))
      const warnings = financeGapWarnings(
        items.map((i) => ({ interestRate: i.interestRate, repaymentTenure: i.repaymentTenure, conditions: i.conditions }))
      )
      return json({ total: items.length, items, warnings })
    } catch (error) {
      return json({ error: 'INTERNAL_ERROR', message: (error as Error).message }, 500)
    }
  }

  // GET /v1/clusters[/{id}], GET /v1/tax[/{id}], GET /v1/privileges[/{id}] --
  // same generic list/detail shape, different catalog + mapper.
  const genericListConfigs: Record<string, { catalog: string; mapper: (r: Record<string, unknown>) => Record<string, unknown>; idField: string }> = {
    clusters: { catalog: 'cluster_assistance', mapper: clusterMap, idField: 'clusterId' },
    tax: { catalog: 'tax', mapper: taxMap, idField: 'taxId' },
    privileges: { catalog: 'msme_privilege', mapper: privilegeMap, idField: 'privilegeId' },
  }
  if (route in genericListConfigs && req.method === 'GET') {
    try {
      const config = genericListConfigs[route]
      const supabase = getServiceClient()
      if (!supabase) return json({ error: 'Supabase environment variables are missing' }, 500)

      const { data, error } = await supabase.rpc('mss_lookup_catalog', { p_catalog: config.catalog })
      if (error) return json({ error: 'INTERNAL_ERROR', message: error.message }, 500)
      const rows = (data ?? []) as Array<{ id: string; record_json: Record<string, unknown> }>

      if (subRoute) {
        const row = rows.find((r) => r.id === subRoute)
        if (!row) return json({ error: 'UNKNOWN_ENTITY', message: `No ${config.catalog} '${subRoute}'` }, 404)
        return json(config.mapper(row.record_json))
      }

      const items = rows
        .map((r) => config.mapper(r.record_json))
        .sort((a, b) => String(a[config.idField]).localeCompare(String(b[config.idField])))
      const warnings: Record<string, unknown>[] = []
      if (items.length <= 3) {
        warnings.push({
          type: 'sparse_catalog',
          field: config.catalog,
          message: `This catalog holds only ${items.length} record(s); coverage is known to be incomplete. Absence of a record is a data gap, not a negative finding.`,
        })
      }
      return json({ total: items.length, items, warnings })
    } catch (error) {
      return json({ error: 'INTERNAL_ERROR', message: (error as Error).message }, 500)
    }
  }

  // GET /v1/relationships/{entityId}
  if (route === 'relationships' && subRoute && req.method === 'GET') {
    try {
      const supabase = getServiceClient()
      if (!supabase) return json({ error: 'Supabase environment variables are missing' }, 500)

      const entityRes = await supabase.rpc('mss_entity_record', { p_entity_id: subRoute })
      if (entityRes.error) return json({ error: 'INTERNAL_ERROR', message: entityRes.error.message }, 500)
      const entityRow = (entityRes.data ?? [])[0] as { entity_type: string; record_json: Record<string, unknown> } | undefined
      if (!entityRow) return json({ error: 'UNKNOWN_ENTITY', message: `No entity with id '${subRoute}'` }, 404)

      const edgesRes = await supabase.rpc('mss_relationships', { p_entity_id: subRoute })
      if (edgesRes.error) return json({ error: 'INTERNAL_ERROR', message: edgesRes.error.message }, 500)
      const edges = ((edgesRes.data ?? []) as Array<{
        target_id: string
        target_type: string | null
        target_name: string | null
        relationship_type: string
        generated: boolean
      }>).map((e) => ({
        targetId: e.target_id,
        targetType: e.target_type,
        targetName: e.target_name,
        relationType: e.relationship_type,
        direction: 'outbound',
        generated: e.generated,
        resolved: e.target_type !== null,
      }))
      const dangling = edges.filter((e) => !e.resolved).map((e) => e.targetId)
      const warnings: Record<string, unknown>[] = []
      if (dangling.length > 0) {
        warnings.push({ type: 'data_integrity', field: 'edges', message: `${dangling.length} edge(s) do not resolve.` })
      }

      return json({
        entityId: subRoute,
        entityType: entityRow.entity_type,
        edgeCount: edges.length,
        edges,
        traversable: ['finance', 'tax', 'treds', 'csr', 'authority', 'institution', 'export', 'cluster', 'privileges', 'enablement', 'knowledge'],
        dataIntegrity: { missingReferences: dangling },
        warnings,
      })
    } catch (error) {
      return json({ error: 'INTERNAL_ERROR', message: (error as Error).message }, 500)
    }
  }

  // POST /v1/eligibility -- port of IntelligenceResolver.match_applicability()
  if (route === 'eligibility' && req.method === 'POST') {
    try {
      const supabase = getServiceClient()
      if (!supabase) return json({ error: 'Supabase environment variables are missing' }, 500)

      const body = await req.json().catch(() => ({}))
      const rawProfile = body.profile
      if (!rawProfile || typeof rawProfile !== 'object' || Array.isArray(rawProfile)) {
        return json(
          {
            error: 'INVALID_REQUEST',
            message: 'profile is required and must contain at least one field.',
            field: 'profile',
            detail: `supported fields: ${PROFILE_DIMENSIONS.join(', ')}`,
          },
          400
        )
      }
      const unknownKeys = Object.keys(rawProfile).filter((k) => !(PROFILE_DIMENSIONS as readonly string[]).includes(k))
      if (unknownKeys.length > 0) {
        return json(
          {
            error: 'INVALID_REQUEST',
            message: `Unknown profile field(s): ${unknownKeys.join(', ')}.`,
            field: `profile.${unknownKeys[0]}`,
            detail: `supported fields: ${PROFILE_DIMENSIONS.join(', ')}`,
          },
          400
        )
      }
      const profile: Partial<Record<ProfileDimension, string>> = {}
      for (const dim of PROFILE_DIMENSIONS) {
        const v = rawProfile[dim]
        if (v == null) continue
        if (typeof v !== 'string') {
          return json({ error: 'INVALID_REQUEST', message: `profile.${dim} must be a string.`, field: `profile.${dim}` }, 400)
        }
        profile[dim] = v
      }
      if (Object.keys(profile).length === 0) {
        return json(
          {
            error: 'INVALID_REQUEST',
            message: 'profile is required and must contain at least one field.',
            field: 'profile',
            detail: `supported fields: ${PROFILE_DIMENSIONS.join(', ')}`,
          },
          400
        )
      }
      const onlyEligible = Boolean(body.onlyEligible)
      const limit = typeof body.limit === 'number' && body.limit >= 1 ? body.limit : null

      const [applicabilityRes, schemesRes] = await Promise.all([
        supabase.rpc('mss_lookup_catalog', { p_catalog: 'applicability_matrix' }),
        supabase.rpc('mss_search_data'),
      ])
      if (applicabilityRes.error) return json({ error: 'INTERNAL_ERROR', message: applicabilityRes.error.message }, 500)
      if (schemesRes.error) return json({ error: 'INTERNAL_ERROR', message: schemesRes.error.message }, 500)

      const nameByScheme = new Map<string, string>()
      for (const row of (schemesRes.data ?? []) as Array<{ scheme_id: string; name_en: string | null }>) {
        if (row.name_en) nameByScheme.set(row.scheme_id, row.name_en)
      }

      let matches = matchApplicability(
        profile,
        (applicabilityRes.data ?? []) as Array<{ record_json: Record<string, unknown> }>
      )
      if (onlyEligible) matches = matches.filter((m) => m.eligible)
      if (limit) matches = matches.slice(0, limit)

      const results = matches.map((m, i) => ({
        rank: i + 1,
        schemeId: m.schemeId,
        name: nameByScheme.get(m.schemeId) ?? null,
        eligible: m.eligible,
        matchedFacets: m.matchedFacets,
        neutralFacets: m.neutralFacets,
        excludedBy: m.excludedBy,
        excludedByAll: m.excludedByAll,
      }))

      return json({ profile, resultCount: results.length, results, warnings: [] })
    } catch (error) {
      return json({ error: 'INTERNAL_ERROR', message: (error as Error).message }, 500)
    }
  }

  // GET /v1/localization/{entityId}?lang=ta
  if (route === 'localization' && subRoute && req.method === 'GET') {
    try {
      const lang = (url.searchParams.get('lang') ?? 'ta') as 'en' | 'ta'
      if (lang !== 'en' && lang !== 'ta') {
        return json({ error: 'INVALID_REQUEST', message: `Unsupported lang '${lang}'; expected en or ta` }, 400)
      }
      const supabase = getServiceClient()
      if (!supabase) return json({ error: 'Supabase environment variables are missing' }, 500)

      const entityRes = await supabase.rpc('mss_entity_record', { p_entity_id: subRoute })
      if (entityRes.error) return json({ error: 'INTERNAL_ERROR', message: entityRes.error.message }, 500)
      const entityRow = (entityRes.data ?? [])[0] as { entity_type: string; record_json: Record<string, unknown> } | undefined
      if (!entityRow) return json({ error: 'UNKNOWN_ENTITY', message: `No entity with id '${subRoute}'` }, 404)

      const { data, warnings } = localizationResponse(subRoute, entityRow.entity_type, entityRow.record_json, lang)
      return json({ ...(data as Record<string, unknown>), warnings })
    } catch (error) {
      return json({ error: 'INTERNAL_ERROR', message: (error as Error).message }, 500)
    }
  }

  return json({ error: 'Route not found' }, 404)
})
