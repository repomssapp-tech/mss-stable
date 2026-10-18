#!/usr/bin/env python3
"""High-performance batch tester and status verifier for drafted catalog schemes.

Features:
- Concurrent probing with ThreadPoolExecutor (max_workers=10)
- Browser User-Agent and relaxed SSL for government portals
- Content detection: portal title, closure/subsumption/active keywords
- Output saved per-batch in reports/batch_audit/
"""

import concurrent.futures
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import sys
import time
import urllib3
import requests

if sys.stdout and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9,hi;q=0.8,ta;q=0.7",
    "Connection": "close",
}

CLOSURE_SIGNALS = [
    "discontinued",
    "closed",
    "subsumed under",
    "subsumed into",
    "merged into pm vishwakarma",
    "merged with",
    "applications closed",
    "scheme closed",
    "no longer active",
    "withdrawn",
    "stopped",
    "archived",
]

ACTIVE_SIGNALS = [
    "apply online",
    "online application",
    "guidelines",
    "beneficiary",
    "financial year 2024-25",
    "financial year 2025-26",
    "fy 2024-25",
    "fy 2025-26",
    "login / register",
    "application status",
    "citizen login",
    "apply here",
    "scheme details",
]


def test_url(url: str, timeout: int = 7) -> dict:
    if not url:
        return {"reachable": False, "status_code": None, "error": "No URL provided"}
    
    url = url.strip()
    if not url.startswith("http://") and not url.startswith("https://"):
        url = "https://" + url

    try:
        resp = requests.get(
            url,
            headers=HEADERS,
            timeout=timeout,
            allow_redirects=True,
            verify=False,
            stream=True,
        )
        final_url = resp.url
        status_code = resp.status_code
        content_type = resp.headers.get("Content-Type", "")
        
        # Read up to 100KB for inspection
        content_chunks = []
        bytes_read = 0
        for chunk in resp.iter_content(chunk_size=16384):
            content_chunks.append(chunk)
            bytes_read += len(chunk)
            if bytes_read >= 100000:
                break
        raw_body = b"".join(content_chunks)
        text_body = raw_body.decode("utf-8", errors="replace")

        page_title = ""
        title_match = re.search(r"<title[^>]*>(.*?)</title>", text_body, re.IGNORECASE | re.DOTALL)
        if title_match:
            page_title = title_match.group(1).strip()
            page_title = re.sub(r"\s+", " ", page_title)

        stripped = re.sub(r"<[^>]+>", " ", text_body)
        lower_body = re.sub(r"\s+", " ", stripped).lower()

        found_closure = [sig for sig in CLOSURE_SIGNALS if sig in lower_body]
        found_active = [sig for sig in ACTIVE_SIGNALS if sig in lower_body]

        return {
            "reachable": status_code < 400,
            "status_code": status_code,
            "final_url": final_url,
            "page_title": page_title[:120],
            "content_length": bytes_read,
            "content_type": content_type,
            "closure_signals": found_closure,
            "active_signals": found_active,
            "error": None,
        }
    except requests.exceptions.SSLError as e:
        return {"reachable": False, "status_code": "SSL_ERROR", "error": str(e)[:100]}
    except requests.exceptions.ConnectionError as e:
        return {"reachable": False, "status_code": "CONN_ERROR", "error": str(e)[:100]}
    except requests.exceptions.Timeout:
        return {"reachable": False, "status_code": "TIMEOUT", "error": "Request timed out"}
    except Exception as e:
        return {"reachable": False, "status_code": "ERROR", "error": str(e)[:100]}


def test_scheme_record(scheme: dict) -> dict:
    scheme_id = scheme["id"]
    scheme_code = scheme.get("scheme_code")
    name_en = scheme.get("name_en")
    primary_url = scheme.get("scheme_url")

    primary_res = test_url(primary_url)

    # Test alternate url if primary failed or returned 404
    alt_urls = []
    sources = scheme.get("sources") or []
    if isinstance(sources, list):
        for s in sources:
            if isinstance(s, dict) and s.get("url") and s["url"] != primary_url:
                alt_urls.append(s["url"])

    alt_results = []
    if not primary_res["reachable"] and alt_urls:
        for aurl in alt_urls[:2]:
            alt_res = test_url(aurl)
            alt_results.append({"url": aurl, "result": alt_res})
            if alt_res["reachable"]:
                break

    # Determine recommended status based on probe findings
    is_live = primary_res["reachable"] or any(ar["result"]["reachable"] for ar in alt_results)
    closure_found = bool(primary_res.get("closure_signals"))
    
    if closure_found:
        verdict = "closed"
        reason = f"Closure keywords detected on portal: {primary_res.get('closure_signals')}"
    elif is_live:
        verdict = "active"
        portal_title = primary_res.get("page_title") or (alt_results[0]["result"].get("page_title") if alt_results else "")
        reason = f"Live official portal verified (HTTP {primary_res.get('status_code')}: {portal_title})"
    else:
        verdict = "requires_agent_search"
        reason = f"Endpoint unreachable ({primary_res.get('status_code')}: {primary_res.get('error')})"

    print(f"[{scheme_id}] {scheme_code} -> {verdict.upper()} ({reason[:65]})", flush=True)

    return {
        "id": scheme_id,
        "scheme_code": scheme_code,
        "name_en": name_en,
        "ministry": scheme.get("ministry"),
        "department": scheme.get("department"),
        "state": scheme.get("state"),
        "primary_url": primary_url,
        "primary_result": primary_res,
        "alt_results": alt_results,
        "provisional_status": verdict,
        "evidence_note": reason,
        "audited_at": datetime.now(timezone.utc).isoformat(),
    }


def run_batch(schemes: list, batch_idx: int, out_dir: Path) -> list:
    out_dir.mkdir(parents=True, exist_ok=True)
    batch_file = out_dir / f"batch_{batch_idx}_results.json"
    print(f"\n=======================================================", flush=True)
    print(f"Starting Batch {batch_idx}: {len(schemes)} schemes", flush=True)
    print(f"=======================================================", flush=True)

    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
        futures = {executor.submit(test_scheme_record, s): s for s in schemes}
        for future in concurrent.futures.as_completed(futures):
            try:
                res = future.result()
                results.append(res)
            except Exception as e:
                s = futures[future]
                print(f"Error testing {s.get('id')}: {e}", flush=True)

    # Sort by ID
    results.sort(key=lambda r: r["id"])

    with open(batch_file, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    print(f"Saved Batch {batch_idx} ({len(results)} results) to {batch_file}", flush=True)
    return results


def main():
    clean_path = Path("draft_schemes_clean.json")
    if not clean_path.exists():
        print("draft_schemes_clean.json missing!")
        sys.exit(1)

    with open(clean_path, "r", encoding="utf-8") as f:
        schemes = json.load(f)

    out_dir = Path("reports/batch_audit")
    batch_size = 25

    if len(sys.argv) > 1 and sys.argv[1].isdigit():
        target_b = int(sys.argv[1])
        start = (target_b - 1) * batch_size
        end = min(start + batch_size, len(schemes))
        run_batch(schemes[start:end], target_b, out_dir)
    else:
        # Run all batches sequentially
        total_batches = (len(schemes) + batch_size - 1) // batch_size
        all_results = []
        for b in range(1, total_batches + 1):
            start = (b - 1) * batch_size
            end = min(start + batch_size, len(schemes))
            b_res = run_batch(schemes[start:end], b, out_dir)
            all_results.extend(b_res)
            time.sleep(1)

        all_results.sort(key=lambda r: r["id"])
        full_file = out_dir / "all_131_schemes_audit_raw.json"
        with open(full_file, "w", encoding="utf-8") as f:
            json.dump(all_results, f, indent=2, ensure_ascii=False)
        print(f"\nALL 131 SCHEMES AUDITED! Full output: {full_file}", flush=True)


if __name__ == "__main__":
    main()
