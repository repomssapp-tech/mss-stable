#!/usr/bin/env python3
"""Verify a built catalog bundle against the 2026 scheme source files.

Checks (exit code 1 on any failure, report written as JSON):
  * the core file and every pack are real GZIP, decompress and decode as UTF-8 JSON; each pack's
    sha256 matches the core manifest; merged, they hold every scheme
  * scheme count equals the source count (overall and per jurisdiction)
  * ids are unique and every source id is present
  * every packaged `source` block is deep-equal to the source record
    (nothing silently dropped or altered, Tamil/Hindi/Marathi included)
  * each language's name/description/benefits survive in `localization`
  * one pack per jurisdiction (schemes, applicability and search rows only), tenant ids, central
    required; the embedded manifest (release, record counts, language registry) matches the payload
  * hi/ta text of every scheme, and authority/institution translations, are
    embedded (the former language packs); the id map is embedded
  * no packaged scheme references an unknown scheme id

Usage:
  python tools/verify_scheme_bundle.py --new-dir <schemes_json_only> --bundle-dir <dir with catalog_core.json.gz and the packs>
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import sys
from pathlib import Path

import catalog_packs

APP_FILES = {
    "central": "f1_central/central_schemes_app_2026.json",
    "tamil_nadu": "f2_tamil_nadu/tamil_nadu_schemes_app_2026.json",
    "maharashtra": "f3_maharashtra/maharashtra_schemes_app_2026.json",
}


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def load_gz(path: Path):
    raw = path.read_bytes()
    if raw[:2] != b"\x1f\x8b":
        raise ValueError(f"{path.name} is not GZIP data (magic bytes {raw[:2]!r})")
    return json.loads(gzip.decompress(raw).decode("utf-8"))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--new-dir", required=True, type=Path)
    ap.add_argument("--bundle-dir", required=True, type=Path)
    ap.add_argument("--report", type=Path, default=None)
    args = ap.parse_args()

    failures: list[str] = []
    checks: dict[str, object] = {}

    def check(name: str, ok: bool, detail=None):
        checks[name] = {"ok": bool(ok), "detail": detail}
        if not ok:
            failures.append(f"{name}: {detail}")

    for gz in catalog_packs.pack_files(args.bundle_dir):  # real GZIP, every file
        load_gz(gz)
    try:
        bundle = catalog_packs.load_dir(args.bundle_dir)  # verifies each pack's sha256
    except Exception as exc:  # reported as a failed check, not a crash
        print("FAIL pack_load:", exc, file=sys.stderr)
        return 1
    check("gzip_utf8_json", isinstance(bundle, dict) and "scheme_catalog.json" in bundle,
          sorted(bundle)[:3] if isinstance(bundle, dict) else type(bundle).__name__)
    entities = bundle["scheme_catalog.json"]["data"]
    by_id = {e["identity"]["id"]: e for e in entities}

    source: dict[str, dict] = {}
    per_jur: dict[str, int] = {}
    for jur, rel in APP_FILES.items():
        recs = read_json(args.new_dir / rel)["schemes"]
        per_jur[jur] = len(recs)
        for r in recs:
            source[r["id"]] = r
    check("scheme_count", len(entities) == len(source) == len(by_id),
          {"bundle": len(entities), "source": len(source), "uniqueIds": len(by_id)})
    jur_counts: dict[str, int] = {}
    for e in entities:
        jur = e["provenance"]["jurisdiction"]
        jur_counts[jur] = jur_counts.get(jur, 0) + 1
    check("per_jurisdiction_counts", jur_counts == per_jur, {"bundle": jur_counts, "source": per_jur})
    check("all_source_ids_present", set(source) == set(by_id), sorted(set(source) ^ set(by_id))[:10])

    mismatched = [sid for sid, rec in source.items() if by_id.get(sid, {}).get("source") != rec]
    check("source_blocks_deep_equal", not mismatched, mismatched[:10])

    lost_text = []
    for sid, rec in source.items():
        loc = by_id[sid]["localization"]
        for lang in rec["name"]:
            if loc.get(lang, {}).get("name") != rec["name"][lang]:
                lost_text.append(f"{sid}:{lang}:name")
            for key, field in (("description", "description"), ("benefitsText", "benefits"),
                               ("eligibilityText", "eligibility")):
                want = [x for x in (rec.get(field) or {}).get(lang) or [] if str(x).strip()]
                got = loc.get(lang, {}).get(key)
                if want and got != "\n".join(str(x).strip() for x in want):
                    lost_text.append(f"{sid}:{lang}:{key}")
    check("localized_text_preserved", not lost_text, lost_text[:10])

    langs_by_jur: dict[str, set] = {}
    for e in entities:
        langs_by_jur.setdefault(e["provenance"]["jurisdiction"], set()).update(e["localization"])
    expected = {"central": {"en", "hi", "ta"}, "tamil_nadu": {"en", "ta"}, "maharashtra": {"en", "hi", "mr"}}
    check("language_coverage_per_jurisdiction", langs_by_jur == expected,
          {k: sorted(v) for k, v in langs_by_jur.items()})

    dangling = [(e["identity"]["id"], r["entityId"]) for e in entities
                for r in e["relationships"]["references"]
                if r.get("entityType") == "scheme" and r["entityId"] not in by_id]
    check("scheme_references_resolve", not dangling, dangling[:10])

    # --- packs: one core file plus one file per jurisdiction -------------------
    side_files = sorted(
        f.name for f in args.bundle_dir.iterdir()
        if f.name.startswith("catalog_pack_") or f.name in ("scheme_id_map.json", "scheme_supplement_legacy.json"))
    check("no_stray_side_files_next_to_packs", not side_files, side_files)
    check("legacy_single_bundle_absent", not (args.bundle_dir / catalog_packs.LEGACY_BUNDLE_FILE).exists(),
          catalog_packs.LEGACY_BUNDLE_FILE)
    pack_infos = [p for p in bundle["manifest.json"]["data"][0].get("packs", []) if p.get("kind") == "jurisdiction"]
    check("packs_cover_every_jurisdiction",
          sorted(p["jurisdiction"] for p in pack_infos) == sorted(per_jur), [p["id"] for p in pack_infos])
    check("pack_files_match_manifest",
          all((args.bundle_dir / p["file"]).exists()
              and (args.bundle_dir / p["file"]).stat().st_size == p["bytes"] for p in pack_infos),
          [p["file"] for p in pack_infos])
    wrong_home, wrong_counts = [], []
    for info in pack_infos:
        pack = catalog_packs.load_gz(args.bundle_dir / info["file"])
        for section in catalog_packs.PARTITIONED:
            rows = pack[section]["data"]
            if len(rows) != info["recordCounts"][section]:
                wrong_counts.append((info["id"], section, len(rows), info["recordCounts"][section]))
        for e in pack[catalog_packs.SCHEME_SECTION]["data"]:
            if (e.get("provenance") or {}).get("jurisdiction") != info["jurisdiction"]:
                wrong_home.append((info["id"], e["identity"]["id"]))
        if set(pack) != {catalog_packs.PACK_SECTION, *catalog_packs.PARTITIONED}:
            wrong_home.append((info["id"], "unexpected sections", sorted(pack)))
    check("each_pack_holds_only_its_own_jurisdiction", not wrong_home, wrong_home[:6])
    check("pack_record_counts_match_manifest", not wrong_counts, wrong_counts[:6])
    check("packs_carry_tenant_id_and_central_is_required",
          all(p.get("tenantId") for p in pack_infos)
          and all(p["required"] == (p["jurisdiction"] in catalog_packs.REQUIRED_JURISDICTIONS) for p in pack_infos),
          [(p["id"], p.get("tenantId"), p["required"]) for p in pack_infos])
    core_only = catalog_packs.load_gz(args.bundle_dir / catalog_packs.CORE_FILE)
    check("core_holds_no_schemes", not core_only[catalog_packs.SCHEME_SECTION]["data"],
          len(core_only[catalog_packs.SCHEME_SECTION]["data"]))

    manifest = bundle["manifest.json"]["data"][0]
    sections = {k: v for k, v in bundle.items() if k.endswith("_catalog.json")}
    counts = manifest.get("recordCounts", {})
    wrong = {k: (counts.get(k), len(v["data"])) for k, v in sections.items() if counts.get(k) != len(v["data"])}
    check("manifest_record_counts_match_sections", not wrong and len(counts) == len(sections), wrong or len(counts))
    check("manifest_entity_count", manifest.get("entityCount") == sum(len(v["data"]) for v in sections.values()),
          manifest.get("entityCount"))
    check("manifest_identifies_release", bool(manifest.get("release", {}).get("releaseTag"))
          and manifest.get("bundleFormat") == 3, manifest.get("release"))

    # --- metadata must describe the data, everywhere ---------------------------
    inventory = {f["fileName"]: f for f in manifest.get("files", [])}
    inconsistent = []
    for name in list(sections) + ["search_index.json"]:
        body = bundle[name]
        data, meta = body["data"], body["metadata"]
        entry = inventory.get(name)
        if entry is None:
            inconsistent.append((name, "missing from manifest.files"))
            continue
        canonical = json.dumps(data, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
        actual_sum = "sha256:" + hashlib.sha256(canonical.encode("utf-8")).hexdigest()
        facts = {
            "data length": len(data),
            "metadata.recordCount": meta.get("recordCount"),
            "manifest.files recordCount": entry.get("recordCount"),
        }
        if name in counts:
            facts["manifest.recordCounts"] = counts[name]
        if len(set(facts.values())) != 1:
            inconsistent.append((name, facts))
        if not (entry.get("checksum") == meta.get("checksum") == actual_sum):
            inconsistent.append((name, "checksum differs between data, metadata and manifest.files"))
        if entry.get("schemaVersion") != meta.get("schemaVersion"):
            inconsistent.append((name, f"schemaVersion {entry.get('schemaVersion')} vs {meta.get('schemaVersion')}"))
    extra = sorted(set(inventory) - set(sections) - {"search_index.json"})
    if extra:
        inconsistent.append(("manifest.files", f"lists sections not in the bundle: {extra}"))
    check("sections_metadata_manifest_all_agree", not inconsistent, inconsistent[:6])

    release_tag = manifest.get("release", {}).get("releaseTag")
    check("release_identity_consistent",
          release_tag == manifest.get("catalogRelease")
          and manifest.get("release", {}).get("releasedAt") == manifest.get("releasedAt"),
          {"release": manifest.get("release"), "catalogRelease": manifest.get("catalogRelease"),
           "releasedAt": manifest.get("releasedAt")})
    check("build_history_kept_apart_from_current_state",
          "history" in manifest and not any(k in manifest for k in ("generationOrder", "reservedFiles", "stageBPasses")),
          sorted(manifest))

    # --- jurisdiction: dataset origin vs where the scheme applies --------------
    bad_gov = []
    for e in entities:
        gov = e["content"]["classification"]["government"]
        if gov.get("originDataset") != e["provenance"]["jurisdiction"] or not isinstance(gov.get("appliesNationally"), bool):
            bad_gov.append(e["identity"]["id"])
        if gov.get("appliesNationally") and gov.get("states"):
            bad_gov.append(f"{e['identity']['id']}: national scheme lists states {gov['states']}")
    check("jurisdiction_fields_explicit", not bad_gov, bad_gov[:6])

    def gov_of(sid):
        return by_id[sid]["content"]["classification"]["government"]

    def shape(g):
        return tuple(g.get(k) for k in ("level", "sourceLevel", "appliesNationally", "states"))

    check("tn_dataset_exceptions_handled",
          shape(gov_of("TN2026-049")) == ("central", "central", True, [])
          and shape(gov_of("TN2026-044")) == ("state", "central_state", False, ["IN-TN"]),
          {"TN2026-049": shape(gov_of("TN2026-049")), "TN2026-044": shape(gov_of("TN2026-044"))})

    # --- legacy identifiers: one entry per code, never an exact repeat ---------
    dup_codes = []
    for e in entities:
        codes = [lc["code"] for lc in e["identity"]["legacyCodes"]]
        if len(codes) != len(set(codes)):
            dup_codes.append(e["identity"]["id"])
    check("legacy_codes_unique_per_scheme", not dup_codes, dup_codes[:6])

    offered = {j: e["offeredLanguages"] for j, e in manifest["languageRegistry"]["jurisdictions"].items()}
    check("offered_languages_match_policy",
          offered == {"central": ["en", "hi", "ta"], "tamil_nadu": ["en", "ta"], "maharashtra": ["en", "hi"]}, offered)
    inactive = [l["code"] for l in manifest["languages"] if not l["isActive"]]
    check("marathi_preserved_but_not_offered", "mr" in inactive and
          any("mr" in e["localization"] for e in entities), inactive)

    # Hindi/Tamil of every scheme travel with the scheme (the old packs' scheme rows)
    missing_lang = []
    for lang in ("hi", "ta"):
        want = {sid for sid, rec in source.items() if lang in rec["name"]}
        have = {e["identity"]["id"] for e in entities if (e["localization"].get(lang) or {}).get("name")}
        if want != have:
            missing_lang.append((lang, sorted(want ^ have)[:5]))
    check("hi_ta_translations_embedded_in_schemes", not missing_lang, missing_lang)

    # authority/institution translations that used to be pack rows
    translated = {t: sum(1 for e in bundle[f"{t}_catalog.json"]["data"] if "hi" in e.get("localization", {}) or "ta" in e.get("localization", {}))
                  for t in ("authority", "institution")}
    check("authority_institution_translations_embedded", translated["authority"] > 100 and translated["institution"] > 50,
          translated)

    # the duplicate list fields were removed; the verbatim lists live in `source`
    dup = [e["identity"]["id"] for e in entities
           if any(k.endswith("List") for loc in e["localization"].values() for k in loc)]
    check("no_duplicate_list_fields_in_localization", not dup, dup[:5])

    id_map = bundle.get("migrations.json", {}).get("schemeIdMap", {})
    check("id_map_embedded_and_covers_new_ids", bool(id_map) and set(by_id) <= set(id_map.values()),
          sorted(set(by_id) - set(id_map.values()))[:10])

    report = {"ok": not failures, "bundleBytes": catalog_packs.total_bytes(args.bundle_dir),
              "checks": checks}
    text = json.dumps(report, ensure_ascii=False, indent=2)
    if args.report:
        args.report.write_text(text + "\n", encoding="utf-8")
    print(text)
    for f in failures:
        print("FAIL", f, file=sys.stderr)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
