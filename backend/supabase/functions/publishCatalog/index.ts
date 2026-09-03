import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    // New secret API key first, legacy service-role var as migration fallback.
    // No anon/publishable fallback: this is a write/publish path and must never
    // run on a read-only key.
    const supabaseServiceKey = Deno.env.get('SUPABASE_SECRET_KEY') ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: "Missing Supabase configuration environment variables" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
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
    const errorMessage = error instanceof Error ? error.message : String(error);
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
    );
  }
});
