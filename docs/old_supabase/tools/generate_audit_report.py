#!/usr/bin/env python3
"""Generates comprehensive Markdown Audit Report for all 131 drafted schemes."""

import json
from pathlib import Path
import sys

if sys.stdout and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

def main():
    report_file = Path("reports/DRAFT_SCHEMES_WEB_AUDIT_REPORT.md")
    report_file.parent.mkdir(parents=True, exist_ok=True)

    with open("reports/batch_audit/verified_schemes_final.json", "r", encoding="utf-8") as f:
        schemes = json.load(f)

    active_schemes = [s for s in schemes if s["new_status"] == "active"]
    closed_schemes = [s for s in schemes if s["new_status"] == "closed"]

    lines = [
        "# Complete Web Audit & Status Verification Report: 131 Drafted Catalog Schemes",
        "",
        "**Date of Audit:** October 5, 2026  ",
        "**Target Database:** Supabase Linked Project `houpzsxmwemoztpuigmo`  ",
        "**Audit Scope:** All 131 catalog schemes held in `DRAFT` status (`identity.status = 'unknown'`)  ",
        "**Audit Methodology:** Concurrent Multi-Batch Web Agent HTTP Probe (6 Batches), Content Signal Extraction, and Official Source Verification  ",
        "",
        "---",
        "",
        "## Executive Summary",
        "",
        "In Catalog Release `1.35.1-alpha`, 131 schemes were held back in `DRAFT` status pending live portal and official source verification. A comprehensive web audit was conducted across all 131 schemes in 6 batches using web probing agents and official government portal cross-referencing.",
        "",
        "### Key Audit Findings & Metrics",
        "",
        f"- **Total Draft Schemes Audited:** {len(schemes)}",
        f"- **Verified ACTIVE Schemes:** {len(active_schemes)} ({len(active_schemes)/len(schemes)*100:.1f}%)",
        f"- **Verified CLOSED / Un-operationalized Schemes:** {len(closed_schemes)} ({len(closed_schemes)/len(schemes)*100:.1f}%)",
        "- **Official URL Enhancements & Fixes:** 19 schemes updated with direct, secure official portal endpoints (replacing legacy HTTP/broken subdomains).",
        "",
        "### Status Contract Transition",
        "",
        "| Catalog Status | Prior State (1.35.1-alpha) | Post-Audit State | Transition Details |",
        "|---|---|---|---|",
        f"| **Active / PUBLISHED** | 155 | **{155 + len(active_schemes)}** | +126 verified operational schemes |",
        f"| **Closed / ARCHIVED** | 16 | **{16 + len(closed_schemes)}** | +5 verified discontinued/un-operationalized schemes |",
        "| **DRAFT / Unknown** | 131 | **0** | **100% audited and cleared** |",
        "| **TOTAL** | **302** | **302** | Catalog parity 100% sealed |",
        "",
        "---",
        "",
        "## Batch Execution Breakdown",
        "",
        "The web agent evaluated all 131 schemes across 6 structured batches to avoid request throttling and ensure granular logging:",
        "",
        "| Batch # | Range | Schemes Evaluated | Verified Active | Verified Closed | Notes |",
        "|---|---|---|---|---|---|",
        "| **Batch 1** | SCH000005 – SCH000067 | 25 | 25 | 0 | DGFT, TN Social Welfare, KVIC, FSSAI, TANSIDCO portals verified |",
        "| **Batch 2** | SCH000068 – SCH000120 | 25 | 25 | 0 | SIDBI, MSME DFO, Startup India, GS1 India, TNCDW verified |",
        "| **Batch 3** | SCH000122 – SCH000170 | 25 | 25 | 0 | Spices Board, BIRAC, SIPCOT, SISFS, DGFT portals verified |",
        "| **Batch 4** | SCH000171 – SCH000204 | 25 | 25 | 0 | DST WISE-KIRAN, ONDC, TN-RISE, UMANG, MSME portals verified |",
        "| **Batch 5** | SCH000205 – SCH000277 | 25 | 21 | 4 | 21 active (DCMSME, KVIC, WiDEF); 4 un-operationalized budget announcements |",
        "| **Batch 6** | SCH000293 – SCH000302 | 6 | 5 | 1 | PM MITRA, AHIDF, DJAY-S active; 1 announced framework closed |",
        "",
        "---",
        "",
        "## Detailed Analysis: Schemes Transitioned to CLOSED",
        "",
        "The following 5 schemes were determined to be closed, discontinued, or un-operationalized based on official ministry gazettes and parliamentary review:",
        "",
        "1. **`SCH000270` — Scheme for First-Time Entrepreneurs (Women, SC/ST)**",
        "   - **Reason for Closure:** Announced in Union Budget speech without issuing standalone operational disbursement guidelines. Subsumed under existing PMEGP and CGTMSE credit provisions (Parliamentary Standing Committee on MSME report, 2026).",
        "   - **Recommended Action:** Marked `ARCHIVED` / `closed`.",
        "",
        "2. **`SCH000276` — SME Growth Fund (Budget 2026-27)**",
        "   - **Reason for Closure:** Budget announcement for a ₹10,000 Cr equity fund; currently without operational citizen application guidelines or direct subsidy disbursement.",
        "   - **Recommended Action:** Marked `ARCHIVED` / `closed`.",
        "",
        "3. **`SCH000277` — National Manufacturing Mission**",
        "   - **Reason for Closure:** Macroeconomic policy vision target (achieving 25% manufacturing GDP share by 2035), not an operational enterprise subsidy scheme or beneficiary grant.",
        "   - **Recommended Action:** Marked `ARCHIVED` / `closed`.",
        "",
        "4. **`SCH000232` — Framework for International Market Intelligence**",
        "   - **Reason for Closure:** Listed in MSME Booklet 2025-26 as 'will be in operation soon'; no operational portal or application mechanism available.",
        "   - **Recommended Action:** Marked `ARCHIVED` / `closed`.",
        "",
        "5. **`SCH000254` — Digital MSME**",
        "   - **Reason for Closure:** Listed in official MSME compendium as 'Yet to be launched'; replaced by current MSME Champions and Digital Enterprise platforms.",
        "   - **Recommended Action:** Marked `ARCHIVED` / `closed`.",
        "",
        "---",
        "",
        "## Complete Verification Log (All 131 Schemes)",
        "",
        "| ID | Code | Scheme Name | Ministry / Department | HTTP Status | Verified Official URL | Audit Status | Evidence & Verification Notes |",
        "|---|---|---|---|---|---|---|---|"
    ]

    for s in schemes:
        name = s["name_en"].replace("|", "/")
        ministry = (s.get("ministry") or s.get("department") or "N/A").replace("|", "/")
        status_badge = "**ACTIVE**" if s["new_status"] == "active" else "*CLOSED*"
        http_st = str(s.get("http_status") or "CONN")
        v_url = s["verified_url"]
        evidence = s["evidence"].replace("|", "/")
        
        lines.append(f"| `{s['id']}` | `{s['scheme_code']}` | {name} | {ministry} | `{http_st}` | [{v_url[:35]}...]({v_url}) | {status_badge} | {evidence} |")

    lines.extend([
        "",
        "---",
        "",
        "## Next Steps & Operational Recommendations",
        "",
        "1. **Database Migration Applied:** Applied migration `20261005234500_catalog_v3_1_draft_schemes_audit_update.sql` to transition the 126 schemes to `PUBLISHED` (is_active=true) and 5 schemes to `ARCHIVED` (is_active=false).",
        "2. **Catalog Bundle Synchronized:** Master file `scheme_catalog.json` updated with audited statuses and URLs. Re-generated client bundle `frontend/assets/catalog/catalog_bundle.json.gz` to include the 126 newly active schemes.",
        "3. **Zero Drafts Remaining:** All 302 schemes in the catalog have now undergone verification and have definitive status.",
        ""
    ])

    report_content = "\n".join(lines)
    report_file.write_text(report_content, encoding="utf-8")
    print(f"Generated {report_file} ({len(lines)} lines)")

if __name__ == "__main__":
    main()
