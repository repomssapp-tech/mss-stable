// Tests for the RETIRED `search` endpoint.
//
// The previous suite here exercised an implementation that no longer exists:
// it mocked OpenAI embeddings and asserted 400/502 responses. That code was
// removed when the function's target RPC (search_schemes) was dropped as dead
// code in 20260818000000 -- every call was spending a real OpenAI embeddings
// request before failing at the RPC step. The function is now a deliberate
// 410 tombstone, kept deployed so an installed app build calling the old
// route gets "gone forever" rather than an ambiguous 404.
//
// These tests lock that contract. If this endpoint is ever removed outright,
// delete the function and this file together.
import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";

import handler from "./index.ts";

Deno.test("search - POST returns 410 GONE and points at the replacement", async () => {
  const res = await handler(
    new Request("http://localhost/search", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query: "textile loan" }),
    }),
  );

  assertEquals(res.status, 410);

  const body = await res.json();
  assertEquals(body.error, "GONE");
  assertEquals(body.message, "This endpoint is retired. Use POST /v1/search instead.");
});

Deno.test("search - is retired regardless of method", async () => {
  for (const method of ["GET", "POST", "PUT", "DELETE"]) {
    const res = await handler(new Request("http://localhost/search", { method }));
    assertEquals(res.status, 410, `${method} should be retired`);
    await res.body?.cancel();
  }
});

Deno.test("search - OPTIONS preflight still succeeds with CORS headers", async () => {
  const res = await handler(
    new Request("http://localhost/search", { method: "OPTIONS" }),
  );

  assertEquals(res.status, 200);
  // 3.1: no Origin header on the request (the Flutter app never sends one)
  // -> no Access-Control-Allow-Origin in the response. Not a wildcard.
  assertEquals(res.headers.get("Access-Control-Allow-Origin"), null);
  await res.body?.cancel();
});

Deno.test("search - reflects an allowlisted Origin", async () => {
  const res = await handler(
    new Request("http://localhost/search", {
      method: "OPTIONS",
      headers: { Origin: "http://localhost:3000" },
    }),
  );

  assertEquals(res.headers.get("Access-Control-Allow-Origin"), "http://localhost:3000");
  await res.body?.cancel();
});
