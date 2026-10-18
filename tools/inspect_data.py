#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

# Add tools to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from db_inspect import query

def main():
    print("\n=== Checking admin.catalog_files permissions and existing RPCs ===")
    sql_perm = """
    select grantee, privilege_type 
    from information_schema.role_table_grants 
    where table_schema = 'admin' and table_name = 'catalog_files';
    """
    print("Grants on admin.catalog_files:", query(sql_perm))

    sql_rpcs = """
    select routine_name, routine_schema
    from information_schema.routines
    where routine_name like '%release%' or routine_name like '%catalog_file%';
    """
    print("Release-related routines:", query(sql_rpcs))
    
    sql1_all = """
    select entity_type, entity_id, lang, aliases 
    from catalog.content 
    where 'पीएम विश्वकर्मा' = ANY(aliases)
    order by entity_id
    """
    rows_content = query(sql1_all)
    print(f"Total rows in catalog.content with alias: {len(rows_content)}")
    print("All entity_ids with alias:", [r['entity_id'] for r in rows_content])
    non_124 = [r for r in rows_content if r['entity_id'] != 'SCH000124']
    print(f"Total rows excluding SCH000124: {len(non_124)}")
    print(f"Entity types in non_124: {set(r['entity_type'] for r in non_124)}")
    print(f"Sample entity_ids: {[r['entity_id'] for r in non_124[:10]]}")

    print("\n=== A.2: Checking hi rows whose name has no Devanagari ===")
    sql2 = """
    select entity_type, entity_id, name, origin, engine
    from catalog.content
    where lang = 'hi' and name !~ '[\\u0900-\\u097F]'
    order by entity_type, entity_id
    """
    rows_no_dev = query(sql2)
    print(f"Total hi rows whose name has no Devanagari: {len(rows_no_dev)}")
    by_type = {}
    for r in rows_no_dev:
        by_type.setdefault(r['entity_type'], []).append(r['entity_id'])
    print("\n=== Inspecting SCH000124 and SCH000220 record_json ===")
    sql_sample = """
    select id, 
           record_json #> '{localization,hi}' as hi_loc,
           record_json #> '{search,aliases,hi}' as hi_aliases
    from catalog.scheme
    where id in ('SCH000124', 'SCH000220')
    """
    for r in query(sql_sample):
        print("Scheme:", r['id'])
        print("  hi_loc:", r['hi_loc'])
        print("  hi_aliases:", r['hi_aliases'])

    print("\n=== A.3: Checking hi scheme rows with null fields ===")
    sql3 = """
    select entity_id, 
           (summary is null) as null_summary,
           (benefits_text is null) as null_benefits,
           (eligibility_text is null) as null_eligibility,
           (application_text is null) as null_application
    from catalog.content
    where entity_type = 'scheme' and lang = 'hi'
      and (summary is null or benefits_text is null or eligibility_text is null or application_text is null)
    order by entity_id
    """
    rows_nulls = query(sql3)
    null_s = sum(1 for r in rows_nulls if r['null_summary'])
    null_b = sum(1 for r in rows_nulls if r['null_benefits'])
    null_e = sum(1 for r in rows_nulls if r['null_eligibility'])
    null_a = sum(1 for r in rows_nulls if r['null_application'])
    total_null_fields = null_s + null_b + null_e + null_a
    print(f"Schemes with at least one null field: {len(rows_nulls)}")
    print(f"Counts: summary={null_s}, benefits_text={null_b}, eligibility_text={null_e}, application_text={null_a}")
    print(f"Total null fields: {total_null_fields}")

if __name__ == "__main__":
    main()
