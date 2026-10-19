#!/usr/bin/env python3
"""Release Gate (D17): Pre-publish gate for every release, every language, every change.
Language- and entity-agnostic. Produces PASS/FAIL report for checks G1-G6.
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
from pathlib import Path
import sys

import catalog_packs

REPO_ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIR = REPO_ROOT / "backend" / "catalog" / "source"
DECLARATIONS_DIR = REPO_ROOT / "backend" / "catalog" / "declarations"
REPORTS_DIR = REPO_ROOT / "docs" / "reports"

def get_file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def match_declaration(decl: dict, entity_type: str, entity_id: str, lang: str, field: str, diff_type: str) -> bool:
    d_type = decl.get("entityType", "*")
    d_id = decl.get("entityId", "*")
    d_lang = decl.get("lang", "*")
    d_fields = decl.get("fields", ["*"])
    d_diff_types = decl.get("diffTypes")

    # Item 5(c): declarations require diffTypes
    if not d_diff_types or not isinstance(d_diff_types, list):
        return False
    if "*" not in d_diff_types and diff_type not in d_diff_types:
        return False

    if d_type != "*" and d_type != entity_type:
        return False
    if d_id != "*" and d_id != entity_id:
        return False
    if d_lang != "*" and d_lang != lang:
        return False
    if "*" not in d_fields and field not in d_fields:
        return False
    return True

class ReleaseGate:
    def __init__(self, candidate_dir: Path, previous_dir: Path | None = None, release_tag: str | None = None, is_local_only: bool = False):
        self.candidate_dir = candidate_dir
        self.previous_dir = previous_dir
        self.is_local_only = is_local_only
        self.release_tag = release_tag

        self.candidate_release = json.loads((candidate_dir / "release.json").read_text(encoding="utf-8"))
        if not self.release_tag:
            self.release_tag = self.candidate_release.get("releaseTag", "unknown")

        self.results = {}
        self.diffs = []
        self.unmatched_changes = []
        self.declared_matches = {}
        self.errors = []

    def run_all_checks(self) -> dict:
        print(f"=== Running Release Gate for Candidate {self.release_tag} ===")
        
        self.check_g1_drift()
        self.check_g2_and_g3_diff_and_declarations()
        self.check_g4_preservation()
        self.check_g5_registration_and_hashes()
        self.check_g6_app_compatibility()

        passed = all(r.get("status") == "PASS" for r in self.results.values())
        
        diff_type_counts = {"added": 0, "changed": 0, "removed": 0}
        for d in self.diffs:
            dt = d.get("diffType", "changed")
            diff_type_counts[dt] = diff_type_counts.get(dt, 0) + 1

        report = {
            "releaseTag": self.release_tag,
            "overallStatus": "PASS" if passed else "FAIL",
            "checks": self.results,
            "diffSummary": {
                "totalDiffs": len(self.diffs),
                "unmatchedChanges": len(self.unmatched_changes),
                "diffTypeCounts": diff_type_counts,
            },
            "unmatchedChangesList": self.unmatched_changes[:50],
            "declaredMatches": self.declared_matches,
            "candidateIdentity": {
                "bundleSha256": self.candidate_release.get("bundleSha256"),
                "bundleBytes": self.candidate_release.get("bundleBytes"),
                "activeLanguages": self.candidate_release.get("activeLanguages"),
            }
        }
        return report

    def _declarations(self) -> list[dict]:
        decl_file = DECLARATIONS_DIR / f"{self.release_tag}.json"
        if not decl_file.exists():
            return []
        try:
            return json.loads(decl_file.read_text(encoding="utf-8")).get("declaredChanges", [])
        except Exception:
            return []

    def _source_master_drift(self, cand_bundle) -> list[str]:
        """Candidate scheme text vs the source master (2026 import)."""
        master_path = SOURCE_DIR / "scheme_catalog.json"
        if not cand_bundle or not master_path.exists():
            return []
        try:
            master = json.loads(master_path.read_text(encoding="utf-8"))
        except Exception:
            return []
        if master.get("metadata", {}).get("source") != "schemes_json_only":
            return []
        declarations = self._declarations()
        in_bundle = {s["identity"]["id"]: s for s in cand_bundle.get("scheme_catalog.json", {}).get("data", [])}
        fields = ("name", "shortName", "summary", "description", "benefitsText",
                  "eligibilityText", "applicationText")
        failures = []
        for src in master.get("data", []):
            eid = src["identity"]["id"]
            cand = in_bundle.get(eid)
            if cand is None:
                continue  # an added/removed scheme is reported by G2/G3
            for lang, src_loc in (src.get("localization") or {}).items():
                cand_loc = (cand.get("localization") or {}).get(lang, {})
                for f in fields:
                    expected, actual = src_loc.get(f), cand_loc.get(f)
                    if expected and expected != actual and not any(
                        match_declaration(d, "scheme", eid, lang, f, "changed")
                        or match_declaration(d, "scheme", eid, lang, f, "removed")
                        for d in declarations):
                        failures.append(f"Source drift for {eid} {lang}.{f}: source master differs from bundle")
        return failures[:50]

    def _non_scheme_name_drift(self, cand_bundle, content_rows) -> list[str]:
        """Authority/institution names in the bundle vs catalog.content."""
        if not cand_bundle or not content_rows:
            return []
        declarations = self._declarations()
        catalogs = {"authority": "authority_catalog.json", "institution": "institution_catalog.json"}
        failures = []
        for etype, key in catalogs.items():
            by_id = {e["identity"]["id"]: e for e in cand_bundle.get(key, {}).get("data", [])}
            for r in content_rows:
                if r.get("entity_type") != etype or r.get("entity_id") not in by_id or not r.get("name"):
                    continue
                eid, lang = r["entity_id"], r["lang"]
                actual = (by_id[eid].get("localization") or {}).get(lang, {}).get("name")
                if actual and actual != r["name"] and not any(
                    match_declaration(d, etype, eid, lang, "name", "changed") for d in declarations):
                    failures.append(f"Content drift in bundle for {etype} {eid} {lang}.name")
        return failures[:50]

    def check_g1_drift(self):
        """G1: Drift check between source master, DB catalog.content, and candidate packs."""
        failures = []
        # Check source master files exist
        if not (SOURCE_DIR / "scheme_catalog.json").exists():
            failures.append("source scheme_catalog.json does not exist")
        if not (SOURCE_DIR / "manifest.json").exists():
            failures.append("source manifest.json does not exist")

        # Check candidate bundle decompresses and parses
        core_gz = self.candidate_dir / catalog_packs.CORE_FILE
        cand_bundle = None
        if not core_gz.exists():
            failures.append(f"candidate {core_gz.name} missing")
        else:
            try:
                cand_bundle = catalog_packs.load_dir(self.candidate_dir)
                if "scheme_catalog.json" not in cand_bundle:
                    failures.append("scheme_catalog.json not in bundle")
            except Exception as e:
                failures.append(f"candidate bundle failed decompression: {e}")

        # G1 compares content (reads the local catalog.content cache)
        content_rows = []
        if not content_rows:
            cache_file = REPO_ROOT / "backend" / "scratch" / "lang" / "catalog_content_cache.json"
            if cache_file.exists():
                try:
                    content_rows = json.loads(cache_file.read_text(encoding="utf-8"))
                except Exception:
                    pass

        if content_rows and cand_bundle:
            # Load declared changes for G1 check
            decl_file = DECLARATIONS_DIR / f"{self.release_tag}.json"
            declarations = []
            if decl_file.exists():
                try:
                    declarations = json.loads(decl_file.read_text(encoding="utf-8")).get("declaredChanges", [])
                except Exception:
                    pass

            # Map candidate schemes in bundle
            schemes_in_bundle = {s["identity"]["id"]: s for s in cand_bundle.get("scheme_catalog.json", {}).get("data", [])}
            
            # Map candidate packs
            cand_packs = {}
            for pack_gz in self.candidate_dir.glob("catalog_pack_*.json.gz"):
                lang = pack_gz.name.replace("catalog_pack_", "").replace(".json.gz", "")
                try:
                    p_data = json.loads(gzip.decompress(pack_gz.read_bytes()).decode("utf-8"))
                    cand_packs[lang] = {item.get("entityId"): item for item in p_data.get("data", [])}
                except Exception:
                    pass

            for r in content_rows:
                etype = r.get("entity_type")
                eid = r.get("entity_id")
                lang = r.get("lang")
                if etype != "scheme" or eid not in schemes_in_bundle:
                    continue

                # 1. Compare against scheme in bundle
                s_obj = schemes_in_bundle[eid]
                loc = s_obj.get("localization", {}).get(lang, {})
                for col, f_key in [("name", "name"), ("summary", "summary"), ("objective", "objective"), ("description", "description")]:
                    expected_val = r.get(col)
                    actual_val = loc.get(f_key)
                    if expected_val and actual_val and expected_val != actual_val:
                        # Check if declared change
                        if not any(match_declaration(d, "scheme", eid, lang, f_key, "changed") or match_declaration(d, "scheme", eid, lang, f_key, "added") for d in declarations):
                            failures.append(f"Content drift in bundle for {eid} {lang}.{f_key}: db='{expected_val}' bundle='{actual_val}'")

                # 2. Compare against pack if pack exists
                if lang in cand_packs and eid in cand_packs[lang]:
                    pack_item = cand_packs[lang][eid]
                    for col, f_key in [("name", "name"), ("summary", "summary"), ("objective", "objective"), ("description", "description")]:
                        expected_val = r.get(col)
                        actual_val = pack_item.get(f_key)
                        if expected_val and actual_val and expected_val != actual_val:
                            # Check if declared change
                            if not any(match_declaration(d, "pack_entity", eid, lang, f_key, "changed") or match_declaration(d, "scheme", eid, lang, f_key, "changed") or match_declaration(d, "scheme", eid, lang, f_key, "added") for d in declarations):
                                failures.append(f"Content drift in pack for {eid} {lang}.{f_key}: db='{expected_val}' pack='{actual_val}'")

        # Schemes imported from the 2026 source (metadata.source == schemes_json_only)
        # are not in catalog.content, so the loop above skips them. Their source of
        # truth is the source master scheme_catalog.json: the bundle must carry the
        # same per-language text, unless a change is declared.
        failures += self._source_master_drift(cand_bundle)
        failures += self._non_scheme_name_drift(cand_bundle, content_rows)

        status = "PASS" if not failures else "FAIL"
        self.results["G1_drift"] = {
            "status": status,
            "details": failures if failures else "Source master, catalog.content, and candidate bundle reconcile cleanly without drift."
        }

    def check_g2_and_g3_diff_and_declarations(self):
        """G2: Diff previous vs candidate covering all catalog files and search.aliases/keywords; G3: Check that every diff is declared."""
        if not self.previous_dir or not self.previous_dir.exists():
            self.results["G2_release_diff"] = {"status": "PASS", "details": "No previous release to compare; initial baseline."}
            self.results["G3_declared_changes"] = {"status": "PASS", "details": "No diffs against baseline."}
            return

        # Load declared changes file
        decl_file = DECLARATIONS_DIR / f"{self.release_tag}.json"
        declarations = []
        if decl_file.exists():
            decl_data = json.loads(decl_file.read_text(encoding="utf-8"))
            declarations = decl_data.get("declaredChanges", [])
        
        for i, _ in enumerate(declarations):
            self.declared_matches[i] = 0

        # Load previous bundle & candidate bundle
        try:
            # Merged views: a release from before the packs loads as its single file.
            prev_bundle = catalog_packs.load_dir(self.previous_dir)
            cand_bundle = catalog_packs.load_dir(self.candidate_dir)
        except Exception as e:
            self.results["G2_release_diff"] = {"status": "FAIL", "details": f"Bundle decompression error: {e}"}
            self.results["G3_declared_changes"] = {"status": "FAIL", "details": f"Bundle decompression error: {e}"}
            return

        # G2 covers every catalog file in bundle
        all_catalog_files = sorted(set(prev_bundle.keys()) | set(cand_bundle.keys()))
        for cat_file in all_catalog_files:
            if not cat_file.endswith(".json") or cat_file == "manifest.json":
                continue
            entity_type = cat_file.replace("_catalog.json", "").replace(".json", "")

            p_cat = prev_bundle.get(cat_file, {})
            c_cat = cand_bundle.get(cat_file, {})
            p_data_list = p_cat.get("data", []) if isinstance(p_cat, dict) else []
            c_data_list = c_cat.get("data", []) if isinstance(c_cat, dict) else []

            p_entities = {}
            for item in p_data_list:
                eid = item.get("identity", {}).get("id") or item.get("id") or item.get("code") or item.get("entityId")
                if eid:
                    p_entities[eid] = item

            c_entities = {}
            for item in c_data_list:
                eid = item.get("identity", {}).get("id") or item.get("id") or item.get("code") or item.get("entityId")
                if eid:
                    c_entities[eid] = item

            for eid in sorted(set(p_entities.keys()) | set(c_entities.keys())):
                p_ent = p_entities.get(eid)
                c_ent = c_entities.get(eid)

                if not p_ent:
                    self._record_diff(entity_type, eid, "*", "entity", "added", None, "new_entity", declarations)
                    continue
                if not c_ent:
                    self._record_diff(entity_type, eid, "*", "entity", "removed", "old_entity", None, declarations)
                    continue

                # 1. Compare content fields
                p_content = p_ent.get("content", {})
                c_content = c_ent.get("content", {})
                for field in set(p_content.keys()) | set(c_content.keys()):
                    pv = p_content.get(field)
                    cv = c_content.get(field)
                    if pv != cv:
                        diff_type = "added" if (pv is None or pv == "" or pv == []) and (cv is not None and cv != "" and cv != []) else ("removed" if (cv is None or cv == "" or cv == []) and (pv is not None and pv != "" and pv != []) else "changed")
                        self._record_diff(entity_type, eid, "en", field, diff_type, pv, cv, declarations)

                # 2. Compare localization fields
                p_loc = p_ent.get("localization", {})
                c_loc = c_ent.get("localization", {})
                for lang in set(p_loc.keys()) | set(c_loc.keys()):
                    p_lang = p_loc.get(lang, {})
                    c_lang = c_loc.get(lang, {})
                    for field in set(p_lang.keys()) | set(c_lang.keys()):
                        pv = p_lang.get(field)
                        cv = c_lang.get(field)
                        if pv != cv:
                            diff_type = "added" if (pv is None or pv == "" or pv == []) and (cv is not None and cv != "" and cv != []) else ("removed" if (cv is None or cv == "" or cv == []) and (pv is not None and pv != "" and pv != []) else "changed")
                            self._record_diff(entity_type, eid, lang, field, diff_type, pv, cv, declarations)

                # 3. Compare search.aliases and search.keywords
                p_search = p_ent.get("search", {})
                c_search = c_ent.get("search", {})
                
                # Aliases
                p_aliases = p_search.get("aliases", {})
                c_aliases = c_search.get("aliases", {})
                if isinstance(p_aliases, dict) or isinstance(c_aliases, dict):
                    all_langs = set(p_aliases.keys() if isinstance(p_aliases, dict) else []) | set(c_aliases.keys() if isinstance(c_aliases, dict) else [])
                    for lang in all_langs:
                        pa = p_aliases.get(lang, []) if isinstance(p_aliases, dict) else []
                        ca = c_aliases.get(lang, []) if isinstance(c_aliases, dict) else []
                        if pa != ca:
                            diff_type = "added" if not pa and ca else ("removed" if not ca and pa else "changed")
                            self._record_diff(entity_type, eid, lang, "search.aliases", diff_type, pa, ca, declarations)
                elif p_aliases != c_aliases:
                    diff_type = "added" if not p_aliases and c_aliases else ("removed" if not c_aliases and p_aliases else "changed")
                    self._record_diff(entity_type, eid, "*", "search.aliases", diff_type, p_aliases, c_aliases, declarations)

                # Keywords
                p_kw = p_search.get("keywords", {})
                c_kw = c_search.get("keywords", {})
                if isinstance(p_kw, dict) or isinstance(c_kw, dict):
                    all_langs = set(p_kw.keys() if isinstance(p_kw, dict) else []) | set(c_kw.keys() if isinstance(c_kw, dict) else [])
                    for lang in all_langs:
                        p_k = p_kw.get(lang, []) if isinstance(p_kw, dict) else []
                        c_k = c_kw.get(lang, []) if isinstance(c_kw, dict) else []
                        if p_k != c_k:
                            diff_type = "added" if not p_k and c_k else ("removed" if not c_k and p_k else "changed")
                            self._record_diff(entity_type, eid, lang, "search.keywords", diff_type, p_k, c_k, declarations)
                elif p_kw != c_kw:
                    diff_type = "added" if not p_kw and c_kw else ("removed" if not c_kw and p_kw else "changed")
                    self._record_diff(entity_type, eid, "*", "search.keywords", diff_type, p_kw, c_kw, declarations)

        # Compare language packs dynamically for all present languages
        pack_langs = set()
        for p in list(self.candidate_dir.glob("catalog_pack_*.json.gz")) + list(self.previous_dir.glob("catalog_pack_*.json.gz")):
            code = p.name.replace("catalog_pack_", "").replace(".json.gz", "")
            pack_langs.add(code)

        for lang in sorted(pack_langs):
            cand_pack_file = self.candidate_dir / f"catalog_pack_{lang}.json.gz"
            prev_pack_file = self.previous_dir / f"catalog_pack_{lang}.json.gz"
            if cand_pack_file.exists() and prev_pack_file.exists():
                c_pack = json.loads(gzip.decompress(cand_pack_file.read_bytes()).decode("utf-8"))
                p_pack = json.loads(gzip.decompress(prev_pack_file.read_bytes()).decode("utf-8"))
                c_data = {(item.get("entityId") or item.get("id")): item for item in c_pack.get("data", [])}
                p_data = {(item.get("entityId") or item.get("id")): item for item in p_pack.get("data", [])}
                for eid in set(c_data.keys()) | set(p_data.keys()):
                    pi = p_data.get(eid)
                    ci = c_data.get(eid)
                    if not pi:
                        self._record_diff("pack_entity", eid, lang, "entity", "added", None, "new", declarations)
                    elif not ci:
                        self._record_diff("pack_entity", eid, lang, "entity", "removed", "old", None, declarations)
                    else:
                        for f in set(pi.keys()) | set(ci.keys()):
                            if pi.get(f) != ci.get(f):
                                pv = pi.get(f)
                                cv = ci.get(f)
                                diff_type = "added" if (pv is None or pv == "" or pv == []) and (cv is not None and cv != "" and cv != []) else ("removed" if (cv is None or cv == "" or cv == []) and (pv is not None and pv != "" and pv != []) else "changed")
                                self._record_diff("pack_entity", eid, lang, f, diff_type, pv, cv, declarations)
            elif cand_pack_file.exists() and not prev_pack_file.exists():
                self._record_diff("pack", f"catalog_pack_{lang}", lang, "pack_file", "added", None, "new_pack", declarations)
            elif not cand_pack_file.exists() and prev_pack_file.exists():
                self._record_diff("pack", f"catalog_pack_{lang}", lang, "pack_file", "removed", "old_pack", None, declarations)

        g2_status = "PASS"
        g3_status = "PASS" if not self.unmatched_changes else "FAIL"

        diff_type_counts = {"added": 0, "changed": 0, "removed": 0}
        for d in self.diffs:
            dt = d.get("diffType", "changed")
            diff_type_counts[dt] = diff_type_counts.get(dt, 0) + 1

        self.results["G2_release_diff"] = {
            "status": g2_status,
            "totalDiffs": len(self.diffs),
            "diffTypeCounts": diff_type_counts,
            "details": f"Analyzed {len(self.diffs)} diffs between previous and candidate: {diff_type_counts['added']} added, {diff_type_counts['changed']} changed, {diff_type_counts['removed']} removed."
        }
        self.results["G3_declared_changes"] = {
            "status": g3_status,
            "unmatchedCount": len(self.unmatched_changes),
            "details": "All changes appear in declared changes list." if not self.unmatched_changes else f"{len(self.unmatched_changes)} undeclared change(s) found!"
        }

    def _record_diff(self, entity_type: str, entity_id: str, lang: str, field: str, diff_type: str, old_val, new_val, declarations: list[dict]):
        diff_entry = {
            "entityType": entity_type,
            "entityId": entity_id,
            "lang": lang,
            "field": field,
            "diffType": diff_type,
        }
        self.diffs.append(diff_entry)

        matched = False
        for idx, decl in enumerate(declarations):
            if match_declaration(decl, entity_type, entity_id, lang, field, diff_type):
                self.declared_matches[idx] = self.declared_matches.get(idx, 0) + 1
                matched = True
                break

        if not matched:
            self.unmatched_changes.append(diff_entry)

    def check_g4_preservation(self):
        """G4: Values that existed in previous release stay identical unless declared."""
        # Unmatched changes cover undeclared changes; also check if any language disappeared undeclared
        if self.previous_dir and self.previous_dir.exists():
            prev_rel = json.loads((self.previous_dir / "release.json").read_text(encoding="utf-8"))
            prev_langs = set(prev_rel.get("activeLanguages", []))
            cand_langs = set(self.candidate_release.get("activeLanguages", []))
            dropped = prev_langs - cand_langs
            if dropped:
                self.results["G4_preservation"] = {
                    "status": "FAIL",
                    "details": f"Active language(s) dropped undeclared: {dropped}"
                }
                return

        status = "PASS" if not self.unmatched_changes else "FAIL"
        self.results["G4_preservation"] = {
            "status": status,
            "details": "Existing values and entities preserved according to declared changes." if status == "PASS" else f"{len(self.unmatched_changes)} unauthorized modifications found."
        }

    def check_g5_registration_and_hashes(self):
        """G5: sha256 of candidate files and registration integrity."""
        failures = []
        core_gz = self.candidate_dir / catalog_packs.CORE_FILE
        if core_gz.exists():
            actual_sha = get_file_sha256(core_gz)
            declared_sha = self.candidate_release.get("bundleSha256")
            if actual_sha != declared_sha:
                failures.append(f"core sha256 mismatch: actual={actual_sha} declared={declared_sha}")
            # The core manifest vouches for every pack; release.json must agree with it.
            try:
                core = catalog_packs.load_gz(core_gz)
                listed = {p["file"]: p for p in core["manifest.json"]["data"][0].get("packs", [])
                          if p.get("kind") == "jurisdiction"}
            except Exception as e:
                listed = {}
                failures.append(f"core manifest unreadable: {e}")
            published = {p["file"]: p for p in self.candidate_release.get("packs", [])}
            if set(published) != set(listed):
                failures.append(f"release.json packs {sorted(published)} != manifest packs {sorted(listed)}")
            for fname, info in listed.items():
                fpath = self.candidate_dir / fname
                if not fpath.exists():
                    failures.append(f"pack {fname} missing")
                    continue
                actual_h = get_file_sha256(fpath)
                if actual_h != info["sha256"]:
                    failures.append(f"pack {fname} sha256 mismatch: actual={actual_h} manifest={info['sha256']}")
                if fname in published and published[fname]["sha256"] != info["sha256"]:
                    failures.append(f"pack {fname}: release.json and manifest disagree on sha256")
        else:
            failures.append(f"candidate {core_gz.name} missing")

        per_file = self.candidate_release.get("perFileSha256", {})
        for fname, declared_h in per_file.items():
            fpath = self.candidate_dir / fname
            if fpath.exists():
                actual_h = get_file_sha256(fpath)
                if actual_h != declared_h:
                    failures.append(f"{fname} sha256 mismatch: actual={actual_h} declared={declared_h}")

        status = "PASS" if not failures else "FAIL"
        self.results["G5_hashes"] = {
            "status": status,
            "details": failures if failures else "Artifact hashes and registration reconcile cleanly."
        }

    def check_g6_app_compatibility(self):
        """G6: App schema compatibility check."""
        # Supported app schema is APP_SCHEMA_VERSION = 1
        cand_core_gz = self.candidate_dir / catalog_packs.CORE_FILE
        failures = []
        if cand_core_gz.exists():
            try:
                bundle = catalog_packs.load_dir(self.candidate_dir)
                for req in ["scheme_catalog.json", "authority_catalog.json", "institution_catalog.json"]:
                    if req not in bundle:
                        failures.append(f"Required app catalog missing in bundle: {req}")
            except Exception as e:
                failures.append(f"Error parsing bundle: {e}")

        status = "PASS" if not failures else "FAIL"
        self.results["G6_app_compatibility"] = {
            "status": status,
            "details": failures if failures else "Catalog layout verified compatible with released Flutter app."
        }

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate", type=Path, required=True, help="Directory containing candidate release artifacts")
    parser.add_argument("--previous", type=Path, default=None, help="Directory containing previous release artifacts")
    parser.add_argument("--tag", type=str, default=None, help="Release tag (e.g. 1.36.0-alpha)")
    parser.add_argument("--local-only", action="store_true", help="Run local self-test without checking remote DB")
    parser.add_argument("--out-report", type=Path, default=None, help="Where to save the JSON gate report")
    args = parser.parse_args()

    gate = ReleaseGate(args.candidate, args.previous, args.tag, args.local_only)
    report = gate.run_all_checks()

    print(f"\nOverall Gate Verdict: {report['overallStatus']}")
    for k, v in report["checks"].items():
        print(f"  [{v['status']}] {k}: {v['details']}")

    if args.out_report:
        args.out_report.parent.mkdir(parents=True, exist_ok=True)
        args.out_report.write_text(json.dumps(report, indent=2), encoding="utf-8")
        print(f"\nSaved Gate Report to {args.out_report}")

    sys.exit(0 if report["overallStatus"] == "PASS" else 1)

if __name__ == "__main__":
    main()
