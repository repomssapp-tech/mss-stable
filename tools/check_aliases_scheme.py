#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from db_inspect import query

def main():
    # Check schemes with search.aliases.hi that are not SCH000124
    sql = """
    select id, record_json #> '{search,aliases,hi}' as hi_aliases
    from catalog.scheme
    where jsonb_array_length(coalesce(record_json #> '{search,aliases,hi}', '[]'::jsonb)) > 0
    order by id
    """
    rows = query(sql)
    print(f"Schemes with non-empty search.aliases.hi: {len(rows)}")
    non_124 = [r for r in rows if r['id'] != 'SCH000124']
    print(f"Non-SCH000124 schemes with non-empty search.aliases.hi: {len(non_124)}")
    print(f"Sample: {[r['id'] for r in non_124[:10]]}")

if __name__ == "__main__":
    main()
