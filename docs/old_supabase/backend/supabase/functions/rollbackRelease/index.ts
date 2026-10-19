// 1.5 (audit_fix.md): emergency rollback of the "current" catalog release.
// Flips admin.catalog_releases.is_current back to a specific, explicitly
// named prior release via public.mss_rollback_release() (an atomic,
// service-role-only RPC -- never an implicit "previous release"). Auth
// pattern matches v1/index.ts's POST /v1/cache-bust: present the service
// role key itself, since only trusted backend/admin callers should ever
// invoke this.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { buildCorsHeaders } from "../_shared/cors.ts";

function safeEqual(a: string, b: string): boolean {
  const encoder = new TextEncoder();
  const aBytes = encoder.encode(a);
  const bBytes = encoder.encode(b);
  if (aBytes.length !== bBytes.length) return false;
  let diff = 0;
  for (let i = 0; i < aBytes.length; i++) diff |= aBytes[i] ^ bBytes[i];
  return diff === 0;
}

serve(async (req: Request): Promise<Response> => {
  const corsHeaders = buildCorsHeaders(req);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "METHOD_NOT_ALLOWED" }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 405 },
    );
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SB_SECRET_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(
      JSON.stringify({ error: "Missing Supabase configuration environment variables" }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 },
    );
  }

  const authHeader = req.headers.get("authorization") ?? "";
  const apikeyHeader = req.headers.get("apikey") ?? "";
  const presentedToken = authHeader.replace(/^Bearer\s+/i, "");
  const authorized =
    safeEqual(presentedToken, serviceRoleKey) || safeEqual(apikeyHeader, serviceRoleKey);
  if (!authorized) {
    return new Response(
      JSON.stringify({ error: "UNAUTHORIZED", message: "Service role authorization required" }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 401 },
    );
  }

  let body: { releaseId?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "INVALID_JSON" }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 },
    );
  }

  const releaseId = body.releaseId;
  if (!releaseId || typeof releaseId !== "string") {
    return new Response(
      JSON.stringify({
        error: "MISSING_RELEASE_ID",
        message: "releaseId (admin.catalog_releases.id, a uuid) is required -- there is no implicit 'previous release'.",
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 },
    );
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const { data, error } = await supabase.rpc("mss_rollback_release", {
    target_release_id: releaseId,
  });

  if (error) {
    return new Response(
      JSON.stringify({ error: "ROLLBACK_FAILED", message: error.message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 422 },
    );
  }

  const row = Array.isArray(data) ? data[0] : data;
  return new Response(
    JSON.stringify({
      status: "ok",
      releaseId,
      releaseVersion: row?.release_version ?? null,
      publishedAt: row?.published_at ?? null,
    }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 },
  );
});
