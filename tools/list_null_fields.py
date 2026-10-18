#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from db_inspect import query

def main():
    sql = """
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
    rows = query(sql)
    print(f"Total schemes with at least one null field: {len(rows)}")
    
    summary_nulls = [r['entity_id'] for r in rows if r['null_summary']]
    benefits_nulls = [r['entity_id'] for r in rows if r['null_benefits']]
    eligibility_nulls = [r['entity_id'] for r in rows if r['null_eligibility']]
    application_nulls = [r['entity_id'] for r in rows if r['null_application']]

    print(f"\n1. summary is null ({len(summary_nulls)} schemes, expect 14):")
    print(", ".join(summary_nulls))

    print(f"\n2. benefits_text is null ({len(benefits_nulls)} schemes, expect 19):")
    print(", ".join(benefits_nulls))

    print(f"\n3. eligibility_text is null ({len(eligibility_nulls)} schemes, expect 9):")
    print(", ".join(eligibility_nulls))

    print(f"\n4. application_text is null ({len(application_nulls)} schemes, expect 29):")
    print(", ".join(application_nulls))

    total = len(summary_nulls) + len(benefits_nulls) + len(eligibility_nulls) + len(application_nulls)
    print(f"\nTotal null fields: {total} (expect 71: 14+19+9+29)")

if __name__ == "__main__":
    main()
