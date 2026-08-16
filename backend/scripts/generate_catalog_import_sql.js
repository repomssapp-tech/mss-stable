#!/usr/bin/env node
/**
 * Reads the canonical catalog JSON files from Plan/catalog/ and generates one SQL
 * file per catalog (small enough for `supabase db query --file`, which has a
 * request-size limit) that upserts them into the catalog.* schema in Supabase
 * (see migration 20260805000000_database_architecture_v2.sql for target tables).
 *
 * This does NOT connect to Supabase itself -- it only writes .sql files. Apply
 * each one in order with:
 *   supabase db query --linked --file <output>/00_common.sql
 *   supabase db query --linked --file <output>/01_authority.sql
 *   supabase db query --linked --file <output>/01b_enterprise_classification.sql
 *   supabase db query --linked --file <output>/01c_msme_privilege.sql
 *   supabase db query --linked --file <output>/01d_business_enablement.sql
 *   supabase db query --linked --file <output>/01e_cluster_assistance.sql
 *   supabase db query --linked --file <output>/02_institution.sql
 *   supabase db query --linked --file <output>/03_scheme_*.sql
 *   supabase db query --linked --file <output>/03b_applicability_matrix.sql
 *   ... etc (numeric/lettered prefix = required order; institution needs authority
 *   first, applicability_matrix needs scheme first, the rest are order-independent
 *   since their scheme_id FK is deferred). 01b-01e use letter suffixes rather than
 *   renumbering 02-11 to keep the diff against the original 10-catalog script small.
 *
 * Usage: node generate_catalog_import_sql.js <plan_catalog_dir> <output_dir>
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const [, , catalogDir, outDir] = process.argv;
if (!catalogDir || !outDir) {
  console.error('Usage: node generate_catalog_import_sql.js <plan_catalog_dir> <output_dir>');
  process.exit(1);
}
fs.mkdirSync(outDir, { recursive: true });

function sha256(obj) {
  return crypto.createHash('sha256').update(JSON.stringify(obj)).digest('hex');
}

function sqlStr(value) {
  if (value === null || value === undefined || value === '') return 'NULL';
  return `'${String(value).replace(/'/g, "''")}'`;
}

function sqlBool(value) {
  return value ? 'TRUE' : 'FALSE';
}

// Dollar-quoted strings in Postgres are raw literals -- no backslash or quote
// escaping applies inside them, so JSON.stringify's output can be embedded
// verbatim. Use a random tag per run so a payload containing the literal
// substring "$json$" (vanishingly unlikely, but not impossible) can't break out.
const JSON_TAG = `$mss${crypto.randomBytes(6).toString('hex')}$`;
function sqlJson(obj) {
  return `${JSON_TAG}${JSON.stringify(obj)}${JSON_TAG}::jsonb`;
}

function mapStatus(identityStatus) {
  if (identityStatus === 'active') return 'PUBLISHED';
  if (identityStatus === 'closed') return 'ARCHIVED';
  return 'DRAFT';
}

function readCatalog(fileName) {
  const p = path.join(catalogDir, fileName);
  const parsed = JSON.parse(fs.readFileSync(p, 'utf8'));
  return { version: parsed.metadata?.catalogVersion || '', data: parsed.data || [] };
}

function writeFile(name, lines) {
  const body = ['begin;', '', ...lines, '', 'commit;'].join('\n');
  const p = path.join(outDir, name);
  fs.writeFileSync(p, body, 'utf8');
  const kb = (Buffer.byteLength(body) / 1024).toFixed(1);
  console.log(`Wrote ${name} (${lines.length} statements, ${kb} KB)`);
}

// The `supabase db query --file` endpoint rejects large payloads (observed: 5.1MB
// fails, 1.49MB succeeds). Split any statement list into chunks under a safe byte
// budget so large catalogs (scheme, search_index) still import in one script run.
const MAX_CHUNK_BYTES = 1_000_000;
function writeChunked(baseName, lines) {
  const chunks = [];
  let current = [];
  let currentBytes = 0;
  for (const line of lines) {
    const lineBytes = Buffer.byteLength(line) + 1;
    if (current.length > 0 && currentBytes + lineBytes > MAX_CHUNK_BYTES) {
      chunks.push(current);
      current = [];
      currentBytes = 0;
    }
    current.push(line);
    currentBytes += lineBytes;
  }
  if (current.length > 0) chunks.push(current);
  chunks.forEach((chunkLines, i) => {
    const suffix = String(i).padStart(2, '0');
    writeFile(`${baseName}_${suffix}.sql`, chunkLines);
  });
}

function upsertBase(out, table, id, version, status, checksum, recordJson, extraCols = {}) {
  const cols = ['id', 'version', 'status', 'checksum', 'published_at', 'record_json', ...Object.keys(extraCols)];
  const vals = [
    sqlStr(id),
    sqlStr(version),
    sqlStr(status),
    sqlStr(checksum),
    'now()',
    sqlJson(recordJson),
    ...Object.values(extraCols),
  ];
  const updateSet = cols
    .filter((c) => c !== 'id')
    .map((c) => `${c} = excluded.${c}`)
    .join(', ');
  out.push(
    `insert into ${table} (${cols.join(', ')}) values (${vals.join(', ')}) ` +
      `on conflict (id) do update set ${updateSet}, updated_at = now();`
  );
}

// ---- 00: common ----
{
  const out = [];
  const { version, data } = readCatalog('common_catalog.json');
  for (const r of data) {
    upsertBase(out, 'catalog.common', r.identity.id, version, mapStatus(r.identity.status), sha256(r), r);
  }
  writeFile('00_common.sql', out);
}

// ---- 01: authority ----
{
  const out = [];
  const { version, data } = readCatalog('authority_catalog.json');
  for (const r of data) {
    upsertBase(out, 'catalog.authority', r.identity.id, version, mapStatus(r.identity.status), sha256(r), r, {
      code: sqlStr(r.identity.code),
      name_en: sqlStr(r.identity.name),
      name_ta: sqlStr(r.localization?.ta?.name),
    });
  }
  writeFile('01_authority.sql', out);
}

// ---- 01b-01e: enterprise_classification / msme_privilege / business_enablement /
// cluster_assistance (no scheme dependency; business_enablement and
// cluster_assistance soft-reference authority, deferred-safe since the FK
// is non-deferred but all current values are null -- placed after
// authority regardless for readability) ----
{
  const out = [];
  const { version, data } = readCatalog('enterprise_classification_catalog.json');
  for (const r of data) {
    upsertBase(out, 'catalog.enterprise_classification', r.identity.id, version, mapStatus(r.identity.status), sha256(r), r, {
      code: sqlStr(r.content?.code),
      dimension: sqlStr(r.content?.dimension),
      investment_max_inr: r.content?.investmentMaxInr ?? 'NULL',
      turnover_max_inr: r.content?.turnoverMaxInr ?? 'NULL',
    });
  }
  writeFile('01b_enterprise_classification.sql', out);
}

{
  const out = [];
  const { version, data } = readCatalog('msme_privilege_catalog.json');
  for (const r of data) {
    upsertBase(out, 'catalog.msme_privilege', r.identity.id, version, mapStatus(r.identity.status), sha256(r), r, {
      privilege_type: sqlStr(r.content?.privilegeType),
      statute: sqlStr(r.content?.statute),
    });
  }
  writeFile('01c_msme_privilege.sql', out);
}

{
  const out = [];
  const { version, data } = readCatalog('business_enablement_catalog.json');
  for (const r of data) {
    upsertBase(out, 'catalog.business_enablement', r.identity.id, version, mapStatus(r.identity.status), sha256(r), r, {
      enablement_type: sqlStr(r.content?.enablementType),
      provider_authority_id: sqlStr(r.content?.providerAuthorityId),
      online_url: sqlStr(r.content?.onlineUrl),
    });
  }
  writeFile('01d_business_enablement.sql', out);
}

{
  const out = [];
  const { version, data } = readCatalog('cluster_assistance_catalog.json');
  for (const r of data) {
    upsertBase(out, 'catalog.cluster_assistance', r.identity.id, version, mapStatus(r.identity.status), sha256(r), r, {
      cluster_name: sqlStr(r.content?.clusterName),
      sector: sqlStr(r.content?.sector),
      administering_authority_id: sqlStr(r.content?.administeringAuthorityId),
    });
  }
  writeFile('01e_cluster_assistance.sql', out);
}

// ---- 02: institution (depends on authority: non-deferred FK) ----
{
  const out = [];
  const { version, data } = readCatalog('institution_catalog.json');
  for (const r of data) {
    upsertBase(out, 'catalog.institution', r.identity.id, version, mapStatus(r.identity.status), sha256(r), r, {
      code: sqlStr(r.identity.code),
      name_en: sqlStr(r.identity.name),
      name_ta: sqlStr(r.localization?.ta?.name),
      authority_id: sqlStr(r.content?.authorityId),
    });
  }
  writeFile('02_institution.sql', out);
}

// ---- 03: scheme ----
{
  const out = [];
  const { version, data } = readCatalog('scheme_catalog.json');
  for (const r of data) {
    const gov = r.content?.classification?.government || {};
    const keywords = r.search?.keywords?.en || [];
    upsertBase(out, 'catalog.scheme', r.identity.id, version, mapStatus(r.identity.status), sha256(r), r, {
      scheme_code: sqlStr(r.identity.code),
      name_en: sqlStr(r.identity.name),
      name_ta: sqlStr(r.localization?.ta?.name),
      government_level: sqlStr(gov.level),
      scheme_type: sqlStr(r.content?.classification?.schemeType),
      state: sqlStr(gov.statesText || 'All India'),
      ministry: sqlStr(gov.ministryText),
      department: sqlStr(gov.departmentText),
      search_keywords: sqlStr(keywords.join(' ')),
      primary_authority_id: sqlStr(gov.departmentId),
      primary_institution_id: sqlStr(
        (r.relationships?.references || []).find((x) => x.entityType === 'institution')?.entityId
      ),
      minimum_funding_amount: 'NULL',
      maximum_funding_amount: 'NULL',
      is_active: sqlBool(r.identity.status === 'active'),
    });
  }
  writeChunked('03_scheme', out);
}

// ---- 03b: applicability_matrix (scheme_id FK is deferred; loaded after
// scheme regardless, matching the convention finance/tax/etc. already use) ----
{
  const out = [];
  const { version, data } = readCatalog('applicability_matrix_catalog.json');
  for (const r of data) {
    upsertBase(out, 'catalog.applicability_matrix', r.identity.id, version, mapStatus(r.identity.status), sha256(r), r, {
      scheme_id: sqlStr(r.content?.schemeId),
      government_level: sqlStr(r.content?.governmentLevel),
      department_authority_id: sqlStr(r.content?.department),
      sector_text: sqlStr(r.content?.sectorText),
      district_text: sqlStr(r.content?.districtText),
    });
  }
  writeFile('03b_applicability_matrix.sql', out);
}

// ---- 04..08: finance / tax / export / csr / treds (deferred FK, order-independent) ----
const schemeLinked = [
  ['finance_catalog.json', 'catalog.finance', '04_finance.sql'],
  ['tax_catalog.json', 'catalog.tax', '05_tax.sql'],
  ['export_catalog.json', 'catalog.export', '06_export.sql'],
  ['csr_catalog.json', 'catalog.csr', '07_csr.sql'],
  ['treds_catalog.json', 'catalog.treds', '08_treds.sql'],
];
for (const [file, table, outName] of schemeLinked) {
  const out = [];
  const { version, data } = readCatalog(file);
  for (const r of data) {
    upsertBase(out, table, r.identity.id, version, mapStatus(r.identity.status), sha256(r), r, {
      scheme_id: sqlStr(r.content?.schemeId),
    });
  }
  writeFile(outName, out);
}

// ---- 09: knowledge ----
{
  const out = [];
  const { version, data } = readCatalog('knowledge_catalog.json');
  for (const r of data) {
    upsertBase(out, 'catalog.knowledge', r.identity.id, version, mapStatus(r.identity.status), sha256(r), r, {
      title: sqlStr(r.identity.name),
      item_type: sqlStr(r.content?.itemType),
      category: sqlStr(r.content?.category),
    });
  }
  writeFile('09_knowledge.sql', out);
}

// ---- 10: search_index (flat shape) ----
{
  const out = [];
  const { version, data } = readCatalog('search_index.json');
  for (const r of data) {
    const contentText = [
      r.name?.en,
      ...(r.keywords?.en || []),
      ...(r.aliases?.en || []),
      ...(r.synonyms || []),
    ]
      .filter(Boolean)
      .join(' ');
    upsertBase(out, 'catalog.search_index', r.entityId, version, mapStatus(r.status), sha256(r), r, {
      scheme_id: sqlStr(r.entityType === 'scheme' ? r.entityId : null),
      content: sqlStr(contentText || r.entityId),
    });
  }
  writeChunked('10_search_index', out);
}

// ---- 11: relationships (flattened from every entity's relationships.references) ----
{
  const files = [
    'common_catalog.json',
    'authority_catalog.json',
    'institution_catalog.json',
    'scheme_catalog.json',
    'finance_catalog.json',
    'tax_catalog.json',
    'export_catalog.json',
    'csr_catalog.json',
    'treds_catalog.json',
    'knowledge_catalog.json',
    'applicability_matrix_catalog.json',
    'enterprise_classification_catalog.json',
    'msme_privilege_catalog.json',
    'business_enablement_catalog.json',
    'cluster_assistance_catalog.json',
  ];
  const out = ['delete from catalog.relationships;'];
  for (const file of files) {
    const { data } = readCatalog(file);
    for (const r of data) {
      const refs = r.relationships?.references || [];
      for (const ref of refs) {
        out.push(
          `insert into catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata) ` +
            `values (${sqlStr(r.identity.entityType)}, ${sqlStr(r.identity.id)}, ${sqlStr(ref.entityType)}, ${sqlStr(
              ref.entityId
            )}, ${sqlStr(ref.relationType)}, ${sqlJson(ref)});`
        );
      }
    }
  }
  writeFile('11_relationships.sql', out);
}
