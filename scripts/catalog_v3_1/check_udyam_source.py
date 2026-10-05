import json, csv, re

with open('reports/id_map.csv', encoding='utf-8') as f:
    id_map = {row['allocated_catalog_id']: row for row in csv.DictReader(f)}

with open(r'docs/backend/mss_scheme_data_v3_1/mss_scheme_data_v3_1/data/new_schemes_2025_26.json', encoding='utf-8') as f:
    src_data = json.load(f)
src_by_id = {s['id']: s for s in (src_data.get('schemes') or src_data)}

udyam_schemes = []
for i in range(220, 303):
    sid = f'SCH{i:06d}'
    v3_id = id_map[sid]['v3_1_id']
    s = src_by_id.get(v3_id)
    if not s: continue
    
    sc = s.get('source_current', {})
    elig_list = sc.get('eligibility', {}).get('en') or []
    crit_text = ' '.join(elig_list) if isinstance(elig_list, list) else str(elig_list)
    
    # Check for sentence containing Udyam or UAM
    sents = re.split(r'(?<=[.!?])\s+', crit_text)
    matched_sents = [sent.strip() for sent in sents if re.search(r'\b(udyam|uam)\b', sent, re.I)]
    
    if matched_sents:
        udyam_schemes.append((sid, v3_id, s.get('name', {}).get('en'), matched_sents[0]))

print(f'Count of schemes with explicit Udyam/UAM in eligibility text: {len(udyam_schemes)}')
for u in udyam_schemes:
    print(f'{u[0]} ({u[1]}): {u[2]}')
    print(f'   Quoted sentence: "{u[3]}"')
