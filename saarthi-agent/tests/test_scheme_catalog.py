import json
from pathlib import Path

from scheme_catalog import SchemeCatalog


def _record(
    scheme_id: str,
    code: str,
    name: str,
    summary: str,
    *,
    tamil_name: str | None = None,
) -> dict:
    return {
        "identity": {
            "id": scheme_id,
            "code": code,
            "name": name,
            "status": "active",
        },
        "content": {
            "overview": {"summary": summary},
            "eligibility": {"narrative": {"criteria": "Tamil Nadu residents"}},
            "benefits": {"summary": "Financial assistance"},
            "requiredDocuments": [{"name": "Identity proof", "mandatory": "required"}],
            "applicationProcess": {
                "modeText": "Online",
                "onlineUrl": "https://example.gov.in/apply",
            },
            "sources": [
                {
                    "title": "Official source",
                    "url": "https://example.gov.in/scheme",
                    "isCurrent": True,
                }
            ],
        },
        "localization": {
            "ta": {"name": tamil_name, "summary": None},
        },
        "search": {"keywords": ["assistance"], "aliases": [code]},
        "verification": {"isVerified": True, "statusText": "Verified"},
        "metadata": {"recordStatus": "published"},
    }


def _write_catalog(path: Path, records: list[dict]) -> None:
    path.write_text(json.dumps({"metadata": {}, "data": records}), encoding="utf-8")


def _search_index_row(
    scheme_id: str, tokens_en: list[str], *, tokens_ta: list[str] | None = None
) -> dict:
    # 1.3 (audit_fix.md): HybridSearchEngine's keyword/IDF scoring reads
    # tokens.en/tokens.ta from the search_index row, not free text in
    # content.* the way the old bucket scoring did -- so these fixtures
    # need a matching search_index.json row, same as production data.
    return {
        "entityId": scheme_id,
        "entityType": "scheme",
        "tokens": {"en": tokens_en, "ta": tokens_ta or []},
        "schemeSearchProfile": {"schemeId": scheme_id},
    }


def _write_search_index(path: Path, rows: list[dict]) -> None:
    path.write_text(json.dumps({"metadata": {}, "data": rows}), encoding="utf-8")


def test_search_ranks_code_and_name_matches(tmp_path: Path) -> None:
    catalog_path = tmp_path / "schemes.json"
    index_path = tmp_path / "search_index.json"
    _write_catalog(
        catalog_path,
        [
            _record("SCH1", "TN001", "Micro Manufacturing Subsidy", "For factories"),
            _record("SCH2", "TN002", "Student Scholarship", "For students"),
        ],
    )
    _write_search_index(
        index_path,
        [
            _search_index_row("SCH1", ["tn001", "micro", "manufacturing", "subsidy"]),
            _search_index_row("SCH2", ["tn002", "student", "scholarship"]),
        ],
    )
    catalog = SchemeCatalog(catalog_path, index_path)

    assert catalog.search("TN001", limit=1)[0]["id"] == "SCH1"
    assert catalog.search("student scholarship", limit=1)[0]["id"] == "SCH2"


def test_search_supports_future_tamil_localization(tmp_path: Path) -> None:
    catalog_path = tmp_path / "schemes.json"
    index_path = tmp_path / "search_index.json"
    _write_catalog(
        catalog_path,
        [
            _record(
                "SCH1",
                "TN001",
                "Farmer Support",
                "Support for farmers",
                tamil_name="விவசாயி உதவித் திட்டம்",
            )
        ],
    )
    _write_search_index(
        index_path,
        [_search_index_row("SCH1", ["tn001", "farmer"], tokens_ta=["விவசாயி"])],
    )

    result = SchemeCatalog(catalog_path, index_path).search("விவசாயி", limit=1)[0]

    assert result["id"] == "SCH1"
    assert result["localized"]["ta"]["name"] == "விவசாயி உதவித் திட்டம்"


def test_results_are_compact_and_source_grounded(tmp_path: Path) -> None:
    catalog_path = tmp_path / "schemes.json"
    index_path = tmp_path / "search_index.json"
    _write_catalog(
        catalog_path,
        [_record("SCH1", "TN001", "Micro Manufacturing Subsidy", "For factories")],
    )
    _write_search_index(
        index_path,
        [_search_index_row("SCH1", ["tn001", "micro", "manufacturing", "subsidy"])],
    )

    result = SchemeCatalog(catalog_path, index_path).search("manufacturing", limit=1)[0]

    assert result["verification"]["is_verified"] is True
    assert "match_confidence" not in result
    assert result["application"]["url"] == "https://example.gov.in/apply"
    assert result["sources"] == [
        {"title": "Official source", "url": "https://example.gov.in/scheme"}
    ]
    assert result["required_documents"] == ["Identity proof"]


def test_production_catalog_contains_expected_scheme() -> None:
    path = Path(__file__).parents[1] / "data" / "scheme_catalog.json"
    catalog = SchemeCatalog(path)

    results = catalog.search("micro manufacturing capital subsidy", limit=1)

    assert catalog.count == 219
    assert results[0]["id"] == "SCH000001"
