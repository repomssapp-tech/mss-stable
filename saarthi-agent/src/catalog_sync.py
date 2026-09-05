"""1.1 (audit_fix.md, structural half): keeps this agent's local catalog
copy (data/scheme_catalog.json, data/search_index.json) in sync with the
published release, instead of a snapshot frozen at Docker-build time.

Mirrors frontend/lib/services/scheme_catalog_sync_service.dart exactly --
same public.mss_current_release() RPC for the cheap version check, same
`catalogs` Storage bucket / releases/<release_version>/catalog_bundle.json.gz
path for the payload, same once-per-worker-startup-then-hourly-throttle
policy. The voice agent runs as one persistent LiveKit worker process (see
agent.py's `cli.run_app`), not a fresh process per call, so an in-memory
timestamp is enough to enforce the throttle -- no disk-persisted state
needed, exactly like the Dart singleton this ports.

Never blocks or crashes agent startup: any failure (network, timeout,
checksum mismatch, incompatible schema) leaves the existing local files
untouched and logs a warning. The bundled files shipped in the Docker
image are the fallback, always.
"""

from __future__ import annotations

import gzip
import hashlib
import json
import logging
import time
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Any

import aiohttp

logger = logging.getLogger("catalog_sync")

DATA_DIR = Path(__file__).resolve().parents[1] / "data"
SCHEME_CATALOG_PATH = DATA_DIR / "scheme_catalog.json"
SEARCH_INDEX_PATH = DATA_DIR / "search_index.json"
LOCAL_MANIFEST_PATH = DATA_DIR / "catalog_manifest.json"

SUPPORTED_SCHEMA_VERSION = 1
STORAGE_BUCKET = "catalogs"
BUNDLE_FILE_NAME = "catalog_bundle.json.gz"


class SyncOutcome(Enum):
    UNCHANGED = "unchanged"
    UPDATED = "updated"
    THROTTLED = "throttled"
    OFFLINE = "offline"
    INCOMPATIBLE = "incompatible"
    REJECTED = "rejected"


@dataclass
class CatalogManifest:
    release_version: str
    sha256: str
    byte_size: int
    schema_version: int
    published_at: str

    def same_release_as(self, other: CatalogManifest | None) -> bool:
        if other is None:
            return False
        return (
            self.release_version == other.release_version
            and self.sha256 == other.sha256
        )

    @staticmethod
    def from_release_rpc(row: dict[str, Any]) -> CatalogManifest | None:
        release_version = str(row.get("release_version") or "")
        sha256 = str(row.get("package_sha256") or "")
        if not release_version or not sha256:
            return None
        return CatalogManifest(
            release_version=release_version,
            sha256=sha256,
            byte_size=int(row.get("package_byte_size") or 0),
            schema_version=int(row.get("schema_version") or 0),
            published_at=str(row.get("published_at") or ""),
        )

    @staticmethod
    def from_local_file(path: Path = LOCAL_MANIFEST_PATH) -> CatalogManifest | None:
        if not path.exists():
            return None
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            return CatalogManifest(**data)
        except (json.JSONDecodeError, TypeError, KeyError):
            logger.warning(
                "catalog_sync: local manifest unreadable, ignoring", exc_info=True
            )
            return None

    def write_to(self, path: Path = LOCAL_MANIFEST_PATH) -> None:
        path.write_text(
            json.dumps(
                {
                    "release_version": self.release_version,
                    "sha256": self.sha256,
                    "byte_size": self.byte_size,
                    "schema_version": self.schema_version,
                    "published_at": self.published_at,
                },
                indent=2,
            ),
            encoding="utf-8",
        )


class CatalogSyncService:
    def __init__(
        self,
        *,
        supabase_url: str | None = None,
        supabase_key: str | None = None,
        throttle_seconds: float = 3600,
        timeout_seconds: float = 8,
        clock: Any = time.time,
        data_dir: Path = DATA_DIR,
    ) -> None:
        self._supabase_url = supabase_url
        self._supabase_key = supabase_key
        self._throttle_seconds = throttle_seconds
        self._timeout_seconds = timeout_seconds
        self._clock = clock
        self._data_dir = data_dir

    def _last_check_path(self) -> Path:
        return self._data_dir / "last_sync_check.json"

    def _read_last_check(self) -> float | None:
        # Persisted to disk, not just held in memory: LiveKit may run each
        # job in its own subprocess (setup_fnc's JobProcess), so an
        # in-memory timestamp alone would not reliably survive between
        # jobs and could re-check far more often than once an hour.
        path = self._last_check_path()
        if not path.exists():
            return None
        try:
            return float(json.loads(path.read_text(encoding="utf-8"))["last_check"])
        except (json.JSONDecodeError, KeyError, ValueError, TypeError):
            return None

    def _write_last_check(self, value: float) -> None:
        self._last_check_path().write_text(
            json.dumps({"last_check": value}), encoding="utf-8"
        )

    async def sync_if_needed(self, *, force: bool = False) -> SyncOutcome:
        now = self._clock()
        last_check = self._read_last_check()
        if (
            not force
            and last_check is not None
            and (now - last_check) < self._throttle_seconds
        ):
            return SyncOutcome.THROTTLED
        self._write_last_check(now)

        if not self._supabase_url or not self._supabase_key:
            logger.warning(
                "catalog_sync: SUPABASE_URL/key not configured, skipping sync"
            )
            return SyncOutcome.OFFLINE

        try:
            remote = await self._fetch_current_manifest()
        except Exception:
            logger.warning(
                "catalog_sync: manifest check failed, keeping local catalog",
                exc_info=True,
            )
            return SyncOutcome.OFFLINE

        if remote is None:
            return SyncOutcome.UNCHANGED

        if remote.schema_version > SUPPORTED_SCHEMA_VERSION:
            logger.warning(
                "catalog_sync: release %s needs schema %s > supported %s, keeping local catalog",
                remote.release_version,
                remote.schema_version,
                SUPPORTED_SCHEMA_VERSION,
            )
            return SyncOutcome.INCOMPATIBLE

        local = CatalogManifest.from_local_file(
            self._data_dir / "catalog_manifest.json"
        )
        if local is not None and local.same_release_as(remote):
            return SyncOutcome.UNCHANGED

        try:
            payload = await self._fetch_payload(remote)
            if hashlib.sha256(payload).hexdigest() != remote.sha256:
                logger.warning(
                    "catalog_sync: checksum mismatch for %s, keeping local catalog",
                    remote.release_version,
                )
                return SyncOutcome.REJECTED
            self._install(payload)
            remote.write_to(self._data_dir / "catalog_manifest.json")
        except Exception:
            logger.warning(
                "catalog_sync: download/install failed, keeping local catalog",
                exc_info=True,
            )
            return SyncOutcome.REJECTED

        logger.info("catalog_sync: installed release %s", remote.release_version)
        return SyncOutcome.UPDATED

    async def _fetch_current_manifest(self) -> CatalogManifest | None:
        url = f"{self._supabase_url}/rest/v1/rpc/mss_current_release"
        headers = {
            "apikey": self._supabase_key,
            "Authorization": f"Bearer {self._supabase_key}",
            "Content-Type": "application/json",
        }
        timeout = aiohttp.ClientTimeout(total=self._timeout_seconds)
        async with (
            aiohttp.ClientSession(timeout=timeout) as session,
            session.post(url, headers=headers, json={}) as response,
        ):
            response.raise_for_status()
            rows = await response.json()
        if not rows:
            return None
        return CatalogManifest.from_release_rpc(rows[0])

    async def _fetch_payload(self, manifest: CatalogManifest) -> bytes:
        object_path = f"releases/{manifest.release_version}/{BUNDLE_FILE_NAME}"
        url = f"{self._supabase_url}/storage/v1/object/{STORAGE_BUCKET}/{object_path}"
        headers = {
            "apikey": self._supabase_key,
            "Authorization": f"Bearer {self._supabase_key}",
        }
        timeout = aiohttp.ClientTimeout(total=self._timeout_seconds)
        async with (
            aiohttp.ClientSession(timeout=timeout) as session,
            session.get(url, headers=headers) as response,
        ):
            response.raise_for_status()
            return await response.read()

    def _install(self, payload: bytes) -> None:
        bundle = json.loads(gzip.decompress(payload).decode("utf-8"))

        scheme_catalog = bundle["scheme_catalog.json"]
        (self._data_dir / "scheme_catalog.json").write_text(
            json.dumps(scheme_catalog, ensure_ascii=False), encoding="utf-8"
        )

        search_index = bundle["search_index.json"]
        scheme_only_index = {
            "metadata": search_index.get("metadata"),
            "data": [
                row for row in search_index["data"] if row.get("entityType") == "scheme"
            ],
        }
        (self._data_dir / "search_index.json").write_text(
            json.dumps(scheme_only_index, ensure_ascii=False), encoding="utf-8"
        )
