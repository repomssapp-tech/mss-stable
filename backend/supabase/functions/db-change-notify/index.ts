import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.39.0";

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

export interface BroadcastChannelLike {
  subscribe(callback: (status: string) => void | Promise<void>): unknown;
  send(message: Record<string, unknown>): Promise<unknown>;
}

export interface SupabaseClientLike {
  channel(name: string): BroadcastChannelLike;
  removeChannel(channel: BroadcastChannelLike): unknown;
}

export interface DbChangeNotifyOptions {
  getEnv?: (name: string) => string | undefined;
  createSupabaseClient?: (url: string, key: string) => SupabaseClientLike;
  subscribeTimeoutMs?: number;
}

export function createDbChangeNotifyHandler(options: DbChangeNotifyOptions = {}) {
  const getEnv = options.getEnv ?? ((name: string) => Deno.env.get(name));
  const createSupabaseClient = options.createSupabaseClient ??
    ((url: string, key: string) => createClient(url, key) as unknown as SupabaseClientLike);
  const subscribeTimeoutMs = options.subscribeTimeoutMs ?? 3000;

  return async (req: Request): Promise<Response> => {
    if (req.method === 'OPTIONS') {
      return new Response('ok', { headers: corsHeaders });
    }

    try {
      const supabaseUrl = getEnv('SUPABASE_URL');
      const supabaseServiceKey = getEnv('SUPABASE_SERVICE_ROLE_KEY') || getEnv('SUPABASE_ANON_KEY');

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

      const supabase = createSupabaseClient(supabaseUrl, supabaseServiceKey);
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
        }, subscribeTimeoutMs);
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
  };
}

serve(createDbChangeNotifyHandler());
