import csv

def main():
    with open('docs/backend/mss_scheme_data_v3_1/mss_scheme_data_v3_1/worklists/03_enrich_existing_map.csv', encoding='utf-8') as f:
        enrich = list(csv.DictReader(f))
    print(f"Total enrich rows: {len(enrich)}")
    for i, r in enumerate(enrich, 1):
        print(f"{i:2d}. {r['catalog_id']} -> {r['our_id']} ({r['our_status']}) : {r['catalog_name_en'][:45]}")

    with open('docs/backend/mss_scheme_data_v3_1/mss_scheme_data_v3_1/worklists/04_hindi_backfill.csv', encoding='utf-8') as f:
        hindi = list(csv.DictReader(f))
    print(f"\nTotal hindi rows: {len(hindi)}")

if __name__ == '__main__':
    main()
