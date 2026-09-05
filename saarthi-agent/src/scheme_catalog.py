"""Search and compact rendering for the bundled government-scheme catalog."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from hybrid_search import HybridSearchEngine, SchemeEntry
from search_taxonomy import SchemeSearchTaxonomy

DEFAULT_CATALOG_PATH = (
    Path(__file__).resolve().parents[1] / "data" / "scheme_catalog.json"
)
DEFAULT_SEARCH_INDEX_PATH = (
    Path(__file__).resolve().parents[1] / "data" / "search_index.json"
)


class SchemeCatalog:
    """Load a catalog once and return small, source-grounded search results.

    1.3 (audit_fix.md): search() ranks via HybridSearchEngine -- the same
    taxonomy-based, IDF-weighted algorithm as search_engine.ts and
    hybrid_scheme_search.dart -- instead of the previous ad hoc bucket
    scoring. Voice results changed substantially for every query as a
    result; that is the intended effect of unifying the three engines, not
    a regression (see tests/test_hybrid_search_parity.py).
    """

    def __init__(
        self,
        path: Path | str = DEFAULT_CATALOG_PATH,
        search_index_path: Path | str = DEFAULT_SEARCH_INDEX_PATH,
        taxonomy: SchemeSearchTaxonomy | None = None,
    ) -> None:
        self.path = Path(path)
        payload = json.loads(self.path.read_text(encoding="utf-8"))
        records = payload.get("data")
        if not isinstance(records, list):
            raise ValueError("Scheme catalog must contain a top-level data array")

        self._records = [record for record in records if self._is_available(record)]
        self._records_by_id = {
            str(record.get("identity", {}).get("id", "")): record
            for record in self._records
        }

        search_index_payload = json.loads(
            Path(search_index_path).read_text(encoding="utf-8")
        )
        search_profile_by_id: dict[str, dict[str, Any]] = {
            row["entityId"]: row
            for row in search_index_payload.get("data", [])
            if row.get("entityId")
        }

        entries = [
            SchemeEntry(
                id=record_id,
                status=record.get("identity", {}).get("status", "unknown"),
                name_en=record.get("identity", {}).get("name", ""),
                raw=record,
                search_profile=search_profile_by_id.get(record_id, {}),
            )
            for record_id, record in self._records_by_id.items()
        ]
        self._engine = HybridSearchEngine(entries, taxonomy or SchemeSearchTaxonomy())

    @property
    def count(self) -> int:
        return len(self._records)

    @staticmethod
    def _is_available(record: dict[str, Any]) -> bool:
        metadata = record.get("metadata", {})
        return metadata.get("recordStatus") in {
            None,
            "published",
        }

    def search(self, query: str, *, limit: int = 3) -> list[dict[str, Any]]:
        if not query.strip():
            return []
        limit = max(1, min(limit, 5))
        results = self._engine.search(query, top_n=limit)
        return [self._compact(self._records_by_id[r.scheme_id]) for r in results]

    @staticmethod
    def _compact(record: dict[str, Any]) -> dict[str, Any]:
        identity = record.get("identity", {})
        content = record.get("content", {})
        eligibility = content.get("eligibility", {}).get("narrative", {})
        application = content.get("applicationProcess", {})
        verification = record.get("verification", {})

        localized = {
            language: {
                key: value
                for key, value in values.items()
                if key in {"name", "summary", "eligibilityText", "benefitsText"}
                and value
            }
            for language, values in record.get("localization", {}).items()
            if isinstance(values, dict) and any(values.values())
        }

        sources = [
            {"title": source.get("title"), "url": source.get("url")}
            for source in content.get("sources", [])
            if source.get("url") and source.get("isCurrent", True)
        ][:3]

        required_documents = [
            document.get("name")
            for document in content.get("requiredDocuments", [])
            if document.get("name") and document.get("mandatory") != "optional"
        ]

        return {
            "id": identity.get("id"),
            "code": identity.get("code"),
            "name": identity.get("name"),
            "scheme_status": identity.get("status"),
            "summary": content.get("overview", {}).get("summary"),
            "eligibility": eligibility.get("verifiedCriteria")
            or eligibility.get("criteria"),
            "benefits": content.get("benefits", {}).get("summary"),
            "required_documents": required_documents,
            "application": {
                "mode": application.get("modeText") or application.get("mode"),
                "url": application.get("onlineUrl"),
                "fee": application.get("applicationFeeText"),
            },
            "localized": localized,
            "verification": {
                "is_verified": bool(verification.get("isVerified")),
                "status": verification.get("statusText") or verification.get("status"),
                "confidence": verification.get("confidence"),
            },
            "sources": sources,
        }
