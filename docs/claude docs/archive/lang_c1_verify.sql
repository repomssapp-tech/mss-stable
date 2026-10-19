-- V1 counts per language and entity type
select lang, entity_type, count(*) from catalog.content group by 1, 2 order by 1, 2;
-- V2 scheme partition (has_ta / has_hi)
select exists (select 1 from catalog.content t where t.entity_type='scheme' and t.entity_id=e.entity_id and t.lang='ta') as has_ta,
       exists (select 1 from catalog.content h where h.entity_type='scheme' and h.entity_id=e.entity_id and h.lang='hi') as has_hi,
       count(*)
from catalog.content e where e.entity_type='scheme' and e.lang='en' group by 1, 2 order by 1, 2;
-- V3 provenance of translations
select lang, origin, verified, count(*) from catalog.content where lang <> 'en' group by 1, 2, 3 order by 1, 2, 3;
-- V4 stale translations right after seeding (expect 0 rows)
select t.lang, t.entity_type, t.entity_id
from catalog.content t join catalog.content e on e.entity_type = t.entity_type and e.entity_id = t.entity_id and e.lang = 'en'
where t.lang <> 'en'
  and t.source_checksum is distinct from catalog.content_checksum(e.name,e.short_name,e.summary,e.objective,e.description,e.benefits_text,e.eligibility_text,e.application_text);
-- V5 per-field non-empty counts per language (compare with audit query A; name can be higher because of typed-column fallback)
select lang, count(name) name, count(short_name) short_name, count(summary) summary, count(objective) objective, count(description) description,
       count(benefits_text) benefits_text, count(eligibility_text) eligibility_text, count(application_text) application_text
from catalog.content where entity_type = 'scheme' group by lang order by lang;
-- V6 security: RLS on, no privileges for app roles
select c.relname, c.relrowsecurity as rls, has_table_privilege('anon', c.oid, 'select') as anon_select, has_table_privilege('authenticated', c.oid, 'select') as auth_select
from pg_class c where c.relnamespace = 'catalog'::regnamespace and c.relname in ('language','content') order by 1;
