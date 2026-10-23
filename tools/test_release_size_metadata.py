#!/usr/bin/env python3
"""release.json size metadata.

GET /v1/catalog/releases/:tag publishes `uncompressedBytes` next to `bundleBytes`
and `bundleSha256` so a client can verify the download, then inflate it with a
bounded output limit. The core + packs layout (bundleFormat 3) used to omit it.

Run with pytest, or directly: python tools/test_release_size_metadata.py
"""
import gzip
import tempfile
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_catalog_release as builder  # noqa: E402
import catalog_packs  # noqa: E402

API_FIELDS = {
    "releaseId", "releaseTag", "schemaVersion", "releasedAt", "bundleAsset", "bundleBytes",
    "bundleSha256", "uncompressedBytes", "entityCount", "searchIndexCount", "recordCounts",
    "perFileSha256",
}


def _write_release_files(directory: Path):
    """A tiny core + two packs, repetitive enough that they compress well."""
    filler = [{"id": f"X{i}", "text": "लघु उद्योग योजना " * 20} for i in range(40)]
    core_blob = catalog_packs.dump_gz({"manifest.json": {"data": [{"k": 1}]}, "rows": filler}, directory / catalog_packs.CORE_FILE)
    core = {"file": catalog_packs.CORE_FILE, "bytes": len(core_blob), "sha256": catalog_packs._sha256(core_blob)}
    packs = []
    for jur in ("central", "tamil_nadu"):
        name = catalog_packs.pack_file_name(jur)
        blob = catalog_packs.dump_gz({"pack.json": {"data": [{"jurisdiction": jur}]}, "rows": filler[:10]}, directory / name)
        packs.append({
            "id": jur, "file": name, "jurisdiction": jur, "tenantId": jur,
            "required": jur == "central", "bytes": len(blob), "sha256": catalog_packs._sha256(blob),
        })
    return core, packs


def _release(directory: Path, core: dict, packs: list[dict]) -> dict:
    return builder.build_release_metadata(
        release_tag="9.9.9-test", schema_version="1.0.0", released_at="2026-01-01T00:00:00Z",
        out_dir=directory, core=core, packs=packs, entity_count=3, search_index_count=2,
        record_counts={"scheme_catalog.json": 3}, per_file_sha256={"scheme_catalog.json": "ab" * 32},
    )


def test_total_uncompressed_bytes_is_the_decompressed_size_of_core_and_packs():
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        _write_release_files(d)
        expected = sum(len(gzip.decompress(p.read_bytes())) for p in d.glob("catalog_*.json.gz"))
        assert catalog_packs.total_uncompressed_bytes(d) == expected
        assert expected > catalog_packs.total_bytes(d), "decompressed size must exceed the gzip size"


def test_total_uncompressed_bytes_ignores_files_that_are_not_runtime_catalogs():
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        _write_release_files(d)
        before = catalog_packs.total_uncompressed_bytes(d)
        (d / "release.json").write_text("{}", encoding="utf-8")
        (d / "notes.json.gz").write_bytes(gzip.compress(b"x" * 10_000))
        assert catalog_packs.total_uncompressed_bytes(d) == before


def test_total_uncompressed_bytes_of_an_empty_directory_is_zero():
    with tempfile.TemporaryDirectory() as tmp:
        assert catalog_packs.total_uncompressed_bytes(Path(tmp)) == 0


def test_release_json_publishes_uncompressed_bytes():
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        core, packs = _write_release_files(d)
        rel = _release(d, core, packs)
        assert rel["uncompressedBytes"] == catalog_packs.total_uncompressed_bytes(d)
        assert rel["uncompressedBytes"] > rel["bundleBytes"]


def test_release_json_sizes_agree_with_the_files():
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        core, packs = _write_release_files(d)
        rel = _release(d, core, packs)
        assert rel["bundleBytes"] == catalog_packs.total_bytes(d)
        assert rel["bundleSha256"] == core["sha256"]
        assert [p["file"] for p in rel["packs"]] == [p["file"] for p in packs]


def test_release_json_carries_every_field_the_api_documents():
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        core, packs = _write_release_files(d)
        rel = _release(d, core, packs)
        assert API_FIELDS <= set(rel), sorted(API_FIELDS - set(rel))
        keys = list(rel)
        # same order as the API's documented example: bundleBytes, bundleSha256, uncompressedBytes, entityCount ...
        assert keys.index("uncompressedBytes") == keys.index("bundleSha256") + 1


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for t in tests:
        t()
        print("ok  ", t.__name__)
    print(f"{len(tests)} tests passed")
