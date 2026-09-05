// This function's target RPC (recommend_schemes) was dropped as dead code in
// 20260818000000_restore_orphaned_rls_policies.sql -- it referenced a table
// the v2 schema rewrite removed, so every call here already failed after
// hitting the database. Retired outright. v1's GET /v1/schemes/{id} +
// client-side recommendation logic is the live replacement (see
// functions/v1/index.ts and frontend/lib/engine/recommendation_engine.dart).
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const handler = (req: Request): Response => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  return new Response(
    JSON.stringify({
      error: 'GONE',
      message: 'This endpoint is retired.',
    }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 410 }
  )
}

// Bind the port only when run as a program, never on import -- otherwise
// merely importing this module from a test claims port 8000.
if (import.meta.main) serve(handler)

export default handler
