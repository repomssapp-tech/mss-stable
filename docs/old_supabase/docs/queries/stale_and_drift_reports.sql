-- ============================================================================
-- Saved Operational & Verification Queries: Stale Detection and Drift Reports
-- Target Database: Supabase catalog & admin schemas
-- Master Plan References: Decision D13, Phase P6, Phase P7
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. STALE TRANSLATION DETECTION (Decision D13)
-- Finds translation rows (lang != 'en') whose stored source_checksum no longer
-- matches the current checksum of the corresponding English content.
-- Any row returned here is STALE (the English source was edited after translation)
-- and must either be re-translated or excluded from language packs.
-- ----------------------------------------------------------------------------
with english_checksums as (
  select 
    entity_type,
    entity_id,
    catalog.content_checksum(
      name, short_name, summary, objective,
      description, benefits_text, eligibility_text, application_text
    ) as current_en_checksum
  from catalog.content
  where lang = 'en'
)
select 
  c.lang,
  c.entity_type,
  c.entity_id,
  c.name,
  c.source_checksum as stored_checksum,
  e.current_en_checksum,
  case 
    when c.source_checksum is null then 'MISSING_SOURCE_CHECKSUM'
    when c.source_checksum != e.current_en_checksum then 'STALE_ENGLISH_MODIFIED'
    else 'UP_TO_DATE'
  end as status,
  c.origin,
  c.verified,
  c.updated_at as translation_updated_at
from catalog.content c
join english_checksums e 
  on e.entity_type = c.entity_type 
 and e.entity_id = c.entity_id
where c.lang <> 'en'
  and (c.source_checksum is null or c.source_checksum != e.current_en_checksum)
order by c.lang, c.entity_type, c.entity_id;


-- ----------------------------------------------------------------------------
-- 2. SCHEME LOCALIZATION DRIFT REPORT (catalog.content vs record_json.localization)
-- Compares text in catalog.content against the legacy record_json.localization
-- blocks inside catalog.scheme. Used to verify 0-drift before cutover (Phase P7).
-- ----------------------------------------------------------------------------
with content_fields as (
  select
    c.entity_id as scheme_id,
    c.lang,
    c.name,
    c.short_name,
    c.summary,
    c.objective,
    c.description,
    c.benefits_text,
    c.eligibility_text,
    c.application_text
  from catalog.content c
  where c.entity_type = 'scheme'
),
json_fields as (
  select
    s.id as scheme_id,
    l.lang,
    catalog._nz(l.obj->>'name') as name,
    catalog._nz(l.obj->>'shortName') as short_name,
    catalog._nz(l.obj->>'summary') as summary,
    catalog._nz(l.obj->>'objective') as objective,
    catalog._nz(l.obj->>'description') as description,
    catalog._nz(l.obj->>'benefitsText') as benefits_text,
    catalog._nz(l.obj->>'eligibilityText') as eligibility_text,
    catalog._nz(l.obj->>'applicationText') as application_text
  from catalog.scheme s
  cross join lateral (
    values 
      ('en', s.record_json #> '{localization,en}'),
      ('ta', s.record_json #> '{localization,ta}'),
      ('hi', s.record_json #> '{localization,hi}')
  ) l(lang, obj)
  where l.obj is not null
    and catalog._nz(l.obj->>'name') is not null
)
select
  coalesce(c.scheme_id, j.scheme_id) as scheme_id,
  coalesce(c.lang, j.lang) as lang,
  case 
    when c.scheme_id is null then 'ONLY_IN_JSON'
    when j.scheme_id is null then 'ONLY_IN_CONTENT'
    when c.name is distinct from j.name then 'DIFF_NAME'
    when c.short_name is distinct from j.short_name then 'DIFF_SHORT_NAME'
    when c.summary is distinct from j.summary then 'DIFF_SUMMARY'
    when c.objective is distinct from j.objective then 'DIFF_OBJECTIVE'
    when c.description is distinct from j.description then 'DIFF_DESCRIPTION'
    when c.benefits_text is distinct from j.benefits_text then 'DIFF_BENEFITS'
    when c.eligibility_text is distinct from j.eligibility_text then 'DIFF_ELIGIBILITY'
    when c.application_text is distinct from j.application_text then 'DIFF_APPLICATION'
  end as diff_type,
  c.name as content_name,
  j.name as json_name
from content_fields c
full outer join json_fields j
  on c.scheme_id = j.scheme_id
 and c.lang = j.lang
where c.scheme_id is null 
   or j.scheme_id is null
   or c.name is distinct from j.name
   or c.short_name is distinct from j.short_name
   or c.summary is distinct from j.summary
   or c.objective is distinct from j.objective
   or c.description is distinct from j.description
   or c.benefits_text is distinct from j.benefits_text
   or c.eligibility_text is distinct from j.eligibility_text
   or c.application_text is distinct from j.application_text
order by scheme_id, lang;


-- ----------------------------------------------------------------------------
-- 3. TYPED NAME COLUMN DRIFT REPORT (catalog.content vs base table name columns)
-- Checks whether name_en / name_ta in catalog.scheme, catalog.authority, and
-- catalog.institution match catalog.content.
-- ----------------------------------------------------------------------------
-- Scheme Name Drift
select 
  'scheme' as entity_type,
  s.id as entity_id,
  'en' as lang,
  c.name as content_name,
  s.name_en as base_table_name
from catalog.scheme s
left join catalog.content c on c.entity_type = 'scheme' and c.entity_id = s.id and c.lang = 'en'
where catalog._nz(s.name_en) is not null and c.name is distinct from catalog._nz(s.name_en)
union all
select 
  'scheme' as entity_type,
  s.id as entity_id,
  'ta' as lang,
  c.name as content_name,
  s.name_ta as base_table_name
from catalog.scheme s
left join catalog.content c on c.entity_type = 'scheme' and c.entity_id = s.id and c.lang = 'ta'
where catalog._nz(s.name_ta) is not null and c.name is distinct from catalog._nz(s.name_ta)
union all
-- Authority Name Drift
select 
  'authority' as entity_type,
  a.id as entity_id,
  'en' as lang,
  c.name as content_name,
  a.name_en as base_table_name
from catalog.authority a
left join catalog.content c on c.entity_type = 'authority' and c.entity_id = a.id and c.lang = 'en'
where catalog._nz(a.name_en) is not null and c.name is distinct from catalog._nz(a.name_en)
union all
select 
  'authority' as entity_type,
  a.id as entity_id,
  'ta' as lang,
  c.name as content_name,
  a.name_ta as base_table_name
from catalog.authority a
left join catalog.content c on c.entity_type = 'authority' and c.entity_id = a.id and c.lang = 'ta'
where catalog._nz(a.name_ta) is not null and c.name is distinct from catalog._nz(a.name_ta)
union all
-- Institution Name Drift
select 
  'institution' as entity_type,
  i.id as entity_id,
  'en' as lang,
  c.name as content_name,
  i.name_en as base_table_name
from catalog.institution i
left join catalog.content c on c.entity_type = 'institution' and c.entity_id = i.id and c.lang = 'en'
where catalog._nz(i.name_en) is not null and c.name is distinct from catalog._nz(i.name_en)
union all
select 
  'institution' as entity_type,
  i.id as entity_id,
  'ta' as lang,
  c.name as content_name,
  i.name_ta as base_table_name
from catalog.institution i
left join catalog.content c on c.entity_type = 'institution' and c.entity_id = i.id and c.lang = 'ta'
where catalog._nz(i.name_ta) is not null and c.name is distinct from catalog._nz(i.name_ta);


-- ----------------------------------------------------------------------------
-- 4. VERIFICATION AND ORIGIN SUMMARY REPORT
-- High-level count of verified vs unverified rows per language and entity type.
-- ----------------------------------------------------------------------------
select 
  lang,
  entity_type,
  origin,
  verified,
  count(*) as row_count,
  count(name) as name_count,
  count(summary) as summary_count,
  count(benefits_text) as benefits_count,
  count(eligibility_text) as eligibility_count
from catalog.content
group by lang, entity_type, origin, verified
order by lang, entity_type, origin, verified;


-- ----------------------------------------------------------------------------
-- 5. TRANSLATION JOBS AUDIT & NEEDS-REVIEW REPORT
-- Queries admin.translation_jobs for errors and number-mismatch fallbacks.
-- ----------------------------------------------------------------------------
select 
  target_lang,
  status,
  error_message,
  count(*) as job_count,
  min(created_at) as first_occurrence,
  max(created_at) as latest_occurrence
from admin.translation_jobs
group by target_lang, status, error_message
order by target_lang, status;
