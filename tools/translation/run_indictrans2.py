#!/usr/bin/env python3
"""Translate an exported batch with the local IndicTrans2 model.

Run with the model's own Python, which holds torch and the toolkit:

    C:/development/MSS_Translation/.venv-indictrans-cuda/Scripts/python.exe tools/translation/run_indictrans2.py \
        --in work/mr-001.jsonl --out work/mr-001.out.jsonl --target mar_Deva

Any engine fits the pipeline this way: read `{unit, checksum, en}` lines, write
`{unit, checksum, translation}` lines. Output is appended unit by unit, so a stopped
run resumes where it left off. The model is only loaded from the local folder.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

DEFAULT_MODEL = Path("C:/development/MSS_Translation/models/indictrans2-en-indic-1B")
SOURCE_CODE = "eng_Latn"
BATCH = 16


class Model:
    def __init__(self, path: Path, target: str):
        os.environ["HF_HUB_OFFLINE"] = "1"
        os.environ["TRANSFORMERS_OFFLINE"] = "1"
        import torch
        from IndicTransToolkit.processor import IndicProcessor
        from transformers import AutoModelForSeq2SeqLM, AutoTokenizer

        self.torch, self.target = torch, target
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        kind = torch.float16 if self.device == "cuda" else torch.float32
        self.tokenizer = AutoTokenizer.from_pretrained(str(path), trust_remote_code=True, local_files_only=True)
        self.model = AutoModelForSeq2SeqLM.from_pretrained(
            str(path), trust_remote_code=True, local_files_only=True, torch_dtype=kind
        ).to(self.device)
        self.processor = IndicProcessor(inference=True)

    def translate(self, texts: list[str]) -> list[str]:
        out = []
        for start in range(0, len(texts), BATCH):
            chunk = self.processor.preprocess_batch(texts[start:start + BATCH], src_lang=SOURCE_CODE, tgt_lang=self.target)
            inputs = self.tokenizer(chunk, truncation=True, padding="longest", return_tensors="pt", return_attention_mask=True).to(self.device)
            with self.torch.no_grad():
                # The checkpoint's model code is incompatible with newer KV caching.
                generated = self.model.generate(**inputs, use_cache=False, min_length=0, max_length=256, num_beams=3, num_return_sequences=1)
            decoded = self.tokenizer.batch_decode(generated, skip_special_tokens=True, clean_up_tokenization_spaces=True)
            out.extend(self.processor.postprocess_batch(decoded, lang=self.target))
        return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--in", dest="input", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--target", required=True, help="the language's model code, e.g. mar_Deva")
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    args = parser.parse_args()

    done = set()
    if args.out.exists():
        with args.out.open(encoding="utf-8") as handle:
            done = {json.loads(line)["unit"] for line in handle if line.strip()}
    with args.input.open(encoding="utf-8") as handle:
        todo = [row for row in map(json.loads, filter(str.strip, handle)) if row["unit"] not in done]
    if not todo:
        print(json.dumps({"translated": 0, "already_done": len(done)}))
        return 0

    model = Model(args.model, args.target)
    with args.out.open("a", encoding="utf-8", newline="\n") as out:
        for row in todo:
            is_list = isinstance(row["en"], list)
            items = row["en"] if is_list else [row["en"]]
            result = model.translate(items)
            out.write(json.dumps({"unit": row["unit"], "checksum": row["checksum"], "translation": result if is_list else result[0]}, ensure_ascii=False) + "\n")
            out.flush()
    print(json.dumps({"translated": len(todo), "already_done": len(done), "device": model.device}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
