"""1.1 (audit_fix.md, structural half) tests for catalog_sync.py.

Patches CatalogSyncService's two network seams (_fetch_current_manifest,
_fetch_payload) directly rather than mocking aiohttp internals -- these
are the exact methods scheme_catalog_sync_service_test.dart's Dart
counterpart fakes too (via CatalogReleaseSource), so the two engines'
test suites verify the same behavioral contract the same way.
"""

from __future__ import annotations

import gzip
import hashlib
import json
from pathlib import Path

import pytest

from catalog_sync import CatalogManifest, CatalogSyncService, SyncOutcome


def _manifest(version: str = "1.34.0-alpha", sha256: str = "a" * 64) -> CatalogManifest:
    return CatalogManifest(
        release_version=version,
        sha256=sha256,
        byte_size=100,
        schema_version=1,
        published_at="2026-09-05T00:00:00Z",
    )


def _bundle_payload(scheme_ids: list[str]) -> bytes:
    bundle = {
        "scheme_catalog.json": {
            "metadata": {},
            "data": [
                {"identity": {"id": sid, "name": sid, "status": "active"}}
                for sid in scheme_ids
            ],
        },
        "search_index.json": {
            "metadata": {},
            "data": [
                {
                    "entityId": sid,
                    "entityType": "scheme",
                    "tokens": {"en": [], "ta": []},
                }
                for sid in scheme_ids
            ]
            + [{"entityId": "AUTH001", "entityType": "authority"}],
        },
    }
    return gzip.compress(json.dumps(bundle).encode("utf-8"))


def _async_return(value):
    async def _inner(*_args, **_kwargs):
        return value

    return _inner


@pytest.fixture
def data_dir(tmp_path: Path) -> Path:
    (tmp_path / "scheme_catalog.json").write_text(
        json.dumps({"metadata": {}, "data": []}), encoding="utf-8"
    )
    (tmp_path / "search_index.json").write_text(
        json.dumps({"metadata": {}, "data": []}), encoding="utf-8"
    )
    return tmp_path


def _service(data_dir: Path, clock_value: list[float]) -> CatalogSyncService:
    return CatalogSyncService(
        api_base_url="https://api.example.org",
        data_dir=data_dir,
        clock=lambda: clock_value[0],
    )


@pytest.mark.asyncio
async def test_skips_fetch_when_local_manifest_already_matches(data_dir: Path) -> None:
    remote = _manifest()
    remote.write_to(data_dir / "catalog_manifest.json")
    service = _service(data_dir, [0.0])
    service._fetch_current_manifest = _async_return(remote)  # type: ignore[method-assign]
    fetch_payload_called = False

    async def fail_if_called(_manifest: CatalogManifest) -> bytes:
        nonlocal fetch_payload_called
        fetch_payload_called = True
        raise AssertionError("should not fetch payload when versions match")

    service._fetch_payload = fail_if_called  # type: ignore[method-assign]

    outcome = await service.sync_if_needed()

    assert outcome == SyncOutcome.UNCHANGED
    assert not fetch_payload_called


@pytest.mark.asyncio
async def test_fetches_and_installs_on_version_mismatch(data_dir: Path) -> None:
    payload = _bundle_payload(["SCH001", "SCH002"])
    remote = _manifest(
        version="1.34.0-alpha", sha256=hashlib.sha256(payload).hexdigest()
    )
    service = _service(data_dir, [0.0])
    service._fetch_current_manifest = _async_return(remote)  # type: ignore[method-assign]
    service._fetch_payload = _async_return(payload)  # type: ignore[method-assign]

    outcome = await service.sync_if_needed()

    assert outcome == SyncOutcome.UPDATED
    installed = json.loads(
        (data_dir / "scheme_catalog.json").read_text(encoding="utf-8")
    )
    assert [r["identity"]["id"] for r in installed["data"]] == ["SCH001", "SCH002"]
    installed_index = json.loads(
        (data_dir / "search_index.json").read_text(encoding="utf-8")
    )
    assert len(installed_index["data"]) == 2  # AUTH001 filtered out
    manifest = CatalogManifest.from_local_file(data_dir / "catalog_manifest.json")
    assert manifest is not None
    assert manifest.release_version == "1.34.0-alpha"


@pytest.mark.asyncio
async def test_second_check_within_an_hour_is_throttled(data_dir: Path) -> None:
    clock = [0.0]
    service = _service(data_dir, clock)
    called = 0

    async def count_calls() -> CatalogManifest | None:
        nonlocal called
        called += 1
        return None

    service._fetch_current_manifest = count_calls  # type: ignore[method-assign]

    first = await service.sync_if_needed()
    clock[0] = 1800  # 30 minutes later -- still within the 1hr throttle
    second = await service.sync_if_needed()

    assert first == SyncOutcome.UNCHANGED
    assert second == SyncOutcome.THROTTLED
    assert called == 1


@pytest.mark.asyncio
async def test_check_after_an_hour_is_not_throttled(data_dir: Path) -> None:
    clock = [0.0]
    service = _service(data_dir, clock)
    called = 0

    async def count_calls() -> CatalogManifest | None:
        nonlocal called
        called += 1
        return None

    service._fetch_current_manifest = count_calls  # type: ignore[method-assign]

    await service.sync_if_needed()
    clock[0] = 3700  # just over an hour later
    second = await service.sync_if_needed()

    assert second == SyncOutcome.UNCHANGED
    assert called == 2


@pytest.mark.asyncio
async def test_throttle_persists_across_a_fresh_service_instance(
    data_dir: Path,
) -> None:
    # The realistic LiveKit scenario: a new job subprocess constructs a
    # brand-new CatalogSyncService, so the throttle must survive on disk,
    # not just in the same Python object's memory.
    clock = [0.0]
    first = _service(data_dir, clock)
    called = 0

    async def count_calls() -> CatalogManifest | None:
        nonlocal called
        called += 1
        return None

    first._fetch_current_manifest = count_calls  # type: ignore[method-assign]
    await first.sync_if_needed()

    clock[0] = 1800  # 30 minutes later, fresh instance, same data_dir
    second = _service(data_dir, clock)
    second._fetch_current_manifest = count_calls  # type: ignore[method-assign]
    outcome = await second.sync_if_needed()

    assert outcome == SyncOutcome.THROTTLED
    assert called == 1


@pytest.mark.asyncio
async def test_network_failure_falls_back_without_crashing(data_dir: Path) -> None:
    service = _service(data_dir, [0.0])

    async def boom() -> CatalogManifest | None:
        raise ConnectionError("no network")

    service._fetch_current_manifest = boom  # type: ignore[method-assign]

    outcome = await service.sync_if_needed()

    assert outcome == SyncOutcome.OFFLINE
    # Existing local files must be untouched.
    assert (
        json.loads((data_dir / "scheme_catalog.json").read_text(encoding="utf-8"))[
            "data"
        ]
        == []
    )


@pytest.mark.asyncio
async def test_checksum_mismatch_is_rejected_and_files_untouched(
    data_dir: Path,
) -> None:
    remote = _manifest(sha256="f" * 64)
    service = _service(data_dir, [0.0])
    service._fetch_current_manifest = _async_return(remote)  # type: ignore[method-assign]
    service._fetch_payload = _async_return(b"not the right bytes")  # type: ignore[method-assign]

    outcome = await service.sync_if_needed()

    assert outcome == SyncOutcome.REJECTED
    assert (
        json.loads((data_dir / "scheme_catalog.json").read_text(encoding="utf-8"))[
            "data"
        ]
        == []
    )


@pytest.mark.asyncio
async def test_incompatible_schema_version_is_rejected(data_dir: Path) -> None:
    remote = _manifest()
    remote.schema_version = 99
    service = _service(data_dir, [0.0])
    service._fetch_current_manifest = _async_return(remote)  # type: ignore[method-assign]

    outcome = await service.sync_if_needed()

    assert outcome == SyncOutcome.INCOMPATIBLE


def test_bundle_url_stays_on_the_api_origin(data_dir: Path) -> None:
    service = _service(data_dir, [0.0])
    good = _manifest()
    good.bundle_url = "/v1/catalog/releases/1.34.0-alpha/bundle"
    assert (
        service._bundle_url(good)
        == "https://api.example.org/v1/catalog/releases/1.34.0-alpha/bundle"
    )
    # No bundle_url from the server: the documented release path is used.
    assert service._bundle_url(_manifest()).endswith(
        "/v1/catalog/releases/1.34.0-alpha/bundle"
    )
    for unsafe in (
        "https://evil.example/v1/catalog/releases/x/bundle",
        "//evil.example/v1/catalog/releases/x/bundle",
        "/v1/other/bundle",
        "/v1/catalog/../me/profile",
    ):
        bad = _manifest()
        bad.bundle_url = unsafe
        with pytest.raises(ValueError):
            service._bundle_url(bad)


@pytest.mark.asyncio
async def test_sync_is_skipped_without_an_api_base_url(data_dir: Path) -> None:
    service = CatalogSyncService(api_base_url="", data_dir=data_dir, clock=lambda: 0.0)

    assert await service.sync_if_needed() == SyncOutcome.OFFLINE
