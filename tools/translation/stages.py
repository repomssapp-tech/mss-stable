"""Pipeline stages before the catalogue is touched: audit, baseline, export, ingest, review."""
from __future__ import annotations

import collections
import json
import random
from pathlib import Path

from . import checks
from .config import Config
from .ledger import SETTLED, Ledger
from .units import SCHEME_SECTION, Unit, all_units, checksum, read_target

SAMPLE_PER_FIELD = 30


def planned(bundle: dict, config: Config, lang: str) -> list[tuple[dict, Unit]]:
    language = config.language(lang)
    return [(e, u) for e, u in all_units(bundle) if language.covers(u.jurisdiction)]


def is_government_name(unit: Unit, config: Config) -> bool:
    """A scheme, authority or institution name: never machine translated."""
    return unit.field in config.government_name_fields.get(unit.section, ())


def _field_group(unit: Unit) -> str:
    return unit.field.split("[")[0].split(".")[0]


def audit(bundle: dict, config: Config, lang: str, ledger: Ledger) -> dict:
    """Coverage, gaps and staleness for [lang]. Reads only."""
    rows = collections.defaultdict(collections.Counter)
    names = collections.Counter()
    for entity, unit in planned(bundle, config, lang):
        row = rows[(unit.jurisdiction or "reference", unit.tier)]
        row["total"] += 1
        present = read_target(entity, unit, lang) is not None
        event = ledger.latest.get(unit.key)
        if present and is_government_name(unit, config):
            names["with_official_source" if (event or {}).get("official_source") else "no_official_source"] += 1
        if present:
            row["present"] += 1
            if event is None:
                row["untracked"] += 1
            elif event.get("checksum") != unit.source_checksum:
                row["stale"] += 1
        elif unit.pending:
            row["held_pending_translation"] += 1
        else:
            row["gap"] += 1
    return {
        "language": lang,
        "rows": {f"{j}/{t}": dict(c) for (j, t), c in sorted(rows.items())},
        "ledger": dict(collections.Counter(e["state"] for e in ledger.latest.values())),
        "government_names": dict(names),
    }


def lint(bundle: dict, config: Config, lang: str, out: Path | None = None) -> dict:
    """Run the checks over text already in the catalogue. Reports only: old text
    predates these rules, so a finding here is a lead for review, not a verdict."""
    language = config.language(lang)
    codes, rows = collections.Counter(), []
    for entity, unit in planned(bundle, config, lang):
        text = read_target(entity, unit, lang)
        if text is None:
            continue
        findings = checks.check(unit.en, text, language, config, _sibling_text(entity, unit, language))
        for f in findings:
            codes[f"{f.severity}:{f.code}"] += 1
            rows.append({"unit": unit.key, **f.as_dict(), "en": unit.en, "text": text})
    if out:
        out.parent.mkdir(parents=True, exist_ok=True)
        with out.open("w", encoding="utf-8", newline="\n") as handle:
            for row in rows:
                handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    return {"language": lang, "findings": dict(codes), "file": str(out) if out else None}


def registry_drift(bundle: dict) -> list[str]:
    """Where the manifest's language registry disagrees with the schemes themselves."""
    manifest = bundle["manifest.json"]["data"][0]
    actual = collections.defaultdict(set)
    for scheme in bundle[SCHEME_SECTION]["data"]:
        jurisdiction = (scheme.get("provenance") or {}).get("jurisdiction") or "central"
        actual[jurisdiction].update((scheme.get("content", {}).get("languages") or {}).get("available", []))
    drift = []
    registry = (manifest.get("languageRegistry") or {}).get("jurisdictions", {})
    for jurisdiction, langs in sorted(actual.items()):
        listed = set(registry.get(jurisdiction, {}).get("contentLanguages", []))
        if listed != langs:
            drift.append(f"{jurisdiction}: registry lists {sorted(listed)}, schemes have {sorted(langs)}")
    return drift


def baseline(bundle: dict, config: Config, lang: str, ledger: Ledger) -> int:
    """Record the English behind each translation already in the catalogue, so a
    later English edit shows up as stale. Claims nothing about who translated it."""
    events = []
    for entity, unit in planned(bundle, config, lang):
        text = read_target(entity, unit, lang)
        if text is not None and ledger.state(unit.key) in (None, "baseline", "written"):
            events.append({
                "unit": unit.key, "state": "baseline", "checksum": unit.source_checksum,
                "text_checksum": checksum(text),
            })
    ledger.append(events)
    return len(events)


def export_batch(bundle, config, lang, ledger, out: Path, batch: str, *, tier=None, jurisdiction=None,
                 limit=None, include_pending=False, retry_failed=False, stale=False, official_names=False, only_units=None) -> dict:
    """Queue missing text and write it to [out] for an engine. Re-runs skip settled units.
    Government names are never queued for an engine; [official_names] queues only them,
    for someone to fill in from an official source. [only_units] queues exactly those
    unit keys, existing text included, so a reviewer can supersede it."""
    lines, events = [], []
    skipped = collections.Counter()
    for entity, unit in planned(bundle, config, lang):
        if (tier and unit.tier != tier) or (jurisdiction and unit.jurisdiction != jurisdiction):
            continue
        if only_units is not None and unit.key not in only_units:
            continue
        if is_government_name(unit, config) != official_names:
            if not official_names:
                skipped["government_name"] += 1
            continue
        existing = read_target(entity, unit, lang)
        event = ledger.latest.get(unit.key)
        current = event is not None and event.get("checksum") == unit.source_checksum
        if existing is not None and only_units is None and not (stale and event is not None and not current):
            skipped["has_translation"] += 1
            continue
        if unit.pending and not include_pending:
            skipped["pending_translation"] += 1
            continue
        state = event["state"] if event else None
        if state in SETTLED and current:
            skipped["already_in_progress"] += 1
            continue
        if state == "failed" and current and not retry_failed:
            skipped["failed_needs_retry_flag"] += 1
            continue
        lines.append({"unit": unit.key, "checksum": unit.source_checksum, "lang": lang, "field": unit.field, "en": unit.en})
        events.append({"unit": unit.key, "state": "queued", "checksum": unit.source_checksum, "batch": batch})
        if limit and len(lines) >= limit:
            break
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8", newline="\n") as handle:
        for line in lines:
            handle.write(json.dumps(line, ensure_ascii=False) + "\n")
    ledger.append(events)
    return {"batch": batch, "queued": len(lines), "skipped": dict(skipped), "file": str(out)}


def _sibling_text(entity, unit, language) -> dict:
    found = {s: read_target(entity, unit, s) for s in language.siblings}
    return {k: v for k, v in found.items() if v is not None}


def ingest(bundle, config, lang, ledger, candidates: Path, engine: str, revision: str) -> dict:
    """Check engine output and record it. Never writes to the catalogue."""
    if engine not in config.engines:
        raise ValueError(f"engine '{engine}' is not registered in languages.json; record the engine actually used")
    if not revision:
        raise ValueError("a revision is required so the translation can be traced to a model or run")
    language = config.language(lang)
    by_key = {u.key: (e, u) for e, u in planned(bundle, config, lang)}
    counts, events = collections.Counter(), []
    with candidates.open(encoding="utf-8") as handle:
        for line in handle:
            if not line.strip():
                continue
            row = json.loads(line)
            key = row["unit"]
            if key not in by_key:
                counts["unknown_unit"] += 1
                continue
            entity, unit = by_key[key]
            event = ledger.latest.get(key)
            if not event or event["state"] != "queued":
                counts["not_queued"] += 1
                continue
            if row.get("checksum") != unit.source_checksum:
                counts["english_changed_since_export"] += 1
                events.append({"unit": key, "state": "failed", "checksum": unit.source_checksum, "batch": event.get("batch"),
                               "checks": [{"severity": "block", "code": "stale_source", "detail": ""}]})
                continue
            text = row.get("translation")
            official_source = row.get("official_source")
            if is_government_name(unit, config) and (engine != "official" or not official_source):
                counts["government_name_refused"] += 1
                events.append({"unit": key, "state": "failed", "checksum": unit.source_checksum, "batch": event.get("batch"),
                               "checks": [{"severity": "block", "code": "government_name_needs_official_source", "detail": engine}]})
                continue
            findings = checks.check(unit.en, text, language, config, _sibling_text(entity, unit, language))
            state = checks.verdict(findings)
            counts[state] += 1
            events.append({
                "unit": key, "state": state, "checksum": unit.source_checksum, "batch": event.get("batch"),
                "text": text, "engine": engine, "revision": revision, "origin": "human" if engine == "human" else "machine",
                "checks": [f.as_dict() for f in findings],
                **({"official_source": official_source} if official_source else {}),
            })
    ledger.append(events)
    return dict(counts)


def report(ledger: Ledger, bundle, config, lang, batch: str, out: Path, seed: int = 0) -> dict:
    """Counts and a random sample per field for the owner's review gate."""
    by_key = {u.key: u for _, u in planned(bundle, config, lang)}
    events = [e for e in ledger.latest.values() if e.get("batch") == batch]
    counts = collections.Counter(e["state"] for e in events)
    codes = collections.Counter(c["code"] for e in events for c in e.get("checks", []))
    lines = [f"# Translation review: {lang}, batch {batch}", "", f"States: {dict(counts)}", f"Findings: {dict(codes)}", ""]
    lines += ["Passing checks proves numbers, units and links survived. It does not prove the meaning is right.", ""]
    groups = collections.defaultdict(list)
    for e in events:
        if e["state"] == "checked" and e["unit"] in by_key:
            groups[_field_group(by_key[e["unit"]])].append(e)
    rng = random.Random(f"{batch}:{seed}")
    for name, rows in sorted(groups.items()):
        lines += [f"## {name} ({len(rows)})", "", "| Unit | English | Translation |", "|---|---|---|"]
        for e in rng.sample(rows, min(SAMPLE_PER_FIELD, len(rows))):
            en = str(by_key[e["unit"]].en).replace("|", "/").replace("\n", " ")
            text = str(e["text"]).replace("|", "/").replace("\n", " ")
            lines.append(f"| {e['unit'].replace('|', ' / ')} | {en} | {text} |")
        lines.append("")
    attention = [e for e in events if e["state"] in ("needs_review", "failed")]
    if attention:
        lines += ["## Needs attention", "", "| Unit | State | Findings |", "|---|---|---|"]
        for e in attention:
            found = "; ".join(f"{c['code']} {c['detail']}".strip() for c in e.get("checks", []))
            lines.append(f"| {e['unit'].replace('|', ' / ')} | {e['state']} | {found} |")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return {"states": dict(counts), "findings": dict(codes), "report": str(out)}


def approve_batch(ledger: Ledger, batch: str, reviewer: str, report_file: Path) -> int:
    """Approve a batch's clean units after its sample was reviewed. The text stays
    `verified: false`: a sampled batch is not human verification of every row."""
    if not report_file.exists():
        raise ValueError(f"run `report` and review the sample first: {report_file} not found")
    events = []
    for e in ledger.in_state("checked"):
        if e.get("batch") != batch:
            continue
        if reviewer.strip().lower() == str(e.get("engine", "")).lower():
            raise ValueError("the reviewer cannot be the engine that wrote the text")
        events.append({**{k: v for k, v in e.items() if k != "at"}, "state": "approved", "reviewer": reviewer, "verified": False})
    ledger.append(events)
    return len(events)


def decide(ledger: Ledger, bundle, config, lang, decisions: Path, reviewer: str) -> dict:
    """Per-unit decisions: {"unit", "decision": approve|reject, "text"?, "supersede"?, "verified"?, "override_reason"?}.
    Edited text is re-checked. A blocking finding refuses it unless the reviewer records
    why it is wrong ("Rs 10 million" as "₹1 crore" is correct but fails the amount check)."""
    language = config.language(lang)
    by_key = {u.key: (e, u) for e, u in planned(bundle, config, lang)}
    counts, events = collections.Counter(), []
    with decisions.open(encoding="utf-8") as handle:
        for line in handle:
            if not line.strip():
                continue
            row = json.loads(line)
            current = ledger.latest.get(row["unit"])
            if not current or row["unit"] not in by_key:
                counts["unknown_unit"] += 1
                continue
            base = {k: v for k, v in current.items() if k != "at"}
            if row["decision"] == "reject":
                events.append({**base, "state": "rejected", "reviewer": reviewer, "reason": row.get("reason", "")})
                counts["rejected"] += 1
                continue
            entity, unit = by_key[row["unit"]]
            official_source = row.get("official_source") or current.get("official_source")
            if is_government_name(unit, config) and not official_source:
                counts["refused_government_name"] += 1
                continue
            if official_source:
                base["official_source"] = official_source
            text = row.get("text", current.get("text"))
            edited = "text" in row
            if reviewer.strip().lower() == str(current.get("engine", "")).lower() and not edited:
                raise ValueError("the reviewer cannot be the engine that wrote the text")
            findings = checks.check(unit.en, text, language, config, _sibling_text(entity, unit, language))
            if checks.verdict(findings) == "failed" and not row.get("override_reason"):
                counts["refused_blocking_finding"] += 1
                continue
            base.update(state="approved", text=text, reviewer=reviewer, verified=bool(row.get("verified")),
                        checks=[f.as_dict() for f in findings])
            if row.get("override_reason"):
                base["override_reason"] = row["override_reason"]
            if edited:
                base.update(origin="human", engine="human", revision=reviewer)
            existing = read_target(entity, unit, lang)
            if row.get("supersede") and existing is not None:
                base["replaces"] = checksum(existing)
            events.append(base)
            counts["approved"] += 1
    ledger.append(events)
    return dict(counts)
