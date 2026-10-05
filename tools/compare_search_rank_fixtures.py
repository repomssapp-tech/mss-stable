import subprocess
import json
import gzip
import sys

def load_code_to_name():
    code_to_name = {}
    # From current HEAD bundle
    with gzip.open('frontend/assets/catalog/catalog_bundle.json.gz', 'rt', encoding='utf-8') as f:
        bundle = json.load(f)
    for s in bundle.get('scheme_catalog.json', {}).get('data', []):
        ident = s.get('identity', {})
        name = s.get('localization', {}).get('en', {}).get('name') or ident.get('name') or ident.get('id')
        sid = ident.get('id')
        code = ident.get('code')
        if sid: code_to_name[sid] = name
        if code: code_to_name[code] = name
        for leg in ident.get('legacyCodes', []):
            c = leg.get('code')
            if c: code_to_name[c] = name

    # From origin/main bundle for older schemes
    try:
        main_bundle_raw = subprocess.check_output(['git', 'show', 'origin/main:frontend/assets/catalog/catalog_bundle.json.gz'])
        import io
        with gzip.open(io.BytesIO(main_bundle_raw), 'rt', encoding='utf-8') as f:
            mb = json.load(f)
        for s in mb.get('scheme_catalog.json', {}).get('data', []):
            ident = s.get('identity', {})
            name = s.get('localization', {}).get('en', {}).get('name') or ident.get('name') or ident.get('id')
            sid = ident.get('id')
            code = ident.get('code')
            if sid and sid not in code_to_name: code_to_name[sid] = name
            if code and code not in code_to_name: code_to_name[code] = name
            for leg in ident.get('legacyCodes', []):
                c = leg.get('code')
                if c and c not in code_to_name: code_to_name[c] = name
    except Exception:
        pass
    return code_to_name

def main():
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
    code_to_name = load_code_to_name()
    def get_name(code):
        return code_to_name.get(code, code)

    main_raw = subprocess.check_output(['git', 'show', 'origin/main:frontend/test/fixtures/scheme_search_rank_stability_expected.json']).decode('utf-8')
    main_data = json.loads(main_raw)

    with open('frontend/test/fixtures/scheme_search_rank_stability_expected.json', 'r', encoding='utf-8') as f:
        head_data = json.load(f)

    all_queries = list(main_data.keys())
    flagged = []

    print(f"EVALUATING {len(all_queries)} SEARCH RANK STABILITY QUERIES (origin/main vs HEAD)\n")
    print(f"{'#':<4} {'STATUS':<8} {'QUERY':<40} {'ORIGIN/MAIN #1':<35} {'HEAD #1':<35}")
    print("-" * 125)

    for idx, q in enumerate(all_queries, 1):
        m_items = main_data.get(q, [])[:5]
        h_items = head_data.get(q, [])[:5]

        m_codes = [x['code'] for x in m_items]
        h_codes = [x['code'] for x in h_items]

        prev_1 = m_codes[0] if m_codes else "NONE"
        head_1 = h_codes[0] if h_codes else "NONE"

        prev_1_name = f"{get_name(prev_1)} ({prev_1})"
        head_1_name = f"{get_name(head_1)} ({head_1})"

        is_dropped = prev_1 != "NONE" and prev_1 not in h_codes
        status_str = "FLAGGED" if is_dropped else "OK"

        if is_dropped:
            flagged.append((idx, q, prev_1, m_items, h_items))

        q_trunc = (q[:37] + "...") if len(q) > 40 else q
        p1_trunc = (prev_1_name[:32] + "...") if len(prev_1_name) > 35 else prev_1_name
        h1_trunc = (head_1_name[:32] + "...") if len(head_1_name) > 35 else head_1_name

        print(f"{idx:<4} {status_str:<8} {q_trunc:<40} {p1_trunc:<35} {h1_trunc:<35}")

    lines = []
    lines.append(f"# Search Rank Stability Comparison: `origin/main` vs `HEAD`\n")
    lines.append(f"**Fixture File:** `frontend/test/fixtures/scheme_search_rank_stability_expected.json`  ")
    lines.append(f"**Total Queries Evaluated:** {len(all_queries)}  ")
    lines.append(f"**Maintained Previous #1 in Top-5:** {len(all_queries) - len(flagged)}  ")
    lines.append(f"**Flagged (Previous #1 Dropped from Top-5):** {len(flagged)}  \n")
    lines.append("---")
    lines.append("\n## 1. Summary of Flagged Queries\n")
    lines.append("Under **Decision D4**, 131 `DRAFT` schemes (including 44 Tamil Nadu state schemes) were excluded from the offline client bundle. Queries whose previous #1 was a draft scheme, or where a newly introduced/enriched active scheme ranked higher, are flagged below:\n")
    lines.append("| # | Query | Previous #1 (`origin/main`) | New #1 (`HEAD`) | Status |")
    lines.append("|:---|:---|:---|:---|:---:|")

    for idx, q, prev_1, m_items, h_items in flagged:
        head_1 = h_items[0]['code'] if h_items else "NONE"
        p1_name = f"{get_name(prev_1)} (`{prev_1}`)"
        h1_name = f"{get_name(head_1)} (`{head_1}`)"
        lines.append(f"| {idx} | {q} | {p1_name} | {h1_name} | **FLAGGED** |")

    lines.append("\n---\n")
    lines.append("## 2. Complete Side-by-Side Top-5 Results for All 234 Queries\n")

    for idx, q in enumerate(all_queries, 1):
        m_items = main_data.get(q, [])[:5]
        h_items = head_data.get(q, [])[:5]
        m_codes = [x['code'] for x in m_items]
        h_codes = [x['code'] for x in h_items]
        prev_1 = m_codes[0] if m_codes else "NONE"
        is_dropped = prev_1 != "NONE" and prev_1 not in h_codes
        flag_badge = " ⚠️ **[FLAGGED: PREV #1 DROPPED]**" if is_dropped else " ✅ **[MAINTAINED]**"

        lines.append(f"### Query {idx}: `{q}`{flag_badge}\n")
        lines.append("| Rank | `origin/main` Top 5 | `HEAD` Top 5 |")
        lines.append("|:---:|:---|:---|")
        for r in range(5):
            m_str = f"{get_name(m_items[r]['code'])} (`{m_items[r]['code']}`)" if r < len(m_items) else "-"
            h_str = f"{get_name(h_items[r]['code'])} (`{h_items[r]['code']}`)" if r < len(h_items) else "-"
            lines.append(f"| #{r+1} | {m_str} | {h_str} |")
        lines.append("")

    with open('reports/SEARCH_RANK_STABILITY_COMPARISON.md', 'w', encoding='utf-8') as out_f:
        out_f.write("\n".join(lines) + "\n")

    print(f"Comparison complete! Output saved to reports/SEARCH_RANK_STABILITY_COMPARISON.md")
    print(f"Total: {len(all_queries)} queries | Maintained: {len(all_queries) - len(flagged)} | Flagged: {len(flagged)}")

if __name__ == '__main__':
    main()
