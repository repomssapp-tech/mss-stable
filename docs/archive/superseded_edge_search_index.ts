// This function's target RPC (search_schemes) was dropped as dead code in
// 20260818000000_restore_orphaned_rls_policies.sql -- it referenced a table
// the v2 schema rewrite removed, so every call here already failed after
// hitting the database. Retired outright rather than kept alive with added
// rate limiting: it was previously spending a real OpenAI embeddings API
// call on every single request, unconditionally, before failing at the RPC
// step -- an unbounded-cost, zero-value code path. v1's POST /v1/search is
// the live, rate-limited replacement (see functions/v1/index.ts).
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { buildCorsHeaders } from "../_shared/cors.ts"

const handler = (req: Request): Response => {
  const corsHeaders = buildCorsHeaders(req)

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  return new Response(
    JSON.stringify({
      error: 'GONE',
      message: 'This endpoint is retired. Use POST /v1/search instead.',
    }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 410 }
  )
}

// Bind the port only when run as a program, never on import -- otherwise
// merely importing this module from a test claims port 8000.
if (import.meta.main) serve(handler)

export default handler
