"""Language registry and glossary. Adding a language is a config change, not code."""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
CONFIG_DIR = REPO_ROOT / "backend" / "catalog" / "translations"
PACKS_DIR = REPO_ROOT / "frontend" / "assets" / "catalog"

REQUIRED_KEYS = ("name", "script_ranges", "jurisdictions", "magnitudes", "months")


class ConfigError(ValueError):
    pass


@dataclass(frozen=True)
class Language:
    code: str
    name: str
    script_ranges: tuple[tuple[int, int], ...]
    jurisdictions: tuple[str, ...]
    magnitudes: dict[str, tuple[str, ...]]
    months: tuple[str, ...]
    ordinals: dict[str, tuple[str, ...]] = field(default_factory=dict)
    siblings: tuple[str, ...] = ()
    min_script_ratio: float = 0.5
    reference_sections: bool = False
    model_codes: dict[str, str] = field(default_factory=dict)

    def covers(self, jurisdiction: str | None) -> bool:
        """Whether this language is planned for [jurisdiction]; None is reference data."""
        if jurisdiction is None:
            return self.reference_sections
        return "*" in self.jurisdictions or jurisdiction in self.jurisdictions


@dataclass(frozen=True)
class Config:
    source: str
    engines: tuple[str, ...]
    languages: dict[str, Language]
    do_not_translate: dict[str, dict[str, list[str]]]
    government_name_fields: dict[str, list[str]] = field(default_factory=dict)
    government_names: dict[str, dict[str, list[str]]] = field(default_factory=dict)

    def language(self, code: str) -> Language:
        if code not in self.languages:
            known = ", ".join(sorted(self.languages))
            raise ConfigError(f"unknown language '{code}' (configured: {known})")
        return self.languages[code]


def _language(code: str, raw: dict) -> Language:
    missing = [k for k in REQUIRED_KEYS if not raw.get(k)]
    if missing:
        raise ConfigError(f"language '{code}' is missing {', '.join(missing)}")
    if len(raw["months"]) != 12:
        raise ConfigError(f"language '{code}' needs 12 month names, has {len(raw['months'])}")
    for unit in ("lakh", "crore"):
        if not raw["magnitudes"].get(unit):
            raise ConfigError(f"language '{code}' has no words for {unit}: amounts could not be checked")
    return Language(
        code=code,
        name=raw["name"],
        script_ranges=tuple(tuple(r) for r in raw["script_ranges"]),
        jurisdictions=tuple(raw["jurisdictions"]),
        magnitudes={k: tuple(v) for k, v in raw["magnitudes"].items()},
        months=tuple(raw["months"]),
        ordinals={k: tuple(v) for k, v in raw.get("ordinals", {}).items()},
        siblings=tuple(raw.get("siblings", ())),
        min_script_ratio=raw.get("min_script_ratio", 0.5),
        reference_sections=bool(raw.get("reference_sections")),
        model_codes=dict(raw.get("model_codes", {})),
    )


def load(config_dir: Path = CONFIG_DIR) -> Config:
    raw = json.loads((config_dir / "languages.json").read_text(encoding="utf-8"))
    glossary = json.loads((config_dir / "glossary.json").read_text(encoding="utf-8"))
    languages = {code: _language(code, spec) for code, spec in raw["languages"].items()}
    return Config(
        source=raw["source"],
        engines=tuple(raw["engines"]),
        languages=languages,
        do_not_translate=glossary.get("do_not_translate", {}),
        government_name_fields=glossary.get("government_name_fields", {}),
        government_names=glossary.get("government_names", {}),
    )
