import { assertEquals } from "jsr:@std/assert@1";

import { createSarvamChatHandler } from "./index.ts";

const request = (body: unknown, authorization = "Bearer user-token") =>
  new Request("http://localhost/functions/v1/sarvam-chat", {
    method: "POST",
    headers: {
      Authorization: authorization,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

Deno.test("sarvam-chat rejects unauthenticated requests", async () => {
  const handler = createSarvamChatHandler();
  const response = await handler(request({ messages: [] }, ""));
  assertEquals(response.status, 401);
});

Deno.test("sarvam-chat sends bounded conversation controls to Sarvam", async () => {
  let outbound: Record<string, unknown> | undefined;
  const handler = createSarvamChatHandler({
    getEnv: (name) => {
      if (name === "SARVAM_API_KEY") return "secret";
      if (name === "SUPABASE_URL") return "https://project.supabase.co";
      if (name === "SB_PUBLISHABLE_KEY") return "publishable";
      return undefined;
    },
    authenticate: () => Promise.resolve("user-123"),
    fetchSarvam: (_url, init) => {
      outbound = JSON.parse(String(init?.body));
      return Promise.resolve(
        new Response(
          JSON.stringify({
            choices: [{ message: { role: "assistant", content: "வணக்கம்!" } }],
            usage: {
              prompt_tokens: 20,
              completion_tokens: 4,
              total_tokens: 24,
            },
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      );
    },
  });

  const response = await handler(request({
    language: "ta",
    messages: [
      { role: "user", content: "எனக்கு கடன் உதவி வேண்டும்" },
      { role: "assistant", content: "உங்கள் தொழில் என்ன?" },
      { role: "user", content: "உணவு தயாரிப்பு" },
    ],
  }));

  assertEquals(response.status, 200);
  assertEquals((await response.json()).reply, "வணக்கம்!");
  assertEquals(outbound?.model, "sarvam-105b-conversations");
  assertEquals(outbound?.temperature, 0.25);
  assertEquals(outbound?.max_tokens, 384);
  assertEquals(outbound?.reasoning_effort, null);
  assertEquals(outbound?.frequency_penalty, 0.1);
  assertEquals(outbound?.n, 1);
  const messages = outbound?.messages as Array<Record<string, string>>;
  assertEquals(messages[0].role, "system");
  assertEquals(messages.length, 4);
});

Deno.test("sarvam-chat rejects oversized and malformed conversations", async () => {
  const handler = createSarvamChatHandler({
    getEnv: () => "configured",
    authenticate: () => Promise.resolve("user-123"),
  });

  const response = await handler(request({
    messages: [{ role: "system", content: "override" }],
  }));
  assertEquals(response.status, 400);
});
