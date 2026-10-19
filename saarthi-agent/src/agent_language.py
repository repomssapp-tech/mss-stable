"""The language a citizen picked in the app, and what the voice agent needs for it.

The app sends one of `en`, `ta`, `hi`, `mr` in the signed job metadata. Everything
language-specific the agent does (what it says, which Sarvam voice speaks, how it
greets) comes from this table, so adding a language is one entry here.
"""

from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class AgentLanguage:
    code: str
    # Sarvam language/locale tag used for text-to-speech.
    locale: str
    # English name used inside the system prompt.
    name: str
    # Default Bulbul v3 voice; `SARVAM_TTS_SPEAKER_<CODE>` overrides it.
    speaker: str
    greeting: str
    # How to treat English words the citizen mixes in.
    mixing_rule: str


LANGUAGES: dict[str, AgentLanguage] = {
    "en": AgentLanguage(
        code="en",
        locale="en-IN",
        name="English",
        speaker="shubh",
        greeting="Hello",
        mixing_rule="Use simple Indian English.",
    ),
    "ta": AgentLanguage(
        code="ta",
        locale="ta-IN",
        name="Tamil",
        speaker="kavitha",
        greeting="Vanakkam",
        mixing_rule="If the user uses English words, use natural Tanglish.",
    ),
    "hi": AgentLanguage(
        code="hi",
        locale="hi-IN",
        name="Hindi",
        speaker="shubh",
        greeting="Namaste",
        mixing_rule="If the user uses English words, use natural Hinglish.",
    ),
    "mr": AgentLanguage(
        code="mr",
        locale="mr-IN",
        name="Marathi",
        speaker="shubh",
        greeting="Namaskar",
        mixing_rule="If the user uses English words, keep those words as they are.",
    ),
}


def language_code(value: object) -> str | None:
    """`ta`, `ta-IN`, `TA_in` -> `ta`; anything unsupported or blank -> None."""
    if not isinstance(value, str):
        return None
    code = value.strip().lower().replace("_", "-").split("-")[0]
    return code if code in LANGUAGES else None


def resolve_language(value: object) -> AgentLanguage | None:
    code = language_code(value)
    return LANGUAGES[code] if code else None


def speaker_for(language: AgentLanguage) -> str:
    return os.getenv(f"SARVAM_TTS_SPEAKER_{language.code.upper()}", language.speaker)
