"""Prepare and summarise emulator search runs.

  python tools/search_eval_device.py config en 0 100
      Stages the queries plus the language / offset / limit of the next run in
      frontend/build/eval_serve/, which the host serves to the device test.

  python tools/search_eval_device.py convert
      Turns frontend/build/integration_response_data.json (the run's reportData)
      into a flat results list usable by tools/search_eval_report.py, and
      prints the spell-checker summary. Writes frontend/build/eval_results.json
      and keeps the batch in frontend/build/eval_batches/.

  python tools/search_eval_device.py merge en
      Merges every saved batch for a language into build/eval_results.json.

Long runs go in batches (--dart-define=EVAL_OFFSET=0/100/200 and
EVAL_LIMIT=100) so an interrupted run loses at most one batch.

Queries embed at build time because the app's own storage is wiped when a
device test ends.
"""

import json
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
ROOT = Path(__file__).resolve().parent.parent
FE = ROOT / "frontend"
QUERIES = FE / "test" / "fixtures" / "search_eval" / "queries.json"
BUILD = FE / "build"


SERVE = BUILD / "eval_serve"


def config(lang, offset, limit):
    """Stage queries.json and the language/slice for the device test to fetch.

    Serve this directory on port 8765 (the emulator reaches the host at
    10.0.2.2):  python -m http.server 8765 --bind 127.0.0.1 --directory <dir>
    """
    SERVE.mkdir(parents=True, exist_ok=True)
    (SERVE / "queries.json").write_bytes(QUERIES.read_bytes())
    (SERVE / "eval_config.json").write_text(
        json.dumps({"lang": lang, "offset": int(offset), "limit": int(limit)}),
        encoding="utf-8",
    )
    print(f"staged {SERVE}: lang={lang} offset={offset} limit={limit}")


def spell_summary(rows):
    typo = [r for r in rows if r["typo"]]
    clean = [r for r in rows if not r["typo"]]
    flagged = sum(1 for r in typo if r["spellFlagged"])
    # A flagged word counts as "fixed" when the clean word is among its suggestions.
    fixable = fixed = 0
    for r in typo:
        typed, cleaned = r["query"].split(), r["clean"].split()
        if len(typed) != len(cleaned):
            continue
        for t, c in zip(typed, cleaned):
            if t != c:
                fixable += 1
                if c in (r["spellSuggestions"].get(t) or []):
                    fixed += 1
    print("\nSystem spell checker (real device):")
    print(f"  misspelt queries with at least one flagged word: {flagged}/{len(typo)}")
    print(f"  misspelt words whose correct form is suggested:   {fixed}/{fixable}")
    print(f"  false alarms on correctly spelt queries:          "
          f"{sum(1 for r in clean if r['spellFlagged'])}/{len(clean)}")
    print(f"  false alarms on the clean text of typo queries:   "
          f"{sum(1 for r in typo if r['cleanSpellFlagged'])}/{len(typo)}")


def convert():
    src = BUILD / "integration_response_data.json"
    data = json.load(open(src, encoding="utf-8"))
    data = data.get("data", data) if isinstance(data, dict) else data
    rows = data["rows"]
    # Keep every batch, so an interrupted long run loses only its own batch.
    batches = BUILD / "eval_batches"
    batches.mkdir(exist_ok=True)
    batch = batches / f"{data.get('lang')}_{int(data.get('offset', 0)):04d}.json"
    batch.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    out = BUILD / "eval_results.json"
    out.write_text(json.dumps(rows, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"saved batch {batch.name}; wrote {out} ({len(rows)} rows, lang={data.get('lang')})")
    spell_summary(rows)
    print("\nRecommendations:", json.dumps(data.get("recommendations"), ensure_ascii=False)[:600])


def merge(lang):
    parts = sorted((BUILD / "eval_batches").glob(f"{lang}_*.json"))
    rows, first = [], None
    for p in parts:
        d = json.load(open(p, encoding="utf-8"))
        first = first or d
        rows += d["rows"]
    out = BUILD / "eval_results.json"
    out.write_text(json.dumps(rows, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"merged {len(parts)} batches -> {out} ({len(rows)} rows)")
    print("spell diagnostics:", json.dumps(first.get("spellDiagnostics"), ensure_ascii=False)[:500])
    spell_summary(rows)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "config":
        config(sys.argv[2], sys.argv[3], sys.argv[4])
    elif cmd == "convert":
        convert()
    elif cmd == "merge":
        merge(sys.argv[2])
    else:
        print(__doc__)
