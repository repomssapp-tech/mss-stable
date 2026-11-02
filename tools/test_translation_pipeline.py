#!/usr/bin/env python3
"""The translation pipeline's guarantees, on the real catalogue with a fake engine.

Each test works in temp folders; the repo's packs and ledgers are only read.

Run with pytest, or directly: python tools/test_translation_pipeline.py
"""
import copy
import json
import re
import shutil
import sys
import tempfile
import traceback
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import catalog_packs  # noqa: E402
from translation import checks, release, stages  # noqa: E402
from translation import config as config_module  # noqa: E402
from translation.ledger import IllegalTransition, Ledger  # noqa: E402
from translation.units import all_units, checksum, read_target, scheme_units, write_target  # noqa: E402

PACKS = config_module.PACKS_DIR
GUJARATI = {
    "name": "Gujarati",
    "script_ranges": [[2688, 2815]],
    "jurisdictions": ["maharashtra"],
    "magnitudes": {"lakh": ["લાખ"], "crore": ["કરોડ"]},
    "months": ["જાન્યુઆરી", "ફેબ્રુઆરી", "માર્ચ", "એપ્રિલ", "મે", "જૂન", "જુલાઈ", "ઓગસ્ટ", "સપ્ટેમ્બર", "ઓક્ટોબર", "નવેમ્બર", "ડિસેમ્બર"],
}
_BUNDLE = None


def bundle():
    global _BUNDLE
    if _BUNDLE is None:
        _BUNDLE = catalog_packs.load_dir(PACKS)
    return copy.deepcopy(_BUNDLE)


def config_with_gujarati(directory: Path):
    """Adding a language is only a config entry: nothing else in the pipeline changes."""
    shutil.copy(config_module.CONFIG_DIR / "glossary.json", directory / "glossary.json")
    raw = json.loads((config_module.CONFIG_DIR / "languages.json").read_text(encoding="utf-8"))
    raw["languages"]["gu"] = GUJARATI
    (directory / "languages.json").write_text(json.dumps(raw, ensure_ascii=False), encoding="utf-8")
    return config_module.load(directory)


def fake_translate(text: str) -> str:
    """Keeps numbers and links, renders units correctly, puts other letters in Gujarati."""
    links = checks.URL_RE.findall(text) + checks.EMAIL_RE.findall(text)
    for i, link in enumerate(links):
        text = text.replace(link, f"\x00{i}\x00")
    text = re.sub(r"(?i)\b(?:lakhs?|lacs?)\b|(?<=\d)\s?L\b", "લાખ", text)
    text = re.sub(r"(?i)\b(?:crores?|cr)\b\.?", "કરોડ", text)
    text = re.sub(r"[A-Za-z]", "ક", text)
    for i, link in enumerate(links):
        text = text.replace(f"\x00{i}\x00", link)
    return text


def run_engine(batch_file: Path, out: Path, translate=fake_translate):
    with batch_file.open(encoding="utf-8") as src, out.open("w", encoding="utf-8") as dst:
        for row in map(json.loads, src):
            en = row["en"]
            value = [translate(x) for x in en] if isinstance(en, list) else translate(en)
            dst.write(json.dumps({"unit": row["unit"], "checksum": row["checksum"], "translation": value}, ensure_ascii=False) + "\n")


class Env:
    """A temp workspace with Gujarati configured and an empty ledger."""

    def __enter__(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self._tmp.name)
        self.config = config_with_gujarati(self.dir)
        self.ledger = Ledger("gu", self.dir / "ledger")
        self.bundle = bundle()
        return self

    def __exit__(self, *_):
        self._tmp.cleanup()

    def translate_batch(self, name="b1", **export):
        batch = self.dir / f"{name}.jsonl"
        out = self.dir / f"{name}.out.jsonl"
        info = stages.export_batch(self.bundle, self.config, "gu", self.ledger, batch, name, **export)
        run_engine(batch, out)
        return info, stages.ingest(self.bundle, self.config, "gu", self.ledger, out, "indictrans2", "test")

    def approve(self, name="b1", reviewer="Reviewer"):
        report = self.dir / f"{name}.md"
        stages.report(self.ledger, self.bundle, self.config, "gu", name, report)
        return stages.approve_batch(self.ledger, name, reviewer, report)


# ---- checks ----------------------------------------------------------------

def _lang(code="hi"):
    cfg = config_module.load()
    return cfg.language(code), cfg


def test_lakh_turned_into_crore_is_blocked():
    lang, cfg = _lang()
    found = checks.check("Loan up to Rs 5 lakh for units", "इकाइयों के लिए ₹5 करोड़ तक का ऋण", lang, cfg)
    assert {"lakh_mismatch", "crore_mismatch"} <= {f.code for f in found}
    assert checks.verdict(found) == "failed"


def test_changed_number_is_blocked_and_native_digits_compare_equal():
    lang, cfg = _lang()
    assert checks.verdict(checks.check("Subsidy of 25% for 10 years", "10 वर्षों के लिए 35% सब्सिडी", lang, cfg)) == "failed"
    assert checks.verdict(checks.check("Subsidy of 25% for 10 years", "१० वर्षों के लिए २५% सब्सिडी दी जाती है", lang, cfg)) == "checked"


def test_list_items_must_align():
    lang, cfg = _lang()
    assert checks.check(["one step", "two step"], ["एक चरण"], lang, cfg)[0].code == "list_length_mismatch"


def test_wrong_script_and_english_left_behind_are_blocked():
    lang, cfg = _lang()
    codes = {f.code for f in checks.check("Apply on the portal", "Apply on the portal", lang, cfg)}
    assert {"wrong_script", "same_as_english"} <= codes
    tamil = checks.check("Apply on the portal", "போர்ட்டலில் விண்ணப்பிக்கவும்", lang, cfg)
    assert "wrong_script" in {f.code for f in tamil}


def test_changed_link_is_blocked_but_trailing_slash_is_not():
    lang, cfg = _lang()
    en = "Apply at https://udyam.gov.in/ when open"
    assert checks.verdict(checks.check(en, "खुलने पर https://udyam.gov.in पर आवेदन करें", lang, cfg)) != "failed"
    assert "link_changed" in {f.code for f in checks.check(en, "खुलने पर https://fake.in पर आवेदन करें", lang, cfg)}


def test_acronyms_and_place_names_do_not_false_alarm():
    lang, cfg = _lang("ta")
    assert checks.verdict(checks.check("AICs", "AICs", lang, cfg)) == "checked"
    assert not [f for f in checks.check("Lakshadweep", "லட்சத்தீவு", lang, cfg) if f.severity == checks.BLOCK]


def test_marathi_copied_from_hindi_is_flagged():
    lang, cfg = _lang("mr")
    text = "उद्योगों के लिए राज्य की योजना का लाभ"
    found = checks.check("State scheme benefit for the industries", text, lang, cfg, {"hi": text})
    assert "same_as_sibling" in {f.code for f in found}


# ---- ledger and flow -------------------------------------------------------

def test_ledger_survives_a_crash_at_the_tail_but_not_corruption():
    with tempfile.TemporaryDirectory() as tmp:
        ledger = Ledger("gu", Path(tmp))
        ledger.append([{"unit": "A|name", "state": "queued", "checksum": "x"}])
        with ledger.path.open("a", encoding="utf-8") as handle:
            handle.write('{"unit":"B|name","sta')
        assert Ledger("gu", Path(tmp)).state("A|name") == "queued"
        with ledger.path.open("a", encoding="utf-8") as handle:
            handle.write('\n{"unit":"C|name","state":"queued"}\n')
        try:
            Ledger("gu", Path(tmp))
        except ValueError:
            return
        raise AssertionError("corruption in the middle must be refused")


def test_illegal_transitions_are_refused():
    with tempfile.TemporaryDirectory() as tmp:
        ledger = Ledger("gu", Path(tmp))
        try:
            ledger.append([{"unit": "A|name", "state": "written"}])
        except IllegalTransition:
            assert not ledger.path.exists()
            return
        raise AssertionError("a unit cannot be written without being approved")


def test_export_resumes_without_requeueing():
    with Env() as env:
        first, _ = env.translate_batch("b1", limit=20)
        assert first["queued"] == 20
        second = stages.export_batch(env.bundle, env.config, "gu", env.ledger, env.dir / "b2.jsonl", "b2", limit=20)
        batch_one = {json.loads(x)["unit"] for x in (env.dir / "b1.jsonl").read_text(encoding="utf-8").splitlines()}
        batch_two = {json.loads(x)["unit"] for x in (env.dir / "b2.jsonl").read_text(encoding="utf-8").splitlines()}
        assert second["queued"] == 20 and not batch_one & batch_two


def test_pending_translation_english_is_held_back_unless_asked():
    with Env() as env:
        target = env.bundle["scheme_catalog.json"]["data"]
        marked = next(s for s in target if s["provenance"]["jurisdiction"] == "maharashtra")
        marked["provenance"].setdefault("master", {})["pending_translation"] = True
        held = [
            u for _, u in stages.planned(env.bundle, env.config, "gu")
            if u.pending and not stages.is_government_name(u, env.config)
        ]
        assert held
        info = stages.export_batch(env.bundle, env.config, "gu", env.ledger, env.dir / "b.jsonl", "b")
        assert len(held) == info["skipped"]["pending_translation"]
        queued = {json.loads(x)["unit"] for x in (env.dir / "b.jsonl").read_text(encoding="utf-8").splitlines()}
        assert not queued & {u.key for u in held}


def test_engine_must_be_registered_and_english_must_match():
    with Env() as env:
        batch = env.dir / "b.jsonl"
        stages.export_batch(env.bundle, env.config, "gu", env.ledger, batch, "b", limit=1)
        out = env.dir / "o.jsonl"
        run_engine(batch, out)
        try:
            stages.ingest(env.bundle, env.config, "gu", env.ledger, out, "made_up_engine", "1")
            raise AssertionError("an unregistered engine must be refused")
        except ValueError:
            pass
        row = json.loads(out.read_text(encoding="utf-8"))
        row["checksum"] = "stale"
        out.write_text(json.dumps(row), encoding="utf-8")
        counts = stages.ingest(env.bundle, env.config, "gu", env.ledger, out, "indictrans2", "1")
        assert counts == {"english_changed_since_export": 1}


def test_approval_needs_a_report_and_an_independent_reviewer():
    with Env() as env:
        batch = env.dir / "b.jsonl"
        stages.export_batch(env.bundle, env.config, "gu", env.ledger, batch, "b", limit=5)
        out = env.dir / "o.jsonl"
        run_engine(batch, out)
        stages.ingest(env.bundle, env.config, "gu", env.ledger, out, "claude", "run1")
        report = env.dir / "b.md"
        stages.report(env.ledger, env.bundle, env.config, "gu", "b", report)
        for reviewer, file in (("Roger", env.dir / "missing.md"), ("claude", report)):
            try:
                stages.approve_batch(env.ledger, "b", reviewer, file)
                raise AssertionError("approval must be refused")
            except ValueError:
                pass
        assert stages.approve_batch(env.ledger, "b", "Roger", report) > 0


# ---- release ---------------------------------------------------------------

def test_noop_rewrite_is_byte_identical():
    with tempfile.TemporaryDirectory() as tmp:
        release._write(bundle(), Path(tmp))
        assert release._sha_all(Path(tmp)) == release._sha_all(PACKS)


def test_new_language_end_to_end_changes_nothing_else():
    with Env() as env:
        env.translate_batch(tier="core", jurisdiction="maharashtra")
        assert env.approve() > 500
        before = release._sha_all(PACKS)
        out = env.dir / "candidate"
        result = release.release(env.config, "gu", env.ledger, PACKS, out)
        assert result["published"], result
        rebuilt = catalog_packs.load_dir(out)
        assert release.gate(env.bundle, rebuilt, env.config, "gu") == []
        schemes = [s for s in rebuilt["scheme_catalog.json"]["data"] if s["localization"].get("gu")]
        assert schemes and all(s["provenance"]["jurisdiction"] == "maharashtra" for s in schemes)
        sample = schemes[0]
        assert "gu" in sample["content"]["languages"]["available"]
        assert "gu" not in sample["content"]["languages"]["offered"]
        assert sample["provenance"]["translationFlags"]["gu_is_machine_translation"] is True
        manifest = rebuilt["manifest.json"]["data"][0]
        assert {"code": "gu", "isActive": False} in manifest["languages"]
        assert "gu" in manifest["languageRegistry"]["jurisdictions"]["maharashtra"]["contentLanguages"]
        assert not Ledger("gu", env.dir / "ledger").in_state("approved")
        assert release._sha_all(PACKS) == before


def test_existing_translation_is_never_overwritten_without_supersede():
    with Env() as env:
        hi = Ledger("hi", env.dir / "ledger")
        entity, unit = next((e, u) for e, u in stages.planned(env.bundle, env.config, "hi") if u.field == "name" and read_target(e, u, "hi"))
        before = read_target(entity, unit, "hi")
        base = {"unit": unit.key, "checksum": unit.source_checksum, "text": "नया नाम", "engine": "claude", "batch": "x"}
        hi.append([{**base, "state": "queued"}, {**base, "state": "checked"}, {**base, "state": "approved"}])
        applied = release.apply_events(env.bundle, "hi", hi)
        assert applied["outcome"] == {"existing_text_not_superseded": 1}
        assert read_target(entity, unit, "hi") == before
        hi.append([{**base, "state": "rejected"}, {**base, "state": "queued"}, {**base, "state": "checked"},
                   {**base, "state": "approved", "replaces": checksum("some other text")}])
        assert release.apply_events(env.bundle, "hi", hi)["outcome"] == {"existing_text_not_superseded": 1}
        hi.append([{**base, "state": "rejected"}, {**base, "state": "queued"}, {**base, "state": "checked"},
                   {**base, "state": "approved", "replaces": checksum(before)}])
        previous = bundle()
        applied = release.apply_events(env.bundle, "hi", hi)
        assert applied["outcome"] == {"written": 1} and read_target(entity, unit, "hi") == "नया नाम"
        assert release.gate(previous, env.bundle, env.config, "hi", applied["replaced_paths"]) == []


def test_english_change_after_approval_stops_the_write():
    with Env() as env:
        env.translate_batch(limit=3, tier="core", jurisdiction="maharashtra")
        env.approve()
        entity, unit = next((e, u) for e, u in all_units(env.bundle) if env.ledger.state(u.key) == "approved")
        path = next(p for p in unit.spec.en if read_target.__globals__["get_path"](entity, p) is not None)
        node = entity
        for part in path[:-1]:
            node = node[part]
        value = node[path[-1]]
        node[path[-1]] = [value[0] + " changed", *value[1:]] if isinstance(value, list) else value + " changed"
        assert release.apply_events(env.bundle, "gu", env.ledger)["outcome"]["english_changed"] == 1


def test_gate_catches_every_way_of_damaging_a_release():
    with Env() as env:
        previous = bundle()

        def damaged(change):
            candidate = copy.deepcopy(previous)
            change(candidate)
            return candidate

        schemes = "scheme_catalog.json"
        cases = {
            "english edited": lambda c: c[schemes]["data"][0]["source"]["name"].update(en="edited"),
            "other language removed": lambda c: c[schemes]["data"][0]["source"]["name"].update(hi=""),
            "facts edited": lambda c: c[schemes]["data"][0]["identity"].update(status="closed"),
            "scheme dropped": lambda c: c[schemes]["data"].pop(),
            "order changed": lambda c: c[schemes]["data"].reverse(),
            "release identity changed": lambda c: c["manifest.json"]["data"][0].update(catalogRelease="x"),
        }
        for name, change in cases.items():
            assert release.gate(previous, damaged(change), env.config, "gu"), name
        own = damaged(lambda c: c[schemes]["data"][0]["source"]["name"].update(hi="बदला"))
        assert release.gate(previous, own, env.config, "hi"), "overwriting own language needs a supersede"


def test_release_refuses_when_nothing_changed_and_leaves_output_empty():
    with Env() as env:
        out = env.dir / "candidate"
        result = release.release(env.config, "gu", env.ledger, PACKS, out)
        assert not result["published"] and not out.exists()


def test_failed_gate_publishes_nothing_and_keeps_ledger_state():
    with Env() as env:
        env.translate_batch(limit=2, tier="core", jurisdiction="maharashtra")
        approved = env.approve()
        original = release.gate
        release.gate = lambda *a, **k: ["forced failure"]
        try:
            out = env.dir / "candidate"
            result = release.release(env.config, "gu", env.ledger, PACKS, out)
        finally:
            release.gate = original
        assert not result["published"] and not out.exists()
        assert len(env.ledger.in_state("approved")) == approved


def test_stale_english_is_detected_from_baseline():
    with Env() as env:
        hi = Ledger("hi", env.dir / "ledger")
        assert stages.baseline(env.bundle, env.config, "hi", hi) > 1000
        audit = stages.audit(env.bundle, env.config, "hi", hi)
        assert not any(r.get("stale") for r in audit["rows"].values())
        env.bundle["scheme_catalog.json"]["data"][0]["source"]["name"]["en"] = "A changed English name"
        audit = stages.audit(env.bundle, env.config, "hi", hi)
        assert sum(r.get("stale", 0) for r in audit["rows"].values()) == 1


def test_every_scheme_unit_can_be_read_back_after_writing_for_a_new_language():
    for scheme in bundle()["scheme_catalog.json"]["data"]:
        for unit in scheme_units(scheme):
            assert write_target(scheme, unit, "gu", unit.en), unit.key
            assert read_target(scheme, unit, "gu") == unit.en, unit.key


def test_config_rejects_a_language_that_cannot_be_checked():
    with tempfile.TemporaryDirectory() as tmp:
        directory = Path(tmp)
        shutil.copy(config_module.CONFIG_DIR / "glossary.json", directory / "glossary.json")
        raw = json.loads((config_module.CONFIG_DIR / "languages.json").read_text(encoding="utf-8"))
        raw["languages"]["gu"] = {**GUJARATI, "magnitudes": {"lakh": ["લાખ"]}}
        (directory / "languages.json").write_text(json.dumps(raw, ensure_ascii=False), encoding="utf-8")
        try:
            config_module.load(directory)
        except config_module.ConfigError:
            return
        raise AssertionError("a language with no crore words must be refused")


def test_named_units_can_be_requeued_to_supersede_existing_text():
    with Env() as env:
        ledger = Ledger("ta", env.dir / "ledger")
        target = next(u for e, u in stages.planned(env.bundle, env.config, "ta") if read_target(e, u, "ta") is not None and u.field == "documents")
        info = stages.export_batch(env.bundle, env.config, "ta", ledger, env.dir / "s.jsonl", "s", only_units={target.key})
        assert info["queued"] == 1
        assert ledger.latest[target.key]["state"] == "queued"


def _name_unit(env):
    return next(u for _, u in stages.planned(env.bundle, env.config, "gu") if u.field == "name")


def test_government_names_are_never_sent_to_an_engine():
    with Env() as env:
        info = stages.export_batch(env.bundle, env.config, "gu", env.ledger, env.dir / "b.jsonl", "b")
        fields = {json.loads(x)["field"] for x in (env.dir / "b.jsonl").read_text(encoding="utf-8").splitlines()}
        assert info["skipped"]["government_name"] > 0
        assert not fields & {"name", "short_name", "alt_names", "authority"}


def _official_batch(env, translation, **extra):
    stages.export_batch(env.bundle, env.config, "gu", env.ledger, env.dir / "n.jsonl", "n", official_names=True)
    unit = _name_unit(env)
    line = {"unit": unit.key, "checksum": unit.source_checksum, "translation": translation, **extra}
    (env.dir / "n.out.jsonl").write_text(json.dumps(line, ensure_ascii=False) + "\n", encoding="utf-8")
    return unit


def test_a_machine_engine_cannot_supply_a_government_name():
    with Env() as env:
        unit = _official_batch(env, "ક ક ક", official_source="https://example.gov.in")
        counts = stages.ingest(env.bundle, env.config, "gu", env.ledger, env.dir / "n.out.jsonl", "claude", "r1")
        assert counts == {"government_name_refused": 1}
        assert env.ledger.latest[unit.key]["state"] == "failed"


def test_an_official_name_needs_its_source():
    with Env() as env:
        unit = _official_batch(env, "ક ક ક")
        counts = stages.ingest(env.bundle, env.config, "gu", env.ledger, env.dir / "n.out.jsonl", "official", "r1")
        assert counts == {"government_name_refused": 1}
        assert env.ledger.latest[unit.key]["state"] == "failed"


def test_an_official_name_with_a_source_is_accepted_and_traced():
    with Env() as env:
        unit = _official_batch(env, "કકક કકક કકક", official_source="https://example.gov.in/gu")
        stages.ingest(env.bundle, env.config, "gu", env.ledger, env.dir / "n.out.jsonl", "official", "r1")
        event = env.ledger.latest[unit.key]
        assert event["state"] in ("checked", "needs_review")
        assert event["official_source"] == "https://example.gov.in/gu"


def test_a_reviewer_cannot_approve_a_government_name_without_a_source():
    with Env() as env:
        unit = _official_batch(env, "ક ક ક", official_source="https://example.gov.in")
        stages.ingest(env.bundle, env.config, "gu", env.ledger, env.dir / "n.out.jsonl", "claude", "r1")
        decision = {"unit": unit.key, "decision": "approve", "text": "ક ક ક", "override_reason": "looks fine"}
        (env.dir / "d.jsonl").write_text(json.dumps(decision, ensure_ascii=False) + "\n", encoding="utf-8")
        counts = stages.decide(env.ledger, env.bundle, env.config, "gu", env.dir / "d.jsonl", "owner")
        assert counts == {"refused_government_name": 1}


def test_a_state_name_must_survive_inside_translated_text():
    config = config_module.load()
    language = config.language("mr")
    en = "Available to enterprises in Tamil Nadu only"
    bad = checks.check(en, "फक्त एका दक्षिणेकडील राज्यातील उद्योगांसाठी उपलब्ध", language, config)
    assert "government_name_changed" in {f.code for f in bad}
    assert checks.verdict(bad) == "failed"
    good = checks.check(en, "फक्त तमिळनाडू मधील उद्योगांसाठी उपलब्ध", language, config)
    assert "government_name_changed" not in {f.code for f in good}


if __name__ == "__main__":
    tests = [(n, f) for n, f in sorted(globals().items()) if n.startswith("test_") and callable(f)]
    failed = 0
    for name, test in tests:
        try:
            test()
            print(f"ok   {name}")
        except Exception:
            failed += 1
            print(f"FAIL {name}")
            traceback.print_exc()
    print(f"{len(tests) - failed}/{len(tests)} passed")
    sys.exit(1 if failed else 0)
