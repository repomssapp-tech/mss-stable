-- Migration: 20261006030000_hindi_content_fixes.sql
-- Fixes per Hindi localization audit:
-- 1. Remove duplicate 'पीएम विश्वकर्मा' alias from all non-SCH000124 hi rows in catalog.content.
-- 2. Translate AUTH000126-131 into official Hindi names; delete 83 English institution hi rows.
-- 3. Regenerate record_json.localization.hi and record_json.search.aliases.hi in catalog.scheme from catalog.content.
-- 4. Expose public.mss_current_release_packs() for mobile app on-demand language pack downloads.

-- 1. Remove alias 'पीएम विश्वकर्मा' from every hi row except SCH000124
UPDATE catalog.content
SET aliases = array_remove(aliases, 'पीएम विश्वकर्मा'),
    updated_at = now()
WHERE lang = 'hi'
  AND entity_id <> 'SCH000124'
  AND 'पीएम विश्वकर्मा' = ANY(aliases);

-- 2. Fix non-Devanagari names in catalog.content
-- 2a. Translate authorities AUTH000126–AUTH000131
UPDATE catalog.content
SET name = 'श्रम एवं रोजगार मंत्रालय', updated_at = now()
WHERE entity_type = 'authority' AND entity_id = 'AUTH000126' AND lang = 'hi';

UPDATE catalog.content
SET name = 'मत्स्य पालन, पशुपालन और डेयरी मंत्रालय', updated_at = now()
WHERE entity_type = 'authority' AND entity_id = 'AUTH000128' AND lang = 'hi';

UPDATE catalog.content
SET name = 'नवीन एवं नवीकरणीय ऊर्जा मंत्रालय', updated_at = now()
WHERE entity_type = 'authority' AND entity_id = 'AUTH000129' AND lang = 'hi';

UPDATE catalog.content
SET name = 'भारी उद्योग मंत्रालय', updated_at = now()
WHERE entity_type = 'authority' AND entity_id = 'AUTH000130' AND lang = 'hi';

UPDATE catalog.content
SET name = 'जनजातीय कार्य मंत्रालय', updated_at = now()
WHERE entity_type = 'authority' AND entity_id = 'AUTH000131' AND lang = 'hi';

-- 2b. Delete 83 untranslated institution hi rows so English fallback is explicit
DELETE FROM catalog.content
WHERE entity_type = 'institution' AND lang = 'hi';

-- 3. Regenerate record_json.localization.hi and record_json.search.aliases.hi in catalog.scheme
WITH content_hi AS (
  SELECT 
    c.entity_id AS scheme_id,
    jsonb_strip_nulls(jsonb_build_object(
      'name', c.name,
      'shortName', c.short_name,
      'summary', c.summary,
      'objective', c.objective,
      'description', c.description,
      'benefitsText', c.benefits_text,
      'eligibilityText', c.eligibility_text,
      'applicationText', c.application_text
    )) AS loc_hi,
    to_jsonb(COALESCE(c.aliases, '{}'::text[])) AS aliases_hi
  FROM catalog.content c
  WHERE c.entity_type = 'scheme' AND c.lang = 'hi'
)
UPDATE catalog.scheme s
SET record_json = jsonb_set(
  jsonb_set(
    s.record_json,
    '{search,aliases,hi}',
    c.aliases_hi
  ),
  '{localization,hi}',
  c.loc_hi
)
FROM content_hi c
WHERE s.id = c.scheme_id;

-- 4. Expose public.mss_current_release_packs()
CREATE OR REPLACE FUNCTION public.mss_current_release_packs()
RETURNS TABLE (
  file_name text,
  byte_size integer,
  checksum text,
  storage_path text,
  lang text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, admin, extensions
AS $$
  SELECT f.file_name, f.byte_size, f.checksum, f.storage_path, f.lang
  FROM admin.catalog_files f
  JOIN admin.catalog_releases r ON r.id = f.release_id
  WHERE r.is_current = true AND r.status = 'published' AND f.lang IS NOT NULL;
$$;

GRANT EXECUTE ON FUNCTION public.mss_current_release_packs() TO anon, authenticated;
