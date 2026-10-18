-- A. per-field, per-language coverage (non-empty counts) over ALL schemes
with f(field, ord) as (values ('name',1),('shortName',2),('summary',3),('objective',4),('description',5),('benefitsText',6),('eligibilityText',7),('applicationText',8)),
     l(lang) as (values ('en'),('ta'),('hi'))
select l.lang, f.field,
       count(*) filter (where nullif(btrim(s.record_json #>> array['localization', l.lang, f.field]), '') is not null) as non_empty,
       count(*) as total
from catalog.scheme s cross join f cross join l
group by l.lang, f.field, f.ord order by l.lang, f.ord;

-- B. rows that have some ta/hi text but NO usable name (migration would skip them) -> expect 0 rows
select l.lang, count(*) as rows_with_text_but_no_name
from catalog.scheme s
cross join (values ('ta'), ('hi')) l(lang)
cross join lateral (select s.record_json #> array['localization', l.lang] as j) x
where coalesce(nullif(btrim(x.j ->> 'name'), ''), case when l.lang = 'ta' then nullif(btrim(s.name_ta), '') end) is null
  and jsonb_typeof(x.j) = 'object'
  and exists (select 1 from jsonb_each_text(x.j) kv where nullif(btrim(kv.value), '') is not null)
group by l.lang;

-- C. typed column vs localization JSON: which one wins when they differ
select 'en' as lang,
  count(*) filter (where nullif(btrim(record_json #>> '{localization,en,name}'),'') is not null and nullif(btrim(name_en),'') is not null and btrim(record_json #>> '{localization,en,name}') <> btrim(name_en)) as both_but_different,
  count(*) filter (where nullif(btrim(record_json #>> '{localization,en,name}'),'') is not null and nullif(btrim(name_en),'') is null) as json_only,
  count(*) filter (where nullif(btrim(record_json #>> '{localization,en,name}'),'') is null and nullif(btrim(name_en),'') is not null) as column_only
from catalog.scheme
union all
select 'ta',
  count(*) filter (where nullif(btrim(record_json #>> '{localization,ta,name}'),'') is not null and nullif(btrim(name_ta),'') is not null and btrim(record_json #>> '{localization,ta,name}') <> btrim(name_ta)),
  count(*) filter (where nullif(btrim(record_json #>> '{localization,ta,name}'),'') is not null and nullif(btrim(name_ta),'') is null),
  count(*) filter (where nullif(btrim(record_json #>> '{localization,ta,name}'),'') is null and nullif(btrim(name_ta),'') is not null)
from catalog.scheme;

-- D. who has which language, by government level (expected from your numbers: ta-only 174 / hi-only 83 / both 45 / neither 0)
select government_level,
       (coalesce(nullif(btrim(record_json #>> '{localization,ta,name}'),''), nullif(btrim(name_ta),'')) is not null) as has_ta,
       (nullif(btrim(record_json #>> '{localization,hi,name}'),'') is not null) as has_hi,
       count(*) as schemes
from catalog.scheme group by 1,2,3 order by 1,2,3;

-- E. status / is_active combinations
select status, is_active, count(*) from catalog.scheme group by 1,2 order by 1,2;

-- F. translation provenance recorded per language
select t.k as lang, t.v ->> 'status' as status, t.v ->> 'engine' as engine, coalesce(t.v ->> 'isApproved', 'null') as is_approved, count(*)
from catalog.scheme s
cross join lateral jsonb_each(case when jsonb_typeof(s.record_json #> '{provenance,translations}') = 'object' then s.record_json #> '{provenance,translations}' else '{}'::jsonb end) t(k, v)
group by 1,2,3,4 order by 1,5 desc;

-- H. existing RLS policies and grants on catalog.scheme (to mirror later)
select policyname, roles, cmd, qual from pg_policies where schemaname = 'catalog' and tablename = 'scheme';
select grantee, privilege_type from information_schema.role_table_grants where table_schema = 'catalog' and table_name = 'scheme' order by 1,2;

-- L. Tamil names that exist in typed columns of authority/institution (migration seeds these)
select 'authority' as t, count(*) as total, count(*) filter (where nullif(btrim(name_ta), '') is not null) as with_ta from catalog.authority
union all
select 'institution', count(*), count(*) filter (where nullif(btrim(name_ta), '') is not null) from catalog.institution;
