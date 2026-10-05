import sys, json, csv
sys.stdout.reconfigure(encoding='utf-8')

id_map_path = r'reports/id_map.csv'
source_path = r'docs/backend/mss_scheme_data_v3_1/mss_scheme_data_v3_1/data/new_schemes_2025_26.json'

id_to_v3 = {}
with open(id_map_path, 'r', encoding='utf-8') as f:
    for row in csv.DictReader(f):
        id_to_v3[row['allocated_catalog_id']] = row['v3_1_id']

with open(source_path, 'r', encoding='utf-8') as f:
    v3 = {s['id']: s for s in json.load(f)['schemes']}

def find_quote_verified(obj, path=''):
    res = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k == 'quote_verified' and v is False:
                res.append((path, obj))
            else:
                res.extend(find_quote_verified(v, f'{path}.{k}' if path else k))
    elif isinstance(obj, list):
        for idx, item in enumerate(obj):
            res.extend(find_quote_verified(item, f'{path}[{idx}]'))
    return res

total_unverified = 0
schemes_with_unverified = []

for sid in [f'SCH{i:06d}' for i in range(220, 303)]:
    v3_id = id_to_v3[sid]
    s = v3.get(v3_id, {})
    unv = find_quote_verified(s)
    if unv:
        total_unverified += len(unv)
        schemes_with_unverified.append((sid, v3_id, unv))

print(f'Total quote_verified=false found: {total_unverified}')
print(f'Schemes with quote_verified=false: {len(schemes_with_unverified)}')
for sid, v3_id, unv in schemes_with_unverified[:5]:
    print(f'{sid} ({v3_id}):')
    for p, obj in unv:
        print(f'  Path: {p}, obj: {obj}')
