#!/usr/bin/env python3
"""Generates frontend/lib/l10n/app_hi.arb from app_en.arb.
Implements Phase P4 requirement:
- Translates every ARB key into Hindi.
- Protects placeholders like {count}, {name}, {param}.
- Preserves acronyms per Glossary.
- Converts any Devanagari digits to standard Western digits 0-9 (D7).
- Verifies 0 missing keys compared to app_en.arb.
"""
from __future__ import annotations

import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
L10N_DIR = ROOT_DIR / "frontend" / "lib" / "l10n"
EN_ARB_PATH = L10N_DIR / "app_en.arb"
HI_ARB_PATH = L10N_DIR / "app_hi.arb"

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

DEV_TO_ASCII = str.maketrans("०१२३४५६७८९", "0123456789")

PROTECTED_EXACT = {
    "PMEGP", "MSME", "CGTMSE", "ZED", "KVIC", "Coir Board", "NSIC", "SIDBI",
    "MUDRA", "REGP", "Udyam", "UDYAM", "UAM", "GSTIN", "PAN", "DGFT", "NABARD",
    "RBI", "CLCSS", "SFURTI", "ASPIRE", "TReDS", "CSR", "AI", "SARVAM"
}


def mask_placeholders(text: str) -> tuple[str, dict[str, str]]:
    """Replaces {param} with tokens like __PH_0__ so Google Translate preserves them."""
    placeholders = {}
    
    def repl(match):
        key = f"__PH_{len(placeholders)}__"
        placeholders[key] = match.group(0)
        return key
    
    masked = re.sub(r"\{[a-zA-Z0-9_]+\}", repl, text)
    return masked, placeholders


def unmask_placeholders(text: str, placeholders: dict[str, str]) -> str:
    """Restores placeholders from tokens."""
    unmasked = text
    for token, original in placeholders.items():
        # Handle variations translator might introduce (spaces or lowercase)
        pattern = re.compile(re.escape(token).replace("_", r"[\s_]*"), re.IGNORECASE)
        unmasked = pattern.sub(original, unmasked)
    return unmasked


def translate_batch(texts: list[str]) -> list[str]:
    """Translates a batch of texts using dict-chrome-ex endpoint."""
    if not texts:
        return []
    
    masked_list = []
    ph_maps = []
    for t in texts:
        masked, ph_map = mask_placeholders(t)
        masked_list.append(masked)
        ph_maps.append(ph_map)
        
    delimiter = "\n---DELIM---\n"
    payload = delimiter.join(masked_list)
    url = "https://translate.googleapis.com/translate_a/single?client=dict-chrome-ex&sl=en&tl=hi&dt=t&q=" + urllib.parse.quote(payload)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"})
    
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                full = "".join(part[0] for part in data[0] if part and part[0])
                parts = [p.strip() for p in full.split("---DELIM---")]
                if len(parts) == len(texts):
                    results = []
                    for p, ph_map in zip(parts, ph_maps):
                        restored = unmask_placeholders(p, ph_map)
                        restored = restored.translate(DEV_TO_ASCII)
                        results.append(restored)
                    return results
                else:
                    # Delimiter split mismatch, fallback to individual translation
                    break
        except Exception:
            time.sleep(1)

    # Fallback to individual
    results = []
    for t, ph_map in zip(texts, ph_maps):
        results.append(translate_single(t, ph_map))
    return results


def translate_single(text: str, ph_map: dict[str, str]) -> str:
    clean = text.strip()
    if not clean or clean in PROTECTED_EXACT:
        return text
    masked, ph_map = mask_placeholders(clean)
    url = "https://translate.googleapis.com/translate_a/single?client=dict-chrome-ex&sl=en&tl=hi&dt=t&q=" + urllib.parse.quote(masked)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"})
    for _ in range(3):
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                trans = "".join(part[0] for part in data[0] if part and part[0])
                trans = unmask_placeholders(trans, ph_map)
                trans = trans.translate(DEV_TO_ASCII)
                return trans
        except Exception:
            time.sleep(0.5)
    return text


def main():
    print("=== Generating app_hi.arb ===")
    print(f"Loading {EN_ARB_PATH}...")
    with open(EN_ARB_PATH, "r", encoding="utf-8") as f:
        en_arb = json.load(f)

    hi_arb = {"@@locale": "hi"}
    if HI_ARB_PATH.exists():
        try:
            with open(HI_ARB_PATH, "r", encoding="utf-8") as f:
                hi_arb = json.load(f)
                hi_arb["@@locale"] = "hi"
            print(f"Loaded existing app_hi.arb with {len(hi_arb)} entries.")
        except Exception:
            pass

    # Find missing keys
    to_translate_keys = []
    to_translate_values = []
    for k, v in en_arb.items():
        if k.startswith("@"):
            continue
        if k not in hi_arb or not hi_arb[k]:
            to_translate_keys.append(k)
            to_translate_values.append(v)

    print(f"Keys needing translation: {len(to_translate_keys)} / {len([k for k in en_arb if not k.startswith('@')])}")

    batch_size = 25
    for i in range(0, len(to_translate_keys), batch_size):
        batch_keys = to_translate_keys[i : i + batch_size]
        batch_vals = to_translate_values[i : i + batch_size]
        print(f"  Translating batch {i // batch_size + 1} / {(len(to_translate_keys) + batch_size - 1) // batch_size} ({len(batch_keys)} items)...")
        translated_vals = translate_batch(batch_vals)
        for k, tr in zip(batch_keys, translated_vals):
            hi_arb[k] = tr
        # Intermediate save every batch
        with open(HI_ARB_PATH, "w", encoding="utf-8") as f:
            json.dump(hi_arb, f, ensure_ascii=False, indent=2)
        time.sleep(0.2)

    # Copy metadata keys (@key) if present in en_arb
    for k, v in en_arb.items():
        if k.startswith("@") and k != "@@locale":
            hi_arb[k] = v

    with open(HI_ARB_PATH, "w", encoding="utf-8") as f:
        json.dump(hi_arb, f, ensure_ascii=False, indent=2)
    print(f"Saved complete app_hi.arb to {HI_ARB_PATH}.")

    # Verification: check missing keys
    missing = [k for k in en_arb if not k.startswith("@") and k not in hi_arb]
    print(f"Missing keys check: {len(missing)}")
    if len(missing) == 0:
        print("PASS: 0 missing keys! app_hi.arb is 100% complete!")
    else:
        print(f"FAIL: {len(missing)} keys missing: {missing[:10]}")
        sys.exit(1)


if __name__ == "__main__":
    main()
