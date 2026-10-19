// 3.1 (audit_fix.md): every function shared a static `corsHeaders` literal
// with 'Access-Control-Allow-Origin': '*' -- any web origin could read a
// response. The Flutter app itself sends no Origin header at all (native
// HTTP clients don't), so it needs no entry here; this allowlist exists for
// legitimate web callers only. Reflect the request's Origin when it matches
// an allowed entry; otherwise omit Access-Control-Allow-Origin entirely --
// no CORS header is the safe default, not a wildcard.

const ALLOWED_ORIGINS: readonly string[] = [
  // Local development.
  "http://localhost:3000",
  "http://localhost:8080",
  "http://127.0.0.1:3000",
  "http://127.0.0.1:8080",
  // TODO(3.1): add the production web origin here once provided.
];

/**
 * Builds CORS headers for a response, reflecting `req`'s Origin only if it
 * is on the allowlist above. Always includes Allow-Headers so preflight
 * still succeeds for allowed origins; never adds Allow-Origin for a
 * disallowed or absent one.
 */
export function buildCorsHeaders(
  req: Request,
  extra: Record<string, string> = {},
): Record<string, string> {
  const headers: Record<string, string> = {
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    ...extra,
  };

  const origin = req.headers.get("origin");
  if (origin && ALLOWED_ORIGINS.includes(origin)) {
    headers["Access-Control-Allow-Origin"] = origin;
    headers["Vary"] = "Origin";
  }

  return headers;
}
