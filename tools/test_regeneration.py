#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from db_inspect import query

def main():
    print("Testing regeneration query dry-run...")
    # First inspect how many schemes currently have 'पीएम विश्वकर्मा' in record_json #> '{search,aliases,hi}'
    check_before = query("""
    select count(*) as cnt
    from catalog.scheme
    where record_json #> '{search,aliases,hi}' ? 'पीएम विश्वकर्मा'
      and id != 'SCH000124';
    """)
    print("Schemes with 'पीएम विश्वकर्मा' before in record_json (excluding SCH000124):", check_before)

if __name__ == "__main__":
    main()
