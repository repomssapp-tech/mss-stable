-- 20261005120000_content_table.sql
-- Phase 1 (ADDITIVE ONLY): ONE translations table (catalog.content, one row per entity + language) + seed from existing data.
-- Does NOT modify catalog.scheme / authority / institution / record_json.
-- Must run as ONE transaction (supabase db push does this). Any assertion failure aborts everything.
-- Adding a language later = INSERT into catalog.language (in a migration) + insert content rows. No DDL.

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
  is_active   boolean not null default false,   -- controls whether the bundle build emits a pack for this language
  created_at  timestamptz not null default now()
);
insert into catalog.language (code, name_native, is_active) values
  ('en', 'English', true), ('ta', U&'\0BA4\0BAE\0BBF\0BB4\0BCD', true), ('hi', U&'\0939\093F\0928\094D\0926\0940', false);

create table catalog.content (
  entity_type      text not null check (entity_type in ('scheme','authority','institution','common')),
  entity_id        text not null,
  lang             text not null references catalog.language (code),
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
  source_checksum  text,       -- checksum of the English fields this translation was made from (null for English rows)
  verified         boolean not null default false,
  verified_by      text,
  verified_at      timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  -- constant 'en'; together with the foreign key below it guarantees every translation row has an English row
  en_ref           text generated always as ('en') stored not null,
  primary key (entity_type, entity_id, lang),
  foreign key (entity_type, entity_id, en_ref) references catalog.content (entity_type, entity_id, lang) on delete restrict
);
create index content_lang_idx on catalog.content (lang, entity_type, entity_id);   -- pack export: all rows of one language

alter table catalog.language enable row level security;
alter table catalog.content  enable row level security;
revoke all on table catalog.language, catalog.content from anon, authenticated;
-- NOTE: no policies / grants for app roles here on purpose. Mirror catalog.scheme's in a later, separate migration.

-- ---------- seed: English (schemes) ----------
insert into catalog.content (entity_type, entity_id, lang, name, short_name, summary, objective, description,
  benefits_text, eligibility_text, application_text, aliases, keywords, origin, engine, verified)
select 'scheme', s.id, 'en',
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
insert into catalog.content (entity_type, entity_id, lang, name, short_name, summary, objective, description,
  benefits_text, eligibility_text, application_text, aliases, keywords, origin, engine, source_checksum, verified)
select 'scheme', s.id, 'ta',
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
join catalog.content e on e.entity_type = 'scheme' and e.entity_id = s.id and e.lang = 'en'
cross join lateral (select s.record_json #> '{localization,ta}' as t,
                           s.record_json #> '{provenance,translations,ta}' as p) l
where coalesce(catalog._nz(l.t->>'name'), catalog._nz(s.name_ta)) is not null;

-- ---------- seed: Hindi (schemes) ----------
insert into catalog.content (entity_type, entity_id, lang, name, short_name, summary, objective, description,
  benefits_text, eligibility_text, application_text, aliases, keywords, origin, engine, source_checksum, verified)
select 'scheme', s.id, 'hi',
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
join catalog.content e on e.entity_type = 'scheme' and e.entity_id = s.id and e.lang = 'en'
cross join lateral (select s.record_json #> '{localization,hi}' as t,
                           s.record_json #> '{provenance,translations,hi}' as p) l
where catalog._nz(l.t->>'name') is not null;

-- ---------- seed: authority + institution (names only, typed columns) ----------
insert into catalog.content (entity_type, entity_id, lang, name)
select 'authority', a.id, 'en', catalog._nz(a.name_en) from catalog.authority a where catalog._nz(a.name_en) is not null;
insert into catalog.content (entity_type, entity_id, lang, name)
select 'institution', i.id, 'en', catalog._nz(i.name_en) from catalog.institution i where catalog._nz(i.name_en) is not null;

insert into catalog.content (entity_type, entity_id, lang, name, origin, source_checksum)
select 'authority', a.id, 'ta', catalog._nz(a.name_ta), 'imported',
       catalog.content_checksum(e.name, null, null, null, null, null, null, null)
from catalog.authority a
join catalog.content e on e.entity_type = 'authority' and e.entity_id = a.id and e.lang = 'en'
where catalog._nz(a.name_ta) is not null;
insert into catalog.content (entity_type, entity_id, lang, name, origin, source_checksum)
select 'institution', i.id, 'ta', catalog._nz(i.name_ta), 'imported',
       catalog.content_checksum(e.name, null, null, null, null, null, null, null)
from catalog.institution i
join catalog.content e on e.entity_type = 'institution' and e.entity_id = i.id and e.lang = 'en'
where catalog._nz(i.name_ta) is not null;

-- >>> ASSERT (any mismatch raises -> whole migration rolls back)
do $$
declare
  r record;
begin
  for r in
    select * from (values
      ('scheme en',      (select count(*) from catalog.scheme s where coalesce(catalog._nz(s.record_json #>> '{localization,en,name}'), catalog._nz(s.name_en)) is not null),
                         (select count(*) from catalog.content where entity_type = 'scheme' and lang = 'en')),
      ('scheme ta',      (select count(*) from catalog.scheme s where coalesce(catalog._nz(s.record_json #>> '{localization,ta,name}'), catalog._nz(s.name_ta)) is not null),
                         (select count(*) from catalog.content where entity_type = 'scheme' and lang = 'ta')),
      ('scheme hi',      (select count(*) from catalog.scheme s where catalog._nz(s.record_json #>> '{localization,hi,name}') is not null),
                         (select count(*) from catalog.content where entity_type = 'scheme' and lang = 'hi')),
      ('authority en',   (select count(*) from catalog.authority where catalog._nz(name_en) is not null),
                         (select count(*) from catalog.content where entity_type = 'authority' and lang = 'en')),
      ('authority ta',   (select count(*) from catalog.authority where catalog._nz(name_ta) is not null),
                         (select count(*) from catalog.content where entity_type = 'authority' and lang = 'ta')),
      ('institution en', (select count(*) from catalog.institution where catalog._nz(name_en) is not null),
                         (select count(*) from catalog.content where entity_type = 'institution' and lang = 'en')),
      ('institution ta', (select count(*) from catalog.institution where catalog._nz(name_ta) is not null),
                         (select count(*) from catalog.content where entity_type = 'institution' and lang = 'ta')),
      ('rows in a language not listed in catalog.language',
                         0::bigint,
                         (select count(*) from catalog.content c where not exists (select 1 from catalog.language l where l.code = c.lang))),
      ('translation rows without an English row',
                         0::bigint,
                         (select count(*) from catalog.content c where c.lang <> 'en' and not exists (
                            select 1 from catalog.content e where e.entity_type = c.entity_type and e.entity_id = c.entity_id and e.lang = 'en')))
    ) v(label, expected, actual)
  loop
    if r.expected <> r.actual then
      raise exception 'ASSERT FAILED [%]: expected %, got %', r.label, r.expected, r.actual;
    end if;
  end loop;
end $$;
-- <<< ASSERT
