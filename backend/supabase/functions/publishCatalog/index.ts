import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { timingSafeEqual } from "https://deno.land/std@0.168.0/crypto/timing_safe_equal.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function safeEqual(a: string, b: string): boolean {
  const encoder = new TextEncoder();
  const aBytes = encoder.encode(a);
  const bBytes = encoder.encode(b);
  // timingSafeEqual requires equal-length buffers; pad so a length mismatch
  // itself doesn't leak via an early-return branch.
  if (aBytes.length !== bBytes.length) {
    timingSafeEqual(aBytes, aBytes);
    return false;
  }
  return timingSafeEqual(aBytes, bBytes);
}

serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    // New secret API key first, legacy service-role var as migration fallback.
    // No anon/publishable fallback: this is a write/publish path and must never
    // run on a read-only key.
    const supabaseServiceKey = Deno.env.get('SB_SECRET_KEY') ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: "Missing Supabase configuration environment variables" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
      );
    }

    // This function is not gated by config.toml's [functions.*] verify_jwt
    // overrides, so it runs under the project default (verify_jwt = true) --
    // meaning any authenticated app user, not just an admin, could otherwise
    // trigger a service-role-backed realtime broadcast. Require presenting
    // the service-role key itself (same pattern as v1's /cache-bust route),
    // since only trusted backend/admin callers should ever invoke this.
    const authHeader = req.headers.get('authorization') ?? '';
    const apikeyHeader = req.headers.get('apikey') ?? '';
    const presentedToken = authHeader.replace(/^Bearer\s+/i, '');
    const authorized =
      safeEqual(presentedToken, supabaseServiceKey) || safeEqual(apikeyHeader, supabaseServiceKey);
    if (!authorized) {
      return new Response(
        JSON.stringify({ error: 'UNAUTHORIZED', message: 'Service role authorization required' }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 401 }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const channel = supabase.channel('catalog_sync');

    await new Promise<void>((resolve) => {
      let timer: number | undefined;

      channel.subscribe(async (status: string) => {
        if (status === 'SUBSCRIBED') {
          try {
            await channel.send({
              type: 'broadcast',
              event: 'catalog_updated',
              payload: {
                source: 'publishCatalog',
                timestamp: new Date().toISOString(),
              },
            });
          } finally {
            if (timer !== undefined) clearTimeout(timer);
            resolve();
          }
        }
      });

      timer = setTimeout(() => {
        resolve();
      }, 3000);
    });

    await supabase.removeChannel(channel);

    return new Response(
      JSON.stringify({
        success: true,
        message: "Catalog publication notification broadcasted successfully",
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (error: unknown) {
    console.error('publishCatalog error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal error publishing catalog notification' }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
    );
  }
});
