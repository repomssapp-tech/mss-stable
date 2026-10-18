-- 20261017000000_activate_hindi_language.sql
-- Activates Hindi (D10, FINAL_HINDI_LOCALIZATION_REPORT.md §6 step 1).
-- Where a scheme has no Hindi text for a field the app falls back to English
-- for that field, so activation never leaves content blank.
--
-- Pair with a re-published release manifest (tools/build_catalog_release.py,
-- ACTIVE_LANGUAGES now includes 'hi') -- the app reads activeLanguages from it.
--
-- Rollback / kill switch (no app update needed):
--   update catalog.language set is_active = false where code = 'hi';
--   then remove 'hi' from ACTIVE_LANGUAGES and re-publish the release.

update catalog.language
set is_active = true
where code = 'hi';

do $$
begin
  if not exists (select 1 from catalog.language where code = 'hi' and is_active) then
    raise exception 'Hindi language row missing or not active after update';
  end if;
end $$;
