"""Deterministic checks on one translation, driven by the language's config.

BLOCK findings stop a candidate from being approved. FLAG findings send it to
review. Nothing here judges meaning: passing proves the facts survived, not that
the translation is good, so semantic review stays a separate, independent step.
"""
from __future__ import annotations

import re
import unicodedata
from collections import Counter
from dataclasses import dataclass

from .config import Config, Language

BLOCK, FLAG = "block", "flag"

URL_RE = re.compile(r"https?://[^\s<>\"'।]+|www\.[^\s<>\"'।]+", re.I)
EMAIL_RE = re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+")
NUMBER_RE = re.compile(r"\d+(?:[.,/]\d+)*")
ORDINAL_RE = re.compile(r"(?<!\d)(\d+)(?:st|nd|rd|th)\b", re.I)
ISO_DATE_RE = re.compile(r"\b\d{4}-(\d{1,2})-\d{1,2}\b")
MAGNITUDE_EN = {
    # "2.25L" and "3Cr" are the catalogue's short forms.
    "lakh": re.compile(r"\b(?:lakhs?|lacs?)\b|(?<=\d)\s?L\b", re.I),
    "crore": re.compile(r"\b(?:crores?|cr)\b\.?", re.I),
}
TRAILING = ".,;:!?)]}/।"
# Below this a text is not in the target language at all; between this and the
# language's min_script_ratio it may just hold many proper nouns, so a person looks.
HARD_MIN_SCRIPT_RATIO = 0.25


@dataclass(frozen=True)
class Finding:
    severity: str
    code: str
    detail: str = ""

    def as_dict(self) -> dict:
        return {"severity": self.severity, "code": self.code, "detail": self.detail}


def western_digits(text: str) -> str:
    """Any script's decimal digits as 0-9, so १० and ௧௦ compare equal to 10."""
    return "".join(str(unicodedata.digit(c)) if c.isdecimal() else c for c in text)


def _canonical_number(value: str) -> str:
    value = value.replace(",", "")
    if value.count(".") == 1 and "/" not in value:
        whole, frac = value.split(".")
        frac = frac.rstrip("0")
        return f"{whole}.{frac}" if frac else whole
    return value


def _strip_links(text: str) -> str:
    return EMAIL_RE.sub(" ", URL_RE.sub(" ", text))


def numbers(text: str) -> Counter:
    return Counter(_canonical_number(n) for n in NUMBER_RE.findall(_strip_links(western_digits(text))))


def links(text: str) -> Counter:
    found = URL_RE.findall(text) + EMAIL_RE.findall(text)
    return Counter(re.sub(r"^https?://", "", u.rstrip(TRAILING).lower()) for u in found)


def script_ratio(text: str, lang: Language) -> float:
    letters = [c for c in text if c.isalpha()]
    if not letters:
        return 1.0
    hits = sum(any(lo <= ord(c) <= hi for lo, hi in lang.script_ranges) for c in letters)
    return hits / len(letters)


def _check_numbers(en: str, text: str, lang: Language) -> list[Finding]:
    missing = numbers(en) - numbers(text)
    added = numbers(text) - numbers(en)
    # A spelled ordinal or month name is a faithful rendering of a source number.
    for number in ORDINAL_RE.findall(en):
        if missing[number] and any(form in text for form in lang.ordinals.get(number, ())):
            missing[number] -= 1
    for month in ISO_DATE_RE.findall(en):
        for form in (str(int(month)), month):
            if missing[form] and 1 <= int(month) <= 12 and lang.months[int(month) - 1] in text:
                missing[form] -= 1
    out = []
    if +missing:
        out.append(Finding(BLOCK, "number_missing", ",".join(sorted((+missing).elements()))))
    if +added:
        out.append(Finding(BLOCK, "number_added", ",".join(sorted((+added).elements()))))
    return out


def _check_magnitudes(en: str, text: str, lang: Language) -> list[Finding]:
    """"5 lakh" turned into "5 crore" passes a digit check, so units are counted too."""
    out = []
    if not numbers(en) and not numbers(text):
        return out  # no amount here: "Lakshadweep" is not a lakh
    for unit, pattern in MAGNITUDE_EN.items():
        want = len(pattern.findall(en))
        forms = lang.magnitudes[unit]
        have = len(re.findall("|".join(re.escape(f) for f in sorted(forms, key=len, reverse=True)), text))
        have += len(pattern.findall(text))  # the English word kept as written
        if want != have:
            out.append(Finding(BLOCK, f"{unit}_mismatch", f"source {want}, target {have}"))
    return out


def _only_protected(en: str, config: Config) -> bool:
    """True when the source is only acronyms, names and numbers: nothing to translate."""
    rest = _strip_links(western_digits(en))
    for term in config.do_not_translate:
        rest = re.sub(rf"\b{re.escape(term)}\b", " ", rest, flags=re.I)
    words = re.findall(r"[^\W\d_]+", rest)
    # Two capitals make an acronym, including plurals and mixed forms: AICs, MoMSME.
    return not words or all(sum(c.isupper() for c in w) >= 2 for w in words)


def _check_text(en: str, text: str, lang: Language, config: Config, others: dict[str, str]) -> list[Finding]:
    out = _check_numbers(en, text, lang) + _check_magnitudes(en, text, lang)
    missing_links = links(en) - links(text)
    if +missing_links:
        out.append(Finding(BLOCK, "link_changed", ",".join(sorted((+missing_links).elements()))))
    protected = _only_protected(en, config)
    ratio = script_ratio(text, lang)
    if not protected and ratio < HARD_MIN_SCRIPT_RATIO:
        out.append(Finding(BLOCK, "wrong_script", f"{ratio:.2f}"))
    elif not protected and ratio < lang.min_script_ratio:
        out.append(Finding(FLAG, "low_script_ratio", f"{ratio:.2f}"))
    if not protected and text.strip() == en.strip():
        out.append(Finding(BLOCK, "same_as_english"))
    for sibling in lang.siblings:
        # Hindi and Marathi share a script, so the script check cannot tell them apart.
        if not protected and others.get(sibling, "").strip() == text.strip() and len(text.split()) > 3:
            out.append(Finding(FLAG, "same_as_sibling", sibling))
    if len(en) >= 20 and not 0.4 <= len(text) / len(en) <= 3.0:
        out.append(Finding(FLAG, "length_ratio", f"{len(text) / len(en):.2f}"))
    for term, forms in config.do_not_translate.items():
        if re.search(rf"\b{re.escape(term)}\b", en):
            allowed = [term, *forms.get(lang.code, ())]
            if not any(form in text for form in allowed):
                out.append(Finding(FLAG, "term_changed", term))
    return out


def check(en, text, lang: Language, config: Config, others: dict | None = None) -> list[Finding]:
    """Findings for a scalar or list value. List items must align one to one."""
    others = others or {}
    if isinstance(en, str):
        if not isinstance(text, str) or not text.strip():
            return [Finding(BLOCK, "empty_or_wrong_type")]
        flat = {k: v for k, v in others.items() if isinstance(v, str)}
        return _check_text(en, text, lang, config, flat)
    if not isinstance(text, list) or not all(isinstance(t, str) and t.strip() for t in text):
        return [Finding(BLOCK, "empty_or_wrong_type")]
    if len(en) != len(text):
        return [Finding(BLOCK, "list_length_mismatch", f"source {len(en)}, target {len(text)}")]
    findings = []
    for i, (src, tgt) in enumerate(zip(en, text)):
        item_others = {k: v[i] for k, v in others.items() if isinstance(v, list) and len(v) == len(en)}
        for f in _check_text(src, tgt, lang, config, item_others):
            findings.append(Finding(f.severity, f.code, f"item {i}: {f.detail}".rstrip(": ")))
    return findings


def verdict(findings: list[Finding]) -> str:
    if any(f.severity == BLOCK for f in findings):
        return "failed"
    return "needs_review" if findings else "checked"
