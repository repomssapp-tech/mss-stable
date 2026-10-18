#!/usr/bin/env python3
"""Generates SQL migration to apply audit status updates and URL corrections."""

import json
from pathlib import Path
import sys

if sys.stdout and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

def main():
    with open("reports/batch_audit/verified_schemes_final.json", "r", encoding="utf-8") as f:
        schemes = json.load(f)

    migration_file = Path("backend/supabase/migrations/20261005234500_catalog_v3_1_draft_schemes_audit_update.sql")

    lines = [
        "-- Migration: 20261005234500_catalog_v3_1_draft_schemes_audit_update.sql",
        "-- Purpose: Update status and verified URLs for all 131 drafted schemes based on web audit findings.",
        "-- Result: 126 schemes transitioned to PUBLISHED (active=true), 5 schemes transitioned to ARCHIVED (active=false).",
        "-- Zero DRAFT schemes remaining.",
        "",
        "BEGIN;",
        ""
    ]

    for s in schemes:
        sid = s["id"]
        status = s["db_status"]  # "PUBLISHED" or "ARCHIVED"
        is_active = "true" if s["is_active"] else "false"
        json_status = "active" if s["is_active"] else "closed"
        v_url = s["verified_url"].replace("'", "''")

        sql = f"""-- [{sid}] {s['name_en'][:40]} -> {status}
UPDATE catalog.scheme
SET
    status = '{status}',
    is_active = {is_active},
    scheme_url = '{v_url}',
    record_json = jsonb_set(
        jsonb_set(
            jsonb_set(
                record_json,
                '{{identity,status}}',
                '"{json_status}"'::jsonb
            ),
            '{{identity,is_active}}',
            '{is_active}'::jsonb
        ),
        '{{content,scheme_url}}',
        to_jsonb('{v_url}'::text)
    ),
    updated_at = NOW()
WHERE id = '{sid}';
"""
        lines.append(sql)

    lines.extend([
        "",
        "-- Verification assertion",
        "DO $$",
        "DECLARE",
        "    v_draft_count integer;",
        "    v_published_count integer;",
        "    v_archived_count integer;",
        "BEGIN",
        "    SELECT count(*) INTO v_draft_count FROM catalog.scheme WHERE status = 'DRAFT';",
        "    SELECT count(*) INTO v_published_count FROM catalog.scheme WHERE status = 'PUBLISHED';",
        "    SELECT count(*) INTO v_archived_count FROM catalog.scheme WHERE status = 'ARCHIVED';",
        "    IF v_draft_count > 0 THEN",
        "        RAISE EXCEPTION 'Audit update failure: % draft schemes still remaining', v_draft_count;",
        "    END IF;",
        "    RAISE NOTICE 'Audit update verified: PUBLISHED=%, ARCHIVED=%, DRAFT=%', v_published_count, v_archived_count, v_draft_count;",
        "END $$;",
        "",
        "COMMIT;",
        ""
    ])

    migration_file.write_text("\n".join(lines), encoding="utf-8")
    print(f"Generated migration {migration_file} ({len(lines)} lines)")

if __name__ == "__main__":
    main()
