import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.39.0";

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
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || Deno.env.get('SUPABASE_ANON_KEY');

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: "Missing Supabase configuration environment variables" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
      );
    }

    let payload: Record<string, any> = {};
    if (req.method === 'POST') {
      try {
        payload = await req.json();
      } catch (_e) {
        payload = {};
      }
    }

    const { table, schema, type, record } = payload;

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
                table: table ?? 'unknown',
                schema: schema ?? 'public',
                eventType: type ?? 'UPDATE',
                recordId: record?.id ?? record?.scheme_code ?? null,
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
        message: "Realtime catalog_updated broadcast sent successfully",
        table: table ?? null,
        schema: schema ?? null,
        eventType: type ?? null,
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
