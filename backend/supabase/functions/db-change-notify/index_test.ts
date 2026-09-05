import {
  assertEquals,
  assertMatch,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type BroadcastChannelLike,
  createDbChangeNotifyHandler,
  type SupabaseClientLike,
} from "./index.ts";

const environment: Record<string, string> = {
  SUPABASE_URL: "https://test.supabase.co",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

interface ChannelSpy {
  client: SupabaseClientLike;
  channelNames: string[];
  sent: Record<string, unknown>[];
  removed: number;
}

/**
 * Builds a stand-in Supabase client. `subscribeStatus` of null models a channel
 * that never reaches SUBSCRIBED, so the handler has to fall back to its timer.
 * The status is delivered on a microtask because the real client is async, and
 * the handler only assigns its timeout after `subscribe()` returns.
 */
function channelSpy(subscribeStatus: string | null = "SUBSCRIBED"): ChannelSpy {
  const spy: ChannelSpy = {
    client: null as unknown as SupabaseClientLike,
    channelNames: [],
    sent: [],
    removed: 0,
  };

  const channel: BroadcastChannelLike = {
    subscribe(callback) {
      if (subscribeStatus !== null) {
        queueMicrotask(() => {
          void callback(subscribeStatus);
        });
      }
      return channel;
    },
    send(message) {
      spy.sent.push(message);
      return Promise.resolve("ok");
    },
  };

  spy.client = {
    channel(name: string) {
      spy.channelNames.push(name);
      return channel;
    },
    removeChannel() {
      spy.removed += 1;
      return Promise.resolve("ok");
    },
  };

  return spy;
}

function notifyRequest(body?: unknown): Request {
  return new Request("http://localhost/db-change-notify", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: body === undefined ? "not-json" : JSON.stringify(body),
  });
}

Deno.test("db-change-notify answers CORS preflight without touching Supabase", async () => {
  const spy = channelSpy();
  const handler = createDbChangeNotifyHandler({
    getEnv: (name) => environment[name],
    createSupabaseClient: () => spy.client,
  });

  const response = await handler(
    new Request("http://localhost/db-change-notify", { method: "OPTIONS" }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.text(), "ok");
  // 3.1: no Origin header on the request (the Flutter app never sends one)
  // -> no Access-Control-Allow-Origin in the response. Not a wildcard.
  assertEquals(response.headers.get("Access-Control-Allow-Origin"), null);
  assertEquals(spy.channelNames.length, 0);
});

Deno.test("db-change-notify fails closed when Supabase configuration is absent", async () => {
  const spy = channelSpy();
  const handler = createDbChangeNotifyHandler({
    getEnv: () => undefined,
    createSupabaseClient: () => spy.client,
  });

  const response = await handler(notifyRequest({ table: "schemes" }));

  assertEquals(response.status, 500);
  assertEquals(await response.json(), {
    error: "Missing Supabase configuration environment variables",
  });
  assertEquals(spy.channelNames.length, 0);
});

Deno.test("db-change-notify falls back to the anon key when no service role key is set", async () => {
  const spy = channelSpy();
  let observedKey = "";
  const handler = createDbChangeNotifyHandler({
    getEnv: (name) =>
      ({
        SUPABASE_URL: "https://test.supabase.co",
        SUPABASE_ANON_KEY: "test-anon-key",
      })[name],
    createSupabaseClient: (_url, key) => {
      observedKey = key;
      return spy.client;
    },
  });

  const response = await handler(notifyRequest({ table: "schemes" }));

  assertEquals(response.status, 200);
  assertEquals(observedKey, "test-anon-key");
});

Deno.test("db-change-notify broadcasts the change on the catalog_sync channel", async () => {
  const spy = channelSpy();
  const handler = createDbChangeNotifyHandler({
    getEnv: (name) => environment[name],
    createSupabaseClient: () => spy.client,
  });

  const response = await handler(notifyRequest({
    table: "schemes",
    schema: "public",
    type: "INSERT",
    record: { id: "scheme-uuid" },
  }));

  assertEquals(response.status, 200);
  assertEquals(spy.channelNames, ["catalog_sync"]);
  assertEquals(spy.sent.length, 1);

  const message = spy.sent[0] as {
    type: string;
    event: string;
    payload: Record<string, unknown>;
  };
  assertEquals(message.type, "broadcast");
  assertEquals(message.event, "catalog_updated");
  assertEquals(message.payload.table, "schemes");
  assertEquals(message.payload.schema, "public");
  assertEquals(message.payload.eventType, "INSERT");
  assertEquals(message.payload.recordId, "scheme-uuid");
  assertMatch(
    String(message.payload.timestamp),
    /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/,
  );

  assertEquals(await response.json(), {
    success: true,
    message: "Realtime catalog_updated broadcast sent successfully",
    table: "schemes",
    schema: "public",
    eventType: "INSERT",
  });
  assertEquals(spy.removed, 1);
});

Deno.test("db-change-notify identifies a record by scheme_code when it has no id", async () => {
  const spy = channelSpy();
  const handler = createDbChangeNotifyHandler({
    getEnv: (name) => environment[name],
    createSupabaseClient: () => spy.client,
  });

  await handler(notifyRequest({
    table: "schemes",
    record: { scheme_code: "MSS-001" },
  }));

  const message = spy.sent[0] as { payload: Record<string, unknown> };
  assertEquals(message.payload.recordId, "MSS-001");
});

Deno.test("db-change-notify defaults every field when the body is unreadable", async () => {
  const spy = channelSpy();
  const handler = createDbChangeNotifyHandler({
    getEnv: (name) => environment[name],
    createSupabaseClient: () => spy.client,
  });

  const response = await handler(notifyRequest());

  assertEquals(response.status, 200);
  const message = spy.sent[0] as { payload: Record<string, unknown> };
  assertEquals(message.payload.table, "unknown");
  assertEquals(message.payload.schema, "public");
  assertEquals(message.payload.eventType, "UPDATE");
  assertEquals(message.payload.recordId, null);

  assertEquals(await response.json(), {
    success: true,
    message: "Realtime catalog_updated broadcast sent successfully",
    table: null,
    schema: null,
    eventType: null,
  });
});

Deno.test("db-change-notify gives up on a channel that never subscribes", async () => {
  const spy = channelSpy(null);
  const handler = createDbChangeNotifyHandler({
    getEnv: (name) => environment[name],
    createSupabaseClient: () => spy.client,
    subscribeTimeoutMs: 5,
  });

  const response = await handler(notifyRequest({ table: "schemes" }));

  assertEquals(response.status, 200);
  assertEquals(spy.sent.length, 0);
  assertEquals(spy.removed, 1);
});

Deno.test("db-change-notify reports a broadcast failure as a 500", async () => {
  const handler = createDbChangeNotifyHandler({
    getEnv: (name) => environment[name],
    createSupabaseClient: () => ({
      channel: () => {
        throw new Error("realtime unavailable");
      },
      removeChannel: () => undefined,
    }),
  });

  const response = await handler(notifyRequest({ table: "schemes" }));

  assertEquals(response.status, 500);
  assertEquals(await response.json(), { error: "realtime unavailable" });
});
