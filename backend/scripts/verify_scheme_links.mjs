#!/usr/bin/env node

/**
 * Scheme & Official Portal Link Health Checker
 * ─────────────────────────────────────────────
 * Validates availability and response status of external government portal URLs
 * referenced in the MSS App (e.g. e-Sevai, NSDL, UIDAI, Udyam, Startup India).
 *
 * Runs on native Node.js 20+ with zero external dependencies.
 */

import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Path to constants.dart
const constantsPath = resolve(__dirname, '../../frontend/lib/utils/constants.dart');

function extractDocumentLinks() {
  const content = readFileSync(constantsPath, 'utf8');
  const match = content.match(/static const Map<String, String> documentLinks = \{([\s\S]*?)\};/);
  if (!match) {
    console.error('Could not find documentLinks map in constants.dart');
    process.exit(1);
  }

  const linksBlock = match[1];
  const urlRegex = /'([^']+)':\s*'([^']+)'/g;
  const links = [];
  let m;
  while ((m = urlRegex.exec(linksBlock)) !== null) {
    links.push({ document: m[1], url: m[2] });
  }
  return links;
}

async function checkUrl(document, url) {
  const startTime = Date.now();
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 10000);

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      },
      signal: controller.signal,
      redirect: 'follow',
    });

    clearTimeout(timeoutId);
    const duration = Date.now() - startTime;

    return {
      document,
      url,
      status: response.status,
      statusText: response.statusText,
      ok: response.status >= 200 && response.status < 400,
      durationMs: duration,
    };
  } catch (error) {
    const duration = Date.now() - startTime;
    const causeMsg = error.cause ? ` (${error.cause.code || error.cause.message || error.cause})` : '';
    return {
      document,
      url,
      status: error.name === 'AbortError' ? 'TIMEOUT' : 'ERROR',
      statusText: `${error.message}${causeMsg}`,
      ok: false,
      durationMs: duration,
    };
  }
}

async function run() {
  console.log('─────────────────────────────────────────────────────────────────');
  console.log('🔍 MSS App: Verifying Government Portal & Document Links');
  console.log('─────────────────────────────────────────────────────────────────');

  const links = extractDocumentLinks();
  console.log(`Found ${links.length} portal endpoints in constants.dart.\n`);

  // Run checks with bounded concurrency (3 at a time)
  const results = [];
  for (let i = 0; i < links.length; i += 3) {
    const batch = links.slice(i, i + 3);
    const batchResults = await Promise.all(batch.map(item => checkUrl(item.document, item.url)));
    results.push(...batchResults);
  }

  let passed = 0;
  let failed = 0;

  for (const r of results) {
    const statusLabel = r.ok ? '✅ PASS' : (r.status === 403 || r.status === 401 ? '⚠️ SHIELDED' : '❌ FAIL');
    console.log(`${statusLabel} [${r.status}] (${r.durationMs}ms) - ${r.document}`);
    console.log(`   URL: ${r.url}`);
    if (!r.ok) {
      console.log(`   Reason: ${r.statusText}`);
    }
    if (r.ok || r.status === 403) {
      // 403 often indicates Cloudflare or WAF government anti-bot shields, but the URL is valid/reachable
      passed++;
    } else {
      failed++;
    }
  }

  console.log('\n─────────────────────────────────────────────────────────────────');
  console.log(`Health Check Complete: ${passed} reachable/shielded, ${failed} failed.`);
  console.log('─────────────────────────────────────────────────────────────────');

  if (failed > 3) {
    console.error('Too many broken portal URLs detected.');
    process.exit(1);
  }
}

run();
