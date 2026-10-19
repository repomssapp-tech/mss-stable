-- 20261005120000_content_language_tables.sql
-- Phase 1 (ADDITIVE ONLY): per-language content tables + seed from existing data.
-- Does NOT modify catalog.scheme / authority / institution / record_json.
-- Must run as ONE transaction (supabase db push does this). Any assertion failure aborts everything.

-- ---------- helpers ----------
create or replace function catalog._nz(p text) returns text
  language sql immutable set search_path = '' as $$ select nullif(btrim(p), '') $$;

create or replace function catalog.jsonb_text_array(j jsonb) returns text[]
  language sql immutable set search_path = '' as $$
  select case when jsonb_typeof(j) = 'array' and jsonb_array_length(j) > 0
              then array(select jsonb_array_elements_text(j)) end
$$;

create or replace function catalog.content_checksum(
  p_name text, p_short_name text, p_summary text, p_objective text,
  p_description text, p_benefits_text text, p_eligibility_text text, p_application_text text)
returns text language sql immutable set search_path = '' as $$
  select md5(jsonb_build_array(p_name, p_short_name, p_summary, p_objective,
                               p_description, p_benefits_text, p_eligibility_text, p_application_text)::text)
$$;

-- ---------- tables ----------
create table catalog.language (
  code        text primary key check (code ~ '^[a-z]{2,3}$'),
  name_native text not null,
  is_active   boolean not null default false,
  created_at  timestamptz not null default now()
);
insert into catalog.language (code, name_native, is_active) values
  ('en', 'English', true), ('ta', U&'\0BA4\0BAE\0BBF\0BB4\0BCD', true), ('hi', U&'\0939\093F\0928\094D\0926\0940', false);

create table catalog.content_en (
  entity_type      text not null check (entity_type in ('scheme','authority','institution','common')),
  entity_id        text not null,
  name             text not null check (length(btrim(name)) > 0),
  short_name       text,
  summary          text,
  objective        text,
  description      text,
  benefits_text    text,
  eligibility_text text,
  application_text text,
  aliases          text[],
  keywords         text[],
  origin           text not null default 'human' check (origin in ('human','machine','imported')),
  engine           text,
  source_checksum  text,
  verified         boolean not null default false,
  verified_by      text,
  verified_at      timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  primary key (entity_type, entity_id)
);
create table catalog.content_ta (like catalog.content_en including all);
create table catalog.content_hi (like catalog.content_en including all);

alter table catalog.language   enable row level security;
alter table catalog.content_en enable row level security;
alter table catalog.content_ta enable row level security;
alter table catalog.content_hi enable row level security;
revoke all on table catalog.language, catalog.content_en, catalog.content_ta, catalog.content_hi
  from anon, authenticated;
-- NOTE: no policies / grants for app roles here on purpose. Mirror catalog.scheme's in a later, separate migration.

create or replace function catalog.add_language(p_code text, p_name_native text) returns void
  language plpgsql set search_path = '' as $$
begin
  if p_code !~ '^[a-z]{2,3}$' then raise exception 'invalid language code: %', p_code; end if;
  insert into catalog.language (code, name_native) values (p_code, p_name_native);
  execute format('create table catalog.%I (like catalog.content_en including all)', 'content_' || p_code);
  execute format('alter table catalog.%I enable row level security', 'content_' || p_code);
  execute format('revoke all on table catalog.%I from anon, authenticated', 'content_' || p_code);
end $$;
revoke execute on function catalog.add_language(text, text) from public, anon, authenticated;

-- ---------- seed: English (schemes) ----------
insert into catalog.content_en (entity_type, entity_id, name, short_name, summary, objective, description,
  benefits_text, eligibility_text, application_text, aliases, keywords, origin, engine, verified)
select 'scheme', s.id,
  coalesce(catalog._nz(l.en->>'name'), catalog._nz(s.name_en)),
  catalog._nz(l.en->>'shortName'), catalog._nz(l.en->>'summary'), catalog._nz(l.en->>'objective'),
  catalog._nz(l.en->>'description'), catalog._nz(l.en->>'benefitsText'),
  catalog._nz(l.en->>'eligibilityText'), catalog._nz(l.en->>'applicationText'),
  catalog.jsonb_text_array(s.record_json #> '{search,aliases,en}'),
  catalog.jsonb_text_array(s.record_json #> '{search,keywords,en}'),
  'human', null,
  coalesce(s.record_json #>> '{verification,isVerified}', 'false') = 'true'
from catalog.scheme s
cross join lateral (select s.record_json #> '{localization,en}' as en) l
where coalesce(catalog._nz(l.en->>'name'), catalog._nz(s.name_en)) is not null;

-- ---------- seed: Tamil (schemes) ----------
insert into catalog.content_ta (entity_type, entity_id, name, short_name, summary, objective, description,
  benefits_text, eligibility_text, application_text, aliases, keywords, origin, engine, source_checksum, verified)
select 'scheme', s.id,
  coalesce(catalog._nz(l.t->>'name'), catalog._nz(s.name_ta)),
  catalog._nz(l.t->>'shortName'), catalog._nz(l.t->>'summary'), catalog._nz(l.t->>'objective'),
  catalog._nz(l.t->>'description'), catalog._nz(l.t->>'benefitsText'),
  catalog._nz(l.t->>'eligibilityText'), catalog._nz(l.t->>'applicationText'),
  catalog.jsonb_text_array(s.record_json #> '{search,aliases,ta}'),
  catalog.jsonb_text_array(s.record_json #> '{search,keywords,ta}'),
  case lower(coalesce(l.p->>'status', ''))
    when 'machine' then 'machine'
    when 'human' then 'human' when 'verified' then 'human'
    when 'approved' then 'human' when 'reviewed' then 'human'
    else 'imported' end,
  l.p->>'engine',
  catalog.content_checksum(e.name, e.short_name, e.summary, e.objective, e.description,
                           e.benefits_text, e.eligibility_text, e.application_text),
  coalesce(l.p->>'isApproved', 'false') = 'true'
from catalog.scheme s
join catalog.content_en e on e.entity_type = 'scheme' and e.entity_id = s.id
cross join lateral (select s.record_json #> '{localization,ta}' as t,
                           s.record_json #> '{provenance,translations,ta}' as p) l
where coalesce(catalog._nz(l.t->>'name'), catalog._nz(s.name_ta)) is not null;

-- ---------- seed: Hindi (schemes) ----------
insert into catalog.content_hi (entity_type, entity_id, name, short_name, summary, objective, description,
  benefits_text, eligibility_text, application_text, aliases, keywords, origin, engine, source_checksum, verified)
select 'scheme', s.id,
  catalog._nz(l.t->>'name'),
  catalog._nz(l.t->>'shortName'), catalog._nz(l.t->>'summary'), catalog._nz(l.t->>'objective'),
  catalog._nz(l.t->>'description'), catalog._nz(l.t->>'benefitsText'),
  catalog._nz(l.t->>'eligibilityText'), catalog._nz(l.t->>'applicationText'),
  catalog.jsonb_text_array(s.record_json #> '{search,aliases,hi}'),
  catalog.jsonb_text_array(s.record_json #> '{search,keywords,hi}'),
  case lower(coalesce(l.p->>'status', ''))
    when 'machine' then 'machine'
    when 'human' then 'human' when 'verified' then 'human'
    when 'approved' then 'human' when 'reviewed' then 'human'
    else 'imported' end,
  l.p->>'engine',
  catalog.content_checksum(e.name, e.short_name, e.summary, e.objective, e.description,
                           e.benefits_text, e.eligibility_text, e.application_text),
  coalesce(l.p->>'isApproved', 'false') = 'true'
from catalog.scheme s
join catalog.content_en e on e.entity_type = 'scheme' and e.entity_id = s.id
cross join lateral (select s.record_json #> '{localization,hi}' as t,
                           s.record_json #> '{provenance,translations,hi}' as p) l
where catalog._nz(l.t->>'name') is not null;

-- ---------- seed: authority + institution (names only, typed columns) ----------
insert into catalog.content_en (entity_type, entity_id, name)
select 'authority', a.id, catalog._nz(a.name_en) from catalog.authority a where catalog._nz(a.name_en) is not null;
insert into catalog.content_en (entity_type, entity_id, name)
select 'institution', i.id, catalog._nz(i.name_en) from catalog.institution i where catalog._nz(i.name_en) is not null;

insert into catalog.content_ta (entity_type, entity_id, name, origin, source_checksum)
select 'authority', a.id, catalog._nz(a.name_ta), 'imported',
       catalog.content_checksum(e.name, null, null, null, null, null, null, null)
from catalog.authority a
join catalog.content_en e on e.entity_type = 'authority' and e.entity_id = a.id
where catalog._nz(a.name_ta) is not null;
insert into catalog.content_ta (entity_type, entity_id, name, origin, source_checksum)
select 'institution', i.id, catalog._nz(i.name_ta), 'imported',
       catalog.content_checksum(e.name, null, null, null, null, null, null, null)
from catalog.institution i
join catalog.content_en e on e.entity_type = 'institution' and e.entity_id = i.id
where catalog._nz(i.name_ta) is not null;

-- >>> ASSERT (any mismatch raises -> whole migration rolls back)
do $$
declare
  r record;
begin
  for r in
    select * from (values
      ('scheme en',      (select count(*) from catalog.scheme s where coalesce(catalog._nz(s.record_json #>> '{localization,en,name}'), catalog._nz(s.name_en)) is not null),
                         (select count(*) from catalog.content_en where entity_type = 'scheme')),
      ('scheme ta',      (select count(*) from catalog.scheme s where coalesce(catalog._nz(s.record_json #>> '{localization,ta,name}'), catalog._nz(s.name_ta)) is not null),
                         (select count(*) from catalog.content_ta where entity_type = 'scheme')),
      ('scheme hi',      (select count(*) from catalog.scheme s where catalog._nz(s.record_json #>> '{localization,hi,name}') is not null),
                         (select count(*) from catalog.content_hi where entity_type = 'scheme')),
      ('authority en',   (select count(*) from catalog.authority where catalog._nz(name_en) is not null),
                         (select count(*) from catalog.content_en where entity_type = 'authority')),
      ('authority ta',   (select count(*) from catalog.authority where catalog._nz(name_ta) is not null),
                         (select count(*) from catalog.content_ta where entity_type = 'authority')),
      ('institution en', (select count(*) from catalog.institution where catalog._nz(name_en) is not null),
                         (select count(*) from catalog.content_en where entity_type = 'institution')),
      ('institution ta', (select count(*) from catalog.institution where catalog._nz(name_ta) is not null),
                         (select count(*) from catalog.content_ta where entity_type = 'institution')),
      ('orphans ta/hi (rows without English)',
                         0::bigint,
                         (select count(*) from (
                            select entity_type, entity_id from catalog.content_ta
                            union all select entity_type, entity_id from catalog.content_hi) x
                          where not exists (select 1 from catalog.content_en e
                                            where e.entity_type = x.entity_type and e.entity_id = x.entity_id)))
    ) v(label, expected, actual)
  loop
    if r.expected <> r.actual then
      raise exception 'ASSERT FAILED [%]: expected %, got %', r.label, r.expected, r.actual;
    end if;
  end loop;
end $$;
-- <<< ASSERT
