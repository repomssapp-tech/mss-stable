"""Per-language, append-only record of every translation decision.

One JSONL file per language. Each line is an event for a unit; the last line for
a unit is its current state, and earlier lines are its history, so re-runs resume
and nothing is ever lost. The file replaces the retired `admin.translation_jobs`.

    baseline: text already in the catalogue when tracking began
    queued -> checked | needs_review | failed -> approved | rejected -> written
"""
from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path

from .config import CONFIG_DIR

LEDGER_DIR = CONFIG_DIR / "ledger"
TRANSITIONS = {
    None: {"baseline", "queued"},
    "baseline": {"baseline", "queued"},
    "queued": {"queued", "checked", "needs_review", "failed"},
    "checked": {"queued", "checked", "needs_review", "failed", "approved", "rejected"},
    "needs_review": {"queued", "checked", "needs_review", "failed", "approved", "rejected"},
    "failed": {"queued", "checked", "needs_review", "failed", "approved", "rejected"},  # approved: reviewer override
    "approved": {"queued", "written", "rejected"},
    "rejected": {"queued"},
    "written": {"baseline", "queued"},
}
# States that mean work is finished or in hand: a re-run does not queue these again.
SETTLED = {"queued", "checked", "needs_review", "approved", "written"}


class IllegalTransition(ValueError):
    pass


class Ledger:
    def __init__(self, lang: str, directory: Path = LEDGER_DIR):
        self.lang = lang
        self.path = Path(directory) / f"{lang}.jsonl"
        self.latest: dict[str, dict] = {}
        if self.path.exists():
            with self.path.open(encoding="utf-8") as handle:
                lines = handle.readlines()
            for number, line in enumerate(lines, 1):
                if not line.strip():
                    continue
                try:
                    event = json.loads(line)
                except json.JSONDecodeError:
                    # Only a crash mid-append leaves a bad line, and only at the very end.
                    if number != len(lines):
                        raise ValueError(f"{self.path} line {number} is corrupt") from None
                    break
                self.latest[event["unit"]] = event

    def state(self, unit: str) -> str | None:
        event = self.latest.get(unit)
        return event["state"] if event else None

    def append(self, events: list[dict]) -> None:
        """Record [events] in one durable write, or raise before writing any."""
        now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        staged = dict(self.latest)
        rows = []
        for event in events:
            current = staged.get(event["unit"], {}).get("state")
            if event["state"] not in TRANSITIONS[current]:
                raise IllegalTransition(f"{event['unit']}: {current} -> {event['state']}")
            row = {**event, "at": event.get("at", now)}
            staged[event["unit"]] = row
            rows.append(row)
        if not rows:
            return
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self.path.open("a", encoding="utf-8", newline="\n") as handle:
            for row in rows:
                handle.write(json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n")
            handle.flush()
            os.fsync(handle.fileno())
        self.latest = staged

    def in_state(self, *states: str) -> list[dict]:
        return [e for e in self.latest.values() if e["state"] in states]
