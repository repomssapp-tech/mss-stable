import json
import os
import sys

CAT_DIR = r"C:\Users\roger\OneDrive\Documents\Plan\catalog"
SCHEME_CAT_PATH = os.path.join(CAT_DIR, "scheme_catalog.json")

def main():
    with open(SCHEME_CAT_PATH, "r", encoding="utf-8") as f:
        catalog = json.load(f)
    
    schemes = catalog["data"]
    s_by_id = {s["identity"]["id"]: s for s in schemes}

    # 1. 49 parent_of references across 13 parents
    # Map parent -> children
    parent_to_children = {
        'SCH000033': ['SCH000226', 'SCH000227', 'SCH000228', 'SCH000229'],
        'SCH000071': ['SCH000230', 'SCH000231', 'SCH000232'],
        'SCH000075': ['SCH000247'],
        'SCH000076': ['SCH000242', 'SCH000243', 'SCH000244', 'SCH000245', 'SCH000246'],
        'SCH000095': ['SCH000221', 'SCH000222', 'SCH000223', 'SCH000224', 'SCH000225'],
        'SCH000099': ['SCH000253', 'SCH000254'],
        'SCH000113': ['SCH000233', 'SCH000234', 'SCH000235', 'SCH000236', 'SCH000237', 'SCH000238', 'SCH000239', 'SCH000240', 'SCH000241'],
        'SCH000130': ['SCH000220'],
        'SCH000247': ['SCH000248', 'SCH000249', 'SCH000250', 'SCH000251', 'SCH000252'],
        'SCH000256': ['SCH000257', 'SCH000263'],
        'SCH000257': ['SCH000258', 'SCH000259', 'SCH000260', 'SCH000261', 'SCH000262'],
        'SCH000263': ['SCH000264', 'SCH000265', 'SCH000266', 'SCH000267', 'SCH000268'],
        'SCH000280': ['SCH000281', 'SCH000282'],
    }

    added_parent_refs = 0
    for pid, cids in parent_to_children.items():
        p_scheme = s_by_id[pid]
        rels = p_scheme.setdefault("relationships", {})
        refs = rels.setdefault("references", [])
        for cid in cids:
            if not any(r.get("entityId") == cid and r.get("relationType") == "parent_of" for r in refs):
                refs.append({
                    "entityId": cid,
                    "entityType": "scheme",
                    "relationType": "parent_of"
                })
                added_parent_refs += 1
    print(f"Added {added_parent_refs} parent_of references across {len(parent_to_children)} parents.")

    # 2. Successor links
    def add_ref_if_missing(sid, target_id, relation_type, extra=None):
        s = s_by_id[sid]
        refs = s.setdefault("relationships", {}).setdefault("references", [])
        if not any(r.get("entityId") == target_id and r.get("relationType") == relation_type for r in refs):
            entry = {
                "entityId": target_id,
                "entityType": "scheme",
                "relationType": relation_type
            }
            if extra:
                entry.update(extra)
            refs.append(entry)
            print(f"  Added {relation_type} from {sid} -> {target_id}")

    add_ref_if_missing('SCH000043', 'SCH000302', 'related_to', {'relation': 'successor'})
    add_ref_if_missing('SCH000302', 'SCH000043', 'related_to', {'relation': 'successor'})
    add_ref_if_missing('SCH000070', 'SCH000258', 'related_to', {'relation': 'successor'})
    add_ref_if_missing('SCH000258', 'SCH000070', 'related_to', {'relation': 'successor'})

    # 3. Inverse duplicate links on canonical schemes
    add_ref_if_missing('SCH000095', 'SCH000055', 'merged_from')
    add_ref_if_missing('SCH000038', 'SCH000064', 'merged_from')
    add_ref_if_missing('SCH000218', 'SCH000168', 'has_duplicate')

    # Ensure duplicate schemes status = closed
    for dup_id in ['SCH000055', 'SCH000064', 'SCH000168']:
        s_by_id[dup_id]['identity']['status'] = 'closed'

    # 4. CGTMSE SCH000038
    s38 = s_by_id['SCH000038']
    guar = s38['content']['benefits']['guarantee']
    guar['maxCoverInr'] = 100000000
    guar['maxAmountText'] = "₹10 crore (enhanced w.e.f. 01.04.2025)"
    cond_text = "Booklet 2025-26 text states ₹5 crore; ceiling enhanced to ₹10 crore w.e.f. 01.04.2025"
    if cond_text not in guar['conditions']:
        guar['conditions'].append(cond_text)

    rec_note = "[reconciliation] Booklet 2025-26 text states ₹5 crore; ceiling enhanced to ₹10 crore w.e.f. 01.04.2025 (CGTMSE Circular No. 250 w.e.f. 01.04.2025, https://www.cgtmse.in/)."
    ver = s38.setdefault('verification', {})
    existing_notes = ver.get('notes') or ''
    if rec_note not in existing_notes:
        ver['notes'] = (existing_notes + "; " if existing_notes else "") + rec_note

    # Save scheme_catalog.json
    catalog["metadata"]["totalSchemes"] = len(schemes)
    with open(SCHEME_CAT_PATH, "w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)
    print(f"Updated {SCHEME_CAT_PATH} successfully.")

if __name__ == "__main__":
    main()
