-- ===========================================================
-- Migration: fix_mistagged_scheme_intent_tags
-- Project  : MSS - MSME Schemes Search
-- Purpose : catalog.search_index.record_json->schemeSearchProfile.userIntentTags
--           carried a 'TAX_REQUEST' tag on 4 schemes that have no tax-related
--           nature at all (no linked catalog.tax record, and
--           financialBenefits does not include 'taxBenefit'). This let a
--           bare intent-tag match in the local ranking engine
--           (HybridSchemeSearch._benefitScore) outrank genuinely tax-related
--           schemes for queries like "tax exemption manufacturing" -- e.g.
--           the "Low Tension Power Tariff (LTPT) Subsidy" (an electricity-
--           cost subsidy) was outranking real catalog.tax-backed schemes.
--
--           Verified before removing: each of the 4 rows below has (a) no
--           catalog.relationships row linking it to catalog.tax, and (b)
--           financialBenefits without 'taxBenefit'. Two other schemes that
--           matched the same "TAX_REQUEST present, taxBenefits array empty"
--           filter (SCH000005 Advance Authorisation, SCH000169 Startup
--           India) were confirmed to legitimately carry 'taxBenefit' in
--           financialBenefits and are left untouched, as is SCH000057
--           (EPCG), a genuine customs-duty exemption scheme, per the
--           explicit "don't over do it" instruction to keep this correction
--           minimal and evidence-backed rather than a wholesale re-tag.
--
--           catalog.search_index.checksum is recomputed automatically by
--           the trg_recompute_checksum trigger (see
--           20260904000000_catalog_row_checksum_trigger.sql) -- no manual
--           checksum handling needed here.
-- ===========================================================

begin;

update catalog.search_index
set record_json = jsonb_set(
  record_json,
  '{schemeSearchProfile,userIntentTags}',
  (select coalesce(jsonb_agg(x), '[]'::jsonb)
   from jsonb_array_elements(record_json->'schemeSearchProfile'->'userIntentTags') x
   where x <> '"TAX_REQUEST"'::jsonb)
)
where id in ('SCH000079', 'SCH000094', 'SCH000141', 'SCH000152')
  and record_json->'schemeSearchProfile'->'userIntentTags' @> '["TAX_REQUEST"]'::jsonb;

commit;

-- ===========================================================
-- Rollback (manual):
--   begin;
--   update catalog.search_index
--   set record_json = jsonb_set(
--     record_json,
--     '{schemeSearchProfile,userIntentTags}',
--     (record_json->'schemeSearchProfile'->'userIntentTags') || '["TAX_REQUEST"]'::jsonb
--   )
--   where id in ('SCH000079', 'SCH000094', 'SCH000141', 'SCH000152');
--   commit;
-- ===========================================================
