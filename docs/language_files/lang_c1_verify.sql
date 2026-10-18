-- V1 counts
select 'en' lang, entity_type, count(*) from catalog.content_en group by 2
union all select 'ta', entity_type, count(*) from catalog.content_ta group by 2
union all select 'hi', entity_type, count(*) from catalog.content_hi group by 2 order by 1,2;
-- V2 partition
select (t.entity_id is not null) has_ta, (h.entity_id is not null) has_hi, count(*)
from catalog.content_en e left join catalog.content_ta t using (entity_type, entity_id) left join catalog.content_hi h using (entity_type, entity_id)
where e.entity_type='scheme' group by 1,2 order by 1,2;
-- V3 provenance
select 'ta' lang, origin, verified, count(*) from catalog.content_ta group by 2,3 union all select 'hi', origin, verified, count(*) from catalog.content_hi group by 2,3 order by 1,2,3;
-- V4 stale translations right after seeding (expect 0 rows)
select 'ta' lang, t.entity_type, t.entity_id from catalog.content_ta t join catalog.content_en e using (entity_type, entity_id)
 where t.source_checksum is distinct from catalog.content_checksum(e.name,e.short_name,e.summary,e.objective,e.description,e.benefits_text,e.eligibility_text,e.application_text)
union all
select 'hi', t.entity_type, t.entity_id from catalog.content_hi t join catalog.content_en e using (entity_type, entity_id)
 where t.source_checksum is distinct from catalog.content_checksum(e.name,e.short_name,e.summary,e.objective,e.description,e.benefits_text,e.eligibility_text,e.application_text);
-- V5 per-field non-empty counts (compare with Phase 0 query A)
select 'en' lang, count(name) name, count(short_name) short_name, count(summary) summary, count(objective) objective, count(description) description, count(benefits_text) benefits_text, count(eligibility_text) eligibility_text, count(application_text) application_text from catalog.content_en where entity_type='scheme'
union all select 'ta', count(name), count(short_name), count(summary), count(objective), count(description), count(benefits_text), count(eligibility_text), count(application_text) from catalog.content_ta where entity_type='scheme'
union all select 'hi', count(name), count(short_name), count(summary), count(objective), count(description), count(benefits_text), count(eligibility_text), count(application_text) from catalog.content_hi where entity_type='scheme' order by 1;
-- V6 security
select c.relname, c.relrowsecurity as rls, has_table_privilege('anon', c.oid, 'select') as anon_select, has_table_privilege('authenticated', c.oid, 'select') as auth_select
from pg_class c where c.relnamespace = 'catalog'::regnamespace and c.relname in ('language','content_en','content_ta','content_hi') order by 1;
select has_function_privilege('anon','catalog.add_language(text,text)','execute') as anon_exec, has_function_privilege('authenticated','catalog.add_language(text,text)','execute') as auth_exec;
