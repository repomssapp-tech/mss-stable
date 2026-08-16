# Hash Verification Specification

> **Document status:** New specification, part of the offline/cloud sync architecture correction (see `OFFLINE_CLOUD_SYNC_ARCHITECTURE.md`).
> **Implementation status:** Documentation only.

---

## 1. Algorithm

SHA-256, exclusively, for every hash in this system: package hash, per-file hashes, and (independently) the live per-row checksum scheme already in use in `catalog.*` tables and `public.mss_catalog_meta()`.

## 2. What gets hashed

| Hash | Computed over | Purpose |
|---|---|---|
| `packageSha256` | The exact bytes of the release artifact (the compressed bundle, or — if the multi-file architecture is preserved — a well-defined deterministic combination of the constituent files) | Identity/integrity of the release as a whole; what the client compares against the manifest before and after download |
| per-file SHA-256 | Each individual catalog JSON file's exact bytes | Lets a client (or the pipeline) verify a single file without re-hashing the whole package; also enables partial-integrity diagnosis if a download is corrupted |
| `catalog.*` row `checksum` (existing, unrelated) | Each row's `JSON.stringify`-serialized record (see `backend/scripts/generate_catalog_import_sql.js`) | Table-layer drift detection only (`public.mss_catalog_meta()`'s live aggregate) — **not** comparable to `packageSha256` or the offline bundle's `bundleSha256`, since it uses a different serialization scheme over different data (Postgres rows, not the source files' raw bytes). Keep these two hash families conceptually separate; do not attempt to make them equal. |

## 3. Local vs. cloud comparison

```
LOCAL:
  releaseVersion = 1.34.0
  packageSha256  = ABC...

CLOUD:
  releaseVersion = 1.35.0
  packageSha256  = XYZ...

If releaseVersion or packageSha256 differ → update candidate exists.
```

The comparison is release-identity based (`releaseVersion` + `packageSha256`), not a re-derivation or partial comparison. Either value differing is sufficient to trigger the update flow in `UPDATE_FLOW_SPECIFICATION.md`.

## 4. What a hash proves — and what it does not

**A hash proves integrity and identity of the artifact.** It confirms:
- The downloaded bytes are exactly the bytes that were published under that `releaseVersion`.
- The artifact was not corrupted in transit or tampered with.

**A hash does NOT prove the underlying catalog information is factually correct.** Whether a scheme's eligibility criteria, benefit amounts, or application URL are accurate is the responsibility of the MSS catalog verification pipeline (`Plan/catalog/validate_*.py`, provenance/fieldSources tracking, human review workflow) — entirely separate from hash verification. A release can be perfectly hash-verified and still contain a factual data error; hash verification only guarantees the client received precisely what was published, not that what was published is correct.

## 5. Verification points

The client verifies the downloaded artifact's hash **before** activating it, per the flow in `UPDATE_FLOW_SPECIFICATION.md`:

1. Download release artifact to temporary storage.
2. Compute SHA-256 of the downloaded bytes.
3. Compare against the `packageSha256` declared in the release's manifest (fetched via the lightweight metadata check, before the download started).
4. **Mismatch → reject the download, keep the current active release, do not activate.**
5. Match → proceed to the remaining validation steps (schema compatibility, JSON structure, IDs, relationships, localization, search compatibility) before activation.

Hash verification is necessary but not sufficient for activation — it is the first of several validation gates, not the only one.

## 6. Relationship to existing manifest fields

`frontend/assets/catalog/release.json` already carries `bundleSha256` (package-level) and `perFileSha256` (per-file, added in V2-B2) in exactly this shape. `admin.catalog_files.checksum` (populated in V2-B2) already stores one SHA-256 per catalog file. No new hash *mechanism* is needed — this document formalizes how the existing hashes are to be used for verification, and draws the boundary against the separately-existing, differently-computed `catalog.*` row-checksum scheme (§2) so the two are never confused with each other.
