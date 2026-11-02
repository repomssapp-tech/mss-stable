#!/usr/bin/env python3
"""Catalogue translation pipeline. See docs/translation/PIPELINE.md.

    python tools/translation/cli.py audit --lang mr
    python tools/translation/cli.py export --lang mr --batch mr-001 --out work/mr-001.jsonl
    python tools/translation/cli.py ingest --lang mr --file work/mr-001.out.jsonl --engine indictrans2 --revision bb1e8f49
    python tools/translation/cli.py report --lang mr --batch mr-001 --out work/mr-001.md
    python tools/translation/cli.py approve --lang mr --batch mr-001 --reviewer Roger --report work/mr-001.md
    python tools/translation/cli.py apply --lang mr --out-dir work/candidate
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import catalog_packs  # noqa: E402

from translation import config as config_module  # noqa: E402
from translation import release as release_module  # noqa: E402
from translation import stages  # noqa: E402
from translation.ledger import LEDGER_DIR, Ledger  # noqa: E402


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--config-dir", type=Path, default=config_module.CONFIG_DIR)
    parser.add_argument("--ledger-dir", type=Path, default=LEDGER_DIR)
    parser.add_argument("--packs", type=Path, default=config_module.PACKS_DIR)
    commands = parser.add_subparsers(dest="command", required=True)

    def command(name, *args):
        sub = commands.add_parser(name)
        sub.add_argument("--lang", required=True)
        for flags, options in args:
            sub.add_argument(*flags, **options)

    command("audit")
    command("baseline")
    command("readiness")
    command("lint", (("--out",), {"type": Path}))
    command(
        "export",
        (("--batch",), {"required": True}),
        (("--out",), {"required": True, "type": Path}),
        (("--tier",), {"choices": ["core", "detail", "reference"]}),
        (("--jurisdiction",), {}),
        (("--limit",), {"type": int}),
        (("--include-pending",), {"action": "store_true", "help": "also translate English marked pending_translation"}),
        (("--retry-failed",), {"action": "store_true"}),
        (("--stale",), {"action": "store_true", "help": "also queue text whose English has changed"}),
    )
    command(
        "ingest",
        (("--file",), {"required": True, "type": Path}),
        (("--engine",), {"required": True}),
        (("--revision",), {"required": True}),
    )
    command("report", (("--batch",), {"required": True}), (("--out",), {"required": True, "type": Path}))
    command(
        "approve",
        (("--batch",), {"required": True}),
        (("--reviewer",), {"required": True}),
        (("--report",), {"required": True, "type": Path}),
    )
    command("decide", (("--file",), {"required": True, "type": Path}), (("--reviewer",), {"required": True}))
    command(
        "apply",
        (("--out-dir",), {"type": Path, "help": "where to write the candidate release"}),
        (("--in-place",), {"action": "store_true", "help": "replace the packs in --packs after the gate passes"}),
        (("--dry-run",), {"action": "store_true"}),
    )
    return parser


def main(argv=None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    args = _parser().parse_args(argv)
    config = config_module.load(args.config_dir)
    config.language(args.lang)
    if args.command == "readiness":
        print(json.dumps(release_module.readiness(config_module.REPO_ROOT, args.lang), indent=2))
        return 0
    ledger = Ledger(args.lang, args.ledger_dir)
    bundle = catalog_packs.load_dir(args.packs)
    status = 0

    if args.command == "audit":
        result = stages.audit(bundle, config, args.lang, ledger)
        result["offer"] = release_module.offer_check(bundle, config, args.lang)
        result["registry_drift"] = stages.registry_drift(bundle)
    elif args.command == "lint":
        result = stages.lint(bundle, config, args.lang, args.out)
    elif args.command == "baseline":
        result = {"recorded": stages.baseline(bundle, config, args.lang, ledger)}
    elif args.command == "export":
        result = stages.export_batch(
            bundle, config, args.lang, ledger, args.out, args.batch, tier=args.tier, jurisdiction=args.jurisdiction,
            limit=args.limit, include_pending=args.include_pending, retry_failed=args.retry_failed, stale=args.stale,
        )
    elif args.command == "ingest":
        result = stages.ingest(bundle, config, args.lang, ledger, args.file, args.engine, args.revision)
    elif args.command == "report":
        result = stages.report(ledger, bundle, config, args.lang, args.batch, args.out)
    elif args.command == "approve":
        result = {"approved": stages.approve_batch(ledger, args.batch, args.reviewer, args.report)}
    elif args.command == "decide":
        result = stages.decide(ledger, bundle, config, args.lang, args.file, args.reviewer)
    else:  # apply
        targets = sum((bool(args.out_dir), args.in_place, args.dry_run))
        if targets != 1:
            print("apply needs exactly one of --out-dir, --in-place or --dry-run", file=sys.stderr)
            return 2
        target = args.packs if args.in_place or args.dry_run else args.out_dir
        result = release_module.release(config, args.lang, ledger, args.packs, target, dry_run=args.dry_run)
        status = 1 if result.get("problem_count") else 0
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return status


if __name__ == "__main__":
    sys.exit(main())
