// Tests for the RETIRED `recommend` endpoint.
//
// The previous suite here asserted UUID validation and recommend_schemes RPC
// failure handling -- behaviour of an implementation that no longer exists.
// Its target RPC was dropped as dead code in 20260818000000 because it
// referenced a table the v2 schema rewrite removed, so every call already
// failed at the database. Recommendation now runs on-device
// (frontend/lib/engine/recommendation_engine.dart).
//
// The function is kept deployed as a deliberate 410 tombstone so an installed
// app build calling the old route gets "gone forever" rather than an
// ambiguous 404. These tests lock that contract. If this endpoint is ever
// removed outright, delete the function and this file together.
import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";

import handler from "./index.ts";

Deno.test("recommend - POST returns 410 GONE", async () => {
  const res = await handler(
    new Request("http://localhost/recommend", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ startup_profile_id: "c4d0a1b2-3c4d-5e6f-7a8b-9c0d1e2f3a4b" }),
    }),
  );

  assertEquals(res.status, 410);

  const body = await res.json();
  assertEquals(body.error, "GONE");
  assertEquals(body.message, "This endpoint is retired.");
});

Deno.test("recommend - retired for every payload shape", async () => {
  // Previously this endpoint distinguished valid from invalid UUIDs. It no
  // longer inspects the body at all -- retirement is unconditional.
  for (const body of ['{"startup_profile_id":"invalid-uuid-1234"}', "{}"]) {
    const res = await handler(
      new Request("http://localhost/recommend", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body,
      }),
    );
    assertEquals(res.status, 410);
    await res.body?.cancel();
  }
});

Deno.test("recommend - OPTIONS preflight still succeeds with CORS headers", async () => {
  const res = await handler(
    new Request("http://localhost/recommend", { method: "OPTIONS" }),
  );

  assertEquals(res.status, 200);
  assertEquals(res.headers.get("Access-Control-Allow-Origin"), "*");
  await res.body?.cancel();
});
