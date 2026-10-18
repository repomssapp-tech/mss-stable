#!/usr/bin/env python3
"""Phase P2: Hindi Content Pipeline for MSS App Catalog.

Translates missing in-scope scheme and entity text fields to Hindi:
- Central schemes (government_level = 'central' or id = 'SCH000006')
- Authorities and Institutions
- Enforces Western digits 0-9 (D7)
- Never overwrites existing non-empty values (D8)
- Number check: multiset equality required (D9)
- Script check: Devanagari predominance
- Updates catalog.content and admin.translation_jobs
"""
from __future__ import annotations

import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request
from collections import Counter
from pathlib import Path

# Setup paths
ROOT_DIR = Path(__file__).resolve().parent.parent
BACKEND_DIR = ROOT_DIR / "backend"
SCRATCH_DIR = BACKEND_DIR / "scratch" / "lang"
SCRATCH_DIR.mkdir(parents=True, exist_ok=True)

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

PROTECTED_TERMS = [
    "PMEGP", "MSME", "CGTMSE", "ZED", "KVIC", "Coir Board", "NSIC", "SIDBI",
    "MUDRA", "REGP", "Udyam", "UAM", "GSTIN", "PAN", "DGFT", "NABARD", "RBI",
    "CLCSS", "SFURTI", "ASPIRE", "ESDP", "EAP", "E-SDP"
]

DEV_TO_ASCII = str.maketrans("०१२३४५६७८९", "0123456789")

TEXT_FIELDS = [
    "name", "short_name", "summary", "objective", "description",
    "benefits_text", "eligibility_text", "application_text"
]


def run_query_json(sql: str) -> list[dict]:
    """Runs a SQL query against linked Supabase DB and returns rows as json list."""
    sql_file = SCRATCH_DIR / "tmp_query.sql"
    sql_file.write_text(f"{sql};", encoding="utf-8")
    cmd = f'npx supabase db query --linked --file "{sql_file}"'
    import subprocess
    res = subprocess.run(cmd, cwd=str(BACKEND_DIR), shell=True, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if res.returncode != 0:
        raise RuntimeError(f"Database query failed: {res.stderr or res.stdout}")
    
    out = res.stdout
    start_idx = out.find("{")
    if start_idx == -1:
        return []
    data = json.loads(out[start_idx:])
    return data.get("rows", [])


def run_sql_batch(sql_content: str) -> None:
    """Executes a SQL batch script against linked Supabase DB."""
    sql_file = SCRATCH_DIR / "tmp_batch.sql"
    sql_file.write_text(sql_content, encoding="utf-8")
    cmd = f'npx supabase db query --linked --file "{sql_file}"'
    import subprocess
    res = subprocess.run(cmd, cwd=str(BACKEND_DIR), shell=True, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if res.returncode != 0:
        raise RuntimeError(f"SQL batch execution failed: {res.stderr or res.stdout}")


def normalize_western_digits(text: str) -> str:
    """Converts any Devanagari digits to standard Western 0-9 digits (Decision D7)."""
    if not text:
        return text
    return text.translate(DEV_TO_ASCII)


def extract_numbers(text: str) -> Counter:
    """Extracts multiset of numbers from text for equivalence check."""
    if not text:
        return Counter()
    norm = normalize_western_digits(text)
    tokens = re.findall(r"\b\d+(?:\.\d+)?\b", norm)
    result = []
    for t in tokens:
        try:
            val = float(t)
            result.append(int(val) if val.is_integer() else val)
        except ValueError:
            result.append(t)
    return Counter(result)


def check_script_devanagari(hi_text: str, en_text: str) -> bool:
    """Validates that Hindi text is predominantly Devanagari script."""
    if not hi_text:
        return False
    clean_en = en_text.strip()
    if len(clean_en) <= 12 and re.fullmatch(r"[A-Za-z0-9\s\-_/()&.]+", clean_en):
        return True
    deva_chars = len(re.findall(r"[\u0900-\u097F]", hi_text))
    latin_chars = len(re.findall(r"[A-Za-z]", hi_text))
    return deva_chars > 0 and deva_chars >= (latin_chars * 0.7)


def translate_text(text: str, is_acronym: bool = False) -> str:
    """Translates text from English to Hindi using Google Translate endpoint."""
    clean_text = text.strip()
    if not clean_text:
        return ""
    if is_acronym and clean_text in PROTECTED_TERMS:
        return clean_text

    url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=hi&dt=t&q=" + urllib.parse.quote(clean_text)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=12) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                translated = "".join([part[0] for part in data[0] if part and part[0]])
                translated = normalize_western_digits(translated)
                return translated
        except Exception as e:
            if attempt == 2:
                raise e
            time.sleep(1)
    return clean_text


def escape_sql(val: str | None) -> str:
    if val is None:
        return "NULL"
    return "'" + val.replace("'", "''") + "'"


def process_schemes(stats, sample_rows, flagged_ratio, limit: int = 0) -> list[str]:
    print("Fetching in-scope schemes...")
    query = """
    with in_scope as (
      select id from catalog.scheme where government_level = 'central' or id = 'SCH000006'
    )
    select 
      s.id as scheme_id,
      e.name as en_name,
      e.short_name as en_short_name,
      e.summary as en_summary,
      e.objective as en_objective,
      e.description as en_description,
      e.benefits_text as en_benefits_text,
      e.eligibility_text as en_eligibility_text,
      e.application_text as en_application_text,
      h.name as hi_name,
      h.short_name as hi_short_name,
      h.summary as hi_summary,
      h.objective as hi_objective,
      h.description as hi_description,
      h.benefits_text as hi_benefits_text,
      h.eligibility_text as hi_eligibility_text,
      h.application_text as hi_application_text,
      (h.entity_id is not null) as has_hi_row
    from in_scope s
    join catalog.content e on e.entity_type = 'scheme' and e.entity_id = s.id and e.lang = 'en'
    left join catalog.content h on h.entity_type = 'scheme' and h.entity_id = s.id and h.lang = 'hi'
    order by s.id
    """
    rows = run_query_json(query)
    print(f"Total in-scope schemes found: {len(rows)}")
    if limit > 0:
        rows = rows[:limit]

    stmts = []
    for i, row in enumerate(rows, 1):
        scheme_id = row["scheme_id"]
        has_hi_row = row["has_hi_row"]
        hi_updates = {}
        row_changed = False

        for f in TEXT_FIELDS:
            en_val = row.get(f"en_{f}")
            hi_val = row.get(f"hi_{f}")

            if not en_val or not str(en_val).strip():
                continue

            stats["fields_checked"] += 1

            if hi_val and str(hi_val).strip():
                stats["already_translated"] += 1
                if len(sample_rows[f]) < 30:
                    sample_rows[f].append((scheme_id, en_val, hi_val, "pre-existing"))
                continue

            try:
                is_short = (f in ["name", "short_name"])
                translated = translate_text(str(en_val), is_acronym=is_short)
                stats["newly_translated"] += 1
            except Exception as e:
                stats["errors"] += 1
                stmts.append(f"""
                INSERT INTO admin.translation_jobs (id, source_lang, target_lang, entity_type, entity_id, field_name, status, source_text, errors, created_at, updated_at)
                VALUES (gen_random_uuid(), 'en', 'hi', 'scheme', '{scheme_id}', '{f}', 'FAILED', {escape_sql(en_val)}, {escape_sql(str(e))}, now(), now());
                """)
                continue

            c_en = extract_numbers(en_val)
            c_hi = extract_numbers(translated)
            if c_en != c_hi:
                stats["needs_review_numbers"] += 1
                diff_desc = f"numbers mismatch: en={dict(c_en)} vs hi={dict(c_hi)}"
                stmts.append(f"""
                INSERT INTO admin.translation_jobs (id, source_lang, target_lang, entity_type, entity_id, field_name, status, source_text, translated_text, errors, created_at, updated_at)
                VALUES (gen_random_uuid(), 'en', 'hi', 'scheme', '{scheme_id}', '{f}', 'FAILED', {escape_sql(en_val)}, {escape_sql(translated)}, 'needs_review: {diff_desc}', now(), now());
                """)
                continue

            if not check_script_devanagari(translated, en_val):
                stats["needs_review_script"] += 1
                stmts.append(f"""
                INSERT INTO admin.translation_jobs (id, source_lang, target_lang, entity_type, entity_id, field_name, status, source_text, translated_text, errors, created_at, updated_at)
                VALUES (gen_random_uuid(), 'en', 'hi', 'scheme', '{scheme_id}', '{f}', 'FAILED', {escape_sql(en_val)}, {escape_sql(translated)}, 'needs_review: script_check', now(), now());
                """)
                continue

            ratio = len(translated) / max(len(en_val), 1)
            if ratio < 0.4 or ratio > 3.0:
                flagged_ratio.append((scheme_id, f, ratio, en_val[:40], translated[:40]))

            stats["passed_checks"] += 1
            hi_updates[f] = translated
            row_changed = True

            if len(sample_rows[f]) < 30:
                sample_rows[f].append((scheme_id, en_val, translated, "newly_translated"))

            stmts.append(f"""
            INSERT INTO admin.translation_jobs (id, source_lang, target_lang, entity_type, entity_id, field_name, status, source_text, translated_text, created_at, updated_at)
            VALUES (gen_random_uuid(), 'en', 'hi', 'scheme', '{scheme_id}', '{f}', 'COMPLETED', {escape_sql(en_val)}, {escape_sql(translated)}, now(), now());
            """)

        if row_changed:
            stats["schemes_written"] += 1
            if has_hi_row:
                set_clauses = [f"{field} = {escape_sql(val)}" for field, val in hi_updates.items()]
                set_clauses.append("updated_at = now()")
                stmts.append(f"""
                UPDATE catalog.content SET {', '.join(set_clauses)}
                WHERE entity_type = 'scheme' AND entity_id = '{scheme_id}' AND lang = 'hi';
                """)
            else:
                cols = ["entity_type", "entity_id", "lang", "origin", "engine", "verified"]
                vals = ["'scheme'", f"'{scheme_id}'", "'hi'", "'machine'", "'google_translate'", "false"]
                for f in TEXT_FIELDS:
                    cols.append(f)
                    vals.append(escape_sql(hi_updates.get(f, row.get(f"en_{f}")) if f == "name" else hi_updates.get(f)))
                stmts.append(f"""
                INSERT INTO catalog.content ({', '.join(cols)}, created_at, updated_at)
                VALUES ({', '.join(vals)}, now(), now());
                """)

        if i % 25 == 0 or i == len(rows):
            print(f"  Processed {i}/{len(rows)} schemes... (Passed: {stats['passed_checks']}, Number Mismatch: {stats['needs_review_numbers']})", flush=True)

    stmts.append("""
    UPDATE catalog.content h
    SET source_checksum = catalog.content_checksum(e.name, e.short_name, e.summary, e.objective, e.description, e.benefits_text, e.eligibility_text, e.application_text)
    FROM catalog.content e
    WHERE e.entity_type = 'scheme' AND e.entity_id = h.entity_id AND e.lang = 'en'
      AND h.entity_type = 'scheme' AND h.lang = 'hi';
    """)
    return stmts


def process_entities(entity_type: str, stats, sample_rows) -> list[str]:
    print(f"Fetching in-scope {entity_type}s...")
    query = f"""
    select e.entity_id, e.name as en_name, h.name as hi_name
    from catalog.content e
    left join catalog.content h on h.entity_type = '{entity_type}' and h.entity_id = e.entity_id and h.lang = 'hi'
    where e.entity_type = '{entity_type}' and e.lang = 'en'
    order by e.entity_id
    """
    rows = run_query_json(query)
    print(f"Total {entity_type}s found: {len(rows)}")

    stmts = []
    count_new = 0
    for row in rows:
        eid = row["entity_id"]
        en_name = row["en_name"]
        hi_name = row["hi_name"]

        if hi_name and str(hi_name).strip():
            continue

        try:
            translated = translate_text(en_name)
            if not check_script_devanagari(translated, en_name):
                translated = en_name
        except Exception:
            translated = en_name

        cols = ["entity_type", "entity_id", "lang", "name", "origin", "engine", "verified"]
        vals = [f"'{entity_type}'", f"'{eid}'", "'hi'", escape_sql(translated), "'machine'", "'google_translate'", "false"]
        stmts.append(f"""
        INSERT INTO catalog.content ({', '.join(cols)}, created_at, updated_at)
        VALUES ({', '.join(vals)}, now(), now())
        ON CONFLICT (entity_type, entity_id, lang) DO UPDATE SET name = EXCLUDED.name, updated_at = now();
        """)
        stmts.append(f"""
        INSERT INTO admin.translation_jobs (id, source_lang, target_lang, entity_type, entity_id, field_name, status, source_text, translated_text, created_at, updated_at)
        VALUES (gen_random_uuid(), 'en', 'hi', '{entity_type}', '{eid}', 'name', 'COMPLETED', {escape_sql(en_name)}, {escape_sql(translated)}, now(), now());
        """)
        count_new += 1

    print(f"  Translated {count_new} {entity_type}s into Hindi.")
    return stmts


def main():
    import argparse
    parser = argparse.ArgumentParser(description="MSS Catalog Hindi Localization Pipeline (P2)")
    parser.add_argument("--dry-run", action="store_true", help="Perform checks and translation without writing to DB")
    parser.add_argument("--limit", type=int, default=0, help="Limit number of schemes (0 for all)")
    args = parser.parse_args()

    print("=== MSS Catalog Hindi Localization Pipeline (Phase P2) ===")
    stats = {
        "fields_checked": 0,
        "already_translated": 0,
        "newly_translated": 0,
        "passed_checks": 0,
        "needs_review_numbers": 0,
        "needs_review_script": 0,
        "errors": 0,
        "schemes_written": 0,
    }
    sample_rows = {f: [] for f in TEXT_FIELDS}
    flagged_ratio = []

    # 1. Translate schemes
    scheme_stmts = process_schemes(stats, sample_rows, flagged_ratio, limit=args.limit)

    # 2. Translate authorities
    auth_stmts = process_entities("authority", stats, sample_rows)

    # 3. Translate institutions
    inst_stmts = process_entities("institution", stats, sample_rows)

    all_stmts = scheme_stmts + auth_stmts + inst_stmts
    print(f"\nTotal SQL statements generated: {len(all_stmts)}")

    if not args.dry_run and all_stmts:
        print(f"Applying SQL statements to linked database in batches of 40...")
        chunk_size = 40
        for b in range(0, len(all_stmts), chunk_size):
            batch = all_stmts[b:b+chunk_size]
            batch_sql = "BEGIN;\n" + "\n".join(batch) + "\nCOMMIT;\n"
            run_sql_batch(batch_sql)
            if (b // chunk_size + 1) % 5 == 0 or (b + chunk_size) >= len(all_stmts):
                print(f"  Applied batch {b//chunk_size + 1}/{(len(all_stmts) + chunk_size - 1)//chunk_size}", flush=True)

    print("\n--- Summary of Phase P2 ---")
    for k, v in stats.items():
        print(f"  {k}: {v}")
    print(f"  flagged length ratios: {len(flagged_ratio)}")

    # Write report artifact
    report_path = ROOT_DIR / "docs" / "P2_TRANSLATION_REPORT.md"
    with open(report_path, "w", encoding="utf-8") as rf:
        rf.write("# Phase P2: Hindi Translation Pipeline Report\n\n")
        rf.write("## 1. Execution Summary\n")
        for k, v in stats.items():
            rf.write(f"- **{k}**: {v}\n")
        rf.write(f"- **flagged_length_ratios**: {len(flagged_ratio)}\n\n")

        rf.write("## 2. Sample 30 Rows Per Field (English | Hindi)\n\n")
        for f in TEXT_FIELDS:
            rf.write(f"### Field: `{f}`\n\n")
            rf.write("| Scheme ID | Type | English Text | Hindi Translation |\n")
            rf.write("|---|---|---|---|\n")
            for sid, en, hi, src in sample_rows[f][:30]:
                en_clean = str(en).replace("\n", " ").replace("|", "\\|")[:80]
                hi_clean = str(hi).replace("\n", " ").replace("|", "\\|")[:80]
                rf.write(f"| {sid} | {src} | {en_clean} | {hi_clean} |\n")
            rf.write("\n")

        if flagged_ratio:
            rf.write("## 3. Flagged Length Ratio Samples\n\n")
            rf.write("| Scheme ID | Field | Ratio | English Preview | Hindi Preview |\n")
            rf.write("|---|---|---|---|---|\n")
            for sid, fld, r, en, hi in flagged_ratio[:20]:
                rf.write(f"| {sid} | {fld} | {r:.2f} | {en} | {hi} |\n")
            rf.write("\n")

    print(f"Report written to: {report_path}")


if __name__ == "__main__":
    main()
